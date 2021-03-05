Param(

    #Input your domain name (i.e. jasonmasten.com)
    [Parameter(Mandatory=$true)]
    [string]$Domain,
    
    [parameter(Mandatory=$true)]
    [string]$SubscriptionId,

    [parameter(Mandatory=$true)]
    [System.Management.Automation.PSCredential]$Credential = (Get-Credential -Message 'Input the credentials used for your local administator on your Azure virtual machines.  The same password will be used for your domain users using WVD.')
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
# Variables
#############################################################
$Context = Get-AzContext
$Username = $Context.Account.Id.Split('@')[0]
$Email = $Context.Account.Id
$TimeStamp = Get-Date -F 'yyyyMMddhhmmss'
$Name =  $Username + '_' + $TimeStamp


#############################################################
# Add Azure AD Connect Account
#############################################################
$UPN = 'adconnect@' + $Domain
$test = Get-AzADUser -UserPrincipalName $UPN -ErrorAction SilentlyContinue
if(!$test)
{
    New-AzADUser -DisplayName 'AD Connect' -UserPrincipalName $UPN -Password $Credential.Password -MailNickname 'ADConnect'
}


#############################################################
# Template Parameter Object
#############################################################
$Params = @{}
$Params.Add("Domain", $Domain)
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
        -TemplateFile 'https://raw.githubusercontent.com/jamasten/Azure/master/solutions/wth-dc/subscription.json' `
        -TemplateParameterObject $Params `
        -ErrorAction Stop `
        -Verbose
}
catch 
{
    Write-Host "Deployment Failed: $Name"
    $_ | Select-Object *
}