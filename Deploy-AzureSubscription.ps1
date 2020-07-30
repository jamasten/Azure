#############################################################
# Authentication
#############################################################
$Subscription = 'Visual Studio Enterprise Subscription'
Import-Module -Name Az
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
    PerformanceType = 'p';
    ResourceGroups = @('identity','network','shared','wvd');
    Subnets = $Subnets
    User = $User
    UserObjectId = 'b3b8d141-7e06-4505-a140-a6fde63b6934'
}
$VSE.Add("VmPassword", $VmPassword) # Secure Strings must use Add Method for proper deserialization
$VSE.Add("VmUsername", $VmUsername) # Secure Strings must use Add Method for proper deserialization


#############################################################
# Deployment
#############################################################
try 
{
  New-AzSubscriptionDeployment `
    -Name $Name `
    -Location 'eastus' `
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