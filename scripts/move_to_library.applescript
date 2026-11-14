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

on run argv
    -- argv[1]: source library path, argv[2]: record GUID,
    -- argv[3]: target library path, argv[4]: target folder GUID or ""
    -- EagleFiler has no cross-library move: import a copy, copy the metadata,
    -- check the checksum, then move the original to the source library's trash.
    set srcPath to item 1 of argv
    set recGUID to item 2 of argv
    set dstPath to item 3 of argv
    set folderGUID to item 4 of argv

    set srcLib to my findLib(srcPath)
    if srcLib is missing value then return my errResp("library not open: " & srcPath)
    set dstLib to my findLib(dstPath)
    if dstLib is missing value then return my errResp("library not open: " & dstPath)

    tell application "EagleFiler"
        try
            set srcRec to first library record of srcLib whose guid is recGUID
        on error
            return my errResp("record not found: " & recGUID)
        end try
        if is folder of srcRec then return my errResp("folders cannot be moved between libraries")
        if trashed of srcRec then return my errResp("record is in the trash: " & recGUID)
        set dstContainer to missing value
        if folderGUID is not "" then
            try
                set dstContainer to first library record of dstLib whose guid is folderGUID
            on error
                return my errResp("target folder not found: " & folderGUID)
            end try
        end if
        set srcFile to file of srcRec
        set srcTitle to title of srcRec
        set srcBase to basename of srcRec
        set srcTags to assigned tag names of srcRec
        set srcHasNote to has note of srcRec
        set srcNoteRTF to ""
        if srcHasNote then set srcNoteRTF to note RTF of srcRec
        set srcURL to source URL of srcRec
        set srcFrom to from name of srcRec
        set srcLabel to label index of srcRec
        set srcFlagged to flagged of srcRec
        set srcUnread to unread of srcRec
        set srcAdded to added date of srcRec
        set srcSum to checksum of srcRec
        set srcLink to URL of srcRec
    end tell

    set newRecs to {}
    try
        tell application "EagleFiler"
            if dstContainer is missing value then
                set newRecs to import dstLib files {srcFile} tag names srcTags source URL srcURL deleting afterwards false asking for options false
            else
                set newRecs to import dstLib files {srcFile} tag names srcTags source URL srcURL container dstContainer deleting afterwards false asking for options false
            end if
        end tell
    on error msg
        return my errResp("Import into the target failed: " & msg & ". The original was kept.")
    end try
    if (count of newRecs) = 0 then return my errResp("Not imported. The target library already holds the same file. The original was kept.")
    set newRec to item 1 of newRecs

    set problems to {}
    tell application "EagleFiler"
        set newGUID to guid of newRec
        set newLink to URL of newRec
        -- Equal title and basename: treat as linked, so the title follows the filename
        try
            if srcTitle is srcBase then
                set title of newRec to ""
            else
                set title of newRec to srcTitle
            end if
        on error
            set end of problems to "title"
        end try
        if srcHasNote then
            try
                set note RTF of newRec to srcNoteRTF
            on error
                set end of problems to "note"
            end try
        end if
        try
            set from name of newRec to srcFrom
        on error
            set end of problems to "from"
        end try
        try
            set label index of newRec to srcLabel
        on error
            set end of problems to "label"
        end try
        try
            set flagged of newRec to srcFlagged
        on error
            set end of problems to "flagged"
        end try
        try
            set unread of newRec to srcUnread
        on error
            set end of problems to "unread"
        end try
        try
            set added date of newRec to srcAdded
        on error
            set end of problems to "added date"
        end try
        set newSum to checksum of newRec
    end tell

    set AppleScript's text item delimiters to ", "
    if (count of problems) > 0 then return my errResp("Copied to the target as " & newGUID & ", but failed to copy: " & (problems as text) & ". The original was kept; check the copy, then trash one of them.")
    if newSum is not srcSum then return my errResp("Copied to the target as " & newGUID & ", but the checksums differ. The original was kept.")

    try
        tell application "EagleFiler" to set container of srcRec to trash of srcLib
    on error errMsg
        return my errResp("Copied to the target as " & newGUID & ", but failed to trash the original: " & errMsg)
    end try

    set d to current application's NSMutableDictionary's new()
    d's setValue:recGUID forKey:"old_guid"
    d's setValue:srcLink forKey:"old_url"
    d's setValue:newGUID forKey:"new_guid"
    d's setValue:newLink forKey:"new_url"
    d's setValue:srcTitle forKey:"title"
    return my okResp(d)
end run
