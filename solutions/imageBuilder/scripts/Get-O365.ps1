# Download & extract the Office 365 Deployment Toolkit

$ErrorActionPreference = 'Stop'

try 
{
    $URL = 'https://download.microsoft.com/download/2/7/A/27AF1BE6-DD20-4CB4-B154-EBAB8A7D4A7E/officedeploymenttool_16130-20218.exe'
    $Installer = 'C:\temp\office.exe'
    Invoke-WebRequest -Uri $URL -OutFile $Installer
    Write-Host 'Downloaded the Office 365 Deployment Toolkit'

    Start-Process -FilePath $Installer -ArgumentList "/extract:C:\temp /quiet /passive /norestart" -Wait -PassThru | Out-Null
    Write-Host 'Extracted the Office 365 Deployment Toolkit'
}
catch 
{
    Write-Host $_
    throw
}