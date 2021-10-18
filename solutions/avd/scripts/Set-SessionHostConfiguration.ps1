[Cmdletbinding()]
Param(

    [parameter(Mandatory)]
    [string]
    $Environment,

    [parameter(Mandatory)]
    [string]
    $FSLogix,

    [parameter(Mandatory)]
    [string]
    $HostPoolName,

    [parameter(Mandatory)]
    [string]
    $ImageOffer,
    
    [parameter(Mandatory)]
    [string]
    $ImagePublisher,
    
    [parameter(Mandatory)]
    [string]
    $PooledHostPool,

    [parameter(Mandatory)]
    [string]
    $ScreenCaptureProtection,

    [parameter(Mandatory)]
    [string]
    $StorageAccountName

)


###############################
#  Recommended Settings
###############################

# Disable Automatic Updates: https://docs.microsoft.com/en-us/azure/virtual-desktop/set-up-customize-master-image#disable-automatic-updates
New-ItemProperty -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU' -Name 'NoAutoUpdate' -PropertyType 'DWord' -Value 1

# Enable Time Zone Redirection: https://docs.microsoft.com/en-us/azure/virtual-desktop/set-up-customize-master-image#set-up-time-zone-redirection
New-ItemProperty -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services' -Name 'fEnableTimeZoneRedirection' -PropertyType 'DWord' -Value 1

# Disable Storage Sense: https://docs.microsoft.com/en-us/azure/virtual-desktop/set-up-customize-master-image#disable-storage-sense
New-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\StorageSense\Parameters\StoragePolicy' -Name '01' -PropertyType 'DWord' -Value 0


###############################
#  Screen Capture Protection
###############################

if($ScreenCaptureProtection -eq 'true')
{
    # Enable Screen Capture Protection: https://docs.microsoft.com/en-us/azure/virtual-desktop/screen-capture-protection
    New-ItemProperty -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services' -Name 'fEnableScreenCaptureProtect' -PropertyType 'DWord' -Value 1
}


###############################
#  FSLogix Configurations
###############################

if($PooledHostPool -eq 'true' -and $FSLogix -eq 'true')
{
    $Suffix = switch($Environment)
    {
        AzureCloud {'.file.core.windows.net'}
        AzureUSGovernment {'.file.core.usgovcloudapi.net'}
    }
    $FileShare = '\\' + $StorageAccountName + $Suffix + '\' + $HostPoolName

    # Enables FSLogix profile containers
    New-ItemProperty -Path 'HKLM:\SOFTWARE\FSLogix\Profiles' -Name 'Enabled' -PropertyType 'DWord' -Value 1

    # Deletes a local profile if it exists and matches the profile being loaded from VHD
    New-ItemProperty -Path 'HKLM:\SOFTWARE\FSLogix\Profiles' -Name 'DeleteLocalProfileWhenVHDShouldApply' -PropertyType 'DWord' -Value 1

    # The folder created in the FSLogix fileshare will begin with the username instead of the SID
    New-ItemProperty -Path 'HKLM:\SOFTWARE\FSLogix\Profiles' -Name 'FlipFlopProfileDirectoryName' -PropertyType 'DWord' -Value 1

    # Loads FRXShell if there's a failure attaching to, or using an existing profile VHD(X)
    New-ItemProperty -Path 'HKLM:\SOFTWARE\FSLogix\Profiles' -Name 'PreventLoginWithFailure' -PropertyType 'DWord' -Value 1

    # Loads FRXShell if it's determined a temp profile has been created
    New-ItemProperty -Path 'HKLM:\SOFTWARE\FSLogix\Profiles' -Name 'PreventLoginWithTempProfile' -PropertyType 'DWord' -Value 1

    # List of file system locations to search for the user's profile VHD(X) file
    New-ItemProperty -Path 'HKLM:\SOFTWARE\FSLogix\Profiles' -Name 'VHDLocations' -PropertyType 'MultiString' -Value $FileShare

    # Defender Exclusions for FSLogix
    $Files = @(
        "%ProgramFiles%\FSLogix\Apps\frxdrv.sys",
        "%ProgramFiles%\FSLogix\Apps\frxdrvvt.sys",
        "%ProgramFiles%\FSLogix\Apps\frxccd.sys",
        "%TEMP%\*.VHD",
        "%TEMP%\*.VHDX",
        "%Windir%\TEMP\*.VHD",
        "%Windir%\TEMP\*.VHDX",
        "$FileShare\*.VHD",
        "$FileShare\*.VHDX"
    )

    $CloudCache = Get-ItemProperty -Path 'HKLM:\SOFTWARE\FSLogix\Profiles' -Name 'CCDLocations' -ErrorAction 'SilentlyContinue'
    if($CloudCache)
    { 
        $Files += @(
            "%ProgramData%\FSLogix\Cache\*.VHD"
            "%ProgramData%\FSLogix\Cache\*.VHDX"
            "%ProgramData%\FSLogix\Proxy\*.VHD"
            "%ProgramData%\FSLogix\Proxy\*.VHDX"
        )
    }

    foreach($File in $Files)
    {
        Add-MpPreference -ExclusionPath $File
    }

    $Processes = @(
        "%ProgramFiles%\FSLogix\Apps\frxccd.exe",
        "%ProgramFiles%\FSLogix\Apps\frxccds.exe",
        "%ProgramFiles%\FSLogix\Apps\frxsvc.exe"
    )

    foreach($Process in $Processes)
    {
        Add-MpPreference -ExclusionProcess $Process
    }
}

###############################
#  Windows Client Optimizations
###############################

if($ImagePublisher -eq 'MicrosoftWindowsDesktop' -and $ImageOffer -ne 'windows-7')
{
    # Download WVD Optimizer
    New-Item -Path C:\ -Name Optimize -ItemType Directory -ErrorAction SilentlyContinue
    $LocalPath = "C:\Optimize\"
    $WVDOptimizeURL = 'https://github.com/The-Virtual-Desktop-Team/Virtual-Desktop-Optimization-Tool/archive/refs/heads/main.zip'
    $WVDOptimizeInstaller = "Windows_10_VDI_Optimize-master.zip"
    Invoke-WebRequest `
        -Uri $WVDOptimizeURL `
        -OutFile "$Localpath$WVDOptimizeInstaller"

    # Prep for WVD Optimize
    Expand-Archive `
        -LiteralPath "C:\Optimize\Windows_10_VDI_Optimize-master.zip" `
        -DestinationPath "$Localpath" `
        -Force

    # Run WVD Optimize Script
    New-Item -Path C:\Optimize\ -Name install.log -ItemType File -Force
    Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Force
    & C:\Optimize\Virtual-Desktop-Optimization-Tool-main\Win10_VirtualDesktop_Optimize.ps1 -Restart -AcceptEULA
}