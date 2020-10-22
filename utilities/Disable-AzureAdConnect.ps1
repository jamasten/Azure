# TIP: Use the Global Admin account used to setup AD Connect

Param(

    [string] [Paramter(Mandatory=$true)] $TenantId

)

if(!(Get-Module -ListAvailable | Where-Object {$_.Name -eq 'MSOnline'}))
{
    Install-Module -Name MSOnline -AllowClobber -Force
}

if(!(Get-MsolDomain -ErrorAction SilentlyContinue))
{
    Connect-MsolService -AzureEnvironment AzureCloud
}

Set-MsolDirSyncEnabled -TenantId $TenantId -EnableDirSync $false -Force