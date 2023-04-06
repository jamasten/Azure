# Execute the Virtual Desktop Optimization Tool (VDOT)
# https://github.com/The-Virtual-Desktop-Team/Virtual-Desktop-Optimization-Tool
$ErrorActionPreference = 'Stop'
try
{
    # Set Exectuion Policy
    Set-ExecutionPolicy -ExecutionPolicy 'RemoteSigned' -Scope 'Process'
    Write-Host 'Set the Execution Policy'

    # Disable the "Configuring Network Adapter Buffer Size" configuration
    $Path = 'C:\temp\Virtual-Desktop-Optimization-Tool-main\Windows_VDOT.ps1'
    $Script = Get-Content -Path $Path
    $ScriptUpdate = $Script -replace 'Set-NetAdapterAdvancedProperty', '#Set-NetAdapterAdvancedProperty'
    $ScriptUpdate | Set-Content -Path $Path
    Write-Host 'Disabled the "Configuring Network Adapter Buffer Size" configuration'

    # Run VDOT
    & C:\temp\Virtual-Desktop-Optimization-Tool-main\Windows_VDOT.ps1 -Optimizations 'AppxPackages','Autologgers','DefaultUserSettings','LGPO','NetworkOptimizations','ScheduledTasks','Services','WindowsMediaPlayer' -AdvancedOptimizations 'Edge','RemoveLegacyIE' -AcceptEULA
    Write-Host 'Optimized the operating system using the Virtual Desktop Optimization Tool'
}
catch 
{
    Write-Host $_
    throw
}