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
    -- argv[1]: library path, argv[2]: folder name, argv[3]: parent folder GUID or ""
    set libPath to item 1 of argv
    set folderName to item 2 of argv
    set parentGUID to item 3 of argv

    set theLib to my findLib(libPath)
    if theLib is missing value then return my errResp("library not open: " & libPath)

    set newFolder to missing value
    try
        tell application "EagleFiler"
            if parentGUID is "" then
                set newFolder to add folder theLib name folderName
            else
                set parentRec to missing value
                try
                    set parentRec to first library record of theLib whose guid is parentGUID
                on error
                    return my errResp("record not found: " & parentGUID)
                end try
                set newFolder to add folder theLib name folderName container parentRec
            end if
        end tell
    on error msg
        return my errResp("Failed to create folder: " & msg)
    end try

    set d to current application's NSMutableDictionary's new()
    try
        tell application "EagleFiler"
            d's setValue:(guid of newFolder) forKey:"guid"
            d's setValue:(name of newFolder) forKey:"name"
        end tell
    on error errMsg
        return my errResp("Failed to read new folder: " & errMsg)
    end try
    return my okResp(d)
end run
