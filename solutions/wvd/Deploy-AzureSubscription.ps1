Param(

    #The first node in the domain name (i.e. jasonmasten.com)
    [Parameter(Mandatory=$true)]
    [string]$Domain,

    #An abbreviated version of the domain name
    #Used for naming external resources (i.e. key vault, storage account, automation account)
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
    [ValidateSet("eastus", "usgovvirginia")]
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
# Template Parameter Object
#############################################################
$Context = Get-AzContext
$Username = $Context.Account.Id.Split('@')[0]
$TimeStamp = Get-Date -F 'yyyyMMddhhmmss'
$Name =  $Username + '_' + $TimeStamp
$Locations = switch($Location)
{
    eastus {@('eastus','westus2')}
    usgovvirginia {@('usgovvirginia','usgovarizona')}
}
$LocationAbbreviations = switch($Location)
{
    eastus {@('eus','wus')}
    usgovvirginia {@('usv','usa')}
}
$AutomationLocations = switch($Location)
{
    eastus {@('eastus2','westus2')}
    usgovvirginia {@('usgovvirginia','usgovarizona')}
}
$StorageAccount = (Get-AzResource -ResourceType Microsoft.Storage/storageAccounts | Where-Object {$_.ResourceGroupName -eq $('rg-shared-' + $Environment + '-' + $Location)}).Name
$Netbios = $Domain.Split('.')[0]

$Params = @{}       
$Params.Add("Domain", $Domain)
$Params.Add("DomainAbbreviation", $DomainAbbreviation)
$Params.Add("Environment", $Environment)
$Params.Add("Locations", $Locations)
$Params.Add("LocationAbbreviations", $LocationAbbreviations)
$Params.Add("Netbios", $Netbios)
$Params.Add("StorageAccount", $StorageAccount)
$Params.Add("Username", $UserName)


#############################################################
# Deployment
#############################################################
try 
{
    New-AzSubscriptionDeployment `
        -Name $Name `
        -Location $Location `
        -TemplateFile '.\subscription.json' `
        -TemplateParameterObject $Params `
        -ErrorAction Stop `
        -Verbose
}
catch 
{
    Write-Host "Deployment Failed: $Name"
    $_ | Select-Object *
}