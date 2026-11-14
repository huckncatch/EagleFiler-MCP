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
    -- argv[1]: library path
    set libPath to item 1 of argv
    set theLib to my findLib(libPath)
    if theLib is missing value then return my errResp("library not open: " & libPath)

    set out to current application's NSMutableArray's new()
    tell application "EagleFiler"
        set tagNames to (get name of every tag of theLib)
        repeat with nm in tagNames
            set nm to nm as text
            set c to count (every library record of (tag nm of theLib))
            set d to current application's NSMutableDictionary's new()
            d's setValue:nm forKey:"name"
            d's setValue:c forKey:"count"
            out's addObject:d
        end repeat
    end tell
    return my okResp(out)
end run
