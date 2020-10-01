Param(
    
    [string]$AzureLocation = 'eastus',
    
    [string]$AzureRg = 'rg-dnstest-dev-eastus',

    [string]$AzureSubId = '3764b123-4849-4395-8e6e-ca6d68d8d4b4'

)


#############################################################
# Load functions
#############################################################
. C:\Users\jamasten\GitHub\Azure\utilities\functions.ps1


#############################################################
# Authenticate to Azure
#############################################################
if(!(Get-AzSubscription | Where-Object {$_.Id -eq $AzureSubId}))
{
    Connect-AzAccount `
        -Subscription $AzureSubId `
        -UseDeviceAuthentication
}


#############################################################
# Set Subscription Context
#############################################################
if(!(Get-AzContext | Where-Object {$_.Subscription.Id -eq $AzureSubId}))
{
    Set-AzContext -Subscription $AzureSubId
}


#############################################################
# Variables
#############################################################
$Context = Get-AzContext
$Username = $Context.Account.Id.Split('@')[0]
$TimeStamp = Get-Date -F 'yyyyMMddhhmmss'
$Name =  $Username + '_' + $TimeStamp
$Credential = Get-Credential -Message "Input the credentials for the Azure VM local admin account"
$HomePip = Get-PublicIpAddress
$VSE = @{
    HomePip = $HomePip.Trim()
}
$VSE.Add("VmPassword", $Credential.Password) # Secure Strings must use Add Method for proper deserialization
$VSE.Add("VmUsername", $Credential.UserName)


#############################################################
# Resource Group
#############################################################
if(!(Get-AzResourceGroup -Name $AzureRg -ErrorAction SilentlyContinue))
{
    New-AzResourceGroup -Name $AzureRg -Location $AzureLocation | Out-Null
}


#############################################################
# Deployment
#############################################################
try 
{
    New-AzResourceGroupDeployment `
        -Name $Name `
        -ResourceGroupName $AzureRg `
        -TemplateFile '.\template.json' `
        -TemplateParameterObject $VSE `
        -ErrorAction Stop `
        -Verbose
}
catch 
{
    Write-Host "Deployment Failed: $Name"
    $_ | Select-Object *
}