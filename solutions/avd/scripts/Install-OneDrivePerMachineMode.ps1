param(
    [parameter(Mandatory)]
    [string]$TenantId
)

# Create temporary directory to save the installer file
New-Item -Path C:\ -Name Temp -ItemType Directory -ErrorAction SilentlyContinue

# Download the installer
$InstallerURL = 'https://aka.ms/OneDriveWVD-Installer'
$InstallerLocation = 'C:\Temp\OneDriveSetup.exe'
Invoke-WebRequest `
    -Uri $InstallerURL `
    -OutFile $InstallerLocation

# Uninstall default, per user installation of OneDrive
Start-Process -FilePath $InstallerLocation -Args "/uninstall" -Wait

# Set registry setting for OneDrive in Per Machine Mode
New-ItemProperty -Path 'HKLM\Software\Microsoft\OneDrive' -Name 'AllUsersInstall' -PropertyType 'Dword' -Value 1

# Install OneDrive in Per Machine Mode
Start-Process -FilePath $InstallerLocation -Args "/allusers" -Wait

# Configures OneDrive to start at sign in for all users
New-ItemProperty -Path 'HKLM\Software\Microsoft\Windows\CurrentVersion\Run' -Name 'AllUsersInstall' -PropertyType 'String' -Value 'C:\Program Files (x86)\Microsoft OneDrive\OneDrive.exe /background'

# Silently configures user accounts
New-ItemProperty -Path 'HKLM\SOFTWARE\Policies\Microsoft\OneDrive' -Name 'SilentAccountConfig' -PropertyType 'Dword' -Value 1

# Redirect and move Windows known folders to OneDrive
New-ItemProperty -Path 'HKLM\SOFTWARE\Policies\Microsoft\OneDrive' -Name 'KFMSilentOptIn' -PropertyType 'String' -Value $TenantId