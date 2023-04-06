# Install Office 365 in per-machine mode on a Windows x64 multi-session operating system
# This script was developed to install Office 365 using Azure Image Builder

$ErrorActionPreference = 'Stop'

$OfficeConfiguration = @'
    <Configuration>
        <Add OfficeClientEdition="64" Channel="Current">
            <Product ID="O365ProPlusRetail">
                <Language ID="en-us" />
            </Product>
        </Add>
        <Updates Enabled="FALSE" />
        <Display Level="None" AcceptEULA="TRUE" />
        <Property Name="FORCEAPPSHUTDOWN" Value="TRUE"/>
        <Property Name="SharedComputerLicensing" Value="1"/>
    </Configuration>
'@

try 
{
    # Output Office 365 configuration to an XML file
    $OfficeConfiguration | Out-File -FilePath 'C:\temp\office365x64.xml'
    Write-Host 'Created the XML configuration file for Office 365'

    $URL = 'https://download.microsoft.com/download/2/7/A/27AF1BE6-DD20-4CB4-B154-EBAB8A7D4A7E/officedeploymenttool_16130-20218.exe'
    $File = 'C:\temp\office.exe'
    Invoke-WebRequest -Uri $URL -OutFile $File
    Start-Process -FilePath 'C:\temp\office.exe' -ArgumentList "/extract:C:\temp /quiet /passive /norestart" -Wait -PassThru | Out-Null
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