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

on jsonList(jsonStr)
    set jData to (current application's NSString's stringWithString:jsonStr)'s dataUsingEncoding:(current application's NSUTF8StringEncoding)
    set arr to current application's NSJSONSerialization's JSONObjectWithData:jData options:0 |error|:(missing value)
    if arr is missing value then return missing value
    if (arr's isKindOfClass:(current application's NSArray's class)) as boolean is false then return missing value
    set asList to {}
    repeat with i from 1 to (arr's |count|()) as integer
        set end of asList to ((arr's objectAtIndex:(i - 1)) as text)
    end repeat
    return asList
end jsonList

on run argv
    -- argv[1]: library path, argv[2]: JSON array of absolute file paths,
    -- argv[3]: folder_guid or "", argv[4]: JSON array of tag names,
    -- argv[5]: note or "", argv[6]: "true" to delete the source after import
    set libPath to item 1 of argv
    set pathList to my jsonList(item 2 of argv)
    set folderGUID to item 3 of argv
    set tagList to my jsonList(item 4 of argv)
    set noteStr to item 5 of argv
    set deleteSource to ((item 6 of argv) is "true")

    if pathList is missing value then return my errResp("Invalid paths JSON")
    if tagList is missing value then return my errResp("Invalid tags JSON")

    set theLib to my findLib(libPath)
    if theLib is missing value then return my errResp("library not open: " & libPath)

    set theContainer to missing value
    if folderGUID is not "" then
        tell application "EagleFiler"
            try
                set theContainer to first library record of theLib whose guid is folderGUID
            on error
                return my errResp("record not found: " & folderGUID)
            end try
        end tell
    end if

    set results to current application's NSMutableArray's new()
    repeat with p in pathList
        set p to p as text
        set item_ to current application's NSMutableDictionary's new()
        item_'s setValue:p forKey:"path"
        -- Make the alias outside the tell block; this also fails on a missing file
        set fileAlias to missing value
        try
            set fileAlias to (POSIX file p) as alias
        on error
            item_'s setValue:"file not found" forKey:"error"
        end try
        if fileAlias is not missing value then
            set newRecs to {}
            set errMsg to ""
            try
                tell application "EagleFiler"
                    if theContainer is missing value then
                        set newRecs to import theLib files {fileAlias} tag names tagList note noteStr deleting afterwards deleteSource asking for options false
                    else
                        set newRecs to import theLib files {fileAlias} tag names tagList note noteStr container theContainer deleting afterwards deleteSource asking for options false
                    end if
                end tell
            on error msg
                set errMsg to "Import failed: " & msg
            end try
            if errMsg is not "" then
                item_'s setValue:errMsg forKey:"error"
            else if (count of newRecs) = 0 then
                item_'s setValue:"not imported (duplicate or unsupported file)" forKey:"error"
            else
                set newRec to item 1 of newRecs
                try
                    tell application "EagleFiler"
                        item_'s setValue:(guid of newRec) forKey:"guid"
                        item_'s setValue:(title of newRec) forKey:"title"
                    end tell
                on error msg
                    item_'s setValue:("Imported, but failed to read the record: " & msg) forKey:"error"
                end try
            end if
        end if
        results's addObject:item_
    end repeat
    return my okResp(results)
end run
