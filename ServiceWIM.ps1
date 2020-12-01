#Requires -Version 5.0
#Requires -RunAsAdministrator
#Requires -Module DISM
# Version 4.0

# Options
[CmdletBinding(DefaultParameterSetName = 'CustomRun')]
param (
	[Parameter(	Mandatory = $true, 
		ParameterSetName = 'DefaultRun', 
		ValueFromPipeline = $true )]
	[ValidateSet('Default', 'Custom', IgnoreCase)]
	[String]$runMode,

	[Parameter( Mandatory = $true, 
		ParameterSetName = 'CustomRun', 
		ValueFromPipeline = $true )]
	[ValidateSet('Education', 'Enterprise', 'Pro', IgnoreCase)]
	[String]$edition,

	[Parameter( Mandatory = $true, 
		ParameterSetName = 'CustomRun', 
		ValueFromPipeline = $true )]
	[String]$origWIM = "install.wim",

	[Parameter( Mandatory = $true, 
		ParameterSetName = 'CustomRun', 
		ValueFromPipeline = $true )]
	[String]$applyDefaultApps,

	[Parameter( Mandatory = $true, 
		ParameterSetName = 'CustomRun', 
		ValueFromPipeline = $true )]
	[String]$removeIE,

	[Parameter( Mandatory = $true, 
		ParameterSetName = 'CustomRun', 
		ValueFromPipeline = $true )]
	[String]$installNetF,

	[Parameter( Mandatory = $true, 
		ParameterSetName = 'CustomRun', 
		ValueFromPipeline = $true )]
	[String]$userAccPics,

	[Parameter( Mandatory = $true, 
		ParameterSetName = 'CustomRun', 
		ValueFromPipeline = $true )]
	[String]$copyRoot
)

# Variables
$mountDir = "$PSScriptRoot\Mount"
$dismExe = "${env:ProgramFiles(x86)}\Windows Kits\10\Assessment and Deployment Kit\Deployment Tools\amd64\DISM\dism.exe"
$wim = "10_servicing.wim"

# Check for Windows ADK
if (-not (Test-Path -Path $dismExe)) {
	Write-Host "`nADK not found, please install the latest version of the Windows 10 ADK" -ForegroundColor Red
	exit 1
}

# Check for .Net Framework files
if ($installNetF -like "Y*" -or $runMode -eq "Default") {
	if (-not (Test-Path -Path $PSScriptRoot\net35\*.cab)) {
		Write-Host "`n.Net Framework files are missing, please copy them from the ISO" -ForegroundColor Red
		exit 1
	}
}

# Get source information
if ($edition -eq "Education" -or $runMode -eq "Default") {
	$sourceIndex = Get-WindowsImage -ImagePath:$origWIM -Name:"Windows 10 Education" | Select-Object -ExpandProperty ImageIndex 
}
elseif ($edition -eq "Enterprise") {
	$sourceIndex = Get-WindowsImage -ImagePath:$origWIM -Name:"Windows 10 Enterprise" | Select-Object -ExpandProperty ImageIndex
}
elseif ($edition -eq "Pro") {
	$sourceIndex = Get-WindowsImage -ImagePath:$origWIM -Name:"Windows 10 Pro" | Select-Object -ExpandProperty ImageIndex
}
else {
	Write-Host "`nEdition unknown" -ForegroundColor Red
	exit 1
}

# Extract chosen index from WIM
Write-Host "`nExtracting Windows 10 $edition" -ForegroundColor Green
& $dismExe /Export-Image /SourceImageFile:$origWIM /SourceIndex:$sourceIndex /DestinationImageFile:$wim /Compress:Max /CheckIntegrity /quiet

# Mount WIM file
Write-Host "`nMounting WIM image" -ForegroundColor Green
if ((Test-Path $mountDir) -eq $False) {
	New-Item -Path $PSScriptRoot -Name "Mount" -ItemType "directory"
}
& $dismExe /Mount-Image /ImageFile:"$PSScriptRoot\$wim" /index:1 /MountDir:"$mountDir" /quiet

# Apply default app associations
if ($applyDefaultApps -like "Y*" -or $runMode -eq "Default") {
	Write-Host "`nSetting default app associations" -ForegroundColor Green
	& $dismExe /Image:"$mountDir" /Import-DefaultAppAssociations:"$PSScriptRoot\AppAssociations.xml" /quiet
}

