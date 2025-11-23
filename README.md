# Custom hotkeys for Windows

A lightweight AutoHotkey project that introduces a set of custom hotkeys and state-based actions for enhanced productivity on Windows. It provides quick and intuitive controls for window management, Discord and Spotify integration and text utilities such as clipboard append and text comparison. The project newly includes state-based actions. It automatically switch between home and portable modes, each with its own set of actions, which personalize environment for both home and on the go. Also automatically switch between light and dark app theme based on the time of day.

Created with AutoHotkey v2 (https://www.autohotkey.com).

## Hotkeys

| Key Combination  | Description                                                                   |
| ---------------- | ----------------------------------------------------------------------------- |
| `Win + F`        | Minimize all windows on the primary monitor                                   |
| `Win + H`        | Restore minimized windows on the primary monitor and activate the topmost one |
| `Win + T`        | Mute/unmute Discord microphone and pause/play Spotify if it is playing        |
| `Win + B`        | Switch between windows on the secondary or selected monitor                   |
| `Win + Ctrl + C` | Append selected text to the end of clipboard with blank line between texts    |
| `Win + Ctrl + X` | Compare selected text with clipboard; optionally replace selected text        |

## Aditional Features

Script run some actions triggered by states (system start, monitor count change, entering in time interval).  
The actions depends on whether portable mode is enabled (if there is only 1 monitor connected) or not (if there are 2 or more monitors connected).

### Portable mode

-   Enable Power saver Power scheme and enable Energy saver.
-   Terminate Steam, Epic Games and Wargaming Game Center to disable update downloads.
-   Change VS Code editor font to the Monocraft font.

### Home mode

-   Enable Balanced Power scheme and disable Energy saver.
-   Run Discord and Spotify and move these windows to secondary or selected monitor.
-   Run Steam and Epic Games to enable update downloads.
-   Change VS Code editor font to the deafult font (Consolas, 'Courier New', monospace).

### Actions independent of mode

-   Run Everything program on logon.
-   Change app theme based on sunrise and sunset time or on times set in settings.

## Getting Started

### 1. Install AutoHotkey v2

Download from the official website:  
https://www.autohotkey.com

### 2. Run the Script

Double-click the `main.ahk` file to be able to use the actions and hotkeys.

Note: Run script with the highest privilegies if possible. Things below couldn't work well if script is running as user:

-   Everything won't work because it needs to be run as administrator to index NTFS volumes.
-   After using hotkey containing Win key, Start Menu could open.
-   If active window has highest privilegies, hotkeys won't work at all.
-   Operations with windows that have highest privilegies is unable and even can throw exception (for example minimizing windows that contains window with highest privilegies).

### 3. Create task in Task scheduler (recommended)

1. Press `Win + R`, type `taskschd.msc` and press **Enter** to open the **Task Scheduler**.
2. In the **right-hand panel**, click **"Create Task..."**.
3. In the **General** tab:

    - Enter a **name** for the task (e.g., AutoHotkey Script).
    - Enable **Run with highest privilegies** option if possible, for the script to work properly.

4. Switch to the **Triggers** tab:
    - Click **"New..."**.
    - From the **Begin the task** dropdown, select **"At log on"**.
    - Click **OK**.
5. Go to the **Actions** tab:
    - Click **"New..."**.
    - From the **Action** dropdown, choose **"Start a program"**.
    - In the **Program/script** field, enter the **full path** to your `main.ahk` file.
    - Click **OK**.
6. _(Optional)_ Adjust options in the **Conditions** and **Settings** tabs as needed.
7. Click **OK** to create the task.

From now on, the `main.ahk` script will **run automatically** on **logon**, ensuring that all hotkeys are active.

### 4. Customize the settings

Settings are stored in the `settings.ini` file. There are many things that can be set.

#### General

-   To change the monitor used by the `Win + B` hotkey (for switching windows) and logon actions (Discord and Spotify move), modify the `monitorToSwitchWindowsOn` variable.

    -   On systems with **3 or more monitors**, this value determines the exact monitor.
    -   On **2-monitor setups**, windows switch on the **secondary** monitor.
    -   On **single-monitor setups**, it defaults to the **primary** monitor.

-   To change the VS Code font that will be used in **portable mode**, modify `portableVSCodeFont` variable.  
    To change the VS Code font that will be used in **home mode**, modify `homeVSCodeFont` variable.

#### App Theme

App theme can change based on sunrise and sunset times or based on fixed times. Set the app theme change type using `useSunriseSunset` variable.

If change app theme should be based on **sunrise and sunset times**, set settings below:

-   Set **home** latitude, longitude and timezone shift:
    -   Set home latitude and longitude using `homeLatitude` and `homeLongitude` variables. Latitude and longitude are used to calculate sunrise and sunset times.
    -   Set home timezone shift using `homeTimezoneShift` variable. Timezone shift is used to handle Daylight saving time and travel to different timezones.
    -   Calculating sunrise and sunset times while far away from home is done using timezone difference but it is accurate only if travel in similar latitude as home. To calculate sunrise and sunset times
    
-   Set **travel** latitude, longitude and timezone shift:
    -   Calculating sunrise and sunset times while far away from home is done using timezone difference but it is accurate only if latitude of travel destination is similar as home latitude.  
    To calculate sunrise and sunset times accurately everywhere while travel set latitude, longitude and timezone shift of travel destination where using `travelLatitude`, `travelLongitude` and `travelTimezoneShift` variables.
    -   To switch whether use home and travel variables, modify `useTravelMode` variable.

If change app theme should be based on **fixed times**, set settings below:

-   To change the **app light theme** activation hour, modify `lightThemeHour` variable.
-   To change the **app dark theme** activation hour, modify `darkThemeHour` variable.

#### Action and Hotkey toggle

-   To enable/disable state-based and logon actions and hotkeys, modify variables under `ActionToggler` and `HotkeyToggler` sections.

#### Hotkey mapping

-   To change hotkey key combinations, modify variables under `Hotkeys` section.

#### Game list

-   Add games that support **Discord's overlay** to the `gameList` section to enable proper detection and handling. List each game’s `.exe` file name **on a separate line**.

### 5. Set up Power schemes (recommended, if you want to use them)

In order for the script to use schemes and Energy saver, they need to be set up first.  
It isn't necessary to set this up. If they aren't set up, the script will create all the necessary schemes and can switch between them. However the Energy saver won't be used, which is the most important part, so it will be almost useless without setting this up.

There are two schemes script use:

-   Balanced Power scheme - Default scheme, system use (already there)
-   Power saver Power scheme - Scheme designed to consume less power (need to set up)

#### 1. First option - execute the `setup.ahk` file

This is the easiest way how to set up Power schemes. All you have to do is execute the `setup.ahk` file and it will do all work for you.

Internally it creates a new Power saver Power scheme, set Energy saver to be always on, set Energy saver brightness to be same as with Energy saver disabled and save the GUID (Globally Unique Identifier) to the `local_config.ini` file (if it isn't exist, script creates it).

#### 2. Second option - set up Power saver Power scheme manually

Do this if you want to have more control over it or if you already have some Power saver Power scheme and want to use it.

Firstly use command below to find out if Power saver Power scheme already is in system.

```powershell
powercfg list
```

Output should looks like this:

```powershell
Existing Power Schemes (* Active)
-----------------------------------
Power Scheme GUID: 381b4222-f694-41f0-9685-ff5bb260df2e  (Balanced) *
Power Scheme GUID: e5f79a4c-684d-41ea-af84-9c4b35bc161a  (Power saver)
```

If there is any Power saver Power scheme, you can use it. If you don't want to or it doesn't exist, use command below to create a new one.

```powershell
powercfg -duplicatescheme a1841308-3541-4fab-bc81-f71556f20b4a
```

Note: It will create copy of the default Power saver Power scheme. Copy has different GUID then.

Then copy the Power saver Power scheme GUID (Globally Unique Identifier) which you can get from the list or from output of the duplication command. Create the `local_config.ini` file (if it isn't exist). Paste GUID into `powerSaverGUID` variable in `local_config.ini` file. Then use this commands to set Energy saver activation to 100%, so it is always active, and set brightness with Energy saver activated to 100% of brightness with Energy saver deactivated. These settings are only used when notebook is powered with battery. If it is plugged in, settings won't be used. Replace \<GUID> with GUID you obtained.

```powershell
powercfg /setdcvalueindex <GUID> SUB_ENERGYSAVER ESBATTTHRESHOLD 100
powercfg /setdcvalueindex <GUID> SUB_ENERGYSAVER ESBRIGHTNESS 100
```

Note: A value of 100 means that the brightness will remain the same as when Energy saver mode is turned off. However, the brightness may change between schemes because each scheme has its own brightness value stored.

#### Change Power saver Power scheme settings

This is possible from _Control Panel -> Power Options -> Power saver - Change scheme settings_. Here is possible to change display turn off time and computer sleep in time. More options are available in _Change advanced power settings_ dialog.

To change display turn off time and computer sleep in time is also possible to use cmd or powershell using commands below. `/setacvalueindex` is used for plugged in settings, `/setdcvalueindex` is used for on battery settings.

```powershell
powercfg /setacvalueindex <GUID> SUB_VIDEO VIDEOIDLE 600
powercfg /setdcvalueindex <GUID> SUB_VIDEO VIDEOIDLE 300
powercfg /setacvalueindex <GUID> SUB_SLEEP STANDBYIDLE 1200
powercfg /setdcvalueindex <GUID> SUB_SLEEP STANDBYIDLE 900
```

Note: Values are in seconds.

Now everything is working properly. In portable mode Power saver Power scheme and also Energy saver will be used. In home mode Balanced Power scheme will be used and Energy saver will be disabled.

### Set up Monocraft font (necessary, if you want to use it)

1. Download the `Monocraft.ttc` file from the latest relase from github: https://github.com/IdreesInc/Monocraft/releases.
2. Double-click the downloaded file and click **Install**.
3. Set the `portableVSCodeFont` or `homeVSCodeFont` variable to Monocraft.

## License

This project is licensed under the GNU General Public License v3.0 or later. See the [LICENSE](/LICENSE) file for details.
