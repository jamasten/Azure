Param(

    #An abbreviated version of the domain name
    #Used for naming external resources (i.e. key vault, storage account, automation account)
    [Parameter(Mandatory=$true)]
    [string]$DomainPrefixAbbreviation,

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
  
    #Storage Account SKU
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
$User = (Get-AzADUser | Where-Object {$_.UserPrincipalName -like "$((Get-AzContext).Account.Id.Split('@')[0])*"}).Id
$TimeStamp = Get-Date -F 'yyyyMMddhhmmss'
$Name =  $User + '_' + $TimeStamp
$ResourceGroups = @('identity','network','shared','wvd');
$Subnets = @(
    @{
        "Name" = "shared";
        "AddressPrefix" = "10.0.0.0/24";
    },
    @{
        "Name" = "servers";
        "AddressPrefix" = "10.0.1.0/24";
    },
    @{
        "Name" = "wvd";
        "AddressPrefix" = "10.0.2.0/24";
    }
)
$VmUsername = Read-Host -Prompt 'Enter Virtual Machine Username' -AsSecureString
$VmPassword = Read-Host -Prompt 'Enter virtual Machine Password' -AsSecureString
$VSE = @{
    DomainPrefixAbbreviation = $DomainPrefixAbbreviation;
    Environment = $Environment;
    Locations = @($LocationPrimary, $LocationSecondary);
    PerformanceType = $PerformanceType;
    Subnets = $Subnets;
    User = $User
}
$VSE.Add("VmPassword", $VmPassword) # Secure Strings must use Add Method for proper deserialization
$VSE.Add("VmUsername", $VmUsername) # Secure Strings must use Add Method for proper deserialization


#############################################################
# Create Resource Groups
#############################################################
# Resource Groups must be created in PS b/c the KEK can only be created in PS
foreach ($Location in $VSE.Locations) 
{
    foreach ($Group in $ResourceGroups) 
    {
        try 
        {
            New-AzResourceGroup `
                -Name $('rg-' + $Group + '-' + $VSE.Environment + '-' + $Location) `
                -Location $Location `
                -Force `
                -ErrorAction Stop | Out-Null    
        }
        catch 
        {
            $_ | Select-Object *
        }
    }
}


#############################################################
# Create Key Vault & KEK
#############################################################
# KEK cannot be created via ARM template
$KeyVault = $('kv' + $VSE.DomainPrefixAbbreviation + $VSE.Environment + $VSE.Locations[0])
$KeyVaultResourceGroup = $('rg-shared-' + $VSE.Environment + '-' + $VSE.Locations[0])

New-AzKeyvault `
    -Name $KeyVault `
    -ResourceGroupName $KeyVaultResourceGroup `
    -Location $VSE.Locations[0] `
    -EnabledForDiskEncryption `
    -EnabledForDeployment `
    -EnabledForTemplateDeployment `
    -DisableSoftDelete `
    -WarningAction SilentlyContinue

Set-AzKeyVaultAccessPolicy `
    -VaultName $KeyVault `
    -ResourceGroupName $KeyVaultResourceGroup `
    -ObjectId $UserObjectId `
    -PermissionsToKeys encrypt,decrypt,wrapKey,unwrapKey,sign,verify,get,list,create,update,import,delete,backup,restore,recover,purge `
    -PermissionsToSecrets get,list,set,delete,backup,restore,recover,purge

Add-AzKeyVaultKey `
    -Name "DiskEncryption" `
    -VaultName $KeyVault `
    -Destination "Software"

$KeyEncryptionKeyURL = (Get-AzKeyVaultKey `
    -VaultName $KeyVault `
    -Name 'DiskEncryption' `
    -IncludeVersions | Where-Object {$_.Enabled -eq $true}).Id

$VSE.Add("KeyEncryptionKeyURL", $KeyEncryptionKeyURL)


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