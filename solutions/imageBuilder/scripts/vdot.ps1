##############################################################
#  Virtual Desktop Optimization Tool (VDOT)
##############################################################
# https://github.com/The-Virtual-Desktop-Team/Virtual-Desktop-Optimization-Tool

$ErrorActionPreference = 'Stop'

try
{
    # Download VDOT
    $URL = 'https://github.com/The-Virtual-Desktop-Team/Virtual-Desktop-Optimization-Tool/archive/refs/heads/main.zip'
    $ZIP = 'C:\temp\VDOT.zip'
    Invoke-WebRequest -Uri $URL -OutFile $ZIP
    Write-Host 'Downloaded the GitHub repository for the Virtual Desktop Optimization Tool'
    
    # Unblock ZIP archive
    Unblock-File -Path $ZIP
    Write-Host 'Unblocked the archive of the Virtual Desktop Optimization Tool'

    # Extract VDOT from ZIP archive
    Expand-Archive -LiteralPath $ZIP -DestinationPath 'C:\temp' -Force
    Write-Host 'Expanded the archive of the Virtual Desktop Optimization Tool'
    
    # Set Exectuion Policy
    Set-ExecutionPolicy -ExecutionPolicy 'RemoteSigned' -Scope 'Process'
    Write-Host 'Set the Execution Policy'

    # Fix to disable AppX Packages
    # As of 2/8/22, all AppX Packages are enabled by default
    $Files = (Get-ChildItem -Path 'C:\temp\Virtual-Desktop-Optimization-Tool-main' -File -Recurse -Filter 'AppxPackages.json').FullName
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
    Write-Host 'Disabled all Appx Packages in the configuration files for the Virtual Desktop Optimization Tool'

    # Disable the "Configuring Network Adapter Buffer Size" configuration
    $Path = 'C:\temp\Virtual-Desktop-Optimization-Tool-main\Windows_VDOT.ps1'
    $Script = Get-Content -Path $Path
    $ScriptUpdate = $Script -replace 'Set-NetAdapterAdvancedProperty', '#Set-NetAdapterAdvancedProperty'
    $ScriptUpdate | Set-Content -Path $Path
    Write-Host 'Disabled the "Configuring Network Adapter Buffer Size" configuration'

    # Run VDOT
    & C:\temp\Virtual-Desktop-Optimization-Tool-main\Windows_VDOT.ps1 -Optimizations 'All' -AdvancedOptimizations 'Edge','RemoveLegacyIE' -AcceptEULA
    Write-Host 'Optimized the operating system using the Virtual Desktop Optimization Tool'
}
catch 
{
    Write-Host $_
    throw
}