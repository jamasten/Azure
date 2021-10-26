[Cmdletbinding()]
Param(
    [parameter(Mandatory)]
    [string]
    $AmdVmSize, 

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
    $NvidiaVmSize,

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

$ErrorActionPreference = 'Stop'

function Write-Log
{
    param(
        [parameter(Mandatory)]
        [string]$Message,
        
        [parameter(Mandatory)]
        [string]$Type
    )
    $Path = 'C:\cse.log'
    if(!(Test-Path -Path C:\cse.log))
    {
        New-Item -Path C:\ -Name cse.log | Out-Null
    }
    $Timestamp = Get-Date -Format 'MM/dd/yyyy HH:mm:ss.ff'
    $Entry = '[' + $Timestamp + '] [' + $Type + '] ' + $Message
    $Entry | Out-File -FilePath $Path -Append
}

try 
{
    ###############################
    #  Recommended Settings
    ###############################

    # Disable Automatic Updates: https://docs.microsoft.com/en-us/azure/virtual-desktop/set-up-customize-master-image#disable-automatic-updates
    Set-ItemProperty -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU' -Name 'NoAutoUpdate' -Value 1
    Write-Log -Message 'Disabled Automatic Updates' -Type 'INFO'

    # Enable Time Zone Redirection: https://docs.microsoft.com/en-us/azure/virtual-desktop/set-up-customize-master-image#set-up-time-zone-redirection
    New-ItemProperty -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services' -Name 'fEnableTimeZoneRedirection' -PropertyType 'DWord' -Value 1
    Write-Log -Message 'Enabled Time Zone Redirection' -Type 'INFO'

    # Disable Storage Sense: https://docs.microsoft.com/en-us/azure/virtual-desktop/set-up-customize-master-image#disable-storage-sense
    Set-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\StorageSense\Parameters\StoragePolicy' -Name '01' -Value 0
    Write-Log -Message 'Disabled Storage Sense' -Type 'INFO'


    ###############################
    #  GPU Settings
    ###############################

    # These settings apply to any VM Size with a GPU
    if ($AmdVmSize -eq 'true' -or $NvidiaVmSize -eq 'true') 
    {
        # Configure GPU-accelerated app rendering: https://docs.microsoft.com/en-us/azure/virtual-desktop/configure-vm-gpu#configure-gpu-accelerated-app-rendering
        New-ItemProperty -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services' -Name 'bEnumerateHWBeforeSW' -PropertyType 'DWord' -Value 1
        Write-Log -Message 'Configured GPU-accelerated app rendering' -Type 'INFO'

        # Configure fullscreen video encoding: https://docs.microsoft.com/en-us/azure/virtual-desktop/configure-vm-gpu#configure-fullscreen-video-encoding
        New-ItemProperty -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services' -Name 'AVC444ModePreferred' -PropertyType 'DWord' -Value 1     
        Write-Log -Message 'Configured fullscreen video encoding' -Type 'INFO'
    }

    # This setting applies only to VM Size's with a Nvidia GPU
    if($NvidiaVmSize -eq 'true')
    {
        # Configure GPU-accelerated frame encoding: https://docs.microsoft.com/en-us/azure/virtual-desktop/configure-vm-gpu#configure-gpu-accelerated-frame-encoding
        New-ItemProperty -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services' -Name 'AVChardwareEncodePreferred' -PropertyType 'DWord' -Value 1
        Write-Log -Message 'Configured GPU-accelerated frame encoding' -Type 'INFO'
    }


    ###############################
    #  Screen Capture Protection
    ###############################

    if($ScreenCaptureProtection -eq 'true')
    {
        # Enable Screen Capture Protection: https://docs.microsoft.com/en-us/azure/virtual-desktop/screen-capture-protection
        New-ItemProperty -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services' -Name 'fEnableScreenCaptureProtect' -PropertyType 'DWord' -Value 1
        Write-Log -Message 'Enabled Screen Capture Protection' -Type 'INFO'
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
        Write-Log -Message "File Share: $FileShare" -Type 'INFO'

        # Enables FSLogix profile containers: https://docs.microsoft.com/en-us/fslogix/profile-container-configuration-reference#enabled
        New-ItemProperty -Path 'HKLM:\SOFTWARE\FSLogix\Profiles' -Name 'Enabled' -PropertyType 'DWord' -Value 1
        Write-Log -Message 'Enabled FSLogix profile containers' -Type 'INFO'

        # Deletes a local profile if it exists and matches the profile being loaded from VHD: https://docs.microsoft.com/en-us/fslogix/profile-container-configuration-reference#deletelocalprofilewhenvhdshouldapply
        New-ItemProperty -Path 'HKLM:\SOFTWARE\FSLogix\Profiles' -Name 'DeleteLocalProfileWhenVHDShouldApply' -PropertyType 'DWord' -Value 1
        Write-Log -Message 'Enabled FSLogix profile deletion for local profiles' -Type 'INFO'

        # The folder created in the FSLogix fileshare will begin with the username instead of the SID: https://docs.microsoft.com/en-us/fslogix/profile-container-configuration-reference#flipflopprofiledirectoryname
        New-ItemProperty -Path 'HKLM:\SOFTWARE\FSLogix\Profiles' -Name 'FlipFlopProfileDirectoryName' -PropertyType 'DWord' -Value 1
        Write-Log -Message 'Enabled FSLogix folder name swap for SID and username' -Type 'INFO'

        # Loads FRXShell if there's a failure attaching to, or using an existing profile VHD(X): https://docs.microsoft.com/en-us/fslogix/profile-container-configuration-reference#preventloginwithfailure
        New-ItemProperty -Path 'HKLM:\SOFTWARE\FSLogix\Profiles' -Name 'PreventLoginWithFailure' -PropertyType 'DWord' -Value 1
        Write-Log -Message 'Enabled FSLogix failure message for existing profile' -Type 'INFO'

        # Loads FRXShell if it's determined a temp profile has been created: https://docs.microsoft.com/en-us/fslogix/profile-container-configuration-reference#preventloginwithtempprofile
        New-ItemProperty -Path 'HKLM:\SOFTWARE\FSLogix\Profiles' -Name 'PreventLoginWithTempProfile' -PropertyType 'DWord' -Value 1
        Write-Log -Message 'Enabled FSLogix failure for a temp profile' -Type 'INFO'

        # List of file system locations to search for the user's profile VHD(X) file: https://docs.microsoft.com/en-us/fslogix/profile-container-configuration-reference#vhdlocations
        New-ItemProperty -Path 'HKLM:\SOFTWARE\FSLogix\Profiles' -Name 'VHDLocations' -PropertyType 'MultiString' -Value $FileShare
        Write-Log -Message 'Enabled FSLogix fileshare location' -Type 'INFO'

        # Defender Exclusions for FSLogix: https://docs.microsoft.com/en-us/azure/architecture/example-scenario/wvd/windows-virtual-desktop-fslogix#antivirus-exclusions
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
        Write-Log -Message 'Enabled Defender exlusions for FSLogix paths' -Type 'INFO'

        $Processes = @(
            "%ProgramFiles%\FSLogix\Apps\frxccd.exe",
            "%ProgramFiles%\FSLogix\Apps\frxccds.exe",
            "%ProgramFiles%\FSLogix\Apps\frxsvc.exe"
        )

        foreach($Process in $Processes)
        {
            Add-MpPreference -ExclusionProcess $Process
        }
        Write-Log -Message 'Enabled Defender exlusions for FSLogix processes' -Type 'INFO'
    }

    ######################################
    #  Virtual Desktop Optimization Tool: https://github.com/The-Virtual-Desktop-Team/Virtual-Desktop-Optimization-Tool
    ######################################

    if($ImagePublisher -eq 'MicrosoftWindowsDesktop' -and $ImageOffer -ne 'windows-7')
    {
        # Download VDOT
        New-Item -Path C:\ -Name Optimize -ItemType Directory -ErrorAction SilentlyContinue
        $LocalPath = "C:\Optimize\"
        $WVDOptimizeURL = 'https://github.com/The-Virtual-Desktop-Team/Virtual-Desktop-Optimization-Tool/archive/refs/heads/main.zip'
        $WVDOptimizeInstaller = "Windows_10_VDI_Optimize-master.zip"
        Invoke-WebRequest `
            -Uri $WVDOptimizeURL `
            -OutFile "$Localpath$WVDOptimizeInstaller"

        # Extract VDOT from ZIP archive
        Expand-Archive `
            -LiteralPath "C:\Optimize\Windows_10_VDI_Optimize-master.zip" `
            -DestinationPath "$Localpath" `
            -Force

        # Run VDOT
        New-Item -Path C:\Optimize\ -Name install.log -ItemType File -Force
        Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Force
        & C:\Optimize\Virtual-Desktop-Optimization-Tool-main\Win10_VirtualDesktop_Optimize.ps1 -Restart -AcceptEULA
        Write-Log -Message 'Optimized the operating system using the VDOT' -Type 'INFO'
    }
}
catch 
{
    Write-Log -Message $_ -Type 'ERROR'
}