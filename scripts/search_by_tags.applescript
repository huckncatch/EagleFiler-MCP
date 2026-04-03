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
    -- argv[1]: library path, argv[2]: JSON array of tag strings,
    -- argv[3]: limit, argv[4]: offset
    set libPath to item 1 of argv
    set tagsJSON to item 2 of argv
    set limitNum to (item 3 of argv) as integer
    set offsetNum to (item 4 of argv) as integer

    -- Parse tags array
    set tagsData to (current application's NSString's stringWithString:tagsJSON)'s dataUsingEncoding:(current application's NSUTF8StringEncoding)
    set tagsList to current application's NSJSONSerialization's JSONObjectWithData:tagsData options:0 |error|:(missing value)
    if tagsList is missing value then return my errResp("Invalid tags JSON")
    set tagsCount to (tagsList's count()) as integer
    if tagsCount = 0 then return my errResp("At least one tag is required")

    set theLib to missing value
    tell application "EagleFiler"
        repeat with lib in library documents
            if ((current application's NSString's stringWithString:(POSIX path of (get file of lib)))'s stringByStandardizingPath() as text) is libPath then
                set theLib to lib
                exit repeat
            end if
        end repeat
    end tell
    if theLib is missing value then return my errResp("library not open: " & libPath)

    -- Get records for the first tag (smallest candidate set)
    set firstTag to (tagsList's objectAtIndex:0) as text
    set candidates to {}
    tell application "EagleFiler"
        try
            set tagObj to tag firstTag of theLib
            set candidates to every library record of tagObj
        on error
            -- Tag doesn't exist → no results
            set resultData to current application's NSMutableDictionary's new()
            resultData's setValue:(current application's NSMutableArray's new()) forKey:"records"
            resultData's setValue:0 forKey:"total"
            return my okResp(resultData)
        end try
    end tell

    -- Filter candidates to those that also have all remaining tags
    set matchingRecs to current application's NSMutableArray's new()
    tell application "EagleFiler"
        try
            repeat with rec in candidates
                set recTags to assigned tag names of rec
                set hasAll to true
                repeat with i from 1 to tagsCount
                    set requiredTag to (tagsList's objectAtIndex:(i - 1)) as text
                    set found to false
                    repeat with rt in recTags
                        if rt as text is requiredTag then
                            set found to true
                            exit repeat
                        end if
                    end repeat
                    if not found then
                        set hasAll to false
                        exit repeat
                    end if
                end repeat
                if hasAll then
                    matchingRecs's addObject:rec
                end if
            end repeat
        on error errMsg
            return my errResp("Failed to filter records: " & errMsg)
        end try
    end tell

    set totalCount to (matchingRecs's count()) as integer
    set resultList to current application's NSMutableArray's new()
    set endIdx to offsetNum + limitNum
    if endIdx > totalCount then set endIdx to totalCount

    try
        repeat with i from (offsetNum + 1) to endIdx
            resultList's addObject:(my recordToSummary(matchingRecs's objectAtIndex:(i - 1)))
        end repeat
    on error errMsg
        return my errResp("Failed to build results: " & errMsg)
    end try

    set resultData to current application's NSMutableDictionary's new()
    resultData's setValue:resultList forKey:"records"
    resultData's setValue:totalCount forKey:"total"
    return my okResp(resultData)
end run
