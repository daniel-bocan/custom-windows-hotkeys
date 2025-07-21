# Custom hotkeys for Windows
A simple AutoHotkey project that adds useful custom hotkeys for Windows to easily handle window operations and daily tasks.

Created with AutoHotkey v2 (https://www.autohotkey.com/).

## Hotkeys

Key Combination         | Description                                                                 
------------------------|-----------------------------------------------------------------------------
`Win + Alt + F`         | Minimize all windows on the primary monitor
`Win + Alt + H`         | Restore minimized windows on the primary monitor and activate the topmost one
`Win + T`               | Mute/unmute Discord microphone and pause/play Spotify if it is playing
`Win + B`               | Switch between windows on the secondary or selected monitor
`Win + Ctrl + C`        | Append selected text to the end of clipboard with blank line between texts
`Win + Ctrl + X`        | Compare selected text with clipboard; optionally replace selected text

## Getting Started

### 1. Install AutoHotkey v2

Download from the official website:  
https://www.autohotkey.com/

### 2. Run the Script

Double-click the `main.ahk` file to be able to use the hotkeys.  

### 3. Create task in Task scheduler (optional)

1. Press `Win + R` and type `taskschd.msc`.
2. Select `Create Task...`.
3. Type name in General tab.
4. In Triggers tab press `New...` then select `At log on` in dropdown and press `OK`.
5. In Actions tab press `New...` then select `Start a program` in dropdown, paste path to `main.ahk` file to Program/script text field and press `OK`.
6. Optionaly Conditions and Settings tabs can be customized.
7. Press `OK` and from now `main.ahk` file will run after log on and hotkeys will be always available.

### 4. Customize `settings.ini` file

By changing `monitorToSwitchWindowsOn` variable change on which monitor windows will switch with `Win + B` hotkey (only for 3 and more monitors, otherwise it is the secondary monitor for 2 and the primary monitor for 1).

Add games that support Discord's overlay to the game list.

## License
This project is licensed under the GNU General Public License v3.0 or later. See the [LICENSE](/LICENSE) file for details.