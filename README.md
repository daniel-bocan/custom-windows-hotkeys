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

## Aditional Features
Script run actions that will trigger after each log on (script start) and on every wake up.  
The actions depends on whether portable mode is enabled (if there is only 1 monitor connected) or not (if there are 2 or more monitors connected).
### Portable mode
Enable Power saver Power scheme and enable Energy saver.
### Home mode
Enable Balanced Power scheme and disable Energy saver.  
Run Discord and Spotify and move these windows to secondary or selected monitor.

## Getting Started

### 1. Install AutoHotkey v2

Download from the official website:  
https://www.autohotkey.com

### 2. Run the Script

Double-click the `main.ahk` file to be able to use the hotkeys.  

### 3. Create task in Task scheduler (optional)
1. Press `Win + R`, type `taskschd.msc` and press **Enter** to open the **Task Scheduler**.
2. In the **right-hand panel**, click **"Create Task..."**.
3. In the **General** tab:
   - Enter a **name** for the task (e.g., AutoHotkey Script).
   - Enable **Run with highest privilegies** option if possible, for the script to work properly

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

Settings are stored in the `settings.ini` file. This file contains three key items: the **preferred monitor**, **enable/disable logon actions** and the **game list**.

- To change the monitor used by the `Win + B` hotkey (for switching windows) and logon actions (Discord and Spotify move), modify the `monitorToSwitchWindowsOn` variable.
  - On systems with **3 or more monitors**, this value determines the exact monitor.
  - On **2-monitor setups**, windows switch on the **secondary** monitor.
  - On **single-monitor setups**, it defaults to the **primary** monitor.

- To enable/disable logon actions change `enableLogonActions` variable.

- Add games that support **Discord's overlay** to the `gameList` section to enable proper detection and handling. List each game’s `.exe` file name **on a separate line**.

### 5. Set up Power schemes to be used in a script (Recommended)
In order for the script to use schemes and Energy saver, they need to be set up first.  
It is not neccessery to set this up. If they aren't set up, the script will create all the necessary schemes and can switch between them. However the Energy saver will not be used, which is the most important part, so it will be almost useless without setting this up.

Run this command in CMD or Windows Powershell to see what Power schemes system offers:
```powershell
powercfg list
```
Output should look like this:
```powershell
Existing Power Schemes (* Active)
-----------------------------------
Power Scheme GUID: 381b4222-f694-41f0-9685-ff5bb260df2e  (Balanced) *
Power Scheme GUID: a1841308-3541-4fab-bc81-f71556f20b4a  (Power saver)
```
If there is only Balanced Power scheme and not Power saver Power scheme run this command:

```powershell
powercfg -duplicatescheme a1841308-3541-4fab-bc81-f71556f20b4a
```

To have the script turn on Energy saver during Power saver Power scheme run this command:

```powershell
powercfg /setdcvalueindex a1841308-3541-4fab-bc81-f71556f20b4a SUB_ENERGYSAVER ESBATTTHRESHOLD 100
```
Note: Internally, the way it works is that the Power saver Power scheme is set to turn on Energy saver at 100%, so it is always on.

If it is problem with changing brightness when Energy saver enables, run this command:

```powershell
powercfg /setdcvalueindex a1841308-3541-4fab-bc81-f71556f20b4a SUB_ENERGYSAVER ESBRIGHTNESS 100
```
Note: A value of 100 means that the brightness will remain the same as when Energy saver mode is turned off. However, the brightness may change between schemes because each scheme has its own brightness value stored.

Now everything is working properly. In portable mode Power saver Power scheme and also Energy saver will be used. In home mode Balanced Power scheme will be used and Energy saver will be disabled.

## License
This project is licensed under the GNU General Public License v3.0 or later. See the [LICENSE](/LICENSE) file for details.