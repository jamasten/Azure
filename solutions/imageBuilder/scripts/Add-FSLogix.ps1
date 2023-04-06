# Install FSLogix silently on a Windows x64 operating system
$ErrorActionPreference = 'Stop'
try 
{
    Start-Process -FilePath 'C:\temp\fslogix\x64\Release\FSLogixAppsSetup.exe' -ArgumentList "/install /quiet /norestart" -Wait -PassThru | Out-Null
    Write-Host 'Installed FSLogix'
}
catch 
{
    Write-Host $_
    throw
}