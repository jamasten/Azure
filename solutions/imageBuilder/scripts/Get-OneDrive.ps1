# Install OneDrive on a Windows multi-session operating system
$ErrorActionPreference = 'Stop'
# Set variables
$URL = 'https://go.microsoft.com/fwlink/?linkid=844652'
$Installer = 'C:\temp\OneDrive.exe'
try 
{
    # Download OneDrive installer to temp folder
    Invoke-WebRequest -Uri $URL -OutFile $Installer
    Write-Host 'Downloaded the OneDrive installer'
}
catch 
{
    Write-Host $_
    throw
}