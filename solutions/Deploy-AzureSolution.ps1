Param(

    [Parameter(Mandatory=$true)]
    [string]$Domain,

    # This is used to uniquely name resources that need to be globally unique (i.e. storage account name)
    [Parameter(Mandatory=$true)]
    [string]$DomainAbbreviation,

    [Parameter(Mandatory=$true)]
    [ValidateSet("dev", "prod", "qa", "sandbox", "shared", "stage", "test")]
    [string]$Environment, 

    [Parameter(Mandatory=$true)]
    [ValidateScript({(Get-AzLocation | Select-Object -ExpandProperty Location) -contains $_})]
    [string]$Location,

    [parameter(Mandatory=$true)]
    [ValidateSet("dns", "sql", "wvd")]
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
# Load functions
#############################################################
. ..\utilities\functions.ps1


#############################################################
# Variables
#############################################################
$Context = Get-AzContext
$Username = $Context.Account.Id.Split('@')[0]
$TimeStamp = Get-Date -F 'yyyyMMddhhmmss'
$Name =  $Username + '_' + $TimeStamp
$Params = @{}
switch($Solution)
{
    dns {
            $Credential = Get-Credential -Message "Input the credentials for the Azure VM local admin account"
            $HomePip = Get-PublicIpAddress
            $Params.Add("HomePip", $HomePip.Trim())
            $Params.Add("VmPassword", $Credential.Password)
            $Params.Add("VmUsername", $Credential.UserName)
            $TemplateFile = ".\dns\template.json"
            $ResourceGroup = 'rg-' + $Solution + '-' + $Environment + '-' + $Location
            if(!(Get-AzResourceGroup -Name $ResourceGroup -ErrorAction SilentlyContinue))
            {
                New-AzResourceGroup -Name $ResourceGroup -Location $Location | Out-Null
            }
        }
    sql {
            $Params.Add("vmName", "vmsqltest")
            $TemplateFile = ".\sql\namedInstance\template.json"
            $ResourceGroup = 'rg-' + $Solution + '-' + $Environment + '-' + $Location
            if(!(Get-AzResourceGroup -Name $ResourceGroup -ErrorAction SilentlyContinue))
            {
                New-AzResourceGroup -Name $ResourceGroup -Location $Location | Out-Null
            }
        }
    wvd {
            $Credential = Get-Credential -Message "Input the credentials for the Azure VM local admin account"
            $Netbios = $Domain.Split('.')[0]
            $Params.Add("Domain", $Domain)
            $Params.Add("DomainAbbreviation", $DomainAbbreviation)
            $Params.Add("Environment", $Environment)
            $Params.Add("Netbios", $Netbios)
            $Params.Add("Username", $UserName)
            $Params.Add("VmPassword", $Credential.Password)
            $Params.Add("VmUsername", $Credential.UserName)
            $TemplateFile = ".\wvd\template.json"
            $ResourceGroup = 'rg-' + $Solution + 'core-' + $Environment + '-' + $Location
            if(!(Get-AzResourceGroup -Name $ResourceGroup -ErrorAction SilentlyContinue))
            {
                New-AzResourceGroup -Name $ResourceGroup -Location $Location | Out-Null
            }
            $ResourceGroup2 = 'rg-' + $Solution + 'hosts-' + $Environment + '-' + $Location
            if(!(Get-AzResourceGroup -Name $ResourceGroup2 -ErrorAction SilentlyContinue))
            {
                New-AzResourceGroup -Name $ResourceGroup2 -Location $Location | Out-Null
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