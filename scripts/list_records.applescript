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

on errResp(msg)
    set r to current application's NSMutableDictionary's new()
    r's setValue:false forKey:"ok"
    r's setValue:msg forKey:"error"
    return my toJSON(r)
end errResp

on dateToISO(d)
    set fmt to current application's NSDateFormatter's new()
    fmt's setDateFormat:"yyyy-MM-dd'T'HH:mm:ssXXXXX"
    fmt's setLocale:(current application's NSLocale's localeWithLocaleIdentifier:"en_US_POSIX")
    return (fmt's stringFromDate:d) as text
end dateToISO

on recordToSummary(rec)
    set d to current application's NSMutableDictionary's new()
    tell application "EagleFiler"
        d's setValue:(guid of rec) forKey:"guid"
        d's setValue:(id of rec) forKey:"id"
        d's setValue:(title of rec) forKey:"title"
        d's setValue:(kind of rec) forKey:"kind"
        d's setValue:(is folder of rec) forKey:"is_folder"
        d's setValue:(flagged of rec) forKey:"flagged"
        d's setValue:(unread of rec) forKey:"unread"
        d's setValue:(my dateToISO(modification date of rec)) forKey:"modification_date"
        set tagNames to assigned tag names of rec
        set tagsArray to current application's NSMutableArray's new()
        repeat with t in tagNames
            tagsArray's addObject:(t as text)
        end repeat
        d's setValue:tagsArray forKey:"tags"
    end tell
    return d
end recordToSummary

on run argv
    -- argv[1]: library path, argv[2]: folder_guid or "" for root,
    -- argv[3]: limit (integer string), argv[4]: offset (integer string)
    set libPath to item 1 of argv
    set folderGUID to item 2 of argv
    set limitNum to (item 3 of argv) as integer
    set offsetNum to (item 4 of argv) as integer

    -- Find open library
    set theLib to missing value
    tell application "EagleFiler"
        repeat with lib in library documents
            if POSIX path of (get file of lib) is libPath then
                set theLib to lib
                exit repeat
            end if
        end repeat
    end tell
    if theLib is missing value then return my errResp("library not open: " & libPath)

    -- Get container (root or specified folder)
    set theContainer to missing value
    tell application "EagleFiler"
        if folderGUID is "" then
            set theContainer to root folder of theLib
        else
            set matchRecs to (every library record of theLib whose guid is folderGUID)
            if (count of matchRecs) is 0 then
                return my errResp("record not found: " & folderGUID)
            end if
            set theContainer to item 1 of matchRecs
        end if

        set allRecs to every library record of theContainer
        set totalCount to count of allRecs
        set resultList to current application's NSMutableArray's new()

        -- Apply offset and limit
        set endIdx to offsetNum + limitNum
        if endIdx > totalCount then set endIdx to totalCount

        repeat with i from (offsetNum + 1) to endIdx
            resultList's addObject:(my recordToSummary(item i of allRecs))
        end repeat
    end tell

    set resultData to current application's NSMutableDictionary's new()
    resultData's setValue:resultList forKey:"records"
    resultData's setValue:totalCount forKey:"total"
    return my okResp(resultData)
end run
