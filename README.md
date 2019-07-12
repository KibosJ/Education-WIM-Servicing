# What the script does by default?

**If you choose not to run defaults, each step below will ask you if you wish to run it or not, type *y/yes* or *n/no*

- Asks for the name of the original WIM file (usually just install.wim)
- Asks for the name of the required WIM file
- Extracts the “Windows 10 Education” index from the original WIM file 
- Removes the original WIM file 
- Applies default app associations from AppAssociations.xml
- Disables Internet Explorer
- Enables .NET Framework 3.5 from net35 folder 
- Modifies default registry settings
  - Explorer items
  - Lock screen settings
  - Fast user switching settings
  - Taskbar/search settings
  - Cloud content settings
  - Content delivery manager settings
- Copies replacement user account pictures from *UserAccountPictures* to the WIM
- Copies folders/files from *Root_Folders* to root of WIM
- Commits the new image

# Registry edits

## Explorer Items

> "HKLM\_NTUSER\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v LaunchTo /d 1  /t REG_DWORD /f`

**Makes Explorer launch to *This PC* instead of *Quick access***

> "HKLM\_NTUSER\Software\Microsoft\Windows\CurrentVersion\Explorer\Serialize"  /v StartupDelayInMSec /d 0  /t REG_DWORD /f

**Disables the startup delay for applications**

>"HKLM\_SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer"  /v DisableEdgeDesktopShortcutCreation /d 1  /t REG_DWORD /f

**Disables the creation of the Edge desktop shortcut**

## Lock screen settings

> "HKLM\_SOFTWARE\Policies\Microsoft\Windows\Personalization"  /v NoLockscreen /d 1  /t REG_DWORD /f

**Disables the lock screen**

## Fast user switching settings

> "HKLM\_SOFTWARE\Policies\Microsoft\Windows\CurrentVersion\Policies\System"  /v HideFastUserSwitching /d 1  /t REG_DWORD /f

**Disables fast user switching options in the UI**

## Taskbar/Search settings
>"HKLM\_NTUSER\Software\Microsoft\Windows\CurrentVersion\Search"  /v BingSearchEnabled /d 0  /t REG_DWORD /f

**Disables Bing search**

>"HKLM\_NTUSER\Software\Microsoft\Windows\CurrentVersion\Search"  /v CanCortanaBeEnabled /d 0  /t REG_DWORD /f
>
>"HKLM\_NTUSER\Software\Microsoft\Windows\CurrentVersion\Search"  /v CortanaEnabled /d 0  /t REG_DWORD /f

**Disables Cortana**

>"HKLM\_NTUSER\Software\Microsoft\Windows\CurrentVersion\Search"  /v SearchboxTaskbarMode /d 1  /t REG_DWORD /f

**Sets the search button in the taskbar, a value of 0 will disable the search icon**

>"HKLM\_SOFTWARE\Policies\Microsoft\Windows\Windows Search"  /v AllowSearchToUseLocation /d 0  /t REG_DWORD /f

**Stops search using location services**

>"HKLM\_SOFTWARE\Policies\Microsoft\Windows\Windows Search"  /v ConnectedSearchUseWeb /d 0  /t REG_DWORD /f
>
>"HKLM\_SOFTWARE\Policies\Microsoft\Windows\Windows Search"  /v DisableWebSearch /d 1  /t REG_DWORD /f

**Disables searching the web from search**

>"HKLM\_NTUSER\Software\Policies\Microsoft\Windows\Explorer"  /v HidePeopleBar /d 1  /t REG_DWORD /f
>
>"HKLM\_NTUSER\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced\People"  /v PeopleBand /d 0  /t REG_DWORD /f

**Disables People features in the taskbar**

## Cloud content settings

>"HKLM\_SOFTWARE\Policies\Microsoft\Windows\CloudContent"  /v DisableWindowsConsumerFeatures /d 1  /t REG_DWORD /f

**Disables consumer features (Pre-loaded games, like Candy Crush, etc.)**

>"HKLM\_SOFTWARE\Policies\Microsoft\Windows\CloudContent"  /v DisableSoftLanding /d 1  /t REG_DWORD /f

**Disables *Tips, Tricks, and Suggestions* notifications**

## Content delivery manager settings

>"HKLM\_NTUSER\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v SystemPaneSuggestionsEnabled /d 0 /t REG_DWORD /f

**Disables suggestions on start**

>"HKLM\_NTUSER\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v OemPreInstalledAppsEnabled /d 0 /t REG_DWORD /f

**Disables OEM pre-installed applications**

>"HKLM\_NTUSER\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v PreInstalledAppsEnabled /d 0 /t REG_DWORD /f

**Disables pre-installed applications**

>"HKLM\_NTUSER\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v SoftLandingEnabled /d 0 /t REG_DWORD /f

**Disables *Tips, Tricks, and Suggestions* notifications**

