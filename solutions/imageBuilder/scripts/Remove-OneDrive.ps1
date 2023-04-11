# Install OneDrive on a Windows multi-session operating system
# This script was developed to install OneDrive using Azure Image Builder

$ErrorActionPreference = 'Stop'

try 
{
    # Uninstall existing OneDrive install
    $Installer = 'C:\temp\OneDrive.exe'
    Start-Process -FilePath $Installer -Args "/uninstall" -Wait -PassThru | Out-Null
    Write-Host 'Uninstalled existing installation of OneDrive'
}
catch 
{
    Write-Host $_
    throw
}