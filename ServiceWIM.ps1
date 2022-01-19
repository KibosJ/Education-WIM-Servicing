#Requires -Version 5.0
#Requires -RunAsAdministrator
# Version 3.1

# Variables
$MountDir = "$PSScriptRoot\Mount"
$Dismexe = "${env:ProgramFiles(x86)}\Windows Kits\10\Assessment and Deployment Kit\Deployment Tools\amd64\DISM\dism.exe"
$RunDefault = Read-Host 'Would you like to run with defaults?'

# Check for Windows ADK
$ADKcheck = Test-Path $Dismexe
if ($ADKcheck -eq $False) {
Write-Host "`nCannot find ADK DISM, exiting" -ForegroundColor Red 
exit	
}

# Get vanilla WIM name
Write-Host "`n"
$origWIM = Read-Host 'What is the name of the current WIM file, including extension?'

# Get name of the required WIM name
Write-Host "`n"
$wim = Read-Host 'What is the name of the required WIM file, including the extension?'

# Get source information
$sourceIndex = Get-WindowsImage -ImagePath:$origWIM -Name:"Windows 10 Education" | Select-Object -ExpandProperty ImageIndex 

# Extract Education index from WIM
Write-Host "`nExtracting Windows 10 Education" -ForegroundColor Green
& $Dismexe /Export-Image /SourceImageFile:$origWIM /SourceIndex:$sourceIndex /DestinationImageFile:$wim /Compress:Max /CheckIntegrity /quiet

# Delete the old WIM
if ($RunDefault -notlike "Y*") {
	Write-Host "`n"
	$deleteoldwim = Read-Host 'Would you like to remove the old WIM file?'
}
if ($deleteoldwim -like "Y*" -or $RunDefault -like "Y*") {
	Write-Host "`nDeleting original WIM file" -ForegroundColor Green
	Set-ItemProperty -Path "$PSScriptRoot\$origWIM" -Name IsReadOnly -Value $false | Out-Null
	Remove-Item $origWIM
}

# Mount WIM file
Write-Host "`nMounting WIM image" -ForegroundColor Green
if ((Test-Path $MountDir) -eq $False) {
	New-Item -Path $PSScriptRoot -name "Mount" -ItemType "directory"
}
& $Dismexe /Mount-Image /ImageFile:"$PSScriptRoot\$wim" /index:1 /MountDir:"$MountDir" /quiet

# Apply default app associations
if ($RunDefault -notlike "Y*") {
	Write-Host "`n"
	$ApplyDefaultApps = Read-Host 'Would you like to apply default app associations?'
}
if ($ApplyDefaultApps -like "Y*" -or $RunDefault -like "Y*") {
	Write-Host "`nSetting default app associations" -ForegroundColor Green
	& $Dismexe /Image:"$MountDir" /Import-DefaultAppAssociations:"$PSScriptRoot\AppAssociations.xml" /quiet
}

# Disable features	
if ($RunDefault -notlike "Y*") {
	Write-Host "`n"
	$RemoveIE = Read-Host 'Would you like to remove Internet Explorer?'
}
if ($RemoveIE -like "Y*" -or $RunDefault -like "Y*") {
	Write-Host "`nDisabling Internet Explorer" -ForegroundColor Green
	& $Dismexe /Image:"$MountDir" /Disable-Feature /FeatureName:Internet-Explorer-Optional-amd64 /quiet
}

# Install features
if ($RunDefault -notlike "Y*") {
	Write-Host "`n"
	$InstallNetF = Read-Host 'Would you like to install .Net Framework 3.5?'
}
if ($InstallNetF -like "Y*" -or $RunDefault -like "Y*") {
	Write-Host "`nInstalling .Net Framework 3.5 Feature" -ForegroundColor Green
		& $Dismexe /image:"$MountDir" /enable-feature /featurename:NetFx3 /All /LimitAccess /Source:"$PSScriptRoot\net35" /quiet	
}

# Customise registry
if ($RunDefault -notlike "Y*") {
	Write-Host "`n"
	$CustomiseREG = Read-Host 'Would you like to customise the registry?'
	}

