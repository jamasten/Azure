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
$User = (Get-AzContext).Account.Id.Split('@')[0]
$EmailDomain = (Get-AzContext).Account.Id.Split('@')[1]
$TimeStamp = Get-Date -F 'yyyyMMddhhmmss'
$Name =  $User + '_' + $TimeStamp
$UserObjectId = (Get-AzADUser | Where-Object {$_.UserPrincipalName -eq (Get-AzContext).Account.Id -or $_.UserPrincipalName -eq $($User + '_' + $EmailDomain + '#EXT#@' + $User + $($EmailDomain.Split('.')[0]) + '.onmicrosoft.com')}).Id
$Location = 'eastus'
$NamePrefixExternal = 'mastonia'
$NamePrefixInternal = 'c' + $Location
$NetworkParams = @{
    NamePrefixInternal = $NamePrefixInternal
}
$VmUsername = Read-Host -Prompt 'Enter Virtual Machine Username' -AsSecureString
$VmPassword = Read-Host -Prompt 'Enter virtual Machine Password' -AsSecureString
$SharedParams = @{
    NamePrefixExternal = $NamePrefixExternal;
    NamePrefixInternal = $NamePrefixInternal;
    UserObjectId = $UserObjectId;
}
$SharedParams.Add("VmPassword", $VmPassword) # Secure Strings must use Add Method for proper deserialization
$SharedParams.Add("VmUsername", $VmUsername) # Secure Strings must use Add Method for proper deserialization
$CoreParams = @{
    NamePrefixInternal = $NamePrefixInternal;
}
$CoreParams.Add("VmPassword", $VmPassword) # Secure Strings must use Add Method for proper deserialization
$CoreParams.Add("VmUsername", $VmUsername) # Secure Strings must use Add Method for proper deserialization
# Resource Groups are ordered in appropriate deployment order
$ResourceGroups = @(
    # Contains all network resources: VNET's, NSG's, Route Tables
    [pscustomobject][ordered]@{
        Name = 'network'
        Params = $NetworkParams
    },
    # Contains shared resources: Automation Accounts, Key Vaults, Storage Accounts
    [pscustomobject][ordered]@{
        Name = 'shared'
        Params = $SharedParams
    },
    # Contains core virtual machines for an enterprise enviroment
    [pscustomobject][ordered]@{
        Name = 'core'
        Params = $CoreParams
    }    
)


#############################################################
# Deploy Resource Groups
#############################################################
try
{
    New-AzSubscriptionDeployment `
        -ErrorAction Stop `
        -Location $Location `
        -Name $Name `
        -TemplateFile '.\subscription.json'
}
catch
{
    Write-Host "Deployment Failed: $Name"
    $_ | Select-Object *
}


#############################################################
# Deploy Resources
#############################################################
foreach($Group in $ResourceGroups)
{
    if($Group -eq 'core')
    {
        <#
        $CoreParams.Add("AutomationUrl", $(Read-Host -Prompt 'Enter Azure Automation URL' -AsSecureString)) # Secure Strings must use Add Method for proper deserialization
        $CoreParams.Add("AutomationKey", $(Read-Host -Prompt 'Enter Azure Automation Key' -AsSecureString)) # Secure Strings must use Add Method for proper deserialization
        #>
    }

    try 
    {
        New-AzResourceGroupDeployment `
            -Name $Name `
            -ResourceGroupName $Group.Name `
            -Mode 'Incremental' `
            -TemplateFile $('.\' + $Group.Name + '.json') `
            -TemplateParameterObject $Group.Params `
            -ErrorAction Stop
    }
    catch 
    {
        Write-Host "Deployment Failed: $($Name + '_' + $Group.Name)"
        $_ | Select-Object *
    }
}