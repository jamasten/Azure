[Cmdletbinding()]
Param(

    [parameter(Mandatory)]
    [string]
    $MicrosoftMonitoringAgent,

    [parameter(Mandatory)]
    [string]
    $SentinelWorkspaceId,

    [parameter(Mandatory)]
    [string]
    $SentinelWorkspaceKey

)

$ErrorActionPreference = 'Stop'

try
{
    ##############################################################
    #  Logging Function
    ##############################################################
    function Write-Log
    {
        param(
            [parameter(Mandatory)]
            [string]$Message,
            
            [parameter(Mandatory)]
            [string]$Type
        )
        $Path = 'C:\cse.txt'
        if(!(Test-Path -Path $Path))
        {
            New-Item -Path 'C:\' -Name 'cse.txt' | Out-Null
        }
        $Timestamp = Get-Date -Format 'MM/dd/yyyy HH:mm:ss.ff'
        $Entry = '[' + $Timestamp + '] [' + $Type + '] ' + $Message
        $Entry | Out-File -FilePath $Path -Append
    }


    ##############################################################
    #  Dual-home Microsoft Monitoring Agent for Azure Sentinel
    ##############################################################
    if($MicrosoftMonitoringAgent -eq 'true' -and $SentinelWorkspaceId -ne 'NotApplicable' -and $SentinelWorkspaceKey -ne 'NotApplicable')
    {
        $mma = New-Object -ComObject 'AgentConfigManager.MgmtSvcCfg'
        $mma.AddCloudWorkspace($SentinelWorkspaceId, $SentinelWorkspaceKey)
        $mma.ReloadConfiguration()
        Write-Log -Message 'Dual-homed the Microsoft Monitoring Agent for Azure Sentinel' -Type 'INFO'
    }


    ##############################################################
    #  Run the Virtual Desktop Optimization Tool (VDOT)
    ##############################################################
    # https://github.com/The-Virtual-Desktop-Team/Virtual-Desktop-Optimization-Tool

    # Extract VDOT from ZIP archive
    Expand-Archive -LiteralPath 'main.zip' -Force
    Write-Log -Message 'Expanded the ZIP archive for the Virtual Desktop Optimization Tool' -Type 'INFO'
        
    # Run VDOT
    & .\main\Virtual-Desktop-Optimization-Tool-main\Windows_VDOT.ps1 -Optimizations All -AcceptEULA -Restart
    Write-Log -Message 'Ran the Virtual Desktop Optimization Tool' -Type 'INFO'

}
catch
{
    Write-Log -Message $_ -Type 'ERROR'
    throw
}