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
    $HostPoolRegistrationToken,    

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
    $Path = 'C:\cse.txt'
    if(!(Test-Path -Path $Path))
    {
        New-Item -Path 'C:\' -Name 'cse.txt' | Out-Null
    }
    $Timestamp = Get-Date -Format 'MM/dd/yyyy HH:mm:ss.ff'
    $Entry = '[' + $Timestamp + '] [' + $Type + '] ' + $Message
    $Entry | Out-File -FilePath $Path -Append
}

Write-Log -Message "AmdVmSize: $AmdVmSize" -Type 'INFO'
Write-Log -Message "Environment: $Environment" -Type 'INFO'
Write-Log -Message "FSLogix: $FSLogix" -Type 'INFO'
Write-Log -Message "HostPoolName: $HostPoolName" -Type 'INFO'
Write-Log -Message "ImageOffer: $ImageOffer" -Type 'INFO'
Write-Log -Message "ImagePublisher: $ImagePublisher" -Type 'INFO'
Write-Log -Message "NvidiaVmSize: $NvidiaVmSize" -Type 'INFO'
Write-Log -Message "PooledHostPool: $PooledHostPool" -Type 'INFO'
Write-Log -Message "ScreenCaptureProtection: $ScreenCaptureProtection" -Type 'INFO'
Write-Log -Message "AmdVmSize: $AmdVmSize" -Type 'INFO'
Write-Log -Message "StorageAccountName: $StorageAccountName" -Type 'INFO'


###############################
#  Recommended AVD Settings
###############################
$Settings = @(

    # Disable Automatic Updates: https://docs.microsoft.com/en-us/azure/virtual-desktop/set-up-customize-master-image#disable-automatic-updates
    [PSCustomObject]@{
        Name = 'NoAutoUpdate'
        Path = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU'
        PropertyType = 'DWord'
        Value = 1
    },

    # Enable Time Zone Redirection: https://docs.microsoft.com/en-us/azure/virtual-desktop/set-up-customize-master-image#set-up-time-zone-redirection
    [PSCustomObject]@{
        Name = 'fEnableTimeZoneRedirection'
        Path = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services'
        PropertyType = 'DWord'
        Value = 1
    }
)


###############################
#  GPU Settings
###############################
# This setting applies to the VM Size's recommended for AVD with a GPU
if ($AmdVmSize -eq 'true' -or $NvidiaVmSize -eq 'true') 
{
    $Settings += @(

        # Configure GPU-accelerated app rendering: https://docs.microsoft.com/en-us/azure/virtual-desktop/configure-vm-gpu#configure-gpu-accelerated-app-rendering
        [PSCustomObject]@{
            Name = 'bEnumerateHWBeforeSW'
            Path = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services'
            PropertyType = 'DWord'
            Value = 1
        },

        # Configure fullscreen video encoding: https://docs.microsoft.com/en-us/azure/virtual-desktop/configure-vm-gpu#configure-fullscreen-video-encoding
        [PSCustomObject]@{
            Name = 'AVC444ModePreferred'
            Path = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services'
            PropertyType = 'DWord'
            Value = 1
        }
    )
}

# This setting applies only to VM Size's recommended for AVD with a Nvidia GPU
if($NvidiaVmSize -eq 'true')
{
    $Settings += @(

        # Configure GPU-accelerated frame encoding: https://docs.microsoft.com/en-us/azure/virtual-desktop/configure-vm-gpu#configure-gpu-accelerated-frame-encoding
        [PSCustomObject]@{
            Name = 'AVChardwareEncodePreferred'
            Path = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services'
            PropertyType = 'DWord'
            Value = 1
        }
    )
}


###############################
#  Screen Capture Protection
###############################
if($ScreenCaptureProtection -eq 'true')
{
    $Settings += @(

        # Enable Screen Capture Protection: https://docs.microsoft.com/en-us/azure/virtual-desktop/screen-capture-protection
        [PSCustomObject]@{
            Name = 'fEnableScreenCaptureProtect'
            Path = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services'
            PropertyType = 'DWord'
            Value = 1
        }
    )
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

    $Settings += @(

        # Enables FSLogix profile containers: https://docs.microsoft.com/en-us/fslogix/profile-container-configuration-reference#enabled
        [PSCustomObject]@{
            Name = 'Enabled'
            Path = 'HKLM:\SOFTWARE\FSLogix\Profiles'
            PropertyType = 'DWord'
            Value = 1
        },

        # Deletes a local profile if it exists and matches the profile being loaded from VHD: https://docs.microsoft.com/en-us/fslogix/profile-container-configuration-reference#deletelocalprofilewhenvhdshouldapply
        [PSCustomObject]@{
            Name = 'DeleteLocalProfileWhenVHDShouldApply'
            Path = 'HKLM:\SOFTWARE\FSLogix\Profiles'
            PropertyType = 'DWord'
            Value = 1
        },

        # The folder created in the FSLogix fileshare will begin with the username instead of the SID: https://docs.microsoft.com/en-us/fslogix/profile-container-configuration-reference#flipflopprofiledirectoryname
        [PSCustomObject]@{
            Name = 'FlipFlopProfileDirectoryName'
            Path = 'HKLM:\SOFTWARE\FSLogix\Profiles'
            PropertyType = 'DWord'
            Value = 1
        },

        # List of file system locations to search for the user's profile VHD(X) file: https://docs.microsoft.com/en-us/fslogix/profile-container-configuration-reference#vhdlocations
        [PSCustomObject]@{
            Name = 'VHDLocations'
            Path = 'HKLM:\SOFTWARE\FSLogix\Profiles'
            PropertyType = 'MultiString'
            Value = $FileShare
        }
    )
}

