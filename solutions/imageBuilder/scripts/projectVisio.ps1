$ErrorActionPreference = 'Stop'

try 
{
    Connect-AzAccount -Environment 'AzureCloud' -Identity
    Get-AzStorageBlobContent -AbsoluteUri 'https://stshdsvcdeu000.blob.core.windows.net/artifacts/office.zip' -Destination 'office.zip'
    #Invoke-WebRequest -Uri 'https://stshdsvcdeu000.blob.core.windows.net/artifacts/office.zip' -OutFile 'Office.zip'
    Expand-Archive -LiteralPath '.\office.zip' -Force
    Start-Process -FilePath '.\office\setup.exe' -ArgumentList "/configure .\office\configuration-Office365-x64.xml" -Wait -PassThru
}
catch 
{
    Write-Host $_
    throw
}