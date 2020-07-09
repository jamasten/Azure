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
$TimeStamp = Get-Date -F 'yyyyMMddhhmmss'
$Name =  $User + '_' + $TimeStamp
$Location = 'eastus'
$NamePrefixInternal = 'c' + $Location
$VmUsername = Read-Host -Prompt 'Enter Virtual Machine Username' -AsSecureString
$VmPassword = Read-Host -Prompt 'Enter virtual Machine Password' -AsSecureString
$CoreParams = @{
    NamePrefixInternal = $NamePrefixInternal;
}
$CoreParams.Add("VmPassword", $VmPassword) # Secure Strings must use Add Method for proper deserialization
$CoreParams.Add("VmUsername", $VmUsername) # Secure Strings must use Add Method for proper deserialization


#############################################################
# Deploy Resources
#############################################################
try 
{
    New-AzResourceGroupDeployment `
        -Name $Name `
        -ResourceGroupName 'core' `
        -Mode 'Incremental' `
        -TemplateFile $('.\templates\core.json') `
        -TemplateParameterObject $CoreParams `
        -ErrorAction Stop
}
catch 
{
    Write-Host "Deployment Failed: $($Name + '_core')"
    $_ | Select-Object *
}