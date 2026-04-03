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
    -- argv[1]: library path, argv[2]: record GUID
    set libPath to item 1 of argv
    set recGUID to item 2 of argv

    set theLib to my findLib(libPath)
    if theLib is missing value then return my errResp("library not open: " & libPath)

    tell application "EagleFiler"
        set theRec to missing value
        try
            set theRec to first library record of theLib whose guid is recGUID
        on error
            return my errResp("record not found: " & recGUID)
        end try
        try
            set container of theRec to trash of theLib
        on error errMsg
            return my errResp("Failed to trash record: " & errMsg)
        end try
    end tell

    set d to current application's NSMutableDictionary's new()
    d's setValue:recGUID forKey:"guid"
    return my okResp(d)
end run
