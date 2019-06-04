# Requires -Version 5.0
# Requires -RunAsAdministrator
# Requires -Modules Dism
# Version 2.0

# Variables
	$ScriptDir = "D:\Sources\OperatingSystems\ImageEdit"
	$MountDir = "$ScriptDir\Mount"
	
# Get vanilla WIM name
	$origWIM = Read-Host 'What is the name of the current WIM file, including extension?'
	
# Get name of the required WIM name
	$wim = Read-Host 'What is the name of the required WIM file, including the extension?'

# Get source
	$sourceIndex = Get-WindowsImage -ImagePath:$origWIM -Name:"Windows 10 Education" | Select-Object -ExpandProperty ImageIndex

# Extract Education index from WIM
	Write-Output -InputObject "`nExtracting Windows 10 Education"
	Dism /Export-Image /SourceImageFile:$origWIM /SourceIndex:$sourceIndex /DestinationImageFile:$wim /Compress:Max /CheckIntegrity /quiet

# Delete the old WIM
	Write-Output -InputObject "`nDeleting original WIM file"
	Remove-Item $origWIM

# Mount WIM file
	Write-Output -InputObject "`nMounting WIM image"
	Dism /Mount-Image /ImageFile:"$ScriptDir\$wim" /index:1 /MountDir:"$MountDir" /quiet

# Apply default app associations
	Write-Output -InputObject "`nSetting default App associations"
	Dism /Image:"$MountDir" /Import-DefaultAppAssociations:"$ScriptDir\AppAssociations.xml" /quiet
	
# Disable features	
	Write-Output -InputObject "`nDisabling Internet Explorer"
	Dism /Image:"$MountDir" /Disable-Feature /FeatureName:Internet-Explorer-Optional-amd64 /quiet

# Install features
	Write-Output -InputObject "`nInstalling .Net Framework 3.5 Feature"
	dism /image:"$MountDir" /enable-feature /featurename:NetFx3 /All /LimitAccess /Source:"$ScriptDir\net35" /quiet

# Customise registry
	Write-Output -InputObject "`nCustomising registry"

	# Mount registry
		REG LOAD "HKLM\_NTUSER" "$MountDir\Users\Default\NTUSER.DAT" | Out-Null
		REG LOAD "HKLM\_SOFTWARE" "$MountDir\Windows\System32\config\SOFTWARE" | Out-Null

	# Explorer items
		Write-Output -InputObject "`nCustomising explorer settings"
		& REG ADD "HKLM\_NTUSER\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v LaunchTo /d 1 /t REG_DWORD /f
		& REG ADD "HKLM\_NTUSER\Software\Microsoft\Windows\CurrentVersion\Explorer\Serialize" /v StartupDelayInMSec /d 0 /t REG_DWORD /f
		& REG ADD "HKLM\_SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer" /v DisableEdgeDesktopShortcutCreation /d 1 /t REG_DWORD /f

    # Disable lockscreen
		Write-Output -InputObject "`nDisabling lockscreen"
		& REG ADD "HKLM\_SOFTWARE\Policies\Microsoft\Windows\Personalization" /v NoLockscreen /d 1 /t REG_DWORD /f
		
	# Disable fast user switching
		Write-Output -InputObject "`nDisabling fast user switching"
		& REG ADD "HKLM\_SOFTWARE\Policies\Microsoft\Windows\CurrentVersion\Policies\System" /v HideFastUserSwitching /d 1 /t REG_DWORD /f

    # Taskbar/Search settings
		Write-Output -InputObject "`nCustomising taskbar/search settings"
		& REG ADD "HKLM\_NTUSER\Software\Microsoft\Windows\CurrentVersion\Search" /v BingSearchEnabled /d 0 /t REG_DWORD /f
		& REG ADD "HKLM\_NTUSER\Software\Microsoft\Windows\CurrentVersion\Search" /v CanCortanaBeEnabled /d 0 /t REG_DWORD /f
		& REG ADD "HKLM\_NTUSER\Software\Microsoft\Windows\CurrentVersion\Search" /v CortanaEnabled /d 0 /t REG_DWORD /f
		& REG ADD "HKLM\_NTUSER\Software\Microsoft\Windows\CurrentVersion\Search" /v SearchboxTaskbarMode /d 1 /t REG_DWORD /f
		& REG ADD "HKLM\_SOFTWARE\Policies\Microsoft\Windows\Windows Search" /v AllowSearchToUseLocation /d 0 /t REG_DWORD /f
		& REG ADD "HKLM\_SOFTWARE\Policies\Microsoft\Windows\Windows Search" /v ConnectedSearchUseWeb /d 0 /t REG_DWORD /f
		& REG ADD "HKLM\_SOFTWARE\Policies\Microsoft\Windows\Windows Search" /v DisableWebSearch /d 1 /t REG_DWORD /f
		& REG ADD "HKLM\_NTUSER\Software\Policies\Microsoft\Windows\Explorer" /v HidePeopleBar /d 1 /t REG_DWORD /f
		& REG ADD "HKLM\_NTUSER\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced\People" /v PeopleBand /d 0 /t REG_DWORD /f

    # Cloud content settings
		Write-Output -InputObject "`nCustomising cloud content settings"
		& REG ADD "HKLM\_SOFTWARE\Policies\Microsoft\Windows\CloudContent" /v DisableWindowsConsumerFeatures /d 1 /t REG_DWORD /f
		& REG ADD "HKLM\_SOFTWARE\Policies\Microsoft\Windows\CloudContent" /v DisableSoftLanding /d 1 /t REG_DWORD /f

    # Content delivery manager settings
		Write-Output -InputObject "`nCustomising content delivery manager settings"
		& REG ADD "HKLM\_NTUSER\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v SystemPaneSuggestionsEnabled /d 0 /t REG_DWORD /f
		& REG ADD "HKLM\_NTUSER\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v OemPreInstalledAppsEnabled /d 0 /t REG_DWORD /f
		& REG ADD "HKLM\_NTUSER\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v PreInstalledAppsEnabled /d 0 /t REG_DWORD /f
		& REG ADD "HKLM\_NTUSER\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v SoftLandingEnabled /d 0 /t REG_DWORD /f
		
# Unmount registry
	REG UNLOAD "HKLM\_NTUSER" | Out-Null
	REG UNLOAD "HKLM\_SOFTWARE" | Out-Null

# Copy folders to local disk
	Write-Output -InputObject "`nCopying Folders"
	xcopy Root_Folders\*.* "$MountDir\" /E /C /H

# Commit image
	Write-Output -InputObject "`nCommiting WIM image, this may take some time"
	dism /Unmount-Image /MountDir:"$MountDir" /Commit