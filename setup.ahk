; Copyright (C) 2025 Daniel Bočan
; Licensed under GNU GPL v3.0 or later: https://www.gnu.org/licenses/gpl-3.0.html

; This script create copy of default Power saver Power scheme, set its important properties and save GUID of the scheme to the settings.ini file.

#Requires AutoHotkey v2.0

guidKey := "powerSaverGUID"  ; Key in .ini file that stores value of GUID of Power saver Power scheme

; The script is only run if the GUID value in the settings.ini file is empty to prevent unwanted execution
if IniRead("settings.ini", "Constants", guidKey, "") == ""
{
    output := CmdOutput("powercfg -duplicatescheme a1841308-3541-4fab-bc81-f71556f20b4a")  ; Make copy default Power saver Power scheme
    guid := GetGUID(output)
    IniWrite(guid, "settings.ini", "Constants", guidKey)  ; Save GUID to settings.ini file
    Run("powercfg /setdcvalueindex " guid " SUB_ENERGYSAVER ESBATTTHRESHOLD 100 && powercfg /setdcvalueindex " guid " SUB_ENERGYSAVER ESBRIGHTNESS 100", , "Hide")  ; Set Energy saver activation to 100% so it is always active and set brightness with Energy saver activated to 100% of brightness with Energy saver deactivated

    ; Get GUID from line of informations (get the part that contains numbers)
    GetGUID(line)
    {
        lineSplit := StrSplit(line, " ")
        for part in lineSplit
            if RegExMatch(part, "\d")
                return part
    }

    ; return output of cmd command in parameter
    CmdOutput(command)
    {
        shell := ComObject("WScript.Shell")
        exec := shell.Exec("cmd /c " command)
        return exec.StdOut.ReadAll()
    }
}
