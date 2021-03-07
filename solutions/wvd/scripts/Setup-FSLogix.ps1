$ErrorActionPreference = "Stop"

$Path = 'C:\Temp'

New-Item -Path C:\ -Name 'Temp' -ItemType Directory -Force

Set-Location -Path $Path

$Installed = Get-WmiObject -Class Win32_Product | Where-Object {$_.Name -eq 'Microsoft FSLogix Apps'}
if($Installed.Count -eq 0)
{
    Invoke-WebRequest -UseBasicParsing -Uri 'https://aka.ms/fslogix_download' -OutFile $($Path + '\FSlogix.zip')

    Expand-Archive -Path $($Path + '\FSlogix.zip')

    Start-Process -FilePath 'C:\Temp\FSlogix\x64\Release\FSLogixAppsSetup.exe' -ArgumentList "/install","/quiet" -Wait | Out-Null
}

Start-Process -FilePath 'C:\Windows\System32\gpupdate.exe' -ArgumentList "/force" -Wait | Out-Null