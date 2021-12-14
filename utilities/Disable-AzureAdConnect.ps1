# TIP: Use the Global Admin account used to setup AD Connect

Param(

    [Paramter(Mandatory=$true)]
    [ValidateSet('AzureCloud','AzureUSGovernmentCloud')]
    [string]$Environment,

    [Paramter(Mandatory=$true)]
    [string]$TenantId

)

if(!(Get-Module -ListAvailable | Where-Object {$_.Name -eq 'MSOnline'}))
{
    Install-Module -Name MSOnline -AllowClobber -Force
}

if(!(Get-MsolDomain -ErrorAction SilentlyContinue))
{
    Connect-MsolService -AzureEnvironment $Environment
}

Set-MsolDirSyncEnabled -TenantId $TenantId -EnableDirSync $false -Force