[Cmdletbinding()]
Param(

    [parameter(Mandatory)]
    [string]
    $Environment,

    [parameter(Mandatory)]
    [string]
    $HostPoolName,

    [parameter(Mandatory)]
    [string]
    $InstallTeams,
    
    [parameter(Mandatory)]
    [string]
    $Optimizations,
    
    [parameter(Mandatory)]
    [string]
    $StorageAccountName

)

.\Add-FslogixSettings.ps1 -Environment $Environment -HostPoolName $HostPoolName -StorageAccountName $StorageAccountName

if($InstallTeams -eq 'true')
{
    .\Install-Teams
}

.\Set-AvdOptimizations.ps1 -Optimizations $Optimizations