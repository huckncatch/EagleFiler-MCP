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
    -- argv[1]: library path, argv[2]: query string,
    -- argv[3]: limit, argv[4]: offset
    set libPath to item 1 of argv
    set queryStr to item 2 of argv
    set limitNum to (item 3 of argv) as integer
    set offsetNum to (item 4 of argv) as integer

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

    -- Ensure a browser window is open for the library
    set theWindow to missing value
    tell application "EagleFiler"
        if (count of browser windows of theLib) > 0 then
            set theWindow to browser window 1 of theLib
        end if
    end tell

    if theWindow is missing value then
        -- Bring library to front to create a window
        tell application "EagleFiler"
            activate
            open POSIX file libPath
        end tell
        delay 0.5
        tell application "EagleFiler"
            if (count of browser windows of theLib) > 0 then
                set theWindow to browser window 1 of theLib
            end if
        end tell
    end if

    if theWindow is missing value then return my errResp("Could not open browser window for library")

    -- Run search
    tell application "EagleFiler"
        tell theWindow
            set search query to queryStr
        end tell
    end tell
    delay 0.5 -- allow search index to update display

    set allMatches to {}
    try
        tell application "EagleFiler"
            tell theWindow
                set allMatches to displayed records
            end tell
        end tell
    on error errMsg
        -- Clear search field even on error
        tell application "EagleFiler"
            tell theWindow
                set search query to ""
            end tell
        end tell
        return my errResp("Failed to read search results: " & errMsg)
    end try

    set totalCount to count of allMatches
    set resultList to current application's NSMutableArray's new()
    set endIdx to offsetNum + limitNum
    if endIdx > totalCount then set endIdx to totalCount

    set buildErr to ""
    try
        repeat with i from (offsetNum + 1) to endIdx
            resultList's addObject:(my recordToSummary(item i of allMatches))
        end repeat
    on error errMsg
        set buildErr to errMsg
    end try

    -- Clear search field
    tell application "EagleFiler"
        tell theWindow
            set search query to ""
        end tell
    end tell

    if buildErr is not "" then return my errResp("Failed to build results: " & buildErr)

    set resultData to current application's NSMutableDictionary's new()
    resultData's setValue:resultList forKey:"records"
    resultData's setValue:totalCount forKey:"total"
    return my okResp(resultData)
end run
