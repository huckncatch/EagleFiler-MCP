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
    -- Collect file aliases inside tell (POSIX path coercion fails inside tell application block)
    set libFiles to {}
    tell application "EagleFiler"
        set libCount to count of library documents
        repeat with i from 1 to libCount
            set end of libFiles to (file of library document i)
        end repeat
    end tell
    -- Compare POSIX paths outside tell block
    repeat with i from 1 to count of libFiles
        set libPathRaw to POSIX path of (item i of libFiles)
        set normalPath to ((current application's NSString's stringWithString:libPathRaw)'s stringByStandardizingPath()) as text
        if normalPath is libPath then
            tell application "EagleFiler"
                return library document i
            end tell
        end if
    end repeat
    return missing value
end findLib

on run argv
    -- argv[1]: library path, argv[2]: record GUID,
    -- argv[3]: "1" to set the filename, argv[4]: new basename (no extension),
    -- argv[5]: "1" to set the title, argv[6]: new title ("" re-links the title to the filename)
    set libPath to item 1 of argv
    set recGUID to item 2 of argv
    set setName to ((item 3 of argv) is "1")
    set newName to item 4 of argv
    set setTitle to ((item 5 of argv) is "1")
    set newTitle to item 6 of argv

    set theLib to my findLib(libPath)
    if theLib is missing value then return my errResp("library not open: " & libPath)

    tell application "EagleFiler"
        try
            set theRec to first library record of theLib whose guid is recGUID
        on error
            return my errResp("record not found: " & recGUID)
        end try
        -- Filename first, so that a blank title links to the new filename
        if setName then
            try
                set basename of theRec to newName
            on error errMsg
                return my errResp("Failed to set the filename: " & errMsg)
            end try
        end if
        if setTitle then
            try
                set title of theRec to newTitle
            on error errMsg
                return my errResp("Failed to set the title: " & errMsg)
            end try
        end if
        set finalTitle to title of theRec
        set finalName to filename of theRec
    end tell

    set d to current application's NSMutableDictionary's new()
    d's setValue:recGUID forKey:"guid"
    d's setValue:finalTitle forKey:"title"
    d's setValue:finalName forKey:"filename"
    return my okResp(d)
end run
