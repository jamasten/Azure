<#
MIT License

Copyright (c) 2023 Brandon McMillan

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
#>
#region Prerequisites
$ErrorActionPreference = "Stop"
# Downloads and installs Winget
$testWinget = Get-AppxProvisionedPackage -Online | Where-Object {$_.DisplayName -eq "Microsoft.DesktopAppInstaller"}
if (-not($testWinget))
{
    try
    {
        Write-Output "Installing winget"
        $URI = "https://aka.ms/getwinget"
        $Installer = "$env:SystemDrive\packages\Microsoft.DesktopInstaller.msixbundle"
        Invoke-WebRequest -Uri $URI -OutFile $Installer
        # Installs for Local Session
        Add-AppxPackage $Installer
        # Installs for All Users under System Context
        Add-AppxProvisionedPackage -Online -PackagePath $Installer -SkipLicense
        Start-Sleep -Seconds 60
    }
    catch 
    {
        Write-Error $_
    }
}
else 
{
    Write-Output "Winget is installed.  Continuing."
}
#endregion