[Cmdletbinding()]
Param(
    [Parameter(Mandatory)]
    [string]$HostPoolRegistrationToken
)


$ErrorActionPreference = 'Stop'


##############################################################
#  Function
##############################################################
function Get-WebFile
{
    param(
        [parameter(Mandatory)]
        [string]$FileName,

        [parameter(Mandatory)]
        [string]$URL
    )
    $Counter = 0
    do
    {
        Invoke-WebRequest -Uri $URL -OutFile $FileName -ErrorAction 'SilentlyContinue'
        if($Counter -gt 0)
        {
            Start-Sleep -Seconds 30
        }
        $Counter++
    }
    until((Test-Path $FileName) -or $Counter -eq 9)
}


##############################################################
#  Install AVD Agent
##############################################################
try
{
    $BootInstaller = 'AVD-Bootloader.msi'
    Get-WebFile -FileName $BootInstaller -URL 'https://query.prod.cms.rt.microsoft.com/cms/api/am/binary/RWrxrH'
    Start-Process -FilePath 'msiexec.exe' -ArgumentList "/i $BootInstaller /quiet /qn /norestart /passive" -Wait -Passthru
    Start-Sleep -Seconds 5

    $AgentInstaller = 'AVD-Agent.msi'
    Get-WebFile -FileName $AgentInstaller -URL 'https://query.prod.cms.rt.microsoft.com/cms/api/am/binary/RWrmXv'
    Start-Process -FilePath 'msiexec.exe' -ArgumentList "/i $AgentInstaller /quiet /qn /norestart /passive REGISTRATIONTOKEN=$HostPoolRegistrationToken" -Wait -PassThru
}
catch
{
    Write-Log -Message $_ -Type 'ERROR'
    throw
}