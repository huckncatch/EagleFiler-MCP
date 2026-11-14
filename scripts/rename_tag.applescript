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
    -- argv[1]: library path, argv[2]: current tag name, argv[3]: new tag name
    set libPath to item 1 of argv
    set oldName to item 2 of argv
    set newName to item 3 of argv

    set theLib to my findLib(libPath)
    if theLib is missing value then return my errResp("library not open: " & libPath)

    tell application "EagleFiler"
        set existing to (get name of every tag of theLib)
        set found to false
        repeat with e in existing
            considering case
                if (e as text) is oldName then set found to true
            end considering
        end repeat
        if not found then return my errResp("tag not found: " & oldName)
        -- A rename onto an existing name does nothing in EagleFiler; refuse it.
        -- A case-only change of the same tag is allowed.
        if (newName is not oldName) and (existing contains newName) then return my errResp("tag already exists: " & newName & ". Merge with tag_records instead (add the new tag, remove the old one).")
        try
            set name of tag oldName of theLib to newName
        on error errMsg
            return my errResp("Failed to rename tag: " & errMsg)
        end try
        set afterNames to (get name of every tag of theLib)
    end tell
    set ok to false
    repeat with e in afterNames
        considering case
            if (e as text) is newName then set ok to true
        end considering
    end repeat
    if not ok then return my errResp("EagleFiler did not rename the tag")
    set d to current application's NSMutableDictionary's new()
    d's setValue:oldName forKey:"old_name"
    d's setValue:newName forKey:"new_name"
    return my okResp(d)
end run
