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

on run argv
    -- argv[1]: library path, argv[2]: record GUID
    set libPath to item 1 of argv
    set recGUID to item 2 of argv

    -- Collect file aliases inside tell (POSIX path coercion fails inside tell application block)
    set libFiles to {}
    tell application "EagleFiler"
        set libCount to count of library documents
        repeat with i from 1 to libCount
            set end of libFiles to (file of library document i)
        end repeat
    end tell
    -- Find matching library by comparing POSIX paths outside tell block
    set theLib to missing value
    repeat with i from 1 to count of libFiles
        set libPathRaw to POSIX path of (item i of libFiles)
        set normalPath to ((current application's NSString's stringWithString:libPathRaw)'s stringByStandardizingPath()) as text
        if normalPath is libPath then
            tell application "EagleFiler"
                set theLib to library document i
            end tell
            exit repeat
        end if
    end repeat
    if theLib is missing value then return my errResp("library not open: " & libPath)

    set theRec to missing value
    tell application "EagleFiler"
        try
            set theRec to first library record of theLib whose guid is recGUID
        on error
            return my errResp("record not found: " & recGUID)
        end try
    end tell

    tell application "EagleFiler"
        set d to current application's NSMutableDictionary's new()
        try
            d's setValue:(guid of theRec) forKey:"guid"
            d's setValue:(id of theRec) forKey:"id"
            d's setValue:(title of theRec) forKey:"title"
            d's setValue:(filename of theRec) forKey:"filename"
            d's setValue:(kind of theRec) forKey:"kind"
            d's setValue:(is folder of theRec) forKey:"is_folder"
            d's setValue:(flagged of theRec) forKey:"flagged"
            d's setValue:(unread of theRec) forKey:"unread"
            d's setValue:(label index of theRec) forKey:"label"
            d's setValue:(size of theRec) forKey:"size"
            d's setValue:((URL of theRec) as text) forKey:"url"
            d's setValue:((source URL of theRec) as text) forKey:"source_url"
            d's setValue:(POSIX path of (get file of theRec)) forKey:"file_path"
            d's setValue:(my dateToISO(modification date of theRec)) forKey:"modification_date"
            d's setValue:(my dateToISO(added date of theRec)) forKey:"added_date"
            d's setValue:(my dateToISO(creation date of theRec)) forKey:"creation_date"

            -- Note text (empty string if none)
            if has note of theRec then
                d's setValue:(note text of theRec) forKey:"note_text"
            else
                d's setValue:"" forKey:"note_text"
            end if

            set tagNames to assigned tag names of theRec
            set tagsArray to current application's NSMutableArray's new()
            repeat with t in tagNames
                tagsArray's addObject:(t as text)
            end repeat
            d's setValue:tagsArray forKey:"tags"
        on error errMsg
            return my errResp("failed to read record properties: " & errMsg)
        end try
    end tell

    return my okResp(d)
end run
