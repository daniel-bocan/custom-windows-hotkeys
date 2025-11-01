; Copyright (C) 2025 Daniel Bočan
; Licensed under GNU GPL v3.0 or later: https://www.gnu.org/licenses/gpl-3.0.html

; Hotkeys:
; Win + F                    Minimize all windows on the primary monitor
; Win + H                    Restore all minimized windows on the primary monitor and activate the topmost one
; Win + T                    Mute/unmute Discord microphone and pause/play Spotify if it is playing
; Win + B                    Switch between windows on the secondary or selected monitor
; Win + Ctrl + C             Append selected text to the end of clipboard with blank line between texts
; Win + Ctrl + X             Compare selected text with clipboard; optionally replace selected text

; Additional features:
; Script run some actions triggered by states (system start, monitor count change, entering in time interval)
; The actions depends on whether portable mode is enabled (if there is only 1 monitor connected)
; Portable mode:
; Enable Power saver Power scheme and enable Energy saver
; Terminate Steam, Epic Games and Wargaming Game Center to disable update downloads
; Switch VS Code font to portable font specified in the settings file
; Home mode:
; Enable Balanced Power scheme and disable Energy saver
; Run Discord and Spotify and move these windows to secondary or selected monitor
; Run Steam, Epic Games and Wargaming Game Center to enable update downloads
; Switch VS Code font to home font specified in the settings file
; Actions independent of mode:
; Run Everything program on logon
; Change app theme based on the time of day

; Note:
; Many settings can be changed in the settings.ini file, including disabling any action or hotkey and setting custom hotkey key combiantions

#Requires AutoHotkey v2.0

; Constants
powerSaverGUID := IniRead("local_config.ini", "GUID", "powerSaverGUID", "")  ; GUID of Power saver Power scheme that should be generated with setup.ahk file

; General Settings
monitorToSwitchWindowsOn := IniRead("settings.ini", "General", "monitorToSwitchWindowsOn", 1)  ; Monitor on which the windows will be switching (only 3 or more monitors, otherwise it is the secondary monitor if 2 and primary monitor if 1)
lightThemeHour := IniRead("settings.ini", "General", "lightThemeHour", "7")
darkThemeHour := IniRead("settings.ini", "General", "darkThemeHour", "20")
portableVSCodeFont := IniRead("settings.ini", "General", "portableVSCodeFont", "")
homeVSCodeFont := IniRead("settings.ini", "General", "homeVSCodeFont", "")

; Action toggler
runEverythingOnLogon := IniRead("settings.ini", "ActionToggler", "runEverythingOnLogon", 1)
changeAppTheme := IniRead("settings.ini", "ActionToggler", "changeAppTheme", 1)
changePowerPlans := IniRead("settings.ini", "ActionToggler", "changePowerPlans", 1)
discordStart := IniRead("settings.ini", "ActionToggler", "discordStart", 1)
spotifyStart := IniRead("settings.ini", "ActionToggler", "spotifyStart", 1)
gameLaunchersOperations := IniRead("settings.ini", "ActionToggler", "gameLaunchersOperations", 1)
VSCodeFontChange := IniRead("settings.ini", "ActionToggler", "VSCodeFontChange", 1)

; Hotkey toggler
minimizeWindowsToggler := IniRead("settings.ini", "HotkeyToggler", "minimizeWindows", 1)
restoreWindowsToggler := IniRead("settings.ini", "HotkeyToggler", "restoreWindows", 1)
muteUnmuteDiscordSpotifyToggler := IniRead("settings.ini", "HotkeyToggler", "muteUnmuteDiscordSpotify", 1)
switchWindowsToggler := IniRead("settings.ini", "HotkeyToggler", "switchWindows", 1)
appendClipboardToggler := IniRead("settings.ini", "HotkeyToggler", "appendClipboard", 1)
compareTextsToggler := IniRead("settings.ini", "HotkeyToggler", "compareTexts", 1)

; Hotkeys
minimizeWindowsHotkey := IniRead("settings.ini", "Hotkeys", "minimizeWindows", "#F")
restoreWindowsHotkey := IniRead("settings.ini", "Hotkeys", "restoreWindows", "#H")
muteUnmuteDiscordSpotifyHotkey := IniRead("settings.ini", "Hotkeys", "muteUnmuteDiscordSpotify", "#T")
switchWindowsHotkey := IniRead("settings.ini", "Hotkeys", "switchWindows", "#B")
appendClipboardHotkey := IniRead("settings.ini", "Hotkeys", "appendClipboard", "#^C")
compareTextsHotkey := IniRead("settings.ini", "Hotkeys", "compareTexts", "#^X")

