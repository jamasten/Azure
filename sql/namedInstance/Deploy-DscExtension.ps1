Param(
  
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
# Deployment
#############################################################
try 
{
    New-AzResourceGroupDeployment `
        -ResourceGroupName vmsqltest01_group `
        -TemplateFile .\dscExtension.json `
        -ErrorAction Stop
}
catch 
{
    Write-Host "Deployment Failed: $Name"
    $_ | Select-Object *
}