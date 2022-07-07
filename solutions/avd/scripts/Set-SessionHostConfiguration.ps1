[Cmdletbinding()]
Param(
    [parameter(Mandatory)]
    [string]
    $AmdVmSize, 

    [parameter(Mandatory)]
    [string]
    $DisaStigCompliance,

    [parameter(Mandatory)]
    [string]
    $DomainName,

    [parameter(Mandatory)]
    [string]
    $DomainServices,

    [parameter(Mandatory)]
    [string]
    $Environment,

    [parameter(Mandatory)]
    [string]
    $Fslogix,

    [parameter(Mandatory)]
    [string]
    $FslogixSolution,

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
    $NetAppFileShares,

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
    $StorageAccountPrefix,

    [parameter(Mandatory)]
    [int]
    $StorageCount,

    [parameter(Mandatory)]
    [int]
    $StorageIndex,

    [parameter(Mandatory)]
    [string]
    $StorageSolution,

    [parameter(Mandatory)]
    [string]
    $StorageSuffix   
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


try 
{
    # Convert NetAppFiles share names from a JSON array to a PowerShell array
    [array]$NetAppFileShares = $NetAppFileShares.Replace("'",'"') | ConvertFrom-Json
    Write-Log -Message "Azure NetApp Files, Shares:" -Type 'INFO'
    $NetAppFileShares | Add-Content -Path 'C:\cse.txt' -Force


    ##############################################################
    #  Run the Virtual Desktop Optimization Tool (VDOT)
    ##############################################################
    # https://github.com/The-Virtual-Desktop-Team/Virtual-Desktop-Optimization-Tool
    if($ImagePublisher -eq 'MicrosoftWindowsDesktop' -and $ImageOffer -ne 'windows-7')
    {
        # Download VDOT
        $URL = 'https://github.com/The-Virtual-Desktop-Team/Virtual-Desktop-Optimization-Tool/archive/refs/heads/main.zip'
        $ZIP = 'VDOT.zip'
        Invoke-WebRequest -Uri $URL -OutFile $ZIP -ErrorAction 'Stop'
        
        # Extract VDOT from ZIP archive
        Expand-Archive -LiteralPath $ZIP -Force -ErrorAction 'Stop'
        
        # Fix to disable AppX Packages
        # As of 2/8/22, all AppX Packages are enabled by default
        $Files = (Get-ChildItem -Path .\VDOT\Virtual-Desktop-Optimization-Tool-main -File -Recurse -Filter "AppxPackages.json" -ErrorAction 'Stop').FullName
        foreach($File in $Files)
        {
            $Content = Get-Content -Path $File -ErrorAction 'Stop'
            $Settings = $Content | ConvertFrom-Json -ErrorAction 'Stop'
            $NewSettings = @()
            foreach($Setting in $Settings)
            {
                $NewSettings += [pscustomobject][ordered]@{
                    AppxPackage = $Setting.AppxPackage
                    VDIState = 'Disabled'
                    URL = $Setting.URL
                    Description = $Setting.Description
                }
            }

            $JSON = $NewSettings | ConvertTo-Json -ErrorAction 'Stop'
            $JSON | Out-File -FilePath $File -Force -ErrorAction 'Stop'
        }

        # Run VDOT
        & .\VDOT\Virtual-Desktop-Optimization-Tool-main\Windows_VDOT.ps1 -AcceptEULA
        Write-Log -Message 'Optimized the operating system using VDOT' -Type 'INFO'
    }    

    
    ##############################################################
    #  DISA STIG Compliance
    ##############################################################
    if($DisaStigCompliance -eq 'true')
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
    #  Add Fslogix Configurations
    ##############################################################
    if($Fslogix -eq 'true')
    {
        $FilesSuffix = '.file.' + $StorageSuffix
        $CloudCacheOfficeContainers = @()
        $CloudCacheProfileContainers = @()
        $OfficeContainers = @()
        $ProfileContainers = @()
        switch($StorageSolution)
        {
            'AzureStorageAccount' {
                for($i = $StorageIndex; $i -lt $($StorageIndex + $StorageCount); $i++)
                {
                    $CloudCacheOfficeContainers += 'type=smb,connectionString=\\' + $StorageAccountPrefix + $i.ToString().PadLeft(2,'0') + $FilesSuffix + '\officecontainers;'
                    $CloudCacheProfileContainers += 'type=smb,connectionString=\\' + $StorageAccountPrefix + $i.ToString().PadLeft(2,'0') + $FilesSuffix + '\profilecontainers;'
                    $OfficeContainers += '\\' + $StorageAccountPrefix + $i.ToString().PadLeft(2,'0') + $FilesSuffix + '\officecontainers'
                    $ProfileContainers += '\\' + $StorageAccountPrefix + $i.ToString().PadLeft(2,'0') + $FilesSuffix + '\profilecontainers'
                }
            }
            'AzureNetAppFiles' {
                $CloudCacheOfficeContainers += 'type=smb,connectionString=\\' + $NetAppFileShares[0] + ';'
                $CloudCacheProfileContainers += 'type=smb,connectionString=\\' + $NetAppFileShares[1] + ';'
                $OfficeContainers += '\\' + $NetAppFileShares[0]
                $ProfileContainers += '\\' + $NetAppFileShares[1]
            }
        }
        
        $Shares = @()
        $Shares += $OfficeContainers
        $Shares += $ProfileContainers
        $SharesOutput = if($Shares.Count -eq 1){$Shares}else{$Shares -join ', '}
        Write-Log -Message "File Shares: $SharesOutput" -Type 'INFO'

        $Settings += @(

            # Enables Fslogix profile containers: https://docs.microsoft.com/en-us/fslogix/profile-container-configuration-reference#enabled
            [PSCustomObject]@{
                Name = 'Enabled'
                Path = 'HKLM:\SOFTWARE\Fslogix\Profiles'
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

            # The folder created in the Fslogix fileshare will begin with the username instead of the SID: https://docs.microsoft.com/en-us/fslogix/profile-container-configuration-reference#flipflopprofiledirectoryname
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
            }
        )

        if($FslogixSolution -like "CloudCache*")
        {
            $Settings += @(
                # List of file system locations to search for the user's profile VHD(X) file: https://docs.microsoft.com/en-us/fslogix/profile-container-configuration-reference#vhdlocations
                [PSCustomObject]@{
                    Name = 'CCDLocations'
                    Path = 'HKLM:\SOFTWARE\FSLogix\Profiles'
                    PropertyType = 'MultiString'
                    Value = $CloudCacheProfileContainers
                }
            )           
        }
        else
        {
            $Settings += @(
                # List of file system locations to search for the user's profile VHD(X) file: https://docs.microsoft.com/en-us/fslogix/profile-container-configuration-reference#vhdlocations
                [PSCustomObject]@{
                    Name = 'VHDLocations'
                    Path = 'HKLM:\SOFTWARE\FSLogix\Profiles'
                    PropertyType = 'MultiString'
                    Value = $ProfileContainers
                }
            )
        }

        if($FslogixSolution -like "*OfficeContainer")
        {
            $Settings += @(

                # Enables Fslogix office containers: https://docs.microsoft.com/en-us/fslogix/office-container-configuration-reference#enabled
                [PSCustomObject]@{
                    Name = 'Enabled'
                    Path = 'HKLM:\SOFTWARE\Policies\FSLogix\ODFC'
                    PropertyType = 'DWord'
                    Value = 1
                },

                # Deletes a local profile if it exists and matches the profile being loaded from VHD: https://docs.microsoft.com/en-us/fslogix/profile-container-configuration-reference#deletelocalprofilewhenvhdshouldapply
                [PSCustomObject]@{
                    Name = 'DeleteLocalProfileWhenVHDShouldApply'
                    Path = 'HKLM:\SOFTWARE\Policies\FSLogix\ODFC'
                    PropertyType = 'DWord'
                    Value = 1
                },

                # The folder created in the Fslogix fileshare will begin with the username instead of the SID: https://docs.microsoft.com/en-us/fslogix/office-container-configuration-reference#flipflopprofiledirectoryname
                [PSCustomObject]@{
                    Name = 'FlipFlopProfileDirectoryName'
                    Path = 'HKLM:\SOFTWARE\Policies\FSLogix\ODFC'
                    PropertyType = 'DWord'
                    Value = 1
                },

                # OneDrive cache is redirected to the container: https://docs.microsoft.com/en-us/fslogix/office-container-configuration-reference#includeonedrive
                [PSCustomObject]@{
                    Name = 'IncludeOneDrive'
                    Path = 'HKLM:\SOFTWARE\Policies\FSLogix\ODFC'
                    PropertyType = 'DWord'
                    Value = 1
                },

                # OneNote notebook files are redirected to the container: https://docs.microsoft.com/en-us/fslogix/office-container-configuration-reference#includeonenote
                [PSCustomObject]@{
                    Name = 'IncludeOneNote'
                    Path = 'HKLM:\SOFTWARE\Policies\FSLogix\ODFC'
                    PropertyType = 'DWord'
                    Value = 1
                },                

                # OneNote UWP notebook files are redirected to the container: https://docs.microsoft.com/en-us/fslogix/office-container-configuration-reference#includeonenote_uwp
                [PSCustomObject]@{
                    Name = 'IncludeOneNote_UWP'
                    Path = 'HKLM:\SOFTWARE\Policies\FSLogix\ODFC'
                    PropertyType = 'DWord'
                    Value = 1
                },
                
                # Outlook data is redirected to the container: https://docs.microsoft.com/en-us/fslogix/office-container-configuration-reference#includeoutlook
                [PSCustomObject]@{
                    Name = 'IncludeOutlook'
                    Path = 'HKLM:\SOFTWARE\Policies\FSLogix\ODFC'
                    PropertyType = 'DWord'
                    Value = 1
                },
                
                # Outlook personalization data is redirected to the container: https://docs.microsoft.com/en-us/fslogix/office-container-configuration-reference#includeoutlookpersonalization
                [PSCustomObject]@{
                    Name = 'IncludeOutlookPersonalization'
                    Path = 'HKLM:\SOFTWARE\Policies\FSLogix\ODFC'
                    PropertyType = 'DWord'
                    Value = 1
                },     
                
                # Sharepoint data is redirected to the container: https://docs.microsoft.com/en-us/fslogix/office-container-configuration-reference#includesharepoint
                [PSCustomObject]@{
                    Name = 'IncludeSharepoint'
                    Path = 'HKLM:\SOFTWARE\Policies\FSLogix\ODFC'
                    PropertyType = 'DWord'
                    Value = 1
                },          
                
                # Skype for Business Global Address List is redirected to the container: https://docs.microsoft.com/en-us/fslogix/office-container-configuration-reference#includeskype
                [PSCustomObject]@{
                    Name = 'IncludeSkype'
                    Path = 'HKLM:\SOFTWARE\Policies\FSLogix\ODFC'
                    PropertyType = 'DWord'
                    Value = 1
                },              
                
                # Teams data is redirected to the container: https://docs.microsoft.com/en-us/fslogix/office-container-configuration-reference#includeteams
                # NOTE: Users will be required to sign in to teams at the beginning of each session.
                [PSCustomObject]@{
                    Name = 'IncludeTeams'
                    Path = 'HKLM:\SOFTWARE\Policies\FSLogix\ODFC'
                    PropertyType = 'DWord'
                    Value = 1
                },                  

                # Loads FRXShell if there's a failure attaching to, or using an existing profile VHD(X): https://docs.microsoft.com/en-us/fslogix/office-container-configuration-reference#preventloginwithfailure
                [PSCustomObject]@{
                    Name = 'PreventLoginWithFailure'
                    Path = 'HKLM:\SOFTWARE\Policies\FSLogix\ODFC'
                    PropertyType = 'DWord'
                    Value = 1
                },

                # Loads FRXShell if it's determined a temp profile has been created: https://docs.microsoft.com/en-us/fslogix/office-container-configuration-reference#preventloginwithtempprofile
                [PSCustomObject]@{
                    Name = 'PreventLoginWithTempProfile'
                    Path = 'HKLM:\SOFTWARE\Policies\FSLogix\ODFC'
                    PropertyType = 'DWord'
                    Value = 1
                }
            )

            if($FslogixSolution -like "CloudCache*")
            {
                $Settings += @(
                    # List of file system locations to search for the user's profile VHD(X) file: https://docs.microsoft.com/en-us/fslogix/profile-container-configuration-reference#vhdlocations
                    [PSCustomObject]@{
                        Name = 'CCDLocations'
                        Path = 'HKLM:\SOFTWARE\Policies\FSLogix\ODFC'
                        PropertyType = 'MultiString'
                        Value = $CloudCacheOfficeContainers
                    }
                )           
            }
            else
            {
                $Settings += @(
                    # List of file system locations to search for the user's profile VHD(X) file: https://docs.microsoft.com/en-us/fslogix/office-container-configuration-reference#vhdlocations
                    [PSCustomObject]@{
                        Name = 'VHDLocations'
                        Path = 'HKLM:\SOFTWARE\Policies\FSLogix\ODFC'
                        PropertyType = 'MultiString'
                        Value = $OfficeContainers
                    }
                )
            }
        }
    }


    ##############################################################
    #  Add Azure AD Join Configuration
    ##############################################################
    if($DomainServices -like "None*")
    {
        $Settings += @(

            # Enable PKU2U: https://docs.microsoft.com/en-us/azure/virtual-desktop/troubleshoot-azure-ad-connections#windows-desktop-client
            [PSCustomObject]@{
                Name = 'AllowOnlineID'
                Path = 'HKLM:\SYSTEM\CurrentControlSet\Control\Lsa\pku2u'
                PropertyType = 'DWord'
                Value = 1
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
    foreach($Setting in $Settings)
    {
        # Create registry key(s) if necessary
        if(!(Test-Path -Path $Setting.Path))
        {
            New-Item -Path $Setting.Path -Force
        }

        # Checks for existing registry setting
        $Value = Get-ItemProperty -Path $Setting.Path -Name $Setting.Name -ErrorAction 'SilentlyContinue'
        $LogOutputValue = 'Path: ' + $Setting.Path + ', Name: ' + $Setting.Name + ', PropertyType: ' + $Setting.PropertyType + ', Value: ' + $Setting.Value
        
        # Creates the registry setting when it does not exist
        if(!$Value)
        {
            New-ItemProperty -Path $Setting.Path -Name $Setting.Name -PropertyType $Setting.PropertyType -Value $Setting.Value -Force -ErrorAction 'Stop'
            Write-Log -Message "Added registry setting: $LogOutputValue" -Type 'INFO'
        }
        # Updates the registry setting when it already exists
        elseif($Value.$($Setting.Name) -ne $Setting.Value)
        {
            Set-ItemProperty -Path $Setting.Path -Name $Setting.Name -Value $Setting.Value -Force -ErrorAction 'Stop'
            Write-Log -Message "Updated registry setting: $LogOutputValue" -Type 'INFO'
        }
        # Writes log output when registry setting has the correct value
        else 
        {
            Write-Log -Message "Registry setting exists with correct value: $LogOutputValue" -Type 'INFO'    
        }
        Start-Sleep -Seconds 1
    }


    ##############################################################
    # Add Defender Exclusions for FSLogix 
    ##############################################################
    # https://docs.microsoft.com/en-us/azure/architecture/example-scenario/wvd/windows-virtual-desktop-fslogix#antivirus-exclusions
    if($Fslogix -eq 'true')
    {

        $Files = @(
            "%ProgramFiles%\FSLogix\Apps\frxdrv.sys",
            "%ProgramFiles%\FSLogix\Apps\frxdrvvt.sys",
            "%ProgramFiles%\FSLogix\Apps\frxccd.sys",
            "%TEMP%\*.VHD",
            "%TEMP%\*.VHDX",
            "%Windir%\TEMP\*.VHD",
            "%Windir%\TEMP\*.VHDX"
        )

        foreach($Share in $Shares)
        {
            $Files += "$Share\*.VHD"
            $Files += "$Share\*.VHDX"
        }

        if($FslogixSolution -like "CloudCache*")
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


    ##############################################################
    #  Install the AVD Agent
    ##############################################################
    # Disabling this method for installing the AVD agent until AAD Join can completed successfully
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
    throw
}
