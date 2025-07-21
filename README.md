# Custom hotkeys for Windows
A lightweight AutoHotkey project that introduces a set of custom hotkeys for enhanced productivity on Windows. It provides quick and intuitive controls for window management, Discord and Spotify integration, and text utilities such as clipboard append and text comparison.

Created with AutoHotkey v2 (https://www.autohotkey.com).

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
https://www.autohotkey.com

### 2. Run the Script

Double-click the `main.ahk` file to be able to use the hotkeys.  

### 3. Create task in Task scheduler (optional)
<!--
1. Press `Win + R` and type `taskschd.msc`.
2. In task scheduler press `Create Task...` button on the right panel.
3. Type task name in General tab.
4. In Triggers tab press `New...` then select `At log on` in dropdown and press `OK`.
5. In Actions tab press `New...` then select `Start a program` in dropdown, paste path to `main.ahk` file to Program/script text field and press `OK`.
6. Optionaly Conditions and Settings tabs can be customized.
7. Press `OK` and from now `main.ahk` file will run after log on and hotkeys will be always available.
-->

1. Press `Win + R`, type `taskschd.msc` and press **Enter** to open the **Task Scheduler**.
2. In the **right-hand panel**, click **"Create Task..."**.
3. In the **General** tab:
   - Enter a **name** for the task (e.g., AutoHotkey Script).
4. Switch to the **Triggers** tab:
   - Click **"New..."**.
   - From the **Begin the task** dropdown, select **"At log on"**.
   - Click **OK**.
5. Go to the **Actions** tab:
   - Click **"New..."**.
   - From the **Action** dropdown, choose **"Start a program"**.
   - In the **Program/script** field, enter the **full path** to your `main.ahk` file.
   - Click **OK**.
6. *(Optional)* Adjust options in the **Conditions** and **Settings** tabs as needed.
7. Click **OK** to create the task.

From now on, the `main.ahk` script will **run automatically** at **log on**, ensuring that all hotkeys are active.

### 4. Customize the settings file

Settings are stored in the `settings.ini` file. This file contains two key items: the **preferred monitor** and the **game list**.

- To change the monitor used by the `Win + B` hotkey (for switching windows), modify the `monitorToSwitchWindowsOn` variable.
  - On systems with **3 or more monitors**, this value determines the exact monitor.
  - On **2-monitor setups**, windows switch on the **secondary** monitor.
  - On **single-monitor setups**, it defaults to the **primary** monitor.

- Add games that support **Discord's overlay** to the `gameList` section to enable proper detection and handling. List each game’s `.exe` file name **on a separate line**.

## License
This project is licensed under the GNU General Public License v3.0 or later. See the [LICENSE](/LICENSE) file for details.