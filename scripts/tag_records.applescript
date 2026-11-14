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

on jsonList(s)
    set d to (current application's NSString's stringWithString:s)'s dataUsingEncoding:(current application's NSUTF8StringEncoding)
    set a to current application's NSJSONSerialization's JSONObjectWithData:d options:0 |error|:(missing value)
    if a is missing value then return missing value
    if (a's isKindOfClass:(current application's NSArray's class)) as boolean is false then return missing value
    set out to {}
    repeat with i from 1 to (a's |count|()) as integer
        set end of out to ((a's objectAtIndex:(i - 1)) as text)
    end repeat
    return out
end jsonList
on asNSArray(lst)
    set a to current application's NSMutableArray's new()
    repeat with x in lst
        a's addObject:(x as text)
    end repeat
    return a
end asNSArray

on run argv
    -- argv[1]: library path, argv[2]: JSON array of record GUIDs,
    -- argv[3]: JSON array of tags to add, argv[4]: JSON array of tags to remove
    -- AppleScript text comparison ignores case, so "ira" matches an existing "IRA".
    set libPath to item 1 of argv
    set guidList to my jsonList(item 2 of argv)
    set addList to my jsonList(item 3 of argv)
    set removeList to my jsonList(item 4 of argv)
    if guidList is missing value or addList is missing value or removeList is missing value then return my errResp("Invalid JSON array argument")

    set theLib to my findLib(libPath)
    if theLib is missing value then return my errResp("library not open: " & libPath)

    tell application "EagleFiler" to set existing to (get name of every tag of theLib)
    -- Use the existing spelling of a tag, so a case variant does not make a new tag
    set canonAdd to {}
    repeat with a in addList
        set a to a as text
        set chosen to a
        repeat with e in existing
            if (e as text) is a then
                set chosen to e as text
                exit repeat
            end if
        end repeat
        set end of canonAdd to chosen
    end repeat

    set results to current application's NSMutableArray's new()
    repeat with g in guidList
        set g to g as text
        set item_ to current application's NSMutableDictionary's new()
        item_'s setValue:g forKey:"guid"
        try
            tell application "EagleFiler"
                set theRec to first library record of theLib whose guid is g
                set cur to assigned tag names of theRec
            end tell
            set newTags to {}
            repeat with t in cur
                set t to t as text
                if removeList does not contain t then set end of newTags to t
            end repeat
            repeat with a in canonAdd
                set a to a as text
                if newTags does not contain a then set end of newTags to a
            end repeat
            tell application "EagleFiler"
                set assigned tag names of theRec to newTags
                set finalTags to assigned tag names of theRec
            end tell
            item_'s setValue:(my asNSArray(finalTags)) forKey:"tags"
        on error errMsg
            item_'s setValue:errMsg forKey:"error"
        end try
        results's addObject:item_
    end repeat
    return my okResp(results)
end run
