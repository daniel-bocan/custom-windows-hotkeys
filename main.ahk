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
    ; Change app theme based on sunrise and sunset time or on times set in settings
    ; Change keyboard layout based on active window

; Note:
; Many settings can be changed in the settings.ini file, including disabling any action or hotkey and setting custom hotkey key combiantions

#Requires AutoHotkey v2.0

; Power saver GUID
powerSaverGUID := IniRead("local_config.ini", "GUID", "powerSaverGUID", "")  ; GUID of Power saver Power scheme that should be generated with setup.ahk file

; General settings
monitorToSwitchWindowsOn := IniRead("settings.ini", "General", "monitorToSwitchWindowsOn", 1)  ; Monitor on which the windows will be switching (only 3 or more monitors, otherwise it is the secondary monitor if 2 and primary monitor if 1)
portableVSCodeFont := IniRead("settings.ini", "General", "portableVSCodeFont", "")
homeVSCodeFont := IniRead("settings.ini", "General", "homeVSCodeFont", "")

; App theme settings
useSunriseSunset := IniRead("settings.ini", "AppTheme", "useSunriseSunset", 0)
useTravelMode := IniRead("settings.ini", "AppTheme", "useTravelMode", 0)
homeLatitude := IniRead("settings.ini", "AppTheme", "homeLatitude", 0)
homeLongitude := IniRead("settings.ini", "AppTheme", "homeLongitude", 0)
homeTimezoneShift := IniRead("settings.ini", "AppTheme", "homeTimezoneShift", 0)
travelLatitude := IniRead("settings.ini", "AppTheme", "travelLatitude", 0)
travelLongitude := IniRead("settings.ini", "AppTheme", "travelLongitude", 0)
travelTimezoneShift := IniRead("settings.ini", "AppTheme", "travelTimezoneShift", 0)
lightThemeHour := IniRead("settings.ini", "AppTheme", "defaultLightThemeHour", 7)
darkThemeHour := IniRead("settings.ini", "AppTheme", "defaultDarkThemeHour", 20)

; Keyboard layout
primaryKeyboardLayoutID := IniRead("settings.ini", "KeyboardLayout", "primaryID", 0)
secondaryKeyboardLayoutID := IniRead("settings.ini", "KeyboardLayout", "secondaryID", 0)
primaryKeyboardLayoutApps := StrSplit(StrReplace(IniRead("settings.ini", "KeyboardLayout", "primaryApps", ""), ", ", ","), ",")
secondaryKeyboardLayoutApps := StrSplit(StrReplace(IniRead("settings.ini", "KeyboardLayout", "secondaryApps", ""), ", ", ","), ",")

; Action toggler
runEverythingOnLogon := IniRead("settings.ini", "ActionToggler", "runEverythingOnLogon", 1)
changeAppTheme := IniRead("settings.ini", "ActionToggler", "changeAppTheme", 1)
changePowerPlans := IniRead("settings.ini", "ActionToggler", "changePowerPlans", 1)
discordStart := IniRead("settings.ini", "ActionToggler", "discordStart", 1)
spotifyStart := IniRead("settings.ini", "ActionToggler", "spotifyStart", 1)
gameLaunchersOperations := IniRead("settings.ini", "ActionToggler", "gameLaunchersOperations", 1)
VSCodeFontChange := IniRead("settings.ini", "ActionToggler", "VSCodeFontChange", 1)
keyboardLayoutChange := IniRead("settings.ini", "ActionToggler", "keyboardLayoutChange", 1)

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

