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

on pad2(n)
    if n < 10 then return "0" & (n as text)
    return n as text
end pad2

on dateToISO(d)
    return (year of d as text) & "-" & my pad2(month of d as integer) & "-" & my pad2(day of d) & "T" & my pad2(hours of d) & ":" & my pad2(minutes of d) & ":" & my pad2(seconds of d)
end dateToISO

on run argv
    -- argv[1]: library path, argv[2]: record GUID
    set libPath to item 1 of argv
    set recGUID to item 2 of argv

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

    set theRec to missing value
    tell application "EagleFiler"
        set matchRecs to (every library record of theLib whose guid is recGUID)
        if (count of matchRecs) is 0 then
            return my errResp("record not found: " & recGUID)
        end if
        set theRec to item 1 of matchRecs

        set d to current application's NSMutableDictionary's new()
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
        d's setValue:(URL of theRec) forKey:"url"
        d's setValue:(source URL of theRec) forKey:"source_url"
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
    end tell

    return my okResp(d)
end run
