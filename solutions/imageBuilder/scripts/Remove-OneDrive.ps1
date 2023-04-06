# Install OneDrive on a Windows multi-session operating system
# This script was developed to install OneDrive using Azure Image Builder

$ErrorActionPreference = 'Stop'

try 
{
    # Uninstall existing OneDrive install
    Start-Process -FilePath $File -Args "/uninstall" -Wait -PassThru | Out-Null
    Write-Host 'Uninstalled existing installation of OneDrive'
}
catch 
{
    Write-Host $_
    throw
}