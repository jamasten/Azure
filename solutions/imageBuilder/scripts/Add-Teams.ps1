# Install Teams in per-machine mode for Windows multi-session operating systems
$ErrorActionPreference = 'Stop'
try 
{
    # Set registry setting for AVD Media Optimization
    & C:\temp\Set-RegistrySetting -Name 'IsWVDEnvironment' -Path 'HKLM:\SOFTWARE\Microsoft\Teams' -PropertyType 'Dword' -Value '1'

    # Install Visual C++
    $File = 'C:\temp\vc_redist.x64.exe'
    Start-Process -FilePath $File -Args "/install /quiet /norestart /log vcdist.log" -Wait -PassThru | Out-Null
    Write-Host 'Installed Visual C++'

    # Install Teams WebSocket Service
    $File = 'C:\temp\webSocketSvc.msi'
    Start-Process -FilePath msiexec.exe -Args "/i $File /quiet /qn /norestart /passive /log webSocket.log" -Wait -PassThru | Out-Null
    Write-Host 'Installed the Teams WebSocket service'

    # Install Teams
    $File = 'C:\temp\teams.msi'
    Start-Process -FilePath msiexec.exe -Args "/i $File /quiet /qn /norestart /passive /log teams.log ALLUSER=1 ALLUSERS=1" -Wait -PassThru | Out-Null
    Write-Host 'Installed Teams'
}
catch 
{
    Write-Host $_
    throw
}