# Disable Internet Explorer	
if ($removeIE -like "Y*" -or $runMode -eq "Default") {
	Write-Host "`nDisabling Internet Explorer" -ForegroundColor Green
	& $dismExe /Image:"$mountDir" /Disable-Feature /FeatureName:Internet-Explorer-Optional-amd64 /quiet
}

# Install .Net Framework 3.5
if ($installNetF -like "Y*" -or $runMode -eq "Default") {
	Write-Host "`nInstalling .Net Framework 3.5 Feature" -ForegroundColor Green
	& $dismExe /image:"$mountDir" /enable-feature /featurename:NetFx3 /All /LimitAccess /Source:"$PSScriptRoot\net35" /quiet	
}

# Customise registry
if ($customiseREG -like "Y*" -or $runMode -eq "Default") {
	Write-Host "`nImporting JSON settings" -ForegroundColor Green
	$registryconfig = Get-Content .\Registry.json | ConvertFrom-Json
	Write-Host "`nCustomising registry" -ForegroundColor Green
}
# Mount registry
REG LOAD "HKLM\_NTUSER" "$mountDir\Users\Default\NTUSER.DAT" | Out-Null
REG LOAD "HKLM\_SOFTWARE" "$mountDir\Windows\System32\config\SOFTWARE" | Out-Null