; Paths, .exe names
everythingExe := "Everything.exe"
discordExe := "Discord.exe"
spotifyExe := "Spotify.exe"
steamExe := "Steam.exe"
epicgamesExe := "EpicGamesLauncher.exe"
wargamingExe := "wgc.exe"
everythingPath := A_ProgramFiles "\Everything\" everythingExe
; GetDirStartsWith function ensures that Discord.exe file is always found regardless of version
discordPath := GetDirStartsWith("C:\Users\" A_UserName "\AppData\Local\Discord\app*") discordExe
spotifyPath := A_AppData "\Spotify\" spotifyExe
steamPath := "C:\Program Files (x86)\Steam\" steamExe
epicgamesPath := "C:\Program Files (x86)\Epic Games\Launcher\Portal\Binaries\Win32\" epicgamesExe
VSCodeSettingsPath := A_AppData "\Code\User\settings.json"

; Constants
pi := 3.14159265359

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

; Run Everything on logon
if runEverythingOnLogon && !ProcessExist(everythingExe) && FileExist(everythingPath)
    Run(everythingPath, , "Hide")

; Check keyboard layout
if keyboardLayoutChange && AreChosenLayoutsInstalled()
    SetTimer(CheckKeyboardLayout, 200)

; State-based actions
if changeAppTheme || changePowerPlans || discordStart || spotifyStart || gameLaunchersOperations || VSCodeFontChange
{
    ; Used on logon
    CheckState()
    logon := false

    ; Check states every 60 seconds
    SetTimer(CheckState, 60000)
}

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

/**
 * @description  
 * Check states and manage state-based actions.
 */
CheckState()
{
    global wasPortableEnabled

    if CheckWakeUp()
        EnableThreadMerge()

    ; Manage app themes (check if theme should be changed and if yes, change it)
    ManageAppTheme()

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
            static repeatIndex := 0  ; Only in function scope
            if ProcessExist(wargamingExe)
            {
                ProcessClose(wargamingExe)
                SetTimer(TerminateGameLaunchers, 0)  ; Disable timer
            }
            ; If it checked 10 times, stop checking it
            else if repeatIndex >= 10
                SetTimer(TerminateGameLaunchers, 0)  ; Disable timer
            ; Terminate Steam and Epic Games in first iteration if it is running
            if repeatIndex = 0
            {
                if ProcessExist(steamExe)
                    ProcessClose(steamExe)
                if ProcessExist(epicgamesExe)
                    ProcessClose(epicgamesExe)
            }
            repeatIndex++
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

        ; Get coordinates of the monitor
        MonitorGet monitor, &left, &top

        if !WinExist("ahk_exe " discordExe) && FileExist(discordPath) && discordStart
        {
            wasDiscordRunning := ProcessExist(discordExe)

            ; Get the "normal" active window ID, if any, used only if discord is running in background
            firstActiveID := WinIsNormal(WinExist("A"))

            Run(discordPath)
            ; Run 'cmd /c start "" ' discordPath ' --processStart Discord.exe'  ; Use this instead of Run(discordPath) to run Discord independently of AutoHotkey (if AHK script is stopped and Run(discordPath)) is used, it will kill Discord

            ; With Discord is problem that when it starts after log on, the Updater appears first and then the main window. To work with the main window, the script waits for the Updater to appear, to close, and then only the main window remains, so it is certain that discordID is now the main window. If Discord was running (on system wake up) no Updater window will show, so it will not wait for Discord Updater window but directly for the Discord window
            if !wasDiscordRunning
            {
                ; Wait for Discord Updater window to open and then wait to close
                if WinWait("Discord Updater", , 10)
                    WinWaitClose("Discord Updater", , 60)
            }

            ; Wait for Discord window but with different title then Discord Updater
            discordID := WinWait("ahk_exe " discordExe, , 60, "Discord Updater")
            if discordID
            {
                if !IsOnMonitor(discordID, monitor, true)
                {
                    ; Unmaximize window, move it to the selected monitor and then maximize it
                    WinRestore(discordID)
                    WinMove(left, top, , , discordID)
                    WinMaximize(discordID)
                }
            }

            ; Get the "normal" active window ID, if any
            activeID := WinIsNormal(WinExist("A"))

            if !wasDiscordRunning
            {
                WinActivateCorrectly(activeID, WinGetID(discordID), true, false, true)
                Sleep(2000)  ; Wait a while to load the Discord
                WinActivateCorrectly(WinGetID(discordID), activeID, false, true, false)
                someWinActivated := true
            }
            else
            {
                Sleep(1000)  ; Wait a while to load the Discord
                WinActivateCorrectly(WinGetID(discordID), firstActiveID, false, true, false)
                someWinActivated := true
            }
        }

        if !WinExist("ahk_exe " spotifyExe) && FileExist(spotifyPath) && spotifyStart
        {
            Run(spotifyPath)
            ; Run 'cmd /c start "" ' spotifyPath ' --processStart Discord.exe'  ; Use this instead of Run(spotifyPath) to run Spotify independently of AutoHotkey (if AHK script is stopped and Run(spotifyPath)) is used, it kill Spotify

            ; Wait until Spotify is running and if it is not on the selected monitor, move it there
            spotifyID := WinWait("ahk_exe " spotifyExe, , 120)
            if spotifyID && !IsOnMonitor(spotifyID, monitor, true)
            {
                ; Unmaximize window, move it to the selected monitor and then maximize it
                WinRestore(spotifyID)
                WinMove(left, top, , , spotifyID)
                WinMaximize(spotifyID)
            }

            ; Get the "normal" active window ID, if any
            activeID := WinIsNormal(WinExist("A"))

            WinActivateCorrectly(activeID, spotifyID, true, false, false)
            Sleep(1000)  ; Wait a while to load the Spotify
            WinActivateCorrectly(spotifyID, activeID, false, true, false)
            someWinActivated := true
        }

        ; Disable Thread merge if some window was activated (it usually disable automatically but not always, for example if only Spotify was activated)
        if someWinActivated
            DisableThreadMerge()

        ; Run Steam and Epic Games in background if it was not running. WGC run automatically on startup.
        if !ProcessExist(steamExe) && FileExist(steamPath) && gameLaunchersOperations
        {
            Run(steamPath " -Silent")
            ; Steam sometimes open update window, if yes minimize it
            steamID := WinWait("ahk_exe " steamExe)
            if WinExist(steamID)
                WinMinimize(steamID)
        }
        if !ProcessExist(epicgamesExe) && FileExist(epicgamesPath) && gameLaunchersOperations
            Run(epicgamesPath " -Silent")
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

    ; Manage app themes (check if theme should be changed and if yes, change it)
    ManageAppTheme()
    {
        ; If light theme is active
        isLightTheme := RegRead("HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize", "AppsUseLightTheme")

        ; If light theme should be active
        shouldBeLightTheme := ShouldLightThemeBeActive()

        if shouldBeLightTheme && !isLightTheme
            RegWrite("1", "REG_DWORD", "HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize", "AppsUseLightTheme")
        else if !shouldBeLightTheme && isLightTheme
            RegWrite("0", "REG_DWORD", "HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize", "AppsUseLightTheme")

        ; Check if app theme should be light, if yes return 1, otherwise return 0
        ShouldLightThemeBeActive()
        {
            ; If sunrise and sunset date and times should be used to change app theme
            if useSunriseSunset
            {
                ; Current UTC date and time
                nowUTC := A_NowUTC

                ; Get sunrise and sunset UTC date and times
                ; Set current UTC date as last checked sunrise and sunset date
                if logon
                {
                    sunriseSunset := CalculateSunriseSunset()
                    static sunrise := sunriseSunset[1]
                    static sunset := sunriseSunset[2]
                    static lastCheckedSrSsDate := FormatTime(nowUTC, "yyyyMMdd")
                }

                ; Current UTC date
                dateUTC := FormatTime(nowUTC, "yyyyMMdd")
                ; If current UTC date is not same as UTC date of last sunrise and sunset check, update sunrise and sunset date and time
                if dateUTC != lastCheckedSrSsDate
                {
                    sunriseSunset := CalculateSunriseSunset()
                    sunrise := sunriseSunset[1]
                    sunset := sunriseSunset[2]
                }

                ; If sunrise is 0, there is no sun all day (polar night)
                if sunrise = 0
                    return 0
                ; If sunrise is 1, there is only sun all day (midnight sun)
                else if sunrise = 1
                    return 1

                ; If sunrise is before sunset, sun will shine between them
                ; Note: Sunrise is logically always before sunset but if sunrise is out of day range, script will use sunrise from day after this to both sunrise and sunset be in this day (analogously it works if sunset is out of day range)
                if sunrise < sunset
                {
                    if sunrise < nowUTC && nowUTC < sunset
                        return 1
                    else
                        return 0
                }
                else
                {
                    if sunset < nowUTC && nowUTC < sunrise
                        return 0
                    else
                        return 1
                }
            }
            ; If fixed hours should be used to change app theme
            else
            {
                ; If the light theme activation hour is before the dark theme activation hour
                if lightThemeHour < darkThemeHour
                {
                    if lightThemeHour <= A_Hour && A_Hour < darkThemeHour
                        return 1
                    else
                        return 0
                }
                else
                {
                    if darkThemeHour <= A_Hour && A_Hour < lightThemeHour
                        return 0
                    else
                        return 1
                }
            }

            ; Calculate sunrise and sunset UTC date and times from latitude and longitude from settings file and return that values as Array in YYYYMMDDHH24MISS format
            CalculateSunriseSunset()
            {
                ; If the travel mode should be used
                if useTravelMode
                {
                    latitude := travelLatitude
                    longitude := travelLongitude
                    timezoneShift := travelTimezoneShift
                }
                ; If the home mode should be used
                else
                {
                    latitude := homeLatitude
                    longitude := homeLongitude
                    timezoneShift := homeTimezoneShift
                }

                ; Change longitude depending on timezone diff (if user traveled in other timezone then default or if Daylight saving time was turned off/on)
                timezoneDiff := GetTimezoneShift() - timezoneShift  ; Difference between timezone shift from this place (value from settings file) and current timezone shift (difference between current date time and UTC date time)
                longitude += timezoneDiff * 15  ; Change longitude (timezone diff * 15 is approximately 1 hour)

                nowUTC := A_NowUTC  ; Current UTC date and time
                dayOfYear := FormatTime(nowUTC, "YDay")
                srSsMin := CalculateSrSsMin(latitude, longitude, dayOfYear)  ; sunrise and sunset UTC time from midnight in minutes
                sunriseMin := srSsMin[1]
                sunsetMin := srSsMin[2]

                ; If no sun all day (polar night) or only sun all day (midnight sun)
                if sunriseMin = 0 && sunsetMin = 0 || sunriseMin = 1 && sunsetMin = 1
                    return [sunriseMin, sunsetMin]

                ; If sunrise was day before this, calculate sunrise from next day and use it if next day is sunrise (if not, just move the original calculated sunrise by 24 hours)
                if sunriseMin < 0
                {
                    dayOfYear := FormatTime(DateAdd(nowUTC, 1, "Days"), "YDay")
                    srSsMin := CalculateSrSsMin(latitude, longitude, dayOfYear)
                    ; Move original calculated sunrise by 24 hours
                    if srSsMin[1] = 0 && srSsMin[2] = 0 || srSsMin[1] = 1 && srSsMin[2] = 1
                        sunriseMin += 24 * 60
                    ; Use new calculated sunrise from next day
                    else
                        sunriseMin := srSsMin[1]
                }
                ; Similar as above - sunset is next day (not this)
                else if sunsetMin > 24 * 60
                {
                    dayOfYear := FormatTime(DateAdd(nowUTC, -1, "Days"), "YDay")
                    srSsMin := CalculateSrSsMin(latitude, longitude, dayOfYear)
                    if srSsMin[1] = 0 && srSsMin[2] = 0 || srSsMin[1] = 1 && srSsMin[2] = 1
                        sunsetMin -= 24 * 60
                    else
                    {
                        sunsetMin := srSsMin[2]
                    }
                }

                ; Calculate hours, minutes and seconds from minutes
                srHour := Floor(sunriseMin / 60)
                srMin := Floor(sunriseMin - srHour * 60)
                srSec := Round((sunriseMin - srHour * 60 - srMin) * 60)
                ssHour := Floor(sunsetMin / 60)
                ssMin := Floor(sunsetMin - ssHour * 60)
                ssSec := Round((sunsetMin - ssHour * 60 - ssMin) * 60)

                ; Join today date with sunrise/sunset times to get YYYYMMDDHH24MISS format
                sunrise := FormatTime(A_NowUTC, "yyyyMMdd") Format("{:02}{:02}{:02}", srHour, srMin, srSec)
                sunset := FormatTime(A_NowUTC, "yyyyMMdd") Format("{:02}{:02}{:02}", ssHour, ssMin, ssSec)
                return [sunrise, sunset]

                ; Calculate current timezone shift (difference between current date time and UTC date time)
                GetTimezoneShift() => DateDiff(A_Now, A_NowUTC, "Hours")

                ; Calculate sunrise and sunset UTC time from midnight in minutes from latitude, longitude and day of year and return that values as Array
                CalculateSrSsMin(latitude, longitude, dayOfYear)
                {
                    ; Calculate fractional year gamma (in radians)
                    gamma := 2 * pi / 365 * (dayOfYear - 1 + ((12 - 12) / 24))  ; Assuming noon for simplicity

                    ; Equation of time (in minutes)
                    eqtime := 229.18 * (
                        0.000075
                        + 0.001868 * Cos(gamma)
                        - 0.032077 * Sin(gamma)
                        - 0.014615 * Cos(2 * gamma)
                        - 0.040849 * Sin(2 * gamma)
                    )

                    ; Solar declination (in radians)
                    decl := (
                        0.006918
                        - 0.399912 * Cos(gamma)
                        + 0.070257 * Sin(gamma)
                        - 0.006758 * Cos(2 * gamma)
                        + 0.000907 * Sin(2 * gamma)
                        - 0.002697 * Cos(3 * gamma)
                        + 0.00148 * Sin(3 * gamma)
                    )

                    latRad := Rad(latitude)
                    zenith := Rad(90.833)  ; Standard refraction + solar radius correction
                    cosH := (Cos(zenith) - Sin(latRad) * Sin(decl)) / (Cos(latRad) * Cos(decl))  ; Cosine of the hour angle

                    ; Can't calculate sunrise/sunset if cosH isn't between -1 and 1 (midnight sun or polar night)
                    if cosH > 1
                        return [0, 0]

                    if cosH < -1
                        return [1, 1]

                    ; Hour angle for sunrise/sunset (in radians)
                    ha := Acos(cosH)

                    ; Solar noon (in minutes)
                    solarNoon := 720 - 4 * longitude - eqtime

                    ; Calculate sunrise/sunset times in minutes from midnight UTC
                    sunriseMin := solarNoon - (Deg(ha) * 4)
                    sunsetMin := solarNoon + (Deg(ha) * 4)

                    return [sunriseMin, sunsetMin]

                    ; Convert radians from degrees and vice versa
                    Rad(deg) => deg * (pi / 180)
                    Deg(rad) => rad * (180 / pi)
                }
            }
        }
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

/**
 * @description  
 * Check keyboard layout if it is correct based on active window. For special apps (apps that are included in primary or secondary keyboard layout app list) use layout that should be used based on in which list app is and for other apps use default keyboard layout.
 */
CheckKeyboardLayout()
{
    static lastID := 0  ; ID of window that was active before any special app
    static lastExe := ""  ; Process name of window that was active before any special app
    static wasPrimary := GetKeyboardLayout() = primaryKeyboardLayoutID  ; If primary is default keyboard layout (default is that one which was active before any special app)

    ; Get the active window ID
    activeID := WinExist("A")

    ; Check layout only if active window changed
    if (activeID != lastID)
    {
        lastID := activeID

        try
            activeExe := WinGetProcessName(activeID)
        catch
            return

        Sleep 100  ; Needed to work properly, 100 is minimum

        lastExeInPrimaryApps := ContainsElement(primaryKeyboardLayoutApps, lastExe)
        lastExeInSecondaryApps := ContainsElement(secondaryKeyboardLayoutApps, lastExe)

        ; If secondary app is active, activate secondary keyboard layout
        if ContainsElement(secondaryKeyboardLayoutApps, activeExe)
        {
            ; If no special app was active, set new default layout otherwise it will be used that one which was active before any special apps
            if !lastExeInPrimaryApps && !lastExeInSecondaryApps
                wasPrimary := GetKeyboardLayout() = primaryKeyboardLayoutID
            SetKeyboardLayout(secondaryKeyboardLayoutID)
        }
        ; If primary app is active, activate primary keyboard layout
        else if ContainsElement(primaryKeyboardLayoutApps, activeExe)
        {
            ; If no special app was active, set new default layout otherwise it will be used that one which was active before any special apps
            if !lastExeInPrimaryApps && !lastExeInSecondaryApps
                wasPrimary := GetKeyboardLayout() = primaryKeyboardLayoutID
            SetKeyboardLayout(primaryKeyboardLayoutID)
        }
        ; Switch back to the default keyboard layout after some special app was active
        else
        {
            if lastExeInSecondaryApps && wasPrimary
                SetKeyboardLayout(primaryKeyboardLayoutID)
            else if lastExeInPrimaryApps && !wasPrimary
                SetKeyboardLayout(secondaryKeyboardLayoutID)
        }

        ; Set new last exe only if active exe isn't explorer (task bar)
        if activeExe != "explorer.exe"
            lastExe := activeExe
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
    for thisID in ids
    {
        if IsOnPrimaryMonitor(thisID, true)  ; Check if on the primary monitor
        {
            ; reset list of minimized windows (it can be at the start of this hotkey but if this hotkey would be activated twice in a row by mistake, the hotkey for restoration will not work)
            if !topmostWinFound
            {
                minimizedWindows := []
                topmostWinFound := true
            }
            GroupAdd("MinimizeGroup" groupCounter, "ahk_id " thisID)  ; Add window to group (at the first iteration it'll always create new group)
            minimizedWindows.Push(thisID)  ; Add to minimized list
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
    activeID := 0

    ; Iterate all IDs to find ID of the topmost window of the primary monitor that is not minimized (if user open window between minimization and restoration it will be active after restoration)
    for thisID in ids
    {
        if IsOnPrimaryMonitor(thisID, true) && WinGetMinMax(thisID) != -1  ; Check if on the primary monitor and if it's not minimized
        {
            activeID := thisID
            break
        }
    }

    if minimizedWindows.Length > 0 ; Check if the list of minimized windows is not empty
    {
        ; Iterate minimizedWindows list from behind and restore windows that exist and that are not maximized one by one (maximized windows should not be restored because they will be unmaximized)
        loop minimizedWindows.Length
        {
            thisID := minimizedWindows[-A_Index]
            if WinExist(thisID) && WinGetMinMax(thisID) != 1
            {
                GroupAdd("MinimizeGroup" groupCounter, "ahk_id " thisID)  ; Add window ID in group; comment for slow restore
                ; WinRestore(thisID)  ; uncomment for slow restore
            }
        }

        WinRestore("ahk_group MinimizeGroup" groupCounter)  ; comment for slow restore

        ; Activate window that was active on the primary monitor before window restoration or if there was none then activate window that was topmost before restoration
        if !activeID
            activeID := minimizedWindows[1]
        if WinExist(activeID)
            WinActivate(activeID)
        minimizedWindows := []
    }
}

MuteUnmuteDiscordSpotify(*) ; Press Win + T to mute/unmute Discord microphone and pause/play Spotify if it is playing
{
    discordID := WinExist("ahk_exe " discordExe)
    if discordID
    {
        ids := WinGetNormalList()  ; Get all "normal window" IDs

        try
            activeExe := WinGetProcessName("A")  ; Get .exe file name of the active window
        catch
            activeExe := WinGetProcessName(ids[1])  ; Get .exe file name of the topmost window (sometimes "A" is not found)

        ; For games
        if ContainsElement(gameList, activeExe)  ; Check if game is active window (compare active window .exe name with .exe names from list)
        {
            Send "+{SC029}"
            Sleep 500
            Send "^+m"
            Sleep 500
            Send "+{SC029}"
        }

        ; For other apps
        else
        {
            ; Get the "normal" active window ID, if any
            ; It is almost always some window active but sometimes it can't find it, so then it will set the topmost window as active, if it is
            firstActiveID := WinIsNormal(WinExist("A"))
            if !firstActiveID
            {
                firstActiveID := ids[1]
                if !WinActive(firstActiveID)
                    firstActiveID := 0
            }

            minimizedWindows := []
            monitor := 0

            ; Find out on what monitor Discord is
            loop MonitorGetCount()
                if IsOnMonitor(discordID, A_Index, true)
                    monitor := A_Index

            ; Iterate for IDs of windows that are on the same monitor as Discord
            allMaximized := 1
            for thisID in ids
            {
                if IsOnMonitor(thisID, monitor, true)
                {
                    minimizedWindows.Push(thisID)  ; Add window IDs to minimized list
                    if allMaximized
                        allMaximized := WinGetMinMax(thisID)
                }
            }

            ; Activate Discord window and send Ctrl + Shift + M hotkey to mute/unmute microphone
            if firstActiveID != discordID
            {
                WinActivateCorrectly(firstActiveID, discordID, true, false, false)
            }
            Send "^+m"
            Sleep 500  ; Determine for how long will Discord show (minimum is 1 for proper functioning)

            ; Sorting windows out
            if discordID != firstActiveID  ; If Discord window is active it will remain active
            {
                if discordID != minimizedWindows[1]  ; If Discord window was the topmost window but not active (active window was on the other monitor) it will activate window which was active at the beginning
                {
                    if !allMaximized  ; If there is some window that is not maximized it will move windows one by one from the topmost to the bottommost to the bottom to achieve the same window order as at the beginning
                    {
                        for thisID in minimizedWindows
                        {
                            WinMoveBottom(thisID)
                        }
                    }
                    WinActivateCorrectly(discordID, minimizedWindows[1], true, false, false)  ; Activate the window that was the topmost window on monitor where is Discord
                }

                ; Get the "normal" active window ID, if any
                lastActiveID := WinIsNormal(WinExist("A"))
                WinActivateCorrectly(lastActiveID, firstActiveID, false, true, false)  ; Activate the window that was active at the beginning
            }
        }
    }

    ; Pause/play music on Spotify but if music wasn't stopped using this hotkey it will not play it, so it can't play music if I didn't pause it using this hotkey
    global played
    spotifyID := WinExist("ahk_exe " spotifyExe)  ; Check if Spotify is running
    if spotifyID
    {
        spotifyTitle := WinGetTitle(spotifyID)
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
    thisID := 0

    ; Get the "normal" active window ID, if any
    activeID := WinIsNormal(WinExist("A"))

    ; Iterate backwards window IDs to find the bottommost one on the secondary (chosen) monitor and activate it
    loop ids.Length
    {
        thisID := ids.Pop()
        if IsOnMonitor(thisID, monitor, true)  ; Check if on the secondary (chosen) monitor
        {
            WinActivateCorrectly(activeID, thisID, true, false, false)
            break
        }
    }
    ; Activate the window from the beginning if it is not on the secondary monitor
    if activeID && !IsOnMonitor(activeID, monitor, true)
        WinActivateCorrectly(thisID, activeID, false, true, false)
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
 * @description  
 * Get full path that starts with string from parameter.
 * @param {(String)} start Start of the path.
 */
GetDirStartsWith(start)
{
    loop files start, 'D'
    {
        return A_LoopFileFullPath "\"
    }
}

/**
 * @description Checks if the window is in fullscreen mode.  
 * @param {(Integer)} winID  
 * ID of window to be checked.
 * @returns {(Integer)}  
 * 1 if fullscreen, 0 if not.
 */
WinIsFullscreen(winID)
{
    ; Check if window is in fullscreen mode only if it is maximized, otherwise it can't be in fullscreen mode
    if WinGetMinMax(winID) != 1
        return 0

    WinGetClientPos , , &winClientWidth, &winClientHeight, winID  ; Get coordinates of window
    WinGetPos , , &winWidth, &winHeight, winID  ; Get coordinates of window
    ; If client and normal window dimensions are equal and window is maximized then it is in fullscreen mode
    if winWidth = winClientWidth && winHeight = winClientHeight
        return 1
    return 0
}

/**
 * @description Checks if the window has border or if it is in fullscreen mode but I use it to check if the window is "normal window".  
 * "Normal window" is a window that is in foreground (minimized, maximized, restored, etc.) and not a special window on background like Program Manager, etc.
 * @param {(Integer)} winID  
 * ID of window to be checked.
 * @returns {(Integer)}  
 * The ID of the specified window.
 * If the window is not "normal" or ID is 0 or does not exist, 0 is returned.
 */
WinIsNormal(winID)
{
    if !winID
        return 0
    try
        style := WinGetStyle(winID)
    catch
        return 0
    if style & 0x800000 || WinIsFullscreen(winID)
        return winID
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
    for thisID in ids
    {
        if WinIsNormal(thisID)
            normalWindows.Push(thisID)
    }
    return normalWindows
}

/**
 * @description Searches inside an array for an instance of the provided element.
 * @param {(Array)} list The list to search inside of.
 * @param {(Any)} target The element to search for.
 * @returns {(Integer)}  
 * 1 if found, 0 if not
 */
ContainsElement(list, target)
{
    for element in list
        if element = target
            return true
    return false
}

/**
 * @description Finds if window is on specified monitor.
 * @param {'ahk_exe '|'ahk_class '|'ahk_id '|'ahk_pid '|'ahk_group '} winTitle  
 * A string using a {@link https://www.autohotkey.com/docs/v2/misc/WinTitle.htm|WinTitle} to match a window.  
 * Types: {@link https://www.autohotkey.com/docs/v2/misc/WinTitle.htm#ahk_exe|ahk_exe}, {@link https://www.autohotkey.com/docs/v2/misc/WinTitle.htm#ahk_class|ahk_class}, {@link https://www.autohotkey.com/docs/v2/misc/WinTitle.htm#ahk_id|ahk_id}, {@link https://www.autohotkey.com/docs/v2/misc/WinTitle.htm#ahk_pid|ahk_pid}, {@link https://www.autohotkey.com/docs/v2/misc/WinTitle.htm#ahk_group|ahk_group}  
 * Window title is optional and must come before any `ahk_` criteria.  
 * If WinTitle is the letter `A`, the active window is used.  
 * @param {(Integer)} monitorNumber The monitor number to check if it contains a window.
 * @param {(Integer)} offsetSwitch If the global offset should be used when finding the window.
 * @returns {(Integer)}  
 * 1 if found, 0 if not
 */
IsOnMonitor(winTitle, monitorNumber, offsetSwitch)
{
    offset := monitorOffset
    if !offsetSwitch
        offset := 0
    MonitorGet monitorNumber, &left, &top, &right, &bottom  ; Get coordinates of the monitor
    WinGetClientPos &winX, &winY, &winWidth, &winHeight, winTitle  ; Get coordinates of window (client pos is more accurate then window pos)
    return winX < right - offset && winX + winWidth > left + offset && winY < bottom - offset && winY + winHeight > top + offset  ; Check if on the monitor
}

/**
 * @description Finds if window is on the primary monitor. Uses the IsOnMonitor function.
 * @param {'ahk_exe '|'ahk_class '|'ahk_id '|'ahk_pid '|'ahk_group '} winTitle  
 * A string using a {@link https://www.autohotkey.com/docs/v2/misc/WinTitle.htm|WinTitle} to match a window.  
 * Types: {@link https://www.autohotkey.com/docs/v2/misc/WinTitle.htm#ahk_exe|ahk_exe}, {@link https://www.autohotkey.com/docs/v2/misc/WinTitle.htm#ahk_class|ahk_class}, {@link https://www.autohotkey.com/docs/v2/misc/WinTitle.htm#ahk_id|ahk_id}, {@link https://www.autohotkey.com/docs/v2/misc/WinTitle.htm#ahk_pid|ahk_pid}, {@link https://www.autohotkey.com/docs/v2/misc/WinTitle.htm#ahk_group|ahk_group}  
 * Window title is optional and must come before any `ahk_` criteria.  
 * If WinTitle is the letter `A`, the active window is used.  
 * @param {(Integer)} offsetSwitch If the global offset should be used when finding the window.
 * @returns {(Integer)}  
 * 1 if found, 0 if not
 */
IsOnPrimaryMonitor(winTitle, offsetSwitch)
{
    return IsOnMonitor(winTitle, MonitorGetPrimary(), offsetSwitch)
}

/**
 * @description  
 * Activate window properly (not flashing taskbar icon).  
 * It attach the active window thread with the target window thread. After that, window can be activated without problems because it acts like it is on the same thread as the window that was active before. Without it the new window will not activate at all or not correctly and the taskbar icon will flash. This technique is used only the first time any window is activated after the script start, then it works correctly without the Thread merge.
 * @param {(Integer)} activeID  
 * ID of currently active window.  
 * If 0, Thread merging will not be used.
 * @param {(Integer)} targetID  
 * ID of window that will be activated.
 * If 0, nothing will happen.
 * @param {(Integer)} wait If script should wait to window be active.
 * @param {(Integer)} disableThreadMerging If the Thread merging should be disabled after this activation.
 * @param {(Integer)} [activateActive] If the window should activate even if it looks like it is already active.
 */
WinActivateCorrectly(activeID, targetID, wait, disableThreadMerging, activateActive := 0)
{
    ; If target ID is 0, do nothing
    if !targetID
        return

    ; If active ID is 0, do activate target window normally
    if !activeID
    {
        WinActivateNormally()

        if disableThreadMerging
            DisableThreadMerge()
        return
    }

    ; Do anyting only if target and active IDs are different or if active window can be activated and active window is not Start menu (it blocks activation)
    if (activateActive || activeID != targetID) && WinGetTitle(activeID) != "Start"
    {
        if threadMergeEnabled && activeID != targetID
            WinActivateWithThreadMerge()
        else
            WinActivateNormally()

        if disableThreadMerging
            DisableThreadMerge()
    }

    WinActivateNormally()
    {
        WinActivate(targetID)
        if wait
            WinWaitActive(targetID, , 10)
    }

    WinActivateWithThreadMerge()
    {
        ; Get thread IDs
        activeThreadID := DllCall("GetWindowThreadProcessId", "ptr", activeID, "uint*", 0, "uint")
        targetThreadID := DllCall("GetWindowThreadProcessId", "ptr", targetID, "uint*", 0, "uint")

        ; Attach input threads so focus can transfer
        DllCall("AttachThreadInput", "uint", activeThreadID, "uint", targetThreadID, "int", true)

        ; Activate the target window
        WinActivateNormally()

        ; Detach again
        DllCall("AttachThreadInput", "uint", activeThreadID, "uint", targetThreadID, "int", false)
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

/**
 * @description  
 * Check if primary and secondary keyboard layouts are installed. It checks keyboard language IDs only not specific keyboard layout IDs.
 * @returns {(Integer)}  
 * 1 if both layouts exist, 0 if not
 */
AreChosenLayoutsInstalled()
{
    primaryExist := false
    secondaryExist := false

    ; Determine how many layouts are installed
    numLayouts := DllCall("GetKeyboardLayoutList", "Int", 0, "Ptr", 0)

    ; Create a buffer to hold the layout IDs
    layoutIDs := Buffer(numLayouts * A_PtrSize)
    DllCall("GetKeyboardLayoutList", "Int", numLayouts, "Ptr", layoutIDs)

    loop numLayouts
    {
        ; Extract the ID from the buffer
        hkl := NumGet(layoutIDs, (A_Index - 1) * A_PtrSize, "Ptr")

        ; Extract the Language ID
        langID := hkl & 0xFFFF

        ; Check if both primary and secondary keyboard layouts are installed
        if primaryKeyboardLayoutID = langID
            primaryExist := true
        if secondaryKeyboardLayoutID = langID
            secondaryExist := true
    }
    return primaryExist && secondaryExist
}

/**
 * @description  
 * Set keyboard layout language from parameter if it is not already active. It is supposed to be used for changing keyboard language not for changing specific layouts of one language.
 * @param {(Integer)} langID  
 * Hexadecimal number in format 0xFFFF.
 */
SetKeyboardLayout(langID)
{
    ; Check layout is already correct to avoid spamming Windows messages
    if GetKeyboardLayout() != langID
    {
        activeWindow := WinExist("A")
        if activeWindow
            PostMessage(0x0050, 0x0002, langID, , activeWindow)
    }
}

/**
 * @description  
 * Get active keyboard layout language ID. It gets active keyboard language ID only not specific keyboard layout ID.
 * @returns {(Integer)}  
 * Hexadecimal number in format 0xFFFF.
 */
GetKeyboardLayout()
{
    try
    {
        threadID := DllCall("GetWindowThreadProcessId", "ptr", WinActive("A"), "uint*", 0, "uint")
        hkl := DllCall("GetKeyboardLayout", "uint", threadID, "ptr")  ; Full keyboard layout ID (hkl stands for keyboard layout handle)
        return hkl & 0xFFFF  ; 0xFFFF is bitmask and it is used to convert full keyboard layout ID to keyboard language ID
    }
    return 0
}
