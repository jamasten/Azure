$ErrorActionPreference = "Stop"

$Path = 'C:\Temp'

New-Item -Path C:\ -Name 'Temp' -ItemType Directory

Set-Location -Path $Path

Invoke-WebRequest -UseBasicParsing -Uri 'https://aka.ms/fslogix_download' -OutFile $($Path + '\FSlogix.zip')

Expand-Archive -Path $($Path + '\FSlogix.zip')

Start-Process -FilePath 'C:\Temp\FSlogix\x64\Release\FSLogixAppsSetup.exe' -ArgumentList "/install","/quiet" -Wait | Out-Null

Remove-Item -Path $Path -Recurse -Force

Start-Process -FilePath 'C:\Windows\System32\gpupdate.exe' -ArgumentList "/force" -Wait | Out-Null