# Registry Customisation
if ($customiseREG -like "Y*" -or $runMode -eq "Default") {
	Write-Host "`nCustomising explorer settings according to the settings from JSON" -ForegroundColor Green
	# Explorer
	if ($registryconfig.Explorer[0].Set -eq "Yes") {
		& REG ADD "HKLM\_NTUSER\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v LaunchTo /d $registryconfig.Explorer[0].Value /t REG_DWORD /f
	}
	if ($registryconfig.Explorer[1].Set -eq "Yes") {
		& REG ADD "HKLM\_NTUSER\Software\Microsoft\Windows\CurrentVersion\Explorer\Serialize" /v StartupDelayInMSec /d $registryconfig.Explorer[1].Value /t REG_DWORD /f
	}
	if ($registryconfig.Explorer[2].Set -eq "Yes") {
		& REG ADD "HKLM\_SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer" /v DisableEdgeDesktopShortcutCreation /d $registryconfig.Explorer[2].Value /t REG_DWORD /f
	}
	# Lockscreen
	if ($registryconfig.Lockscreen[0].Set -eq "Yes") {
		& REG ADD "HKLM\_SOFTWARE\Policies\Microsoft\Windows\Personalization" /v NoLockscreen /d $registryconfig.Lockscreen[0].Value /t REG_DWORD /f
	}
	# Fast user switching
	if ($registryconfig.UserSwitching[0].Set -eq "Yes") {
		& REG ADD "HKLM\_SOFTWARE\Policies\Microsoft\Windows\CurrentVersion\Policies\System" /v HideFastUserSwitching /d $registryconfig.Explorer[2].Value /t REG_DWORD /f
	}
	# Search
	if ($registryconfig.Search[0].Set -eq "Yes") {
		& REG ADD "HKLM\_NTUSER\Software\Microsoft\Windows\CurrentVersion\Search" /v BingSearchEnabled /d $registryconfig.Search[0].Value /t REG_DWORD /f
	}
	if ($registryconfig.Search[1].Set -eq "Yes") {
		& REG ADD "HKLM\_NTUSER\Software\Microsoft\Windows\CurrentVersion\Search" /v CanCortanaBeEnabled /d $registryconfig.Search[1].Value /t REG_DWORD /f
	}
	if ($registryconfig.Search[2].Set -eq "Yes") {
		& REG ADD "HKLM\_NTUSER\Software\Microsoft\Windows\CurrentVersion\Search" /v CortanaEnabled /d $registryconfig.Search[2].Value /t REG_DWORD /f
	}
	if ($registryconfig.Search[3].Set -eq "Yes") {
		& REG ADD "HKLM\_NTUSER\Software\Microsoft\Windows\CurrentVersion\Search" /v SearchboxTaskbarMode /d $registryconfig.Search[3].Value /t REG_DWORD /f
	}
	if ($registryconfig.Search[4].Set -eq "Yes") {
		& REG ADD "HKLM\_SOFTWARE\Policies\Microsoft\Windows\Windows Search" /v AllowSearchToUseLocation /d $registryconfig.Search[4].Value /t REG_DWORD /f
	}
	if ($registryconfig.Search[5].Set -eq "Yes") {
		& REG ADD "HKLM\_SOFTWARE\Policies\Microsoft\Windows\Windows Search" /v ConnectedSearchUseWeb /d $registryconfig.Search[5].Value /t REG_DWORD /f
	}
	if ($registryconfig.Search[6].Set -eq "Yes") {
		& REG ADD "HKLM\_SOFTWARE\Policies\Microsoft\Windows\Windows Search" /v DisableWebSearch /d $registryconfig.Search[6].Value /t REG_DWORD /f
	}
	# Taskbar
	if ($registryconfig.Taskbar[0].Set -eq "Yes") {
		& REG ADD "HKLM\_NTUSER\Software\Policies\Microsoft\Windows\Explorer" /v HidePeopleBar /d $registryconfig.Taskbar[0].Value /t REG_DWORD /f
	}
	if ($registryconfig.Taskbar[1].Set -eq "Yes") {
		& REG ADD "HKLM\_NTUSER\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced\People" /v PeopleBand /d $registryconfig.Taskbar[1].Value /t REG_DWORD /f
	}
	# Cloud content
	if ($registryconfig.CloudContent[0].Set -eq "Yes") {
		& REG ADD "HKLM\_SOFTWARE\Policies\Microsoft\Windows\CloudContent" /v DisableWindowsConsumerFeatures /d $registryconfig.CloudContent[0].Value /t REG_DWORD /f
	}
	if ($registryconfig.CloudContent[1].Set -eq "Yes") {
		& REG ADD "HKLM\_SOFTWARE\Policies\Microsoft\Windows\CloudContent" /v DisableSoftLanding /d $registryconfig.CloudContent[1].Value /t REG_DWORD /f
	}
	# Content delivery
	if ($registryconfig.ContentDelivery[0].Set -eq "Yes") {
		& REG ADD "HKLM\_NTUSER\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v SystemPaneSuggestionsEnabled /d $registryconfig.ContentDelivery[0].Value /t REG_DWORD /f
	}
	if ($registryconfig.ContentDelivery[1].Set -eq "Yes") {
		& REG ADD "HKLM\_NTUSER\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v OemPreInstalledAppsEnabled /d $registryconfig.ContentDelivery[1].Value /t REG_DWORD /f
	}
	if ($registryconfig.ContentDelivery[2].Set -eq "Yes") {
		& REG ADD "HKLM\_NTUSER\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v PreInstalledAppsEnabled /d $registryconfig.ContentDelivery[2].Value /t REG_DWORD /f
	}
	if ($registryconfig.ContentDelivery[3].Set -eq "Yes") {
		& REG ADD "HKLM\_NTUSER\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v SoftLandingEnabled /d $registryconfig.ContentDelivery[3].Value /t REG_DWORD /f
	}
	# Unmount registry
	REG UNLOAD "HKLM\_NTUSER" | Out-Null
	REG UNLOAD "HKLM\_SOFTWARE" | Out-Null
}

# Copy user account images
if ($userAccPics -like "Y*" -or $runMode -eq "Default") {
	Write-Host "`nCopying replacement user account images" -ForegroundColor Green
	xcopy UserAccountPictures\*.* "$mountDir\ProgramData\Microsoft\User Account Pictures\" /EXCLUDE:CopyExclusions.txt /E /C /H /Y
}

# Copy folders to local disk
if ($copyRoot -like "Y*" -or $runMode -eq "Default") {
	Write-Host "`nCopying Folders" -ForegroundColor Green
	xcopy Root_Folders\*.* "$mountDir\" /EXCLUDE:CopyExclusions.txt /E /C /H /Y
}
# Commit image
Write-Host "`nCommiting WIM image, this may take some time" -ForegroundColor Green
& $dismExe /Unmount-Image /MountDir:"$mountDir" /Commit
& Rename-Item -Path ".\10_servicing.wim" -NewName "10_serviced.wim"

# The end
Write-Host "`nThe WIM image should now be commited with all chosen modifications, we've paused here so you can see any errors!" -ForegroundColor Green
Pause