; Game list
gameList := StrSplit(IniRead("settings.ini", "GameList", , ""), '`n')

; Find dir which starts with start variable
GetDirStartsWith(start)
{
    loop files start, 'D'
    {
        return A_LoopFileFullPath "\"
    }
}

; Paths, .exe names, window IDs
everything_exe := "Everything.exe"
discord_exe := "Discord.exe"
spotify_exe := "Spotify.exe"
steam_exe := "Steam.exe"
epicgames_exe := "EpicGamesLauncher.exe"
wargaming_exe := "wgc.exe"
everythingPath := A_ProgramFiles "\Everything\" everything_exe
; GetDirStartsWith function ensures that Discord.exe file is always found regardless of version
discordPath := GetDirStartsWith("C:\Users\" A_UserName "\AppData\Local\Discord\app*") discord_exe
spotifyPath := A_AppData "\Spotify\" spotify_exe
steamPath := "C:\Program Files (x86)\Steam\" steam_exe
epicgamesPath := "C:\Program Files (x86)\Epic Games\Launcher\Portal\Binaries\Win32\" epicgames_exe
VSCodeSettingsPath := A_AppData "\Code\User\settings.json"
discord_id := "ahk_exe " discord_exe
spotify_id := "ahk_exe " spotify_exe
steam_id := "ahk_exe " steam_exe

; Global variables
logon := true
threadMergeEnabled := true
wasPortableEnabled := MonitorGetCount() >= 2  ; Set inverted value from the value it should be for the first OnWake() function call (log on)
monitorOffset := 1  ; Offset solve problem when some windows in fullscreen are bigger than monitor
groupCounter := 0  ; It is not possible to delete group so for each new minimize is necessary to make new numbered group
minimizedWindows := []  ; Store IDs of all minimized windows (used by slow restore pair)
played := false  ; If Spotify played or not

DllCall("SetThreadDpiAwarenessContext", "ptr", -4, "ptr")  ; Ignore DPI scaling to get accurate window position and size

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; Main

; State-based actions
if runEverythingOnLogon || changeAppTheme || changePowerPlans || discordStart || spotifyStart || gameLaunchersOperations || VSCodeFontChange
{
    ; Used on logon
    if runEverythingOnLogon && !ProcessExist(everything_exe) && FileExist(everythingPath)
        Run(everythingPath, , "Hide")
    CheckState()
    logon := false

    ; Check states every 60 seconds
    SetTimer(CheckState, 60000)
}

; Hotkeys
; Disable hotkeys that will be used because they are usually used by system and map hotkeys actions to hotkey release
if minimizeWindowsToggler
{
    Hotkey(minimizeWindowsHotkey, Empty)
    Hotkey(minimizeWindowsHotkey " Up", MinimizeWindows)
}
if restoreWindowsToggler
{
    Hotkey(restoreWindowsHotkey, Empty)
    Hotkey(restoreWindowsHotkey " Up", RestoreWindows)
}
if muteUnmuteDiscordSpotifyToggler
{
    Hotkey(muteUnmuteDiscordSpotifyHotkey, Empty)
    Hotkey(muteUnmuteDiscordSpotifyHotkey " Up", MuteUnmuteDiscordSpotify)
}
if switchWindowsToggler
{
    Hotkey(switchWindowsHotkey, Empty)
    Hotkey(switchWindowsHotkey " Up", SwitchWindows)
}
if appendClipboardToggler
{
    Hotkey(appendClipboardHotkey, Empty)
    Hotkey(appendClipboardHotkey " Up", AppendClipboard)
}
if compareTextsToggler
{
    Hotkey(compareTextsHotkey, Empty)
    Hotkey(compareTextsHotkey " Up", CompareTexts)
}

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; Main function that check states and manage state-based actions

CheckState()
{
    global wasPortableEnabled

    if CheckWakeUp()
        EnableThreadMerge()

    ; Manage app themes (check if theme should be changed and if yes, change it)
    isLightTheme := RegRead("HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize", "AppsUseLightTheme")
    ; If current hour is in interval of light theme and dark theme is on, turn on light theme
    if lightThemeHour <= A_hour and A_Hour < darkThemeHour and !isLightTheme
        RegWrite("1", "REG_DWORD", "HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize", "AppsUseLightTheme")
    ; If current hour is not in interval of light theme and light theme is on, turn on dark theme
    else if (A_Hour < lightThemeHour or A_hour >= darkThemeHour) and isLightTheme
        RegWrite("0", "REG_DWORD", "HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize", "AppsUseLightTheme")

    ; If mode changed from home to portable
    if MonitorGetCount() = 1 && !wasPortableEnabled
    {
        ; Check if Wargaming Game Center is running every 20 seconds and if yes terminate it
        ; Also terminate Steam and  Epic Games in first iteration if it is running
        ; Terminating WGC is designed differently because Steam and Epic Games can be run in the background so they don't start at startup, but are started manually in this script. But WGC can't be run in the background so it starts at startup and then terminates here. Terminating Steam and Epic Games only occurs here if it was in home mode and is now in portable mode.
        if gameLaunchersOperations
            SetTimer(TerminateGameLaunchers, 20000)
        TerminateGameLaunchers()
        {
            static repeat_index := 0  ; Only in function scope
            if ProcessExist(wargaming_exe)
            {
                ProcessClose(wargaming_exe)
                SetTimer(TerminateGameLaunchers, 0)  ; Disable timer
            }
            ; If it checked 10 times, stop checking it
            else if repeat_index >= 10
                SetTimer(TerminateGameLaunchers, 0)  ; Disable timer
            ; Terminate Steam and Epic Games in first iteration if it is running
            if repeat_index = 0
            {
                if ProcessExist(steam_exe)
                    ProcessClose(steam_exe)
                if ProcessExist(epicgames_exe)
                    ProcessClose(epicgames_exe)
            }
            repeat_index++
        }
        ; Enable Power saver Power scheme and enable Energy saver
        ; Internally, the way it works is that the Power saver Power scheme is set to turn on Energy saver at 100%, so it is always on (it is necessary to set it up before using the script)
        if powerSaverGUID != "" && changePowerPlans
        {
            ; Run cmd in background
            Run("powercfg /setactive " powerSaverGUID, , "Hide")
        }
        ; Change VS Code font
        if portableVSCodeFont != "" && VSCodeFontChange
        {
            SetVSCodeFont(portableVSCodeFont)
        }
    }
    ; If mode changed from portable to home
    else if MonitorGetCount() >= 2 && wasPortableEnabled
    {
        someWinActivated := false
        ; Find monitor to which the windows will be moved
        if MonitorGetCount() = 1
            monitor := 1
        else if MonitorGetCount() = 2
        {
            if MonitorGetPrimary() = 1
                monitor := 2
            else
                monitor := 1
        }
        else
            monitor := monitorToSwitchWindowsOn

        ; On logon wait if user open some window
        if logon
            Sleep(10000)

        ; Get the "normal" active window ID, if any
        ; It is almost always some window active but sometimes it can't find it and throw exception, so it will leave active window unset
        try
            first_active_id := WinIsNormal(WinGetID("A"))
        catch
            first_active_id := 0

        ; Get coordinates of the monitor
        MonitorGet monitor, &Left, &Top

        if !WinExist(discord_id) && FileExist(discordPath) && discordStart
        {
            wasDiscordRunning := ProcessExist(discord_exe)
            Run(discordPath)
            ; Run 'cmd /c start "" ' discordPath ' --processStart Discord.exe'  ; Use this instead of Run(discordPath) to run Discord independently of AutoHotkey (if AHK script is stopped and Run(discordPath)) is used, it will kill Discord

            ; With Discord is problem that when it starts after log on, the Updater appears first and then the main window. To work with the main window, the script waits for the Updater to appear, to close, and then only the main window remains, so it is certain that discord_id is now the main window. If Discord was running (on system wake up) no Updater window will show, so it will not wait for Discord Updater window but directly for the Discord window
            if !wasDiscordRunning && WinWait("Discord Updater") && WinWaitClose("Discord Updater") && !IsOnMonitor(
                discord_id, monitor, true) || wasDiscordRunning && WinWait(discord_id) && !IsOnMonitor(
                    discord_id, monitor, true)
            {
                ; Unmaximize window, move it to the selected monitor and then maximize it
                WinRestore(discord_id)
                WinMove(Left, Top, , , discord_id)
                WinMaximize(discord_id)
            }

            ; Get the "normal" active window ID, if any
            ; It is almost always some window active but sometimes it can't find it and throw exception, so it will leave active window unset
            try
                last_active_id := WinIsNormal(WinGetID("A"))
            catch
                last_active_id := 0
            WinActivateCorrectly(last_active_id, WinGetID(discord_id), true, true, true)
            Sleep(2000)  ; Wait a while to load the Discord
            someWinActivated := true
        }

        if !WinExist(spotify_id) && FileExist(spotifyPath) && spotifyStart
        {
            ; Get the "normal" active window ID, if any
            ; It is almost always some window active but sometimes it can't find it and throw exception, so it will leave active window unset
            try
                last_active_id := WinIsNormal(WinGetID("A"))
            catch
                last_active_id := 0

            Run(spotifyPath)
            ; Run 'cmd /c start "" ' spotifyPath ' --processStart Discord.exe'  ; Use this instead of Run(spotifyPath) to run Spotify independently of AutoHotkey (if AHK script is stopped and Run(spotifyPath)) is used, it kill Spotify

            ; Wait until Spotify is running and if it is not on the selected monitor, move it there
            if WinWait(spotify_id) && !IsOnMonitor(spotify_id, monitor, true)
            {
                ; Unmaximize window, move it to the selected monitor and then maximize it
                WinRestore(spotify_id)
                WinMove(Left, Top, , , spotify_id)
                WinMaximize(spotify_id)
            }

            WinActivateCorrectly(last_active_id, WinGetID(spotify_id), true, false, false)
            Sleep(1000)  ; Wait a while to load the Spotify
            someWinActivated := true
        }

        ; Activate the window from the beginning
        if WinExist(first_active_id)
        {
            ; Get the "normal" active window ID, if any
            ; It is almost always some window active but sometimes it can't find it and throw exception, so it will leave active window unset
            try
                last_active_id := WinIsNormal(WinGetID("A"))
            catch
                last_active_id := 0
            WinActivateCorrectly(last_active_id, first_active_id, false, true, false)
        }

        ; Disable Thread merge if some window was activated (it usually disable automatically but not always, for example if only Spotify was activated)
        if someWinActivated
            DisableThreadMerge()

        ; Run Steam and Epic Games in background if it was not running. WGC run automatically on startup.
        if !ProcessExist(steam_exe) && FileExist(steamPath) && gameLaunchersOperations
        {
            Run(steamPath " -Silent")
            ; Steam sometimes open update window, if yes minimize it
            WinWait(steam_id)
            if WinExist(steam_id)
                WinMinimize(steam_id)
        }
        if !ProcessExist(epicgames_exe) && FileExist(epicgamesPath) && gameLaunchersOperations
            Run(epicgamesPath " -Silent")

        ; Enable Balanced Power scheme and disable Energy saver
        if powerSaverGUID != "" && changePowerPlans
        {
            ; Run cmd in background
            Run("powercfg /setactive 381b4222-f694-41f0-9685-ff5bb260df2e", , "Hide")
        }
        ; Change VS Code font
        if homeVSCodeFont != "" && VSCodeFontChange
        {
            SetVSCodeFont(homeVSCodeFont)
        }
    }
    wasPortableEnabled := MonitorGetCount() = 1

    ; Check if system woke up
    CheckWakeUp()
    {
        static lastTick := A_TickCount
        currentTick := A_TickCount

        if currentTick - lastTick > 10000
            return true

        lastTick := currentTick
        return false
    }

    ; Edit editor.fontFamily variable in settings.json file
    SetVSCodeFont(font)
    {
        ; Basic function that join elements of an array and add a delimiter between them
        StrJoin(Array, Delimiter := '')
        {
            output := ""
            for element in Array
            {
                output .= element Delimiter
            }
            ; Trim the last added delimiter
            return Trim(output, Delimiter)
        }

        contentStr := FileRead(VSCodeSettingsPath, "UTF-8")
        content := StrSplit(contentStr, '`r`n')
        for line in content
        {
            ; Find line that contains "editor.fontFamily":
            if InStr(line, '"editor.fontFamily":')
            {
                ; Create new line with replaced value
                newLine := SubStr(line, 1, InStr(line, ":")) " " '"' font '"'
                ; If there was comma at the end add it again
                if SubStr(Trim(line, " `t`r`n"), -1, 1) = ","
                {
                    newLine .= ","
                }
                ; Change old line for new line
                content[A_Index] := newLine
            }
        }
        ; Join array to string and override file content with the new string
        contentNew := StrJoin(content, "`r`n")
        file := FileOpen(VSCodeSettingsPath, "w", "UTF-8") ; w = write (overwrite)
        file.Write(contentNew)
        file.Close()
    }
}

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; Hotkeys

Empty(*)  ; Empty hotkey that is used for disabling existing hotkeys
{
    return
}

MinimizeWindows(*)  ; Press Win + F to minimize all windows on the primary monitor
{
    global minimizedWindows  ; Necessary to use global variable (if omitted, local variable will be used even if it has same name)
    global groupCounter
    groupCounter++  ; Increase group number (to be able to create new group)
    topmostWinFound := false

    ids := WinGetNormalList()  ; Get all "normal window" IDs

    ; Iterate all IDs and choose IDs of windows that are on the primary monitor and add it to group and minimized list
    for this_id in ids
    {
        if IsOnPrimaryMonitor(this_id, true)  ; Check if on the primary monitor
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

RestoreWindows(*)  ; Press Win + H to restore all minimized windows on the primary monitor and activate the topmost one
{
    ; This hotkey quickly restore minimized windows using groups; For slower but well sorted restore comment and uncomment marked parts
    global minimizedWindows
    global groupCounter  ; comment for slow restore
    groupCounter++  ; comment for slow restore

    ids := WinGetNormalList()  ; Get all "normal window" IDs
    active_id := 0

    ; Iterate all IDs to find ID of the topmost window of the primary monitor that is not minimized (if user open window between minimization and restoration it will be active after restoration)
    for this_id in ids
    {
        if IsOnPrimaryMonitor(this_id, true) && WinGetMinMax(this_id) != -1  ; Check if on the primary monitor and if it's not minimized
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
            if WinExist(this_id) && WinGetMinMax(this_id) != 1
            {
                GroupAdd("MinimizeGroup" groupCounter, "ahk_id " this_id)  ; Add window ID in group; comment for slow restore
                ; WinRestore(this_id)  ; uncomment for slow restore
            }
        }

        WinRestore("ahk_group MinimizeGroup" groupCounter)  ; comment for slow restore

        ; Activate window that was active on the primary monitor before window restoration or if there was none then activate window that was topmost before restoration
        if !active_id
            active_id := minimizedWindows[1]
        if WinExist(active_id)
            WinActivate(active_id)
        minimizedWindows := []
    }
}

MuteUnmuteDiscordSpotify(*) ; Press Win + T to mute/unmute Discord microphone and pause/play Spotify if it is playing
{
    discord_id := WinExist("ahk_exe " discord_exe)
    if discord_id
    {
        ids := WinGetNormalList()  ; Get all "normal window" IDs

        try
            active_exe := WinGetProcessName("A")  ; Get .exe file name of the active window
        catch
            active_exe := WinGetProcessName(ids[1])  ; Get .exe file name of the topmost window (sometimes "A" is not found)

        ; For games
        if ContainsElement(gameList, active_exe)  ; Check if game is active window (compare active window .exe name with .exe names from list)
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
            ; Get the "normal" active window ID, if any
            ; It is almost always some window active but sometimes it can't find it and throw exception, so it will set the topmost window as active, if it is
            try
                first_active_id := WinIsNormal(WinGetID("A"))
            catch
            {
                first_active_id := ids[1]
                if !WinActive(first_active_id)
                    first_active_id := 0
            }

            minimizedWindows := []
            monitor := 0

            ; Find out on what monitor Discord is
            loop MonitorGetCount()
                if IsOnMonitor(discord_id, A_Index, true)
                    monitor := A_Index

            ; Iterate for IDs of windows that are on the same monitor as Discord
            allMaximized := 1
            for this_id in ids
            {
                if IsOnMonitor(this_id, monitor, true)
                {
                    minimizedWindows.Push(this_id)  ; Add window IDs to minimized list
                    if allMaximized
                        allMaximized := WinGetMinMax(this_id)
                }
            }

            ; Activate Discord window and send Ctrl + Shift + M hotkey to mute/unmute microphone
            if first_active_id != discord_id
            {
                WinActivateCorrectly(first_active_id, discord_id, true, false, false)
            }
            Send "^+m"
            Sleep 500  ; Determine for how long will Discord show (minimum is 1 for proper functioning)

            ; Sorting windows out
            if discord_id != first_active_id  ; If Discord window is active it will remain active
            {
                if discord_id != minimizedWindows[1]  ; If Discord window was the topmost window but not active (active window was on the other monitor) it will activate window which was active at the beginning
                {
                    if !allMaximized  ; If there is some window that is not maximized it will move windows one by one from the topmost to the bottommost to the bottom to achieve the same window order as at the beginning
                    {
                        for this_id in minimizedWindows
                        {
                            WinMoveBottom(this_id)
                        }
                    }
                    WinActivateCorrectly(discord_id, minimizedWindows[1], true, false, false)  ; Activate the window that was the topmost window on monitor where is Discord
                }

                ; Get the "normal" active window ID, if any
                ; It is almost always some window active but sometimes it can't find it and throw exception, so it will leave active window unset
                try
                    last_active_id := WinIsNormal(WinGetID("A"))
                catch
                    last_active_id := 0
                WinActivateCorrectly(last_active_id, first_active_id, false, true, false)  ; Activate the window that was active at the beginning
            }
        }
    }

    ; Pause/play music on Spotify but if music wasn't stopped using this hotkey it will not play it, so it can't play music if I didn't pause it using this hotkey
    global played
    spotify_id := WinExist("ahk_exe " spotify_exe)  ; Check if Spotify is running
    if spotify_id
    {
        spotifyTitle := WinGetTitle(spotify_id)
        if spotifyTitle != "Spotify Free" && spotifyTitle != "Spotify Premium"  ; Check if music is playing
        {
            Send "{Media_Play_Pause}"
            played := 1
        }
        else if played  ; Check if music played before
        {
            Send "{Media_Play_Pause}"
            played := 0
        }
    }
}

SwitchWindows(*) ; Press Win + B to switch between windows on the secondary or selected monitor
{
    ; Get monitor on which should windows switch
    if MonitorGetCount() = 1
        monitor := 1
    else if MonitorGetCount() = 2
    {
        if MonitorGetPrimary() = 1
            monitor := 2
        else
            monitor := 1
    }
    else
    {
        monitor := monitorToSwitchWindowsOn
    }

    ids := WinGetNormalList()  ; Get all "normal window" IDs
    this_id := 0

    ; Get the "normal" active window ID, if any
    ; It is almost always some window active but sometimes it can't find it and throw exception, so it will leave active window unset
    try
        active_id := WinIsNormal(WinGetID("A"))
    catch
        active_id := 0

    ; Iterate backwards window IDs to find the bottommost one on the secondary (chosen) monitor and activate it
    loop ids.Length
    {
        this_id := ids.Pop()
        if IsOnMonitor(this_id, monitor, true)  ; Check if on the secondary (chosen) monitor
        {
            WinActivateCorrectly(active_id, this_id, true, false, false)
            break
        }
    }
    ; Activate the window from the beginning if it is not on the secondary monitor
    if active_id && !IsOnMonitor(active_id, monitor, true)
        WinActivateCorrectly(this_id, active_id, false, true, false)
}

AppendClipboard(*) ; Press Win + Ctrl + C to append selected text to the end of clipboard with blank line between texts
{
    copied := A_Clipboard
    Send "^c"
    Sleep 100
    A_Clipboard := copied "`n`n" A_Clipboard
}

CompareTexts(*) ; Press Win + Ctrl + X to compare selected text with clipboard; optionally replace selected text
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
        if count = 1
            return " " word
        else
            return " " word "s"
    }

    if origText = newText
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

            if origLine != newLine
            {
                origWords := StrSplit(origLine, " ")
                newWords := StrSplit(newLine, " ")
                minWords := Min(origWords.Length, newWords.Length)

                ; Iterate all words in line and find diffs
                loop minWords
                {
                    wordNum := A_Index
                    if origWords[wordNum] != newWords[wordNum]
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
        if result = "Yes"
        {
            A_Clipboard := origText
            Send "^v"
            Sleep 1
            return
        }
    }
    A_Clipboard := origText ; Restore copied text
}

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; Utility functions

