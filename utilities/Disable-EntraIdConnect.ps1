﻿# TIP: Use the Global Admin account used to setup AD Connect

Param(

    [Paramter(Mandatory=$true)]
    [ValidateSet('Global','China','Germany','USGov','USGovDoD')]
    [string]$Environment,

    [Paramter(Mandatory=$true)]
    [string]$TenantId

)

if(!(Get-Module -ListAvailable | Where-Object {$_.Name -eq 'Microsoft.Graph.Identity.DirectoryManagement'}))
{
    Install-Module -Name 'Microsoft.Graph.Identity.DirectoryManagement' -AllowClobber -Force
}

if(!(Get-MgOrganization -ErrorAction SilentlyContinue))
{
    Connect-MgGraph -Environment $Environment -TenantId $TenantId -Scopes 'Organization.ReadWrite.All'
}

$OrgId = (Get-MgOrganization).id
$Uri = 'https://graph.microsoft.com/v1.0/organization/' + $OrgId
$Body = @{onPremisesSyncEnabled = 'false'} | ConvertTo-Json
Invoke-MgGraphRequest -Uri $Uri -Body $Body -Method 'PATCH'