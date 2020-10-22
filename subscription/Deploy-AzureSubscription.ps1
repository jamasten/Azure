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
    [ValidateSet("eastus", "usgovvirginia")]
    [string]$LocationPrimary,

    #Secondary Azure Region for BCDR
    [Parameter(Mandatory=$true)]
    [ValidateSet("westus2", "usgovarizona")]
    [string]$LocationSecondary, 
  
    #Storage Account SKU: (p)remium or (s)tandard
    [Parameter(Mandatory=$true)]
    [ValidateSet("p", "s")]
    [string]$PerformanceType, 
    
    [parameter(Mandatory=$true)]
    [string]$SubscriptionId
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
$Credential = Get-Credential -Message 'Input Azure VM credentials'
$AutomationLocationPrimary = switch($LocationPrimary)
{
    eastus {'eastus2'}
    usgovvirginia {'usgovvirginia'}
}
$AutomationLocationSecondary = switch($LocationSecondary)
{
    westus2 {'westus2'}
    usgovarizona {'usgovarizona'}
}


#############################################################
# Add Azure AD Connect Account
#############################################################
$UPN = 'adconnect@' + $Domain
$test = Get-AzADUser -UserPrincipalName $UPN -ErrorAction SilentlyContinue
if(!$test)
{
    New-AzADUser -DisplayName 'AD Connect' -UserPrincipalName $UPN -Password $Credential.Password -MailNickname 'ADConnect'
}


#############################################################
# Template Parameter Object
#############################################################
$VSE = @{
    AutomationLocationPrimary = $AutomationLocationPrimary
    AutomationLocationSecondary = $AutomationLocationSecondary
    Domain = $Domain
    DomainAbbreviation = $DomainAbbreviation
    Environment = $Environment
    Locations = @($LocationPrimary, $LocationSecondary)
    PerformanceType = $PerformanceType
    SecurityDistributionGroup = $Email
    UserObjectId = $UserObjectId
    Username = $Username
}
$VSE.Add("VmPassword", $Credential.Password) # Secure Strings must use Add Method for proper deserialization
$VSE.Add("VmUsername", $Credential.UserName) # Secure Strings must use Add Method for proper deserialization


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