/**
 * @description Checks if the window has border but I use it to check if the window is "normal window".  
 * "Normal window" is a window that is in foreground (minimized, maximized, restored, etc.) and not a special window on background like Program Manager, etc.
 * @param {'ahk_exe '|'ahk_class '|'ahk_id '|'ahk_pid '|'ahk_group '} WinTitle  
 * A string using a {@link https://www.autohotkey.com/docs/v2/misc/WinTitle.htm|WinTitle} to match a window.  
 * Types: {@link https://www.autohotkey.com/docs/v2/misc/WinTitle.htm#ahk_exe|ahk_exe}, {@link https://www.autohotkey.com/docs/v2/misc/WinTitle.htm#ahk_class|ahk_class}, {@link https://www.autohotkey.com/docs/v2/misc/WinTitle.htm#ahk_id|ahk_id}, {@link https://www.autohotkey.com/docs/v2/misc/WinTitle.htm#ahk_pid|ahk_pid}, {@link https://www.autohotkey.com/docs/v2/misc/WinTitle.htm#ahk_group|ahk_group}  
 * Window title is optional and must come before any `ahk_` criteria.  
 * If WinTitle is the letter `A`, the active window is used.  
 * @returns {(Integer)}  
 * The ID of the specified window.
 * If the window is not "normal" or id is 0 or does not exist, 0 is returned.
 */
