param(
    [parameter(Mandatory)]
    [string]$Location,

    [parameter(Mandatory)]
    [string]$ResourceGroup,
    
    [parameter(Mandatory)]
    [string]$VnetName
) 

$Vnet = Get-AzVirtualNetwork -Name $VnetName -ResourceGroupName $ResourceGroup
$DnsServers = "$($Vnet.DhcpOptions.DnsServers[0]),$($Vnet.DhcpOptions.DnsServers[1])"
$SubnetId = ($Vnet.Subnets | Where-Object {$_.Delegations[0].ServiceName -eq "Microsoft.NetApp/volumes"}).Id
Install-Module -Name "Az.NetAppFiles" -Force
$DeployAnfAd = "true"
$Accounts = Get-AzResource -ResourceType "Microsoft.NetApp/netAppAccounts" | Where-Object {$_.Location -eq $Location}
foreach($Account in $Accounts)
{
    $AD = Get-AzNetAppFilesActiveDirectory -ResourceGroupName $Account.ResourceGroupName -AccountName $Account.Name
    if($AD.ActiveDirectoryId){$DeployAnfAd = "false"}
}
$DeploymentScriptOutputs = @{}
$DeploymentScriptOutputs["dnsServers"] = $DnsServers
$DeploymentScriptOutputs["subnetId"] = $SubnetId
$DeploymentScriptOutputs["anfAd"] = $DeployAnfAd