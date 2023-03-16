# Install FSLogix on a Windows x64 multi-session operating system
# This script was developed to install FSLogix using Azure Image Builder

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

try 
{    
    # Download the latest version of FSLogix
    $LandingPage = Invoke-WebRequest -Uri 'https://aka.ms/fslogix-latest'
    $DownloadButtonUrlSuffix = $LandingPage.Links | Where-Object {$_.href -like "confirmation.aspx?id=*"} | Select-Object -ExpandProperty 'href'
    $DownloadButtonUrl = 'https://www.microsoft.com/en-us/download/' + $DownloadButtonUrlSuffix
    $DownloadPage = Invoke-WebRequest -Uri $DownloadButtonUrl
    $URL = $DownloadPage.Links | Where-Object {$_.href -like "https://download.microsoft.com/download/*"} | Select-Object -ExpandProperty 'href' -First 1
    $File = 'C:\temp\fslogix.zip'
    Invoke-WebRequest -Uri $URL -OutFile $File
    Write-Log -Type 'INFO' -Message 'Downloaded latest version of FSLogix'

    # Unblock the ZIP file containing FSLogix
    Unblock-File -Path $File
    Write-Log -Type 'INFO' -Message 'Unblocked the ZIP file containing FSLogix'

    # Expand the ZIP file containing FSLogix
    Expand-Archive -LiteralPath $File -DestinationPath 'C:\temp\fslogix' -Force
    Write-Log -Type 'INFO' -Message 'Expanded the ZIP file containing FSLogix'

    # Install FSLogix silently
    Start-Process -FilePath 'C:\temp\fslogix\x64\Release\FSLogixAppsSetup.exe' -ArgumentList "/install /quiet" -Wait -PassThru
    Write-Log -Type 'INFO' -Message 'Installed FSLogix'
}
catch 
{
    Write-Log -Message $_ -Type 'ERROR'
    throw
}