if ($CustomiseREG -like "Y*" -or $RunDefault -like "Y*") {
	Write-Host "`nCustomising registry" -ForegroundColor Green

# Mount registry
	REG LOAD "HKLM\_NTUSER" "$MountDir\Users\Default\NTUSER.DAT" | Out-Null
	REG LOAD "HKLM\_SOFTWARE" "$MountDir\Windows\System32\config\SOFTWARE" | Out-Null

# Explorer items
	if ($RunDefault -notlike "Y*") {
	Write-Host "`n"
	$ExplorerREG = Read-Host 'Modify Explorer items?'
	}
	if ($ExplorerREG -like "Y*" -or $RunDefault -like "Y*") {
		Write-Host "`nCustomising explorer settings" -ForegroundColor Green
		& REG ADD "HKLM\_NTUSER\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v LaunchTo /d 1 /t REG_DWORD /f
		& REG ADD "HKLM\_NTUSER\Software\Microsoft\Windows\CurrentVersion\Explorer\Serialize" /v StartupDelayInMSec /d 0 /t REG_DWORD /f
		& REG ADD "HKLM\_SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer" /v DisableEdgeDesktopShortcutCreation /d 1 /t REG_DWORD /f
	}
# Disable lockscreen
	if ($RunDefault -notlike "Y*") {
	Write-Host "`n"
	$LockscreenREG = Read-Host 'Disable the lockscreen?'
	}
	if ($LockscreenREG -like "Y*" -or $RunDefault -like "Y*") {
		Write-Host "`nDisabling lockscreen" -ForegroundColor Green
		& REG ADD "HKLM\_SOFTWARE\Policies\Microsoft\Windows\Personalization" /v NoLockscreen /d 1 /t REG_DWORD /f
	}
# Disable fast user switching
	if ($RunDefault -notlike "Y*") {
	Write-Host "`n"
	$FastUserREG = Read-Host 'Disable fast user switching?'
	}
	if ($FastUserREG -like "Y*" -or $RunDefault -like "Y*") {
		Write-Host "`nDisabling fast user switching" -ForegroundColor Green
		& REG ADD "HKLM\_SOFTWARE\Policies\Microsoft\Windows\CurrentVersion\Policies\System" /v HideFastUserSwitching /d 1 /t REG_DWORD /f
	}
# Taskbar/Search settings
	if ($RunDefault -notlike "Y*") {
	Write-Host "`n"
	$TaskbarSearchREG = Read-Host 'Modify taskbar/search settings?'
	}
	if ($TaskbarSearchREG -like "Y*" -or $RunDefault -like "Y*") {
		Write-Host "`nCustomising taskbar/search settings" -ForegroundColor Green
		& REG ADD "HKLM\_NTUSER\Software\Microsoft\Windows\CurrentVersion\Search" /v BingSearchEnabled /d 0 /t REG_DWORD /f
		& REG ADD "HKLM\_NTUSER\Software\Microsoft\Windows\CurrentVersion\Search" /v CanCortanaBeEnabled /d 0 /t REG_DWORD /f
		& REG ADD "HKLM\_NTUSER\Software\Microsoft\Windows\CurrentVersion\Search" /v CortanaEnabled /d 0 /t REG_DWORD /f
		& REG ADD "HKLM\_NTUSER\Software\Microsoft\Windows\CurrentVersion\Search" /v SearchboxTaskbarMode /d 1 /t REG_DWORD /f
		& REG ADD "HKLM\_SOFTWARE\Policies\Microsoft\Windows\Windows Search" /v AllowSearchToUseLocation /d 0 /t REG_DWORD /f
		& REG ADD "HKLM\_SOFTWARE\Policies\Microsoft\Windows\Windows Search" /v ConnectedSearchUseWeb /d 0 /t REG_DWORD /f
		& REG ADD "HKLM\_SOFTWARE\Policies\Microsoft\Windows\Windows Search" /v DisableWebSearch /d 1 /t REG_DWORD /f
		& REG ADD "HKLM\_NTUSER\Software\Policies\Microsoft\Windows\Explorer" /v HidePeopleBar /d 1 /t REG_DWORD /f
		& REG ADD "HKLM\_NTUSER\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced\People" /v PeopleBand /d 0 /t REG_DWORD /f
	}
# Cloud content settings
	if ($RunDefault -notlike "Y*") {
	Write-Host "`n"
	$CloudContentREG = Read-Host 'Modify cloud content settings?'
	}
	if ($CloudContentREG -like "Y*" -or $RunDefault -like "Y*") {
		Write-Host "`nCustomising cloud content settings" -ForegroundColor Green
		& REG ADD "HKLM\_SOFTWARE\Policies\Microsoft\Windows\CloudContent" /v DisableWindowsConsumerFeatures /d 1 /t REG_DWORD /f
		& REG ADD "HKLM\_SOFTWARE\Policies\Microsoft\Windows\CloudContent" /v DisableSoftLanding /d 1 /t REG_DWORD /f
	}
# Content delivery manager settings
	if ($RunDefault -notlike "Y*") {
	Write-Host "`n"
	$ContentDeliveryREG = Read-Host 'Modify content delivery manager settings?'
	}
	if ($ContentDeliveryREG -like "Y*" -or $RunDefault -like "Y*") {
		Write-Host "`nCustomising content delivery manager settings" -ForegroundColor Green
		& REG ADD "HKLM\_NTUSER\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v SystemPaneSuggestionsEnabled /d 0 /t REG_DWORD /f
		& REG ADD "HKLM\_NTUSER\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v OemPreInstalledAppsEnabled /d 0 /t REG_DWORD /f
		& REG ADD "HKLM\_NTUSER\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v PreInstalledAppsEnabled /d 0 /t REG_DWORD /f
		& REG ADD "HKLM\_NTUSER\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v SoftLandingEnabled /d 0 /t REG_DWORD /f
	}
	
# Unmount registry
REG UNLOAD "HKLM\_NTUSER" | Out-Null
REG UNLOAD "HKLM\_SOFTWARE" | Out-Null
}