# Set registry settings
try 
{
    foreach($Setting in $Settings)
    {
        $Value = Get-ItemProperty -Path $Setting.Path -Name $Setting.Name -ErrorAction 'SilentlyContinue'
        if(!$Value)
        {
            New-ItemProperty -Path $Setting.Path -Name $Setting.Name -PropertyType $Setting.PropertyType -Value $Setting.Value -Force
            Write-Log -Message "Added registry setting: $($Setting.Name)" -Type 'INFO'
        }
        elseif($Value.$($Setting.Name) -ne $Setting.Value)
        {
            Set-ItemProperty -Path $Setting.Path -Name $Setting.Name -Value $Setting.Value -Force
            Write-Log -Message "Updated registry setting: $($Setting.Name)" -Type 'INFO'
        }
        else 
        {
            Write-Log -Message "Registry setting exists with correct value: $($Setting.Name)" -Type 'INFO'    
        }
        Start-Sleep -Seconds 1
    }
}
catch 
{
    Write-Log -Message $_ -Type 'ERROR'
}


#####################################
# Defender Exclusions for FSLogix 
#####################################
# https://docs.microsoft.com/en-us/azure/architecture/example-scenario/wvd/windows-virtual-desktop-fslogix#antivirus-exclusions
try
{
    if($PooledHostPool -eq 'true' -and $FSLogix -eq 'true')
    {

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
}
catch 
{
    Write-Log -Message $_ -Type 'ERROR'
}


######################################
#  AVD Agent
######################################
try 
{   
    $BootInstaller = 'AVD-Bootloader.msi'
    Invoke-WebRequest -Uri 'https://query.prod.cms.rt.microsoft.com/cms/api/am/binary/RWrxrH' -OutFile $BootInstaller
    Start-Process -FilePath 'msiexec.exe' -ArgumentList "/i $BootInstaller /quiet /qn /norestart /passive" -Wait -Passthru
    Write-Log -Message 'Installed AVD Bootloader' -Type 'INFO'
    Start-Sleep -Seconds 5

    $AgentInstaller = 'AVD-Agent.msi'
    Invoke-WebRequest -Uri 'https://query.prod.cms.rt.microsoft.com/cms/api/am/binary/RWrmXv' -OutFile $AgentInstaller
    Start-Process -FilePath 'msiexec.exe' -ArgumentList "/i $AgentInstaller /quiet /qn /norestart /passive REGISTRATIONTOKEN=$HostPoolRegistrationToken" -Wait -PassThru
    Write-Log -Message 'Installed AVD Agent' -Type 'INFO'
    Start-Sleep -Seconds 5
}
catch 
{
    Write-Log -Message $_ -Type 'ERROR'    
}
   

######################################
#  Virtual Desktop Optimization Tool
######################################
# https://github.com/The-Virtual-Desktop-Team/Virtual-Desktop-Optimization-Tool
try 
{
    if($ImagePublisher -eq 'MicrosoftWindowsDesktop' -and $ImageOffer -ne 'windows-7')
    {
        # Download VDOT
        $URL = 'https://github.com/The-Virtual-Desktop-Team/Virtual-Desktop-Optimization-Tool/archive/refs/heads/main.zip'
        $ZIP = 'VDOT.zip'
        Invoke-WebRequest -Uri $URL -OutFile $ZIP
        
        # Extract VDOT from ZIP archive
        Expand-Archive -LiteralPath $ZIP -Force
        
        # Run VDOT
        & .\VDOT\Virtual-Desktop-Optimization-Tool-main\Win10_VirtualDesktop_Optimize.ps1 -AcceptEULA
        Write-Log -Message 'Optimized the operating system using the VDOT' -Type 'INFO'
    }
}
catch 
{
    Write-Log -Message $_ -Type 'ERROR'
}

# If the GPU extensions are not deployed then force a reboot for VDOT
if ($AmdVmSize -eq 'false' -and $NvidiaVmSize -eq 'false') 
{
    Start-Process -FilePath 'shutdown' -ArgumentList '/r /t 30'
}