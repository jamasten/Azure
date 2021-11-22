[Cmdletbinding()]
Param(
    [parameter(Mandatory)]
    [string]
    $AmdVmSize, 

    [parameter(Mandatory)]
    [string]
    $DodStigCompliance,

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
    $RdpShortPath,

    [parameter(Mandatory)]
    [string]
    $ScreenCaptureProtection,

    [parameter(Mandatory)]
    [string]
    $StorageAccountName
)


##############################################################
#  Functions
##############################################################
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


function Get-WebFile
{
    param(
        [parameter(Mandatory)]
        [string]$FileName,

        [parameter(Mandatory)]
        [string]$URL
    )
    $Counter = 0
    do
    {
        Invoke-WebRequest -Uri $URL -OutFile $FileName -ErrorAction 'SilentlyContinue'
        if($Counter -gt 0)
        {
            Start-Sleep -Seconds 30
        }
        $Counter++
    }
    until((Test-Path $FileName) -or $Counter -eq 9)
}


##############################################################
#  Output parameter values for validation
##############################################################
Write-Log -Message "AmdVmSize: $AmdVmSize" -Type 'INFO'
Write-Log -Message "Environment: $Environment" -Type 'INFO'
Write-Log -Message "FSLogix: $FSLogix" -Type 'INFO'
Write-Log -Message "HostPoolName: $HostPoolName" -Type 'INFO'
Write-Log -Message "ImageOffer: $ImageOffer" -Type 'INFO'
Write-Log -Message "ImagePublisher: $ImagePublisher" -Type 'INFO'
Write-Log -Message "NvidiaVmSize: $NvidiaVmSize" -Type 'INFO'
Write-Log -Message "PooledHostPool: $PooledHostPool" -Type 'INFO'
Write-Log -Message "RdpShortPath: $RdpShortPath" -Type 'INFO'
Write-Log -Message "ScreenCaptureProtection: $ScreenCaptureProtection" -Type 'INFO'
Write-Log -Message "StorageAccountName: $StorageAccountName" -Type 'INFO'


##############################################################
#  DoD STIG Compliance
##############################################################
if($DodStigCompliance -eq 'true')
{
    # Set Local Admin account password expires True (V-205658)
    $localAdmin = Get-LocalUser | Where-Object Description -eq "Built-in account for administering the computer/domain"
    Set-LocalUser -name $localAdmin.Name -PasswordNeverExpires $false
}

##############################################################
#  Add Recommended AVD Settings
##############################################################
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


##############################################################
#  Add GPU Settings
##############################################################
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


##############################################################
#  Add Screen Capture Protection
##############################################################
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


##############################################################
#  Add FSLogix Configurations
##############################################################
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

        # Loads FRXShell if there's a failure attaching to, or using an existing profile VHD(X): https://docs.microsoft.com/en-us/fslogix/profile-container-configuration-reference#preventloginwithfailure
        [PSCustomObject]@{
            Name = 'PreventLoginWithFailure'
            Path = 'HKLM:\SOFTWARE\FSLogix\Profiles'
            PropertyType = 'DWord'
            Value = 1
        },

        # Loads FRXShell if it's determined a temp profile has been created: https://docs.microsoft.com/en-us/fslogix/profile-container-configuration-reference#preventloginwithtempprofile
        [PSCustomObject]@{
            Name = 'PreventLoginWithTempProfile'
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


##############################################################
#  Add RDP Short Path
##############################################################
if($RdpShortPath -eq 'true')
{
    # Allow inbound network traffic for RDP Shortpath
    New-NetFirewallRule -DisplayName 'Remote Desktop - Shortpath (UDP-In)'  -Action 'Allow' -Description 'Inbound rule for the Remote Desktop service to allow RDP traffic. [UDP 3390]' -Group '@FirewallAPI.dll,-28752' -Name 'RemoteDesktop-UserMode-In-Shortpath-UDP'  -PolicyStore 'PersistentStore' -Profile 'Domain, Private' -Service 'TermService' -Protocol 'udp' -LocalPort 3390 -Program '%SystemRoot%\system32\svchost.exe' -Enabled:True

    $Settings += @(

        # Enable RDP Shortpath for managed networks: https://docs.microsoft.com/en-us/azure/virtual-desktop/shortpath#configure-rdp-shortpath-for-managed-networks
        [PSCustomObject]@{
            Name = 'fUseUdpPortRedirector'
            Path = 'HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations'
            PropertyType = 'DWord'
            Value = 1
        },

        # Enable the port for RDP Shortpath for managed networks: https://docs.microsoft.com/en-us/azure/virtual-desktop/shortpath#configure-rdp-shortpath-for-managed-networks
        [PSCustomObject]@{
            Name = 'UdpPortNumber'
            Path = 'HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations'
            PropertyType = 'DWord'
            Value = 3390
        }
    )
}


# Set registry settings
try 
{
    foreach($Setting in $Settings)
    {
        $Value = Get-ItemProperty -Path $Setting.Path -Name $Setting.Name -ErrorAction 'SilentlyContinue'
        $LogOutputValue = 'Path: ' + $Setting.Path + ', Name: ' + $Setting.Name + ', PropertyType: ' + $Setting.PropertyType + ', Value: ' + $Setting.Value
        if(!$Value)
        {
            New-ItemProperty -Path $Setting.Path -Name $Setting.Name -PropertyType $Setting.PropertyType -Value $Setting.Value -Force -ErrorAction 'Stop'
            Write-Log -Message "Added registry setting: $LogOutputValue" -Type 'INFO'
        }
        elseif($Value.$($Setting.Name) -ne $Setting.Value)
        {
            Set-ItemProperty -Path $Setting.Path -Name $Setting.Name -Value $Setting.Value -Force -ErrorAction 'Stop'
            Write-Log -Message "Updated registry setting: $LogOutputValue" -Type 'INFO'
        }
        else 
        {
            Write-Log -Message "Registry setting exists with correct value: $LogOutputValue" -Type 'INFO'    
        }
        Start-Sleep -Seconds 1
    }
}
catch 
{
    Write-Log -Message $_ -Type 'ERROR'
}


##############################################################
# Add Defender Exclusions for FSLogix 
##############################################################
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
            Add-MpPreference -ExclusionPath $File -ErrorAction 'Stop'
        }
        Write-Log -Message 'Enabled Defender exlusions for FSLogix paths' -Type 'INFO'

        $Processes = @(
            "%ProgramFiles%\FSLogix\Apps\frxccd.exe",
            "%ProgramFiles%\FSLogix\Apps\frxccds.exe",
            "%ProgramFiles%\FSLogix\Apps\frxsvc.exe"
        )

        foreach($Process in $Processes)
        {
            Add-MpPreference -ExclusionProcess $Process -ErrorAction 'Stop'
        }
        Write-Log -Message 'Enabled Defender exlusions for FSLogix processes' -Type 'INFO'
    }
}
catch 
{
    Write-Log -Message $_ -Type 'ERROR'
}


