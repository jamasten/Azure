#############################################################
# Authentication
#############################################################
$Subscription = 'Visual Studio Enterprise Subscription'
if(!(Get-AzSubscription | Where-Object {$_.Name -eq $Subscription}))
{
    Connect-AzAccount `
        -Subscription $Subscription `
        -UseDeviceAuthentication
}
Set-AzContext -Subscription $Subscription


#############################################################
# Variables
#############################################################
$User = (Get-AzContext).Account.Id.Split('@')[0]
$TimeStamp = Get-Date -F 'yyyyMMddhhmmss'
$Name =  $User + '_' + $TimeStamp
$UserObjectId = 'b3b8d141-7e06-4505-a140-a6fde63b6934'
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
    DomainPrefixAbbreviation = 'jmasten';
    Environment = 'dev';
    Locations = @('eastus','westus');
    PerformanceType = 's';
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