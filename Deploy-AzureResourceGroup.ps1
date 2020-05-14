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


#############################################################
# Deploy Resources
#############################################################
foreach($Group in $ResourceGroups)
{
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