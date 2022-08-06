##############################################################
#  Virtual Desktop Optimization Tool (VDOT)
##############################################################
# https://github.com/The-Virtual-Desktop-Team/Virtual-Desktop-Optimization-Tool

$ErrorActionPreference = 'Stop'

try
{
    # Download VDOT
    $URL = 'https://github.com/The-Virtual-Desktop-Team/Virtual-Desktop-Optimization-Tool/archive/refs/heads/main.zip'
    $ZIP = 'VDOT.zip'
    Invoke-WebRequest -Uri $URL -OutFile $ZIP
    Write-Host 'Downloaded VDOT'
    
    # Extract VDOT from ZIP archive
    Expand-Archive -LiteralPath $ZIP -Force
    Write-Host 'Extracted VDOT'
    
    # Fix to disable AppX Packages
    # As of 2/8/22, all AppX Packages are enabled by default
    $Files = (Get-ChildItem -Path .\VDOT\Virtual-Desktop-Optimization-Tool-main -File -Recurse -Filter "AppxPackages.json").FullName
    foreach($File in $Files)
    {
        $Content = Get-Content -Path $File
        $Settings = $Content | ConvertFrom-Json
        $NewSettings = @()
        foreach($Setting in $Settings)
        {
            $NewSettings += [pscustomobject][ordered]@{
                AppxPackage = $Setting.AppxPackage
                VDIState = 'Disabled'
                URL = $Setting.URL
                Description = $Setting.Description
            }
        }

        $JSON = $NewSettings | ConvertTo-Json
        $JSON | Out-File -FilePath $File -Force
    }
    Write-Host 'Set VDOT AppxPackage configuration files to "Disabled"'

    # Run VDOT
    & .\VDOT\Virtual-Desktop-Optimization-Tool-main\Windows_VDOT.ps1 -AcceptEULA
    Write-Host 'Optimized the operating system using VDOT'
}
catch 
{
    Write-Host $_
    throw
}