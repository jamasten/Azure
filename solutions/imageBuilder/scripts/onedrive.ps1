# Install OneDrive on a Windows multi-session operating system
# This script was developed to install OneDrive using Azure Image Builder

$ErrorActionPreference = 'Stop'

function Set-RegistrySetting 
{
    Param(
        [parameter(Mandatory=$false)]
        [String]$Name,

        [parameter(Mandatory=$false)]
        [String]$Path,

        [parameter(Mandatory=$false)]
        [String]$PropertyType,

        [parameter(Mandatory=$false)]
        [String]$Value
    )

    # Create registry key(s) if necessary
    if(!(Test-Path -Path $Path))
    {
        New-Item -Path $Path -Force
    }

    # Checks for existing registry setting
    $Value = Get-ItemProperty -Path $Path -Name $Name -ErrorAction 'SilentlyContinue'
    $LogOutputValue = 'Path: ' + $Path + ', Name: ' + $Name + ', PropertyType: ' + $PropertyType + ', Value: ' + $Value
    
    # Creates the registry setting when it does not exist
    if(!$Value)
    {
        New-ItemProperty -Path $Path -Name $Name -PropertyType $PropertyType -Value $Value -Force
        Write-Host "Added registry setting: $LogOutputValue"
    }
    # Updates the registry setting when it already exists
    elseif($Value.$($Name) -ne $Value)
    {
        Set-ItemProperty -Path $Path -Name $Name -Value $Value -Force
        Write-Host "Updated registry setting: $LogOutputValue"
    }
    # Writes log output when registry setting has the correct value
    else 
    {
        Write-Host "Registry setting exists with correct value: $LogOutputValue"  
    }
    Start-Sleep -Seconds 1
}

try 
{
    # Set variables
    $URL = 'https://go.microsoft.com/fwlink/?linkid=844652'
    $File = 'C:\temp\OneDrive.exe'

    # Download installer to temp folder
    Invoke-WebRequest -Uri $URL -OutFile $File
    Write-Host 'Downloaded the OneDrive installer'

    # Uninstall existing OneDrive install
    Start-Process -FilePath $File -Args "/uninstall" -Wait -PassThru -ErrorAction 'SilentlyContinue'
    Write-Host 'Uninstalled existing installation of OneDrive'

    # Set "All User Install" registry setting
    Set-RegistrySetting -Name 'AllUsersInstall' -Path 'HKLM:\Software\Microsoft\OneDrive' -PropertyType 'DWord' -Value 1

    # Install OneDrive is per-machine mode
    Start-Process -FilePath $File -Args "/allusers" -Wait
    Write-Host 'Installed OneDrive in per-machine mode'

    # Set "Start at Sign-In" registry setting
    Set-RegistrySetting -Name 'OneDrive' -Path 'HKLM:\Software\Microsoft\Windows\CurrentVersion\Run' -PropertyType 'String' -Value 'C:\Program Files (x86)\Microsoft OneDrive\OneDrive.exe /background'

    # Set "Silently configure user account" registry setting
    Set-RegistrySetting -Name 'SilentAccountConfig' -Path 'HKLM:\SOFTWARE\Policies\Microsoft\OneDrive' -PropertyType 'DWord' -Value 1

    # Set "Redirect & move known folders" registry setting
    $AzureADTenantID = Get-Content -Path 'C:\temp\tenantId.txt'
    Set-RegistrySetting -Name 'KFMSilentOptIn' -Path 'HKLM:\SOFTWARE\Policies\Microsoft\OneDrive' -PropertyType 'String' -Value $AzureADTenantID
}
catch 
{
    Write-Host $_
    throw
}