 # Set Registry Key & Setting for AVD Media Optimization
 New-Item -Path HKLM:\SOFTWARE\Microsoft -Name 'Teams'
 New-ItemProperty -Path HKLM:\SOFTWARE\Microsoft\Teams -Name 'IsWVDEnvironment' -PropertyType 'Dword' -Value 1
 
 # Install Visual C++
 $appName = 'teams'
 $drive = 'C:\'
 New-Item -Path $drive -Name $appName  -ItemType 'Directory' -ErrorAction 'SilentlyContinue'
 $LocalPath = $drive + '\' + $appName 
 set-Location $LocalPath
 $visCplusURL = 'https://aka.ms/vs/16/release/vc_redist.x64.exe'
 $visCplusURLexe = 'vc_redist.x64.exe'
 $outputPath = $LocalPath + '\' + $visCplusURLexe
 Invoke-WebRequest -Uri $visCplusURL -OutFile $outputPath
 Start-Process -FilePath $outputPath -Args "/install /quiet /norestart /log vcdist.log" -Wait
 
 # Install Teams WebSocket Service
 $webSocketsURL = 'https://query.prod.cms.rt.microsoft.com/cms/api/am/binary/RE4AQBt'
 $webSocketsInstallerMsi = 'webSocketSvc.msi'
 $outputPath = $LocalPath + '\' + $webSocketsInstallerMsi
 Invoke-WebRequest -Uri $webSocketsURL -OutFile $outputPath
 Start-Process -FilePath msiexec.exe -Args "/I $outputPath /quiet /norestart /log webSocket.log" -Wait
 
 # Install Teams
 $teamsURL = 'https://teams.microsoft.com/downloads/desktopurl?env=production&plat=windows&arch=x64&managedInstaller=true&download=true'
 $teamsMsi = 'teams.msi'
 $outputPath = $LocalPath + '\' + $teamsMsi
 Invoke-WebRequest -Uri $teamsURL -OutFile $outputPath
 Start-Process -FilePath msiexec.exe -Args "/I $outputPath /quiet /norestart /log teams.log ALLUSER=1 ALLUSERS=1" -Wait