WinIsNormal(WinTitle)
{
    if !WinTitle
        return 0
    try
        style := WinGetStyle(WinTitle)
    catch
        return 0
    if style & 0x800000
        return WinTitle
    return 0
}

/**
 * @description Returns the unique ID numbers of all "normal" windows.  
 * If window is "normal" is determined by WinIsNormal function.
 * @returns {(Array)}  
 * An array containing the ID of every "normal" window.  
 * The order of windows is from topmost to bottommost (z-order).  
 * If no windows are matched, the array is empty.  
 */
WinGetNormalList()
{
    ids := WinGetList()
    normalWindows := []
    for this_id in ids
    {
        if WinIsNormal(this_id)
            normalWindows.Push(this_id)
    }
    return normalWindows
}

/**
 * @description Searches inside an array for an instance of the provided element.
 * @param {(Array)} List The list to search inside of.
 * @param {(Any)} Target The element to search for.
 * @returns {(Integer)}  
 * 1 if found, 0 if not
 */
ContainsElement(List, Target)
{
    for element in List
        if element = target
            return true
    return false
}

/**
 * @description Finds if window is on specified monitor.
 * @param {'ahk_exe '|'ahk_class '|'ahk_id '|'ahk_pid '|'ahk_group '} WinTitle  
 * A string using a {@link https://www.autohotkey.com/docs/v2/misc/WinTitle.htm|WinTitle} to match a window.  
 * Types: {@link https://www.autohotkey.com/docs/v2/misc/WinTitle.htm#ahk_exe|ahk_exe}, {@link https://www.autohotkey.com/docs/v2/misc/WinTitle.htm#ahk_class|ahk_class}, {@link https://www.autohotkey.com/docs/v2/misc/WinTitle.htm#ahk_id|ahk_id}, {@link https://www.autohotkey.com/docs/v2/misc/WinTitle.htm#ahk_pid|ahk_pid}, {@link https://www.autohotkey.com/docs/v2/misc/WinTitle.htm#ahk_group|ahk_group}  
 * Window title is optional and must come before any `ahk_` criteria.  
 * If WinTitle is the letter `A`, the active window is used.  
 * @param {(Integer)} MonitorNumber The monitor number to check if it contains a window.
 * @param {(Integer)} OffsetSwitch If the global offset should be used when finding the window.
 * @returns {(Integer)}  
 * 1 if found, 0 if not
 */
