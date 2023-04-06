# Install OneDrive on a Windows multi-session operating system
$ErrorActionPreference = 'Stop'
# Set variables
$URL = 'https://go.microsoft.com/fwlink/?linkid=844652'
$File = 'C:\temp\OneDrive.exe'
try 
{
    # Download OneDrive installer to temp folder
    Invoke-WebRequest -Uri $URL -OutFile $File
    Write-Host 'Downloaded the OneDrive installer'
}
catch 
{
    Write-Host $_
    throw
}