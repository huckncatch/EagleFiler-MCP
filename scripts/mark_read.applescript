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
            if POSIX path of (get file of lib) is libPath then return lib
        end repeat
    end tell
    return missing value
end findLib

on run argv
    -- argv[1]: library path, argv[2]: GUID, argv[3]: "true" (mark read) or "false" (mark unread)
    set libPath to item 1 of argv
    set recGUID to item 2 of argv
    set readVal to (item 3 of argv) is "true"

    set theLib to my findLib(libPath)
    if theLib is missing value then return my errResp("library not open: " & libPath)

    tell application "EagleFiler"
        try
            set theRec to first library record of theLib whose guid is recGUID
        on error
            return my errResp("record not found: " & recGUID)
        end try
        -- EagleFiler uses `unread` property; read=true means unread=false
        set unread of theRec to (not readVal)
    end tell

    set d to current application's NSMutableDictionary's new()
    d's setValue:recGUID forKey:"guid"
    d's setValue:readVal forKey:"read"
    return my okResp(d)
end run
