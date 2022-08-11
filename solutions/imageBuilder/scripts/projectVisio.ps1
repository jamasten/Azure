$ErrorActionPreference = 'Stop'

try 
{
    Invoke-WebRequest -Uri 'https://stshdsvcdeu000.blob.core.windows.net/artifacts/office.zip' -OutFile 'Office.zip'
    Expand-Archive -LiteralPath '.\Office.zip' -Force
    Start-Process -FilePath '.\Office\setup.exe' -ArgumentList "/configure .\Office\configuration-Office365-x64.xml" -Wait -PassThru
}
catch 
{
    Write-Host $_
    throw
}