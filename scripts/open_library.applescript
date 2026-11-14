use framework "Foundation"
use scripting additions

on toJSON(nsObj)
    set jsonData to current application's NSJSONSerialization's dataWithJSONObject:nsObj options:0 |error|:(missing value)
    return (current application's NSString's alloc()'s initWithData:jsonData encoding:(current application's NSUTF8StringEncoding)) as text
end toJSON

on okResp(dataObj)
    set r to current application's NSMutableDictionary's new()
    r's setValue:true forKey:"ok"
    r's setValue:dataObj forKey:"data"
    return my toJSON(r)
end okResp

on makeErrorResponse(msg)
    set r to current application's NSMutableDictionary's new()
    r's setValue:false forKey:"ok"
    r's setObject:msg forKey:"error"
    return my toJSON(r)
end makeErrorResponse

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
    -- argv[1]: full resolved path to .eflibrary file (already expanded by dispatcher)
    set libPath to item 1 of argv

    if my findLib(libPath) is not missing value then
        set dictResult to current application's NSMutableDictionary's new()
        dictResult's setValue:libPath forKey:"path"
        dictResult's setValue:true forKey:"already_open"
        return my okResp(dictResult)
    end if

    -- Make the alias outside the tell block (POSIX file fails inside it); this also fails on a missing file
    try
        set libAlias to (POSIX file libPath) as alias
    on error
        return my makeErrorResponse("Library not found: " & libPath)
    end try

    try
        tell application "EagleFiler" to open libAlias
    on error errMsg
        return my makeErrorResponse("Failed to open library: " & errMsg)
    end try

    set dictResult to current application's NSMutableDictionary's new()
    dictResult's setValue:libPath forKey:"path"
    dictResult's setValue:false forKey:"already_open"
    return my okResp(dictResult)
end run
