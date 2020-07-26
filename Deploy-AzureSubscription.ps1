#############################################################
# Authenticate to Azure
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
# Deployment Variables
#############################################################
$User = (Get-AzContext).Account.Id.Split('@')[0]
$TimeStamp = Get-Date -F 'yyyyMMddhhmmss'
$Name =  $User + '_' + $TimeStamp
$UserObjectId = (Get-AzADUser | Where-Object {$_.UserPrincipalName -like "$User*"}).Id
$VmUsername = Read-Host -Prompt 'Enter Virtual Machine Username' -AsSecureString
$VmPassword = Read-Host -Prompt 'Enter virtual Machine Password' -AsSecureString


#############################################################
# Deploy Resources
#############################################################
try 
{
  New-AzSubscriptionDeployment `
    -Name $Name `
    -Location 'eastus' `
    -TemplateFile '.\subscription.json' `
    -UserObjectId $UserObjectId `
    -LocationFromTemplate 'eastus' `
    -VmUsername $VmUsername `
    -VmPassword $VmPassword `
}
catch 
{
    Write-Host "Deployment Failed: $Name"
    $_ | Select-Object *
}