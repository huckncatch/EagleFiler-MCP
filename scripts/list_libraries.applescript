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

on run argv
    -- argv[1]: JSON string of known libraries map {"name": "path", ...}
    set knownJSON to item 1 of argv

    -- Get open libraries from EagleFiler
    set openLibs to current application's NSMutableArray's new()

    tell application "EagleFiler"
        set libs to every library document
        repeat with lib in libs
            try
                set libFile to file of lib
                set libPath to POSIX path of libFile
                set dictItem to current application's NSMutableDictionary's new()
                dictItem's setValue:(description of lib) forKey:"name"
                dictItem's setValue:libPath forKey:"path"
                dictItem's setValue:true forKey:"is_open"
                openLibs's addObject:dictItem
            end try
        end repeat
    end tell

    -- Build known list (empty for now)
    set knownList to current application's NSMutableArray's new()

    set resultData to current application's NSMutableDictionary's new()
    resultData's setValue:openLibs forKey:"open"
    resultData's setValue:knownList forKey:"known"

    return my okResp(resultData)
end run
