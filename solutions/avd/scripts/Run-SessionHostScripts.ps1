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
    $Optimizations,
    
    [parameter(Mandatory)]
    [string]
    $StorageAccountName

)

.\Add-FslogixSettings.ps1 -Environment $Environment -HostPoolName $HostPoolName -StorageAccountName $StorageAccountName

.\Set-WvdOptimizations.ps1 -Optimizations $Optimizations