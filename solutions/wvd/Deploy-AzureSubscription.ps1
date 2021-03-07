Param(

    #The first node in the domain name (e.g., jasonmasten.com)
    [Parameter(Mandatory=$true)]
    [string]$Domain,

    #An abbreviated version of the domain name
    #Used for naming external resources (e.g., key vault, storage account, automation account)
    [Parameter(Mandatory=$true)]
    [string]$DomainAbbreviation,

    #An abbreviated version of the environment
    #d = development
    #p = production
    #t = test
    [Parameter(Mandatory=$true)]
    [ValidateSet("d", "p", "t")]
    [string]$Environment,

    [Parameter(Mandatory=$true)]
    [int]$HostCount,

    #Primary Azure Region
    [Parameter(Mandatory=$true)]
    [string]$Location,

    [parameter(Mandatory=$true)]
    [string]$SubscriptionId
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
# Variables
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
$Params.Add("Environment", $Environment)
$Params.Add("HostCount", $HostCount)
$Params.Add("Location", $Location)
$Params.Add("Username", $UserName)


#############################################################
# Deployment
#############################################################
try 
{
    New-AzSubscriptionDeployment `
        -Name $Name `
        -Location $Location `
        -TemplateUri 'https://raw.githubusercontent.com/jamasten/Azure/master/solutions/wvd/subscription.json' `
        -TemplateParameterObject $Params `
        -ErrorAction Stop `
        -Verbose
}
catch 
{
    $_ | Select-Object *
}