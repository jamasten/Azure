$ErrorActionPreference = 'Stop'

try 
{
    Expand-Archive -LiteralPath 'C:\temp\office.zip' -Force
    Start-Process -FilePath 'C:\temp\office\setup.exe' -ArgumentList "/configure C:\temp\office\configuration-Office365-x64.xml" -Wait -PassThru
}
catch 
{
    Write-Host $_
    throw
}