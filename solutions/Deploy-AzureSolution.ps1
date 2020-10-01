Param(

    [Parameter(Mandatory=$true)]
    [ValidateSet("dev", "prod", "qa", "sandbox", "shared", "stage", "test")]
    [bool]$DisasterRecovery, 

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

    [parameter(Mandatory=$true)]
    [string]$ResourceGroup,
  
    [parameter(Mandatory=$true)]
    [string]$SubscriptionId,

    [parameter(Mandatory=$true)]
    [string]$TemplateFile
)


#############################################################
# Load functions
#############################################################
. ..\utilities\functions.ps1


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
if(!(Get-AzResourceGroup -Name $ResourceGroup -ErrorAction SilentlyContinue))
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
        -ResourceGroupName $ResourceGroup `
        -TemplateFile $TemplateFile `
        -ErrorAction Stop
        -TemplateParameterObject $VSE `
        -ErrorAction Stop `
        -Verbose
}
catch 
{
    Write-Host "Deployment Failed: $Name"
    $_ | Select-Object *
}