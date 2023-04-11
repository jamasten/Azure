# Download FSLogix

$ErrorActionPreference = 'Stop'

try 
{
    # Download the latest version of FSLogix
    $URL = 'https://aka.ms/fslogix_download'
    $ZIP = 'C:\temp\fslogix.zip'
    Invoke-WebRequest -Uri $URL -OutFile $File
    Write-Host 'Downloaded latest version of FSLogix'

    # Unblock the ZIP file containing FSLogix
    Unblock-File -Path $ZIP
    Write-Host 'Unblocked the ZIP file containing FSLogix'

    # Expand the ZIP file containing FSLogix
    Expand-Archive -LiteralPath $ZIP -DestinationPath 'C:\temp\fslogix' -Force
    Write-Host 'Expanded the ZIP file containing FSLogix'
}
catch 
{
    Write-Host $_
    throw
}