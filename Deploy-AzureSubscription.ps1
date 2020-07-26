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
$User = (Get-AzContext).Account.Id
$TimeStamp = Get-Date -F 'yyyyMMddhhmmss'
$Name =  $User.Split('@')[0] + '_' + $TimeStamp
$UserObjectId = (Get-AzADUser -UserPrincipalName $User).Id
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
    -SubnetId "[parameters('SubnetId')]" `
    -LocationFromTemplate 'eastus' `
    -VmUsername $VmUsername `
    -VmPassword $VmPassword `
}
catch 
{
    Write-Host "Deployment Failed: $Name"
    $_ | Select-Object *
}