param 
( 
    [Parameter(Mandatory)]
    [String]$Environment,

    [Parameter(Mandatory)]
    [String]$HostPoolName,

    [Parameter(Mandatory)]
    [String]$StorageAccountName
)

$Suffix = switch($Environment)
{
    AzureCloud {'.file.core.windows.net'}
    AzureUSGovernment {'.file.core.usgovcloudapi.net'}
}
$FileShare = '\\' + $StorageAccountName + $Suffix + '\' + $HostPoolName

# Enables FSLogix profile containers
New-ItemProperty -Path 'HKLM:\SOFTWARE\FSLogix\Profiles' -Name 'Enabled' -PropertyType 'DWord' -Value 1

# Deletes a local profile if it exists and matches the profile being loaded from VHD
New-ItemProperty -Path 'HKLM:\SOFTWARE\FSLogix\Profiles' -Name 'DeleteLocalProfileWhenVHDShouldApply' -PropertyType 'DWord' -Value 0

# The folder created in the FSLogix fileshare will begin with the username instead of the SID
New-ItemProperty -Path 'HKLM:\SOFTWARE\FSLogix\Profiles' -Name 'FlipFlopProfileDirectoryName' -PropertyType 'DWord' -Value 1

# Loads FRXShell if there's a failure attaching to, or using an existing profile VHD(X)
New-ItemProperty -Path 'HKLM:\SOFTWARE\FSLogix\Profiles' -Name 'PreventLoginWithFailure' -PropertyType 'DWord' -Value 0

# Loads FRXShell if it's determined a temp profile has been created
New-ItemProperty -Path 'HKLM:\SOFTWARE\FSLogix\Profiles' -Name 'PreventLoginWithTempProfile' -PropertyType 'DWord' -Value 0

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