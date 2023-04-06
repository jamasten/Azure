# Install Office 365 in per-machine mode on a Windows x64 multi-session operating system
$ErrorActionPreference = 'Stop'
try 
{
    Start-Process -FilePath 'C:\temp\setup.exe' -ArgumentList "/configure C:\temp\office365x64.xml" -Wait -PassThru | Out-Null
    Write-Host 'Installed Office 365'

    # Mount the default user registry hive
    Start-Process 'reg' -ArgumentList 'load HKU\TempDefault C:\Users\Default\NTUSER.DAT' -Wait -PassThru  | Out-Null
    Write-Host 'Mounted the default user registry hive'

    # Configure default behavior for Office
    Start-Process 'reg' -ArgumentList 'add "HKU\TempDefault\SOFTWARE\Policies\Microsoft\office\16.0\common" /v InsiderSlabBehavior /t REG_DWORD /d 2 /f' -Wait -PassThru  | Out-Null
    Start-Process 'reg' -ArgumentList 'add "HKU\TempDefault\software\policies\microsoft\office\16.0\outlook\cached mode" /v enable /t REG_DWORD /d 1 /f' -Wait -PassThru  | Out-Null
    Start-Process 'reg' -ArgumentList 'add "HKU\TempDefault\software\policies\microsoft\office\16.0\outlook\cached mode" /v syncwindowsetting /t REG_DWORD /d 1 /f' -Wait -PassThru  | Out-Null
    Start-Process 'reg' -ArgumentList 'add "HKU\TempDefault\software\policies\microsoft\office\16.0\outlook\cached mode" /v CalendarSyncWindowSetting /t REG_DWORD /d 1 /f' -Wait -PassThru  | Out-Null
    Start-Process 'reg' -ArgumentList 'add "HKU\TempDefault\software\policies\microsoft\office\16.0\outlook\cached mode" /v CalendarSyncWindowSettingMonths  /t REG_DWORD /d 1 /f' -Wait -PassThru  | Out-Null
    Write-Host 'Configured default behavior for Office'

    #Unmount the default user registry hive
    Start-Process 'reg' -ArgumentList 'unload HKU\TempDefault' -Wait -PassThru  | Out-Null
    Write-Host 'Unmounted the default user registry hive'

    # Set the Office Update UI behavior.
    Start-Process 'reg' -ArgumentList 'add "HKLM\SOFTWARE\Policies\Microsoft\office\16.0\common\officeupdate" /v hideupdatenotifications /t REG_DWORD /d 1 /f' -Wait -PassThru  | Out-Null
    Start-Process 'reg' -ArgumentList 'add "HKLM\SOFTWARE\Policies\Microsoft\office\16.0\common\officeupdate" /v hideenabledisableupdates /t REG_DWORD /d 1 /f' -Wait -PassThru  | Out-Null
    Write-Host 'Set the default update behavior for Office'
}
catch 
{
    Write-Host $_
    throw
}