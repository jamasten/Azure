# Download OneDrive

$ErrorActionPreference = 'Stop'

try 
{
    # Download OneDrive installer to temp folder
    $URL = 'https://go.microsoft.com/fwlink/?linkid=844652'
    $Installer = 'C:\temp\OneDrive.exe'
    Invoke-WebRequest -Uri $URL -OutFile $Installer
    Write-Host 'Downloaded the OneDrive installer'
}
catch 
{
    Write-Host $_
    throw
}