# Install Teams in per-machine mode for Windows multi-session operating systems
# This script was developed to install Teams using Azure Image Builder

function Write-Log
{
    param(
        [parameter(Mandatory)]
        [string]$Message,
        
        [parameter(Mandatory)]
        [string]$Type
    )
    $Timestamp = Get-Date -Format 'MM/dd/yyyy HH:mm:ss.ff'
    $Entry = '[' + $Timestamp + '] [' + $Type + '] ' + $Message
    Write-Host $Entry
}

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
        Write-Log -Message "Added registry setting: $LogOutputValue" -Type 'INFO'
    }
    # Updates the registry setting when it already exists
    elseif($Value.$($Name) -ne $Value)
    {
        Set-ItemProperty -Path $Path -Name $Name -Value $Value -Force
        Write-Log -Message "Updated registry setting: $LogOutputValue" -Type 'INFO'
    }
    # Writes log output when registry setting has the correct value
    else 
    {
        Write-Log -Message "Registry setting exists with correct value: $LogOutputValue" -Type 'INFO'    
    }
    Start-Sleep -Seconds 1
}

try 
{
    # Set registry setting for AVD Media Optimization
    Set-RegistrySetting -Name 'IsWVDEnvironment' -Path 'HKLM:\SOFTWARE\Microsoft\Teams' -PropertyType 'Dword' -Value 1

    # Install Visual C++
    $URL = 'https://aka.ms/vs/16/release/vc_redist.x64.exe'
    $File = 'C:\temp\vc_redist.x64.exe'
    Invoke-WebRequest -Uri $URL -OutFile $File
    Start-Process -FilePath $File -Args "/install /quiet /norestart /log vcdist.log" -Wait
    Write-Log -Type 'INFO' -Message 'Installed Visual C++'

    # Install Teams WebSocket Service
    $URL = 'https://query.prod.cms.rt.microsoft.com/cms/api/am/binary/RE4AQBt'
    $File = 'C:\temp\webSocketSvc.msi'
    Invoke-WebRequest -Uri $URL -OutFile $File
    Start-Process -FilePath msiexec.exe -Args "/i $File /quiet /qn /norestart /passive /log webSocket.log" -Wait
    Write-Log -Type 'INFO' -Message 'Installed the Teams WebSocket service'

    # Install Teams
    $URL = 'https://teams.microsoft.com/downloads/desktopurl?env=production&plat=windows&arch=x64&managedInstaller=true&download=true'
    $File = 'C:\temp\teams.msi'
    Invoke-WebRequest -Uri $URL -OutFile $File
    Start-Process -FilePath msiexec.exe -Args "/i $File /quiet /qn /norestart /passive /log teams.log ALLUSER=1 ALLUSERS=1" -Wait
    Write-Log -Type 'INFO' -Message 'Installed Teams'
}
catch 
{
    Write-Log -Message $_ -Type 'ERROR'
    throw
}