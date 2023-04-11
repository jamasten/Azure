# Download Teams software
$ErrorActionPreference = 'Stop'
try 
{
    # Visual C++
    $URL = 'https://aka.ms/vs/16/release/vc_redist.x64.exe'
    $Installer = 'C:\temp\vc_redist.x64.exe'
    Invoke-WebRequest -Uri $URL -OutFile $Installer
    Write-Host 'Downloaded Visual C++'

    # Teams WebSocket Service
    $URL = 'https://query.prod.cms.rt.microsoft.com/cms/api/am/binary/RE4AQBt'
    $Installer = 'C:\temp\webSocketSvc.msi'
    Invoke-WebRequest -Uri $URL -OutFile $Installer
    Write-Host 'Downloaded the Teams WebSocket service'

    # Teams
    $URL = 'https://teams.microsoft.com/downloads/desktopurl?env=production&plat=windows&arch=x64&managedInstaller=true&download=true'
    $Installer = 'C:\temp\teams.msi'
    Invoke-WebRequest -Uri $URL -OutFile $Installer
    Write-Host 'Downloaded Teams'
}
catch 
{
    Write-Host $_
    throw
}