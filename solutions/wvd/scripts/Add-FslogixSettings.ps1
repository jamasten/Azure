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

New-ItemProperty -Path "HKLM:\SOFTWARE\FSLogix\Profiles" -Name Enabled -PropertyType DWord -Value 1
New-ItemProperty -Path "HKLM:\SOFTWARE\FSLogix\Profiles" -Name DeleteLocalProfileWhenVHDShouldApply -PropertyType DWord -Value 1
New-ItemProperty -Path "HKLM:\SOFTWARE\FSLogix\Profiles" -Name FlipFlopProfileDirectoryName -PropertyType DWord -Value 1
New-ItemProperty -Path "HKLM:\SOFTWARE\FSLogix\Profiles" -Name PreventLoginWithFailure -PropertyType DWord -Value 1
New-ItemProperty -Path "HKLM:\SOFTWARE\FSLogix\Profiles" -Name PreventLoginWithTempProfile -PropertyType DWord -Value 1
New-ItemProperty -Path "HKLM:\SOFTWARE\FSLogix\Profiles" -Name VHDLocations -PropertyType MultiString -Value $FileShare