Param(

    #The first node in the domain name (i.e. jasonmasten.com)
    [Parameter(Mandatory=$true)]
    [string]$Domain,

    #An abbreviated version of the domain name
    #Used for naming external resources (i.e. key vault, storage account, automation account)
    [Parameter(Mandatory=$true)]
    [string]$DomainAbbreviation,

    [Parameter(Mandatory=$true)]
    [ValidateSet("dev", "prod", "qa", "sandbox", "shared", "stage", "test")]
    [string]$Environment, 

    #Primary Azure Region
    [Parameter(Mandatory=$true)]
    [ValidateScript({(Get-AzLocation | Select-Object -ExpandProperty Location) -contains $_})]
    [string]$LocationPrimary,

    #Secondary Azure Region for BCDR
    [Parameter(Mandatory=$true)]
    [ValidateScript({(Get-AzLocation | Select-Object -ExpandProperty Location) -contains $_})]
    [string]$LocationSecondary, 
  
    #Storage Account SKU: (p)remium or (s)tandard
    [Parameter(Mandatory=$true)]
    [ValidateSet("p", "s")]
    [string]$PerformanceType, 
    
    [parameter(Mandatory=$true)]
    [string]$SubscriptionId,

    [Parameter(Mandatory)]
    [String]$VmPassword,

    [Parameter(Mandatory)]
    [String]$VmUsername

)

#############################################################
# Authenticate to Azure
#############################################################
if(!(Get-AzSubscription | Where-Object {$_.Id -eq $SubscriptionId}))
{
    Connect-AzAccount `
        -Subscription $SubscriptionId `
        -UseDeviceAuthentication
}


#############################################################
# Set Subscription Context
#############################################################
if(!(Get-AzContext | Where-Object {$_.Subscription.Id -eq $SubscriptionId}))
{
    Set-AzContext -Subscription $SubscriptionId
}


#############################################################
# Load functions
#############################################################
. ..\utilities\functions.ps1


#############################################################
# Variables
#############################################################
# Gets User Principal for Key Vault Access Policy
$UserObjectId = (Get-AzADUser | Where-Object {$_.UserPrincipalName -like "$((Get-AzContext).Account.Id.Split('@')[0])*"}).Id

# Sets user details for deployment name and Security Center contact
$Context = Get-AzContext
$Username = $Context.Account.Id.Split('@')[0]
$Email = $Context.Account.Id
$TimeStamp = Get-Date -F 'yyyyMMddhhmmss'
$Name =  $Username + '_' + $TimeStamp
$SecureVmPassword = ConvertTo-SecureString -String $VmPassword -AsPlainText -Force
$HomePip = Get-PublicIpAddress


#############################################################
# Template Parameter Object
#############################################################
$VSE = @{
    Domain = $Domain
    DomainAbbreviation = $DomainAbbreviation;
    Environment = $Environment;
    HomePip = $HomePip.Trim();
    Locations = @($LocationPrimary, $LocationSecondary);
    PerformanceType = $PerformanceType;
    SecurityDistributionGroup = $Email
    UserObjectId = $UserObjectId
    Username = $Username
}
$VSE.Add("VmPassword", $SecureVmPassword) # Secure Strings must use Add Method for proper deserialization
$VSE.Add("VmUsername", $VmUsername) # Secure Strings must use Add Method for proper deserialization


#############################################################
# Deployment
#############################################################
try 
{
    New-AzSubscriptionDeployment `
        -Name $Name `
        -Location $VSE.Locations[0] `
        -TemplateFile '.\subscription.json' `
        -TemplateParameterObject $VSE `
        -ErrorAction Stop `
        -Verbose
}
catch 
{
    Write-Host "Deployment Failed: $Name"
    $_ | Select-Object *
}