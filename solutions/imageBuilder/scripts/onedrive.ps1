# Install OneDrive on a Windows multi-session operating system
# This script was developed to install OneDrive using Azure Image Builder

$ErrorActionPreference = 'Stop'

try 
{
    # Set variables
    $URL = 'https://go.microsoft.com/fwlink/?linkid=844652'
    $File = 'C:\temp\OneDrive.exe'

    # Download installer to temp folder
    Invoke-WebRequest -Uri $URL -OutFile $File
    Write-Host 'Downloaded the OneDrive installer'

    if(Get-Package -Name 'Microsoft OneDrive' -ErrorAction 'SilentlyContinue')
    {
        # Uninstall existing OneDrive install
        Start-Process -FilePath $File -Args "/uninstall" -Wait -PassThru | Out-Null
        Write-Host 'Uninstalled existing installation of OneDrive'
    }

    # Set "All User Install" registry setting
    & C:\temp\Set-RegistrySetting -Name 'AllUsersInstall' -Path 'HKLM:\Software\Microsoft\OneDrive' -PropertyType 'DWord' -Value '1'

    # Install OneDrive is per-machine mode
    Start-Process -FilePath $File -Args "/allusers" -Wait -PassThru | Out-Null
    Write-Host 'Installed OneDrive in per-machine mode'

    # Set "Start at Sign-In" registry setting
    & C:\temp\Set-RegistrySetting -Name 'OneDrive' -Path 'HKLM:\Software\Microsoft\Windows\CurrentVersion\Run' -PropertyType 'String' -Value 'C:\Program Files (x86)\Microsoft OneDrive\OneDrive.exe /background'

    # Set "Silently configure user account" registry setting
    & C:\temp\Set-RegistrySetting -Name 'SilentAccountConfig' -Path 'HKLM:\SOFTWARE\Policies\Microsoft\OneDrive' -PropertyType 'DWord' -Value '1'

    # Set "Redirect & move known folders" registry setting
    $AzureADTenantID = Get-Content -Path 'C:\temp\tenantId.txt'
    & C:\temp\Set-RegistrySetting -Name 'KFMSilentOptIn' -Path 'HKLM:\SOFTWARE\Policies\Microsoft\OneDrive' -PropertyType 'String' -Value "$AzureADTenantID"
}
catch 
{
    Write-Host $_
    throw
}