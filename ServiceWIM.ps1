#Requires -Version 5.0
#Requires -RunAsAdministrator
#Requires -Modules Dism
# Version 3.0b

# Variables
	$MountDir = "$PSScriptRoot\Mount"
	$Dismexe = "${env:ProgramFiles(x86)}\Windows Kits\10\Assessment and Deployment Kit\Deployment Tools\amd64\DISM\dism.exe"
	$RunDefault = Read-Host 'Would you like to run with defaults?'

# Check for Windows ADK
	$ADKcheck = Test-Path $Dismexe
	if ($ADKcheck -eq $False) {
	Write-Output -InputObject "`nCannot find ADK DISM, exiting"
	exit	
	}
	
# Get vanilla WIM name
	$origWIM = Read-Host 'What is the name of the current WIM file, including extension?'
	
# Get name of the required WIM name
	$wim = Read-Host 'What is the name of the required WIM file, including the extension?'

# Get source information
	$sourceIndex = Get-WindowsImage -ImagePath:$origWIM -Name:"Windows 10 Education" | Select-Object -ExpandProperty ImageIndex
	$sourceVersion = Get-WindowsImage -ImagePath:$origWIM -Name:"Windows 10 Education" | Select-Object -ExpandProperty Version

# Extract Education index from WIM
	Write-Output -InputObject "`nExtracting Windows 10 Education"
	& $Dismexe /Export-Image /SourceImageFile:$origWIM /SourceIndex:$sourceIndex /DestinationImageFile:$wim /Compress:Max /CheckIntegrity /quiet

# Delete the old WIM
	if ($RunDefault -notlike "Y*") {
		$deleteoldwim = Read-Host 'Would you like to remove the old WIM file?'
	}
	if ($deleteoldwim -like "Y*" -or $RunDefault -like "Y*") {
		Write-Output -InputObject "`nDeleting original WIM file"
		Set-ItemProperty -Path "$PSScriptRoot\$origWIM" -Name IsReadOnly -Value $false | Out-Null
		Remove-Item $origWIM
	}
	
# Mount WIM file
	Write-Output -InputObject "`nMounting WIM image"
	if ((Test-Path $MountDir) -eq $False) {
		New-Item -Path $PSScriptRoot -name "Mount" -ItemType "directory"
	}
	& $Dismexe /Mount-Image /ImageFile:"$PSScriptRoot\$wim" /index:1 /MountDir:"$MountDir" /quiet

# Apply default app associations
	if ($RunDefault -notlike "Y*") {
		$ApplyDefaultApps = Read-Host 'Would you like to apply default app associations?'
	}
	if ($ApplyDefaultApps -like "Y*" -or $RunDefault -like "Y*") {
		Write-Output -InputObject "`nSetting default app associations"
		& $Dismexe /Image:"$MountDir" /Import-DefaultAppAssociations:"$PSScriptRoot\AppAssociations.xml" /quiet
	}
	
# Disable features	
	if ($RunDefault -notlike "Y*") {
		$RemoveIE = Read-Host 'Would you like to remove Internet Explorer?'
	}
	if ($RemoveIE -like "Y*" -or $RunDefault -like "Y*") {
		Write-Output -InputObject "`nDisabling Internet Explorer"
		& $Dismexe /Image:"$MountDir" /Disable-Feature /FeatureName:Internet-Explorer-Optional-amd64 /quiet
	}

# Install features
	if ($RunDefault -notlike "Y*") {
		$InstallNetF = Read-Host 'Would you like to install .Net Framework 3.5?'
	}
	if ($InstallNetF -like "Y*" -or $RunDefault -like "Y*") {
		Write-Output -InputObject "`nInstalling .Net Framework 3.5 Feature"
		if ($sourceVersion -like "10.0.18362*") {
			& $Dismexe /image:"$MountDir" /enable-feature /featurename:NetFx3 /All /LimitAccess /Source:"$PSScriptRoot\net35" /quiet	
		}

		elseif ($sourceVersion -like "10.0.17763*") {
			& $Dismexe /image:"$MountDir" /enable-feature /featurename:NetFx3 /All /LimitAccess /Source:"$PSScriptRoot\net35_1809" /quiet	
		}
	}

# Customise registry
	if ($RunDefault -notlike "Y*") {
		$CustomiseREG = Read-Host 'Would you like to customise the registry?'
	}
	if ($CustomiseREG -like "Y*" -or $RunDefault -like "Y*") {
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
	}

# Copy folders to local disk
	if ($RunDefault -notlike "Y*") {
		$CopyRoot = Read-Host 'Would you like to copy folder from "Root_Folders" to the root of your WIM??'
	}
	if ($CopyRoot -like "Y*" -or $RunDefault -like "Y*") {
		Write-Output -InputObject "`nCopying Folders"
		xcopy Root_Folders\*.* "$MountDir\" /EXCLUDE:CopyExclusions.txt /E /C /H
	}
# Commit image
	Write-Output -InputObject "`nCommiting WIM image, this may take some time"
	& $Dismexe /Unmount-Image /MountDir:"$MountDir" /Commit

# The end
	Write-Output -InputObject "`nThe WIM image should now be commited with all chosen modifications, we've paused here so you can see any errors!"
	pause