# Copy user account images
if ($RunDefault -notlike "Y*") {
	Write-Host "`n"
	$UserAccPics = Read-Host 'Would you like to replace the default user account images?'
}
if ($UserAccPics -like "Y*" -or $RunDefault -like "Y*") {
	Write-Host "`nCopying replacement user account images" -ForegroundColor Green
	xcopy UserAccountPictures\*.* "$MountDir\ProgramData\Microsoft\User Account Pictures\" /EXCLUDE:CopyExclusions.txt /E /C /H /Y
}

# Remove provisioned apps
if ($RunDefault -notlike "Y*") {
	Write-Host "`n"
	$RemoveProvApps = Read-Host 'Would you like to remove provisioned apps listed in RemoveApps.xml?'
}
if ($RemoveProvApps -like "Y*" -and !(Test-Path -Path "$PSScriptRoot\RemoveApps.xml")) {
	Write-Host "`nThere isn't a RemoveApps.xml file" -ForegroundColor Red
}
if ($RemoveProvApps -like "Y*" -or $RunDefault -like "Y*" -and (Test-Path -Path "$PSScriptRoot\RemoveApps.xml")) {
	Write-Host "`nRemoving provisioned apps from RemoveApps.xml" -ForegroundColor Green
	$Removeapps = Get-Content "$PSScriptRoot\RemoveApps.xml"
	$provisionedApps = Get-AppxProvisionedPackage -Path $MountDir
	$appstr = @()
	foreach ($i in $Removeapps) { 
		$appstr += $provisionedApps | Where-Object { $_.DisplayName -eq $i } 
	}
	foreach ($app in $appstr.PackageName) { 
		Remove-AppxProvisionedPackage -Path $MountDir -PackageName $app -LogLevel 1
	}
}

# Copy folders to local disk
if ($RunDefault -notlike "Y*") {
	Write-Host "`n"
	$CopyRoot = Read-Host 'Would you like to copy files/folders from "Root_Folders" to the root of your WIM?'
}
if ($CopyRoot -like "Y*" -or $RunDefault -like "Y*") {
	Write-Host "`nCopying Folders" -ForegroundColor Green
	xcopy Root_Folders\*.* "$MountDir\" /EXCLUDE:CopyExclusions.txt /E /C /H /Y
}
# Commit image
Write-Host "`nCommiting WIM image, this may take some time" -ForegroundColor Green
& $Dismexe /Unmount-Image /MountDir:$MountDir /Commit

# The end
Write-Host "`nThe WIM image should now be commited with all chosen modifications, we've paused here so you can see any errors!" -ForegroundColor Green
pause
