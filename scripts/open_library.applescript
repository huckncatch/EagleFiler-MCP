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

on run argv
    -- argv[1]: full resolved path to .eflibrary file (already expanded by dispatcher)
    set libPath to item 1 of argv

    -- Check if already open
    tell application "EagleFiler"
        set libs to every library document
        repeat with lib in libs
            try
                set libFile to file of lib
                set checkPath to POSIX path of libFile
                if checkPath equals libPath then
                    set dictResult to current application's NSMutableDictionary's new()
                    dictResult's setValue:libPath forKey:"path"
                    dictResult's setValue:true forKey:"already_open"
                    return my okResp(dictResult)
                end if
            end try
        end repeat
    end tell

    -- Open the library
    set didError to false
    set errMsg to ""
    try
        tell application "EagleFiler"
            -- Try opening as string path first
            open POSIX file libPath
        end tell
    on error errMsg
        set didError to true
    end try

    if didError then
        return my makeErrorResponse("Failed to open library: " & errMsg)
    end if

    set dictResult to current application's NSMutableDictionary's new()
    dictResult's setValue:libPath forKey:"path"
    dictResult's setValue:false forKey:"already_open"
    return my okResp(dictResult)
end run
