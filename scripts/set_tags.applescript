use framework "Foundation"
use scripting additions

on toJSON(nsObj)
    set jsonData to current application's NSJSONSerialization's dataWithJSONObject:nsObj options:0 |error|:(missing value)
    return (current application's NSString's alloc()'s initWithData:jsonData encoding:(current application's NSUTF8StringEncoding)) as text
end toJSON
on okResp(d)
    set r to current application's NSMutableDictionary's new()
    r's setValue:true forKey:"ok"
    r's setValue:d forKey:"data"
    return my toJSON(r)
end okResp
on errResp(msg)
    set r to current application's NSMutableDictionary's new()
    r's setValue:false forKey:"ok"
    r's setValue:msg forKey:"error"
    return my toJSON(r)
end errResp
on findLib(libPath)
    tell application "EagleFiler"
        repeat with lib in library documents
            if ((current application's NSString's stringWithString:(POSIX path of (get file of lib)))'s stringByStandardizingPath() as text) is libPath then return lib
        end repeat
    end tell
    return missing value
end findLib

on run argv
    -- argv[1]: library path, argv[2]: record GUID, argv[3]: JSON array of tag strings
    set libPath to item 1 of argv
    set recGUID to item 2 of argv
    set tagsJSON to item 3 of argv

    set theLib to my findLib(libPath)
    if theLib is missing value then return my errResp("library not open: " & libPath)

    set tagsData to (current application's NSString's stringWithString:tagsJSON)'s dataUsingEncoding:(current application's NSUTF8StringEncoding)
    set tagsList to current application's NSJSONSerialization's JSONObjectWithData:tagsData options:0 |error|:(missing value)
    if tagsList is missing value then return my errResp("Invalid tags JSON")
    if (tagsList's isKindOfClass:(current application's NSArray's class)) as boolean is false then return my errResp("Tags must be a JSON array")

    -- Convert NSArray to AppleScript list
    set asTagList to {}
    repeat with i from 1 to (tagsList's count()) as integer
        set end of asTagList to ((tagsList's objectAtIndex:(i - 1)) as text)
    end repeat

    tell application "EagleFiler"
        try
            set theRec to first library record of theLib whose guid is recGUID
        on error
            return my errResp("record not found: " & recGUID)
        end try
        try
            set assigned tag names of theRec to asTagList
            set finalTags to assigned tag names of theRec
        on error errMsg
            return my errResp("Failed to set tags: " & errMsg)
        end try
    end tell

    set resultTags to current application's NSMutableArray's new()
    repeat with t in finalTags
        resultTags's addObject:(t as text)
    end repeat

    set d to current application's NSMutableDictionary's new()
    d's setValue:recGUID forKey:"guid"
    d's setValue:resultTags forKey:"tags"
    return my okResp(d)
end run
