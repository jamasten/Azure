# Download Teams software
$ErrorActionPreference = 'Stop'
try 
{
    # Visual C++
    $URL = 'https://aka.ms/vs/16/release/vc_redist.x64.exe'
    $File = 'C:\temp\vc_redist.x64.exe'
    Invoke-WebRequest -Uri $URL -OutFile $File
    Write-Host 'Downloaded Visual C++'

    # Teams WebSocket Service
    $URL = 'https://query.prod.cms.rt.microsoft.com/cms/api/am/binary/RE4AQBt'
    $File = 'C:\temp\webSocketSvc.msi'
    Invoke-WebRequest -Uri $URL -OutFile $File
    Write-Host 'Downloaded the Teams WebSocket service'

    # Teams
    $URL = 'https://teams.microsoft.com/downloads/desktopurl?env=production&plat=windows&arch=x64&managedInstaller=true&download=true'
    $File = 'C:\temp\teams.msi'
    Invoke-WebRequest -Uri $URL -OutFile $File
    Write-Host 'Downloaded Teams'
}
catch 
{
    Write-Host $_
    throw
}