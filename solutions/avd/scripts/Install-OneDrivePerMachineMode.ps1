param(
    [parameter(Mandatory)]
    [string]$TenantId
)

New-Item -Path C:\ -Name Temp -ItemType Directory -ErrorAction SilentlyContinue
$InstallerLocation = 'C:\Temp\OneDriveSetup.exe'
$InstallerURL = 'https://aka.ms/OneDriveWVD-Installer'
Invoke-WebRequest `
    -Uri $OneDriveURL `
    -OutFile $InstallerLocation


Start-Process -FilePath $InstallerLocation -Args "/uninstall" -Wait


New-ItemProperty -Path 'HKLM\Software\Microsoft\OneDrive' -Name 'AllUsersInstall' -PropertyType 'Dword' -Value '1'


Start-Process -FilePath $InstallerLocation -Args "/allusers" -Wait


New-ItemProperty -Path 'HKLM\Software\Microsoft\Windows\CurrentVersion\Run' -Name 'AllUsersInstall' -PropertyType 'String' -Value 'C:\Program Files (x86)\Microsoft OneDrive\OneDrive.exe /background'


New-ItemProperty -Path 'HKLM\SOFTWARE\Policies\Microsoft\OneDrive' -Name 'SilentAccountConfig' -PropertyType 'Dword' -Value '1'


New-ItemProperty -Path 'HKLM\SOFTWARE\Policies\Microsoft\OneDrive' -Name 'KFMSilentOptIn' -PropertyType 'String' -Value $TenantId