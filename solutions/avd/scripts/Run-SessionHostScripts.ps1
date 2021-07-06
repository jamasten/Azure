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
    $InstallOneDrivePerMachineMode,

    [parameter(Mandatory)]
    [string]
    $InstallTeams,
    
    [parameter(Mandatory)]
    [string]
    $Optimizations,
    
    [parameter(Mandatory)]
    [string]
    $StorageAccountName,

    [parameter(Mandatory)]
    [string]
    $TenantId

)

.\Add-FslogixSettings.ps1 -Environment $Environment -HostPoolName $HostPoolName -StorageAccountName $StorageAccountName

if($InstallOneDrivePerMachineMode -eq 'true')
{
    .\Install-OneDrivePerMachineMode -TenantId $TenantId
}

if($InstallTeams -eq 'true')
{
    .\Install-Teams
}

.\Set-AvdOptimizations.ps1 -Optimizations $Optimizations