# Install OneDrive on a Windows multi-session operating system
$ErrorActionPreference = 'Stop'
try 
{
    # Set "All User Install" registry setting
    & C:\temp\Set-RegistrySetting.ps1 -Name 'AllUsersInstall' -Path 'HKLM:\Software\Microsoft\OneDrive' -PropertyType 'DWord' -Value '1'

    # Install OneDrive is per-machine mode
    Start-Process -FilePath 'C:\temp\OneDrive.exe' -Args "/allusers" -Wait -PassThru | Out-Null
    Write-Host 'Installed OneDrive in per-machine mode'

    # Set "Start at Sign-In" registry setting
    & C:\temp\Set-RegistrySetting.ps1 -Name 'OneDrive' -Path 'HKLM:\Software\Microsoft\Windows\CurrentVersion\Run' -PropertyType 'String' -Value 'C:\Program Files (x86)\Microsoft OneDrive\OneDrive.exe /background'

    # Set "Silently configure user account" registry setting
    & C:\temp\Set-RegistrySetting.ps1 -Name 'SilentAccountConfig' -Path 'HKLM:\SOFTWARE\Policies\Microsoft\OneDrive' -PropertyType 'DWord' -Value '1'

    # Set "Redirect & move known folders" registry setting
    $AzureADTenantID = Get-Content -Path 'C:\temp\tenantId.txt'
    & C:\temp\Set-RegistrySetting.ps1 -Name 'KFMSilentOptIn' -Path 'HKLM:\SOFTWARE\Policies\Microsoft\OneDrive' -PropertyType 'String' -Value "$AzureADTenantID"
}
catch 
{
    Write-Host $_
    throw
}