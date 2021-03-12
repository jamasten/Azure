Param(

    #The first node in the domain name (i.e. jasonmasten.com)
    [Parameter(Mandatory=$true)]
    [string]$Domain,

    #An abbreviated version of the domain name
    #Used for naming external resources (i.e. key vault, storage account, automation account)
    [Parameter(Mandatory=$true)]
    [string]$DomainAbbreviation,

    #An abbreviated version of the environment
    #d = development
    #p = production
    #t = test
    [Parameter(Mandatory=$true)]
    [ValidateSet("d", "p", "t")]
    [string]$Environment, 

    #Primary Azure Region
    [Parameter(Mandatory=$true)]
    [ValidateSet("eastus", "usgovvirginia")]
    [string]$Location,
    
    [parameter(Mandatory=$true)]
    [string]$SubscriptionId
)

#############################################################
# Authenticate to Azure
#############################################################
Connect-AzAccount -Subscription $SubscriptionId


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
$Params = @{
    Domain = $Domain
    DomainAbbreviation = $DomainAbbreviation
    Environment = $Environment
    Location = $Location
    TimeStamp = $TimeStamp
    UserObjectId = $UserObjectId
    Username = $Username
}
$Params.Add("VmPassword", $Credential.Password) # Secure Strings must use Add Method for proper deserialization
$Params.Add("VmUsername", $Credential.UserName) # Secure Strings must use Add Method for proper deserialization


#############################################################
# Deployment
#############################################################
New-AzSubscriptionDeployment `
    -Name $Name `
    -Location $Location `
    -TemplateFile '.\subscription.json' `
    -TemplateParameterObject $Params `
    -Verbose