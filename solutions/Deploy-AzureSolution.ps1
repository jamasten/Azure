Param(

    #[Parameter(Mandatory=$true)]
    [string]$Domain,

    # This is used to uniquely name resources that need to be globally unique (i.e. storage account name)
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
    [ValidateSet("eastus", "usgovvirginia", "usgovarizona", "westus2")]
    [string]$Location,

    [parameter(Mandatory=$true)]
    [ValidateSet("dns", "sql")]
    [string]$Solution,
  
    [parameter(Mandatory=$true)]
    [string]$SubscriptionId
)


#############################################################
# Check directory
#############################################################
$test = Test-Path -Path .\Deploy-AzureSolution.ps1
if(!$test)
{
    Write-Error 'Correct the working directory to support relative paths' -ErrorAction Stop
}


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
$LocationAbbreviation = switch($Location)
{
    eastus {'eus'}
    usgovarizona {'usa'}
    usgovvirginia {'usv'}
    westus2 {'wus'}
}
$StorageAccount = (Get-AzResource -ResourceType Microsoft.Storage/storageAccounts | Where-Object {$_.ResourceGroupName -eq $('rg-shared-' + $Environment + '-' + $Location)}).Name
$VmPassword = (Get-AzKeyVaultSecret -VaultName $('kv-' + $DomainAbbreviation + '-' + $Environment + '-' + $Location) -Name VmPassword).SecretValue
$VmUsername = (Get-AzKeyVaultSecret -VaultName $('kv-' + $DomainAbbreviation + '-' + $Environment + '-' + $Location) -Name VmUsername).SecretValue
$Params = @{}
$Params.Add("VmPassword", $VmPassword)
$Params.Add("VmUsername", $VmUsername)
switch($Solution)
{
    dns {
            . ..\utilities\functions.ps1
            $HomePip = Get-PublicIpAddress
            $Params.Add("HomePip", $HomePip.Trim())
            $TemplateFile = ".\dns\template.json"
            $ResourceGroup = 'rg-' + $Solution + '-' + $Environment + '-' + $Location
            if(!(Get-AzResourceGroup -Name $ResourceGroup -ErrorAction SilentlyContinue))
            {
                New-AzResourceGroup -Name $ResourceGroup -Location $Location | Out-Null
            }
        }
    sql {
            $Params.Add("Environment", $Environment)
            $Params.Add("LocationAbbreviation", $LocationAbbreviation)
            $TemplateFile = ".\sql\namedInstance\template.json"
            $ResourceGroup = 'rg-' + $Solution + '-' + $Environment + '-' + $Location
            if(!(Get-AzResourceGroup -Name $ResourceGroup -ErrorAction SilentlyContinue))
            {
                New-AzResourceGroup -Name $ResourceGroup -Location $Location | Out-Null
            }
        }
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
        -TemplateParameterObject $Params `
        -ErrorAction Stop `
        -Verbose
}
catch 
{
    Write-Host "Deployment Failed: $Name"
    $_ | Select-Object *
}