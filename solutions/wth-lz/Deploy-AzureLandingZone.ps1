Param(

    #Input your domain name (i.e. jasonmasten.com)
    [Parameter(Mandatory=$true)]
    [string]$Domain,
    
    [parameter(Mandatory=$true)]
    [string]$SubscriptionId,

    [parameter(Mandatory=$true)]
    [System.Management.Automation.PSCredential]$Credential
)

#############################################################
# Authenticate to Azure
#############################################################
if(!(Get-AzSubscription | Where-Object {$_.Id -eq $SubscriptionId}))
{
    Connect-AzAccount `
        -Subscription $SubscriptionId
}


#############################################################
# Set Subscription Context
#############################################################
if(!(Get-AzContext | Where-Object {$_.Subscription.Id -eq $SubscriptionId}))
{
    Set-AzContext -Subscription $SubscriptionId
}


#############################################################
# Variables used for setting deployment names
#############################################################
$Context = Get-AzContext
$Username = $Context.Account.Id.Split('@')[0]
$TimeStamp = Get-Date -F 'yyyyMMddhhmmss'
$Name =  $Username + '_' + $TimeStamp


#############################################################
# Template Parameter Object
#############################################################
$Params = @{}
$Params.Add("Domain", $Domain)
$Params.Add("Username", $Username)
$Params.Add("VmPassword", $Credential.Password)
$Params.Add("VmUsername", $Credential.UserName)


#############################################################
# Deployment
#############################################################
try 
{
    New-AzSubscriptionDeployment `
        -Name $Name `
        -Location eastus `
        -TemplateUri 'https://raw.githubusercontent.com/jamasten/Azure/master/solutions/wth-lz/subscription.json' `
        -TemplateParameterObject $Params `
        -ErrorAction Stop `
        -Verbose
}
catch 
{
    Write-Host "Deployment Failed: $Name"
    $_ | Select-Object *
}