IsOnMonitor(WinTitle, MonitorNumber, OffsetSwitch)
{
    global monitorOffset
    offset := monitorOffset
    if !OffsetSwitch
        offset := 0
    MonitorGet MonitorNumber, &Left, &Top, &Right, &Bottom  ; Get coordinates of the primary monitor
    WinGetClientPos &OutX, &OutY, &OutWidth, &OutHeight, WinTitle  ; Get coordinates of window of this iteration (client pos is more accurate then window pos)
    return OutX < Right - offset && OutX + OutWidth > Left + offset && OutY < Bottom - offset && OutY + OutHeight > Top +
        offset  ; Check if on the primary monitor
}

/**
 * @description Finds if window is on the primary monitor. Uses the IsOnMonitor function.
 * @param {'ahk_exe '|'ahk_class '|'ahk_id '|'ahk_pid '|'ahk_group '} WinTitle  
 * A string using a {@link https://www.autohotkey.com/docs/v2/misc/WinTitle.htm|WinTitle} to match a window.  
 * Types: {@link https://www.autohotkey.com/docs/v2/misc/WinTitle.htm#ahk_exe|ahk_exe}, {@link https://www.autohotkey.com/docs/v2/misc/WinTitle.htm#ahk_class|ahk_class}, {@link https://www.autohotkey.com/docs/v2/misc/WinTitle.htm#ahk_id|ahk_id}, {@link https://www.autohotkey.com/docs/v2/misc/WinTitle.htm#ahk_pid|ahk_pid}, {@link https://www.autohotkey.com/docs/v2/misc/WinTitle.htm#ahk_group|ahk_group}  
 * Window title is optional and must come before any `ahk_` criteria.  
 * If WinTitle is the letter `A`, the active window is used.  
 * @param {(Integer)} OffsetSwitch If the global offset should be used when finding the window.
 * @returns {(Integer)}  
 * 1 if found, 0 if not
 */
