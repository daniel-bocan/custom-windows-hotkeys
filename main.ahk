; Copyright (C) 2025 Daniel Bočan
; Licensed under GNU GPL v3.0 or later: https://www.gnu.org/licenses/gpl-3.0.html

; Hotkeys:
; Win + Alt + F              Minimize all windows on the primary monitor
; Win + Alt + H              Restore all minimized windows on the primary monitor and activate the topmost one
; Win + T                    Mute/unmute Discord microphone and pause/play Spotify if it is playing
; Win + B                    Switch between windows on the secondary or selected monitor
; Win + Ctrl + C             Append selected text to the end of clipboard with blank line between texts
; Win + Ctrl + X             Compare selected text with clipboard; optionally replace selected text

#Requires AutoHotkey v2.0

monitorOffset := 1  ; Offset solve problem when some windows in fullscreen are bigger than monitor
groupCounter := 0  ; It is not possible to delete group so for each new minimize is necessary to make new numbered group
minimizedWindows := []  ; Store IDs of all minimized windows (used by slow restore pair)
gameList := StrSplit(IniRead("settings.ini", "GameList"), '`n')  ; Read list of game exe file names from ini file
played := false  ; If Spotify played or not
monitorToSwitchWindowsOn := IniRead("settings.ini", "Settings", "monitorToSwitchWindowsOn", 1)  ; Monitor on which the windows will be switching (only 3 or more monitors, otherwise it is the secondary monitor if 2 and primary monitor if 1)

DllCall("SetThreadDpiAwarenessContext", "ptr", -4, "ptr")  ; Ignore DPI scaling to get accurate window position and size

; Checks if the window has border but I use it to check if the window is "normal window"
; "normal window" is a window that is in foreground (minimized, maximized, restored, etc.) and not a special window on background like Program Manager, etc.
WinIsNormal(id)
{
    Style := WinGetStyle(id)
    if (Style & 0x800000)
        return 1
    return 0
}

; Returns list of all "normal window" IDs
WinGetNormalList()
{
    ids := WinGetList()
    normalWindows := []
    for (this_id in ids)
    {
        if (WinIsNormal(this_id))
        {
            normalWindows.Push(this_id)
        }
    }
    return normalWindows
}

; Basic function that find out if list contains target element
ContainsElement(list, target)
{
    for element in list
        if element == target
            return true
    return false
}

; Check if window with id in parametr is on the monitor with defined monitor number
; Option to switch offset on and off
IsOnMonitor(id, monitorNumber, offsetSwitch)
{
    global monitorOffset
    offset := monitorOffset
    if (!offsetSwitch)
        offset := 0
    MonitorGet monitorNumber, &Left, &Top, &Right, &Bottom  ; Get coordinates of the primary monitor
    WinGetClientPos &OutX, &OutY, &OutWidth, &OutHeight, id  ; Get coordinates of window of this iteration (client pos is more accurate then window pos)
    return OutX < Right - offset && OutX + OutWidth > Left + offset && OutY < Bottom - offset && OutY + OutHeight > Top +
        offset  ; Check if on the primary monitor
}

; Check if window with id in parametr is on the primary monitor
; Option to switch offset on and off
IsOnPrimaryMonitor(id, offsetSwitch)
{
    return IsOnMonitor(id, MonitorGetPrimary(), offsetSwitch)
}

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

