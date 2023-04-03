# Install Office 365 in per-machine mode on a Windows x64 multi-session operating system
# This script was developed to install Office 365 using Azure Image Builder

$ErrorActionPreference = 'Stop'

function Set-RegistrySetting 
{
    Param(
        [parameter(Mandatory=$false)]
        [String]$Name,

        [parameter(Mandatory=$false)]
        [String]$Path,

        [parameter(Mandatory=$false)]
        [String]$PropertyType,

        [parameter(Mandatory=$false)]
        [String]$Value
    )

    # Create registry key(s) if necessary
    if(!(Test-Path -Path $Path))
    {
        New-Item -Path $Path -Force
    }

    # Checks for existing registry setting
    $Value = Get-ItemProperty -Path $Path -Name $Name -ErrorAction 'SilentlyContinue'
    $LogOutputValue = 'Path: ' + $Path + ', Name: ' + $Name + ', PropertyType: ' + $PropertyType + ', Value: ' + $Value
    
    # Creates the registry setting when it does not exist
    if(!$Value)
    {
        New-ItemProperty -Path $Path -Name $Name -PropertyType $PropertyType -Value $Value -Force
        Write-Host "Added registry setting: $LogOutputValue"
    }
    # Updates the registry setting when it already exists
    elseif($Value.$($Name) -ne $Value)
    {
        Set-ItemProperty -Path $Path -Name $Name -Value $Value -Force
        Write-Host "Updated registry setting: $LogOutputValue"
    }
    # Writes log output when registry setting has the correct value
    else 
    {
        Write-Host "Registry setting exists with correct value: $LogOutputValue"
    }
    Start-Sleep -Seconds 1
}

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
    Start-Process 'reg' -ArgumentList 'load HKU\TempDefault C:\Users\Default\NTUSER.DAT' -Wait -PassThru
    Write-Host 'Mounted the default user registry hive'

    # Must be executed with the default registry hive mounted.
    Set-RegistrySetting -Name 'InsiderSlabBehavior' -Path 'HKU\TempDefault\SOFTWARE\Policies\Microsoft\office\16.0\common' -PropertyType 'DWord' -Value 2

    # Set Outlook's Cached Exchange Mode behavior
    # Must be executed with default registry hive mounted.
    Set-RegistrySetting -Name 'enable' -Path 'HKU\TempDefault\software\policies\microsoft\office\16.0\outlook\cached mode' -PropertyType 'DWord' -Value 1
    Set-RegistrySetting -Name 'syncwindowsetting' -Path 'HKU\TempDefault\software\policies\microsoft\office\16.0\outlook\cached mode' -PropertyType 'DWord' -Value 1
    Set-RegistrySetting -Name 'CalendarSyncWindowSetting' -Path 'HKU\TempDefault\software\policies\microsoft\office\16.0\outlook\cached mode' -PropertyType 'DWord' -Value 1
    Set-RegistrySetting -Name 'CalendarSyncWindowSettingMonths' -Path 'HKU\TempDefault\software\policies\microsoft\office\16.0\outlook\cached mode' -PropertyType 'DWord' -Value 1

    #Unmount the default user registry hive
    Start-Process 'reg' -ArgumentList 'unload HKU\TempDefault' -Wait -PassThru
    Write-Host 'Unmounted the default user registry hive'

    # Set the Office Update UI behavior.
    Set-RegistrySetting -Name 'hideupdatenotifications' -Path 'HKLM:\SOFTWARE\Policies\Microsoft\office\16.0\common\officeupdate' -PropertyType 'DWord' -Value 1
    Set-RegistrySetting -Name 'hideenabledisableupdates' -Path 'HKLM:\SOFTWARE\Policies\Microsoft\office\16.0\common\officeupdate' -PropertyType 'DWord' -Value 1
}
catch 
{
    Write-Host $_
    throw
}