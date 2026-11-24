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

on findWindowName(libPath)
    -- A stored window reference (browser window 1 of lib) fails with -1700,
    -- so return the window's name and address it as browser window <name>.
    set winFiles to {}
    set winNames to {}
    tell application "EagleFiler"
        repeat with i from 1 to count of browser windows
            set end of winFiles to (file of document of browser window i)
            set end of winNames to (name of browser window i)
        end repeat
    end tell
    repeat with i from 1 to count of winFiles
        set p to POSIX path of (item i of winFiles)
        set normalPath to ((current application's NSString's stringWithString:p)'s stringByStandardizingPath()) as text
        if normalPath is libPath then return item i of winNames
    end repeat
    return missing value
end findWindowName

on urlEncode(str)
    set allowed to current application's NSCharacterSet's URLQueryAllowedCharacterSet()'s mutableCopy()
    allowed's removeCharactersInString:"&=+?#"
    return ((current application's NSString's stringWithString:str)'s stringByAddingPercentEncodingWithAllowedCharacters:allowed) as text
end urlEncode

on run argv
    -- argv[1]: library path, argv[2]: query string,
    -- argv[3]: limit, argv[4]: offset
    set libPath to item 1 of argv
    set queryStr to item 2 of argv
    set limitNum to (item 3 of argv) as integer
    set offsetNum to (item 4 of argv) as integer

    -- With Always Search All Records on, the search field covers the whole
    -- library, so set it in the background. Otherwise open the search URL,
    -- which brings EagleFiler to the front and selects the Records source.
    set searchAll to "0"
    try
        set searchAll to do shell script "defaults read com.c-command.EagleFiler SearchAllRecords"
    end try

    set winName to my findWindowName(libPath)
    if searchAll is "1" then
        if winName is missing value then
            tell application "EagleFiler"
                open POSIX file libPath
            end tell
        end if
    else
        set searchURL to "x-eaglefiler://search?q=" & my urlEncode(queryStr) & "&library=" & my urlEncode(libPath)
        tell application "EagleFiler"
            get url searchURL
        end tell
    end if

    repeat 10 times
        if winName is not missing value then exit repeat
        delay 0.3
        set winName to my findWindowName(libPath)
    end repeat
    if winName is missing value then return my errResp("Could not find a browser window for library: " & libPath)

    if searchAll is "1" then
        tell application "EagleFiler"
            set search query of browser window winName to queryStr
        end tell
    end if

    -- Read until two reads agree, so a search still in progress is not returned.
    set allMatches to {}
    try
        tell application "EagleFiler"
            set allMatches to displayed records of browser window winName
            repeat 10 times
                delay 0.2
                set nextMatches to displayed records of browser window winName
                if (count of nextMatches) = (count of allMatches) then exit repeat
                set allMatches to nextMatches
            end repeat
        end tell
    on error errMsg
        tell application "EagleFiler"
            set search query of browser window winName to ""
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

    tell application "EagleFiler"
        set search query of browser window winName to ""
    end tell

    if buildErr is not "" then return my errResp("Failed to build results: " & buildErr)

    set resultData to current application's NSMutableDictionary's new()
    resultData's setValue:resultList forKey:"records"
    resultData's setValue:totalCount forKey:"total"
    return my okResp(resultData)
end run
