# Download FSLogix

$ErrorActionPreference = 'Stop'

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
    Write-Host 'Downloaded latest version of FSLogix'

    # Unblock the ZIP file containing FSLogix
    Unblock-File -Path $File
    Write-Host 'Unblocked the ZIP file containing FSLogix'

    # Expand the ZIP file containing FSLogix
    Expand-Archive -LiteralPath $File -DestinationPath 'C:\temp\fslogix' -Force
    Write-Host 'Expanded the ZIP file containing FSLogix'
}
catch 
{
    Write-Host $_
    throw
}