##############################################################
#  Install the AVD Agent
##############################################################
try 
{   
    $BootInstaller = 'AVD-Bootloader.msi'
    Get-WebFile -FileName $BootInstaller -URL 'https://query.prod.cms.rt.microsoft.com/cms/api/am/binary/RWrxrH'
    Start-Process -FilePath 'msiexec.exe' -ArgumentList "/i $BootInstaller /quiet /qn /norestart /passive" -Wait -Passthru -ErrorAction 'Stop'
    Write-Log -Message 'Installed AVD Bootloader' -Type 'INFO'
    Start-Sleep -Seconds 5

    $AgentInstaller = 'AVD-Agent.msi'
    Get-WebFile -FileName $AgentInstaller -URL 'https://query.prod.cms.rt.microsoft.com/cms/api/am/binary/RWrmXv'
    Start-Process -FilePath 'msiexec.exe' -ArgumentList "/i $AgentInstaller /quiet /qn /norestart /passive REGISTRATIONTOKEN=$HostPoolRegistrationToken" -Wait -PassThru -ErrorAction 'Stop'
    Write-Log -Message 'Installed AVD Agent' -Type 'INFO'
    Start-Sleep -Seconds 5
}
catch 
{
    Write-Log -Message $_ -Type 'ERROR'    
}
   

##############################################################
#  Run the Virtual Desktop Optimization Tool (VDOT)
##############################################################
# https://github.com/The-Virtual-Desktop-Team/Virtual-Desktop-Optimization-Tool
try 
{
    if($ImagePublisher -eq 'MicrosoftWindowsDesktop' -and $ImageOffer -ne 'windows-7')
    {
        # Download VDOT
        $URL = 'https://github.com/The-Virtual-Desktop-Team/Virtual-Desktop-Optimization-Tool/archive/refs/heads/main.zip'
        $ZIP = 'VDOT.zip'
        Invoke-WebRequest -Uri $URL -OutFile $ZIP -ErrorAction 'Stop'
        
        # Extract VDOT from ZIP archive
        Expand-Archive -LiteralPath $ZIP -Force -ErrorAction 'Stop'
            
        # Run VDOT
        & .\VDOT\Virtual-Desktop-Optimization-Tool-main\Win10_VirtualDesktop_Optimize.ps1 -AcceptEULA
        Write-Log -Message 'Optimized the operating system using the VDOT' -Type 'INFO'
    }
}
catch 
{
    Write-Log -Message $_ -Type 'ERROR'
}


##############################################################
#  Reboot the Virtual Machine
##############################################################
# If the GPU extensions are not deployed then force a reboot for VDOT
try 
{
    if ($AmdVmSize -eq 'false' -and $NvidiaVmSize -eq 'false') 
    {
        Start-Process -FilePath 'shutdown' -ArgumentList '/r /t 30' -ErrorAction 'Stop'
        Write-Log -Message 'Rebooted virtual machine' -Type 'INFO'
    }
}
catch 
{
    Write-Log -Message $_ -Type 'ERROR'
    $ErrorData = $_ | Select-Object *
    $ErrorData | Out-File -FilePath 'C:\cse.txt' -Append
    throw
}