IsOnPrimaryMonitor(WinTitle, OffsetSwitch)
{
    return IsOnMonitor(WinTitle, MonitorGetPrimary(), OffsetSwitch)
}

/**
 * @description  
 * Activate window properly (not flashing taskbar icon).  
 * It attach the active window thread with the target window thread. After that, window can be activated without problems because it acts like it is on the same thread as the window that was active before. Without it the new window will not activate at all or not correctly and the taskbar icon will flash. This technique is used only the first time any window is activated after the script start, then it works correctly without the Thread merge.
 * @param {(Integer)} Active_id  
 * ID of currently active window.  
 * If 0, Thread merging will not be used.
 * @param {(Integer)} Target_id  
 * ID of window that will be activated.
 * If 0, nothing will happen.
 * @param {(Integer)} Wait If script should wait to window be active.
 * @param {(Integer)} DisableThreadMerging If the Thread merging should be disabled after this activation.
 * @param {(Integer)} [ActivateActive] If the window should activate even if it looks like it is already active.
 */
WinActivateCorrectly(Active_id, Target_id, Wait, DisableThreadMerging, ActivateActive := 0)
{
    ; If target id is 0, do nothing
    if !Target_id
        return

    ; If active id is 0, do activate target window normally
    if !Active_id
    {
        WinActivateNormally()

        if DisableThreadMerging
            DisableThreadMerge()
        return
    }

    ; Do anyting only if target and active ids are different or if active window can be activated and active window is not Start menu (it blocks activation)
    if (ActivateActive || Active_id != Target_id) && WinGetTitle(Active_id) != "Start"
    {
        if threadMergeEnabled && Active_id != Target_id
            WinActivateWithThreadMerge()
        else
            WinActivateNormally()

        if DisableThreadMerging
            DisableThreadMerge()
    }

    WinActivateNormally()
    {
        WinActivate(Target_id)
        if Wait
            WinWaitActive(Target_id, , 10)
    }

    WinActivateWithThreadMerge()
    {
        ; Get thread IDs
        thisThreadId := DllCall("GetWindowThreadProcessId", "ptr", Active_id, "uint*", 0, "uint")
        targetThreadId := DllCall("GetWindowThreadProcessId", "ptr", Target_id, "uint*", 0, "uint")

        ; Attach input threads so focus can transfer
        DllCall("AttachThreadInput", "uint", thisThreadId, "uint", targetThreadId, "int", true)

        ; Activate the target window
        WinActivateNormally()

        ; Detach again
        DllCall("AttachThreadInput", "uint", thisThreadId, "uint", targetThreadId, "int", false)
    }
}

/**
 * @description Enable Thread merge which is used in WinActivateCorrectly function.
 */
EnableThreadMerge()
{
    global threadMergeEnabled
    threadMergeEnabled := true
}

/**
 * @description Disable Thread merge which is used in WinActivateCorrectly function.
 */
DisableThreadMerge()
{
    global threadMergeEnabled
    threadMergeEnabled := false
}
