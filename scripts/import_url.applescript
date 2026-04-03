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
    tell application "EagleFiler"
        repeat with lib in library documents
            if POSIX path of (get file of lib) is libPath then return lib
        end repeat
    end tell
    return missing value
end findLib

on run argv
    -- argv[1]: library path, argv[2]: URL string, argv[3]: format string,
    -- argv[4]: folder_guid or ""
    set libPath to item 1 of argv
    set urlStr to item 2 of argv
    set formatStr to item 3 of argv
    set folderGUID to item 4 of argv

    set theLib to my findLib(libPath)
    if theLib is missing value then return my errResp("library not open: " & libPath)

    -- Map format string to AppleScript format constant
    set webFmt to missing value
    if formatStr is "bookmark" then
        set webFmt to bookmark format
    else if formatStr is "html" then
        set webFmt to HTML format
    else if formatStr is "pdf" then
        set webFmt to PDF format
    else if formatStr is "pdf_single_page" then
        set webFmt to PDF single page format
    else if formatStr is "plain_text" then
        set webFmt to plain text format
    else if formatStr is "webarchive" then
        set webFmt to Web archive format
    -- Note: rich_text and rich_text_with_images formats are intentionally excluded (not in MCP tool spec)
    else
        return my errResp("Unknown format: " & formatStr)
    end if

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

    set newRecs to {}
    try
        tell application "EagleFiler"
            if theContainer is missing value then
                set newRecs to import theLib URLs {urlStr} Web page format webFmt asking for options false
            else
                set newRecs to import theLib URLs {urlStr} Web page format webFmt container theContainer asking for options false
            end if
        end tell
    on error msg
        return my errResp("Import failed: " & msg)
    end try

    if (count of newRecs) = 0 then return my errResp("Import returned no records")

    set newRec to item 1 of newRecs
    set d to current application's NSMutableDictionary's new()
    try
        tell application "EagleFiler"
            d's setValue:(guid of newRec) forKey:"guid"
            d's setValue:(title of newRec) forKey:"title"
        end tell
    on error errMsg
        return my errResp("Failed to read imported record: " & errMsg)
    end try
    return my okResp(d)
end run
