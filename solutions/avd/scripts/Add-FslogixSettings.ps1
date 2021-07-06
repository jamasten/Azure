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
New-ItemProperty -Path 'HKLM:\SOFTWARE\FSLogix\Profiles' -Name 'PreventLoginWithFailure' -PropertyType 'DWord' -Value 1

# Loads FRXShell if it's determined a temp profile has been created
New-ItemProperty -Path 'HKLM:\SOFTWARE\FSLogix\Profiles' -Name 'PreventLoginWithTempProfile' -PropertyType 'DWord' -Value 0

# List of file system locations to search for the user's profile VHD(X) file
New-ItemProperty -Path 'HKLM:\SOFTWARE\FSLogix\Profiles' -Name 'VHDLocations' -PropertyType 'MultiString' -Value $FileShare