#!F::  ; Press Win + F to minimize all windows on the primary monitor
{
    global minimizedWindows  ; Necessary to use global variable (if omitted, local variable will be used even if it has same name)
    global groupCounter
    groupCounter++  ; Increase group number (to be able to create new group)
    topmostWinFound := false

    ids := WinGetNormalList()  ; Get all "normal window" IDs

    ; Iterate all IDs and choose IDs of windows that are on the primary monitor and add it to group and minimized list
    for (this_id in ids)
    {
        if (IsOnPrimaryMonitor(this_id, true))  ; Check if on the primary monitor
        {
            ; reset list of minimized windows (it can be at the start of this hotkey but if this hotkey would be activated twice in a row by mistake, the hotkey for restoration will not work)
            if !topmostWinFound
            {
                minimizedWindows := []
                topmostWinFound := true
            }
            GroupAdd("MinimizeGroup" groupCounter, "ahk_id " this_id)  ; Add window to group (at the first iteration it'll always create new group)
            minimizedWindows.Push(this_id)  ; Add to minimized list
        }
    }

    ; Minimize all windows on the primary monitor at the same time
    if topmostWinFound
        WinMinimize("ahk_group MinimizeGroup" groupCounter)
}

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

#!H::  ; Press Win + H to restore all minimized windows on the primary monitor and activate the topmost one
{
    ; This hotkey quickly restore minimized windows using groups; For slower but well sorted restore comment and uncomment marked parts
    global minimizedWindows
    global groupCounter  ; comment for slow restore
    groupCounter++  ; comment for slow restore

    ids := WinGetNormalList()  ; Get all "normal window" IDs
    active_id := 0

    ; Iterate all IDs to find ID of the topmost window of the primary monitor that is not minimized (if user open window between minimization and restoration it will be active after restoration)
    for (this_id in ids)
    {
        if (IsOnPrimaryMonitor(this_id, true) && WinGetMinMax("ahk_id " this_id) != -1)  ; Check if on the primary monitor and if it's not minimized
        {
            active_id := this_id
            break
        }
    }

    if minimizedWindows.Length > 0 ; Check if the list of minimized windows is not empty
    {
        ; Iterate minimizedWindows list from behind and restore windows that exist and that are not maximized one by one (maximized windows should not be restored because they will be unmaximized)
        loop minimizedWindows.Length
        {
            this_id := minimizedWindows[-A_Index]
            if WinExist("ahk_id " this_id) && WinGetMinMax("ahk_id " this_id) != 1
            {
                GroupAdd("MinimizeGroup" groupCounter, "ahk_id " this_id)  ; Add window ID in group; comment for slow restore
                ; WinRestore("ahk_id " this_id)  ; uncomment for slow restore
            }
        }

        WinRestore("ahk_group MinimizeGroup" groupCounter)  ; comment for slow restore

        ; Activate window that was active on the primary monitor before window restoration or if there was none then activate window that was topmost before restoration
        if active_id == 0
        {
            active_id := minimizedWindows[1]
        }
        if WinExist("ahk_id " active_id)
        {
            WinActivate("ahk_id " active_id)
        }
        minimizedWindows := []
    }
}

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

#T:: ; Press Win + T to mute/unmute Discord microphone and pause/play Spotify if it is playing
{
    global gameList
    discord_id := WinExist("ahk_exe Discord.exe")  ; Check if Discord is running
    if (discord_id)
    {
        ; For games
        if ContainsElement(gameList, WinGetProcessName("A"))  ; Check if game is active window (compare active window exe name with exe names from list)
        {
            Send "+;"
            Sleep 500
            Send "^+m"
            Sleep 500
            Send "+;"
        }
        ; For other apps
        else
        {
            ids := WinGetNormalList()  ; Get all "normal window" IDs
            active_id := 0

            ; Iterate all IDs to find ID of the topmost window
            active_id := ids[1]

            minimizedWindows := []
            secondaryMonitor := 0
            monitor := 0

            ; Find out on what monitor Discord is (only if there is one or two monitors)
            if MonitorGetCount() <= 2
            {
                ; Find out on what monitor Discord is
                if (IsOnPrimaryMonitor(discord_id, false))
                    monitor := 1  ; I just mark primary as 1 and secondary as 2
                else
                    monitor := 2

                ; Iterate for IDs of windows that are on the same monitor as Discord
                allMaximized := 1
                for (this_id in ids)
                {
                    if (IsOnPrimaryMonitor(this_id, true) && monitor == 1 || !IsOnPrimaryMonitor(this_id, true) &&
                    monitor == 2)
                    {
                        minimizedWindows.Push(this_id)  ; Add window IDs to minimized list
                        if (allMaximized)
                            allMaximized := WinGetMinMax("ahk_id " this_id)
                    }
                }
            }

            ; Activate Discord window and send Ctrl + Shift + M hotkey to mute/unmute microphone
            WinActivate("ahk_id " discord_id)
            Send "^+m"
            Sleep 500  ; Determine for how long will Discord show (minimum is 1 for proper functioning)

            ; Sorting windows out
            if (discord_id != active_id)  ; If Discord window is active it will remain active
            {
                if (MonitorGetCount() <= 2)  ; If there are 3 or more monitors it is not clear on what monitor Discord is and what windows were overlayed so it will do nothing
                {
                    if (discord_id != minimizedWindows[1])  ; If Discord window was the topmost window but not active (active window was on the other monitor) it will activate window which was active at the beginning
                    {
                        if (allMaximized)  ; If Discord was not the topmost window and all windows on the same monitor are maximized it will move the window to the bottom
                        {
                            WinMoveBottom("ahk_id " discord_id)
                        }
                        else  ; If there is some window that is not maximized it will move windows one by one from the topmost to the bottommost to the bottom to achieve the same window order as at the beginning
                        {
                            for (this_id in minimizedWindows)
                            {
                                WinMoveBottom("ahk_id " this_id)
                            }
                        }
                    }
                }
                ; WinActivate(minimizedWindows[1])  ; Uncomment this if applications are freezing when they are moving to top or bottom
                WinActivate(active_id)  ; Activate window that was active at the beginning
            }
        }
    }

    ; Pause/play music on Spotify but if music wasn't stopped using this hotkey it will not play it, so it can't play music if I didn't pause it using this hotkey
    global played
    spotify_id := WinExist("ahk_exe Spotify.exe")  ; Check if Spotify is running
    if (spotify_id)
    {
        this_title := WinGetTitle("ahk_id " spotify_id)
        if (this_title != "Spotify Free" && this_title != "Spotify Premium")  ; Check if music is playing
        {
            Send "{Media_Play_Pause}"
            played := 1
        }
        else if (played)  ; Check if music played before
        {
            Send "{Media_Play_Pause}"
            played := 0
        }
    }
}

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

#B:: ; Press Win + B to switch between windows on the secondary or selected monitor
{
    if MonitorGetCount() == 1
        monitor := 1
    else if MonitorGetCount() == 2
    {
        if MonitorGetPrimary() == 1
            monitor := 2
        else
            monitor := 1
    }
    else
    {
        global monitorToSwitchWindowsOn
        monitor := monitorToSwitchWindowsOn
    }
    ids := WinGetNormalList()  ; Get all "normal window" IDs
    active_id := 0
    this_id := 0

    ; Iterate all IDs to find ID of the topmost window
    for (this_id in ids)
    {
        active_id := this_id
        break
    }

    ; Iterate backwards window IDs to find the bottommost one on the secondary (chosen) monitor and activate it
    loop ids.Length
    {
        this_id := ids.Pop()
        if IsOnMonitor(this_id, monitor, true)  ; Check if on the secondary (chosen) monitor
        {
            WinActivate("ahk_id " this_id)
            if WinWaitActive("ahk_id " this_id, , 10)
            {
                break
            }
        }
    }
    ; Sleep 10  ; Determine for how long will the window be active (minimum is 1 for proper functioning)
    if !IsOnMonitor(this_id, monitor, true)
        WinActivate("ahk_id " active_id)  ; Activate the window from the beginning
}

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

#^C:: ; Press Win + Ctrl + C to append selected text to the end of clipboard with blank line between texts
{
    copied := A_Clipboard
    Send "^c"
    Sleep 100
    A_Clipboard := copied "`n`n" A_Clipboard
}

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

#^X:: ; Press Win + Ctrl + X to compare selected text with clipboard; optionally replace selected text
{
    origText := A_Clipboard  ; Save copied text
    Send "^c"
    Sleep 100
    newText := A_Clipboard  ; Save selected text

    ; Define vars for counting lines, words and chars in orig text
    origLineCount := 0
    origWordCount := 0
    origCharCount := 0

    origLines := StrSplit(origText, "`n", "`r")  ; Split orig text in array with lines
    origLineCount := origLines.Length  ; Count lines of orig text
    ; Count words of orig text
    for line in origLines
    {
        words := StrSplit(line, " ")
        for word in words
            if Trim(word) != ""
                origWordCount++
    }
    ; Count chars of orig text
    origCharCount := StrLen(origText)

    ; Make correct word endings
    FormWord(word, count)
    {
        if (count == 1)
            return " " word
        else
            return " " word "s"
    }

    if (origText == newText)
    {
        ; Show message box with one button
        MsgBox("Texts ARE the SAME`nLength of text: " origLineCount FormWord("line", origLineCount) ", " origWordCount FormWord(
            "word", origWordCount) " and " origCharCount FormWord("char", origCharCount), "Texts Comparer", 0)
    }
    else
    {
        ; Define vars for counting lines, words and chars in new text
        newLineCount := 0
        newWordCount := 0
        newCharCount := 0

        ; Define vars to handle first diff info and diff count
        diffLine := 0  ; First diff line
        diffIndex := 0  ; First diff word coulumn
        diffCount := 0  ; Number of different words (missing words also counts)
        diffFound := false  ; Track if first diff was found or not

        newLines := StrSplit(newText, "`n", "`r")  ; Split orig text in array with lines
        newLineCount := newLines.Length  ; Count lines of new text
        ; Count words of new text
        for line in newLines
        {
            words := StrSplit(line, " ")
            for word in words
                if Trim(word) != ""
                    newWordCount++
        }
        newCharCount := StrLen(newText)  ; Count chars of new text

        minLines := Min(origLines.Length, newLines.Length)

        ; Iterate all lines, find first diff line and column and count diffs
        loop minLines
        {
            lineNum := A_Index
            origLine := Trim(origLines[lineNum])
            newLine := Trim(newLines[lineNum])

            if (origLine != newLine)
            {
                origWords := StrSplit(origLine, " ")
                newWords := StrSplit(newLine, " ")
                minWords := Min(origWords.Length, newWords.Length)

                ; Iterate all words in line and find diffs
                loop minWords
                {
                    wordNum := A_Index
                    if (origWords[wordNum] != newWords[wordNum])
                    {
                        if !diffFound
                        {
                            diffLine := lineNum
                            diffIndex := wordNum
                            diffFound := true
                        }
                        diffCount++
                    }
                }

                ; If orig and new lines have different word count
                if origWords.Length != newWords.Length
                {
                    if !diffFound
                    {
                        diffLine := lineNum
                        diffIndex := minWords + 1
                        diffFound := true
                    }
                }
            }
        }

        ; If orig and new texts have different line count
        if origLineCount != newLineCount
        {
            if !diffFound
            {
                diffLine := minLines + 1
                diffIndex := 1
                diffFound := true
            }
        }

        diffCount += Abs(origWordCount - newWordCount)  ; Add diffrence in orig and new word count to diff count
        diffOrigWord := ""
        diffNewWord := ""

        ; Find orig diff word by diff line and column
        if origLineCount >= diffLine  ; Check if diff line is in array (it can be out when other text have more lines)
        {
            diffOrigWords := StrSplit(Trim(origLines[diffLine]), " ")  ; Split diff line in array with words
            if diffOrigWords.Length >= diffIndex  ; Check if diff word is in array (it can be out when other text have more words in diff line)
                diffOrigWord := diffOrigWords[diffIndex]
            else
                diffOrigWord := "<no word>"  ; If diff word is not in this text (diff line is longer in other text)
        }
        else
            diffOrigWord := "<no line>"  ; If diff word is not in this text (other text is longer)

        if newLineCount >= diffLine  ; Check if diff line is in array (it can be out when other text have more lines)
        {
            diffNewWords := StrSplit(Trim(newLines[diffLine]), " ")  ; Split diff line in array with words
            if diffNewWords.Length >= diffIndex  ; Check if diff word is in array (it can be out when other text have more words in diff line)
                diffNewWord := diffNewWords[diffIndex]
            else
                diffNewWord := "<no word>"  ; If diff word is not in this text (diff line is longer in other text)
        }
        else
            diffNewWord := "<no line>"  ; If diff word is not in this text (other text is longer)

        ; Show message box with two buttons
        result := MsgBox("Texts ARE NOT the SAME`nNumber of diffs: " diffCount "`nFirst diff: On line " diffLine " is " diffIndex ". word " diffNewWord " instead of " diffOrigWord "`nLength of original text: " origLineCount FormWord(
            "line", origLineCount) ", " origWordCount FormWord("word", origWordCount) " and " origCharCount FormWord(
                "char", origCharCount) "`nLength of new string: " newLineCount FormWord("line", newLineCount) ", " newWordCount FormWord(
                    "word", newWordCount) " and " newCharCount FormWord("char", newCharCount) "`nDo you want to replace original text?",
        "Texts Comparer", 256 + 4) ; 256 is for Yes/No buttons, 4 is to set the No button as default
        if (result == "Yes")
        {
            A_Clipboard := origText
            Send "^v"
            Sleep 1
            return
        }
    }
    A_Clipboard := origText ; Restore copied text
}