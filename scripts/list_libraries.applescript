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

    -- Collect file aliases inside tell block (POSIX path coercion fails inside tell)
    set openLibFiles to {}
    tell application "EagleFiler"
        set libs to every library document
        repeat with lib in libs
            try
                set end of openLibFiles to (file of lib)
            end try
        end repeat
    end tell

    -- Convert file aliases to POSIX paths outside tell block
    set openRawPaths to {}
    repeat with f in openLibFiles
        set end of openRawPaths to POSIX path of f
    end repeat

    -- Build NS collections
    set openLibs to current application's NSMutableArray's new()
    set openPathSet to current application's NSMutableSet's new()
    repeat with i from 1 to count of openRawPaths
        -- EagleFiler returns paths with trailing slash; stringByStandardizingPath strips it
        set libPath to ((current application's NSString's stringWithString:(item i of openRawPaths))'s stringByStandardizingPath()) as text
        -- Derive display name from filename (strip .eflibrary extension)
        set libDisplayName to ((current application's NSString's stringWithString:libPath)'s lastPathComponent()'s stringByDeletingPathExtension()) as text
        set dictItem to current application's NSMutableDictionary's new()
        dictItem's setValue:libDisplayName forKey:"name"
        dictItem's setValue:libPath forKey:"path"
        dictItem's setValue:true forKey:"is_open"
        openLibs's addObject:dictItem
        openPathSet's addObject:libPath
    end repeat

    -- Parse known libraries map from JSON arg
    set knownList to current application's NSMutableArray's new()
    set jsonData to (current application's NSString's stringWithString:knownJSON)'s dataUsingEncoding:(current application's NSUTF8StringEncoding)
    set knownMap to current application's NSJSONSerialization's JSONObjectWithData:jsonData options:0 |error|:(missing value)
    if knownMap is not missing value then
        set allKeys to (knownMap's allKeys()) as list
        repeat with k in allKeys
            set libName to k as text
            set libPath to (knownMap's valueForKey:libName) as text
            set isOpen to (openPathSet's containsObject:libPath) as boolean
            set dictItem to current application's NSMutableDictionary's new()
            dictItem's setValue:libName forKey:"name"
            dictItem's setValue:libPath forKey:"path"
            dictItem's setValue:isOpen forKey:"is_open"
            knownList's addObject:dictItem
        end repeat
    end if

    set resultData to current application's NSMutableDictionary's new()
    resultData's setValue:openLibs forKey:"open"
    resultData's setValue:knownList forKey:"known"

    return my okResp(resultData)
end run
