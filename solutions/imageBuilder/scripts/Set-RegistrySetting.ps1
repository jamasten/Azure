Param(
    [parameter(Mandatory)]
    [String]$Name,

    [parameter(Mandatory)]
    [String]$Path,

    [parameter(Mandatory)]
    [String]$PropertyType,

    [parameter(Mandatory)]
    [String]$Value
)

# Create registry key(s) if necessary
if(!(Test-Path -Path $Path))
{
    New-Item -Path $Path -Force | Out-Null
}

# Checks for existing registry setting
$Setting = Get-ItemProperty -Path $Path -Name $Name -ErrorAction 'SilentlyContinue'
$LogOutputValue = 'Path: ' + $Path + ', Name: ' + $Name + ', PropertyType: ' + $PropertyType + ', Value: ' + $Value

# Creates the registry setting when it does not exist
if(!$Setting)
{
    New-ItemProperty -Path $Path -Name $Name -PropertyType $PropertyType -Value $Value -Force | Out-Null
    Write-Host "Added registry setting: $LogOutputValue"
}
# Updates the registry setting when it already exists
elseif($Setting.$($Name) -ne $Value)
{
    Set-ItemProperty -Path $Path -Name $Name -Value $Value -Force | Out-Null
    Write-Host "Updated registry setting: $LogOutputValue"
}
# Writes log output when registry setting has the correct value
else 
{
    Write-Host "Registry setting exists with correct value: $LogOutputValue"  
}
Start-Sleep -Seconds 1