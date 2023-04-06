# Uninstall FSLogix on a Windows x64 operating system
$ErrorActionPreference = 'Stop'
try 
{
    # Uninstall FSLogix silently
    Start-Process -FilePath 'C:\temp\fslogix\x64\Release\FSLogixAppsSetup.exe' -ArgumentList "/uninstall /quiet /norestart" -Wait -PassThru | Out-Null
    Write-Host 'Uninstalled an existing installation of FSLogix'
}
catch 
{
    Write-Host $_
    throw
}