# Restrict Azure virtual machine network interfaces to a subnet

This policy restricts virtual machine network interfaces to a subnet based on the resource group.  This policy plays into Role-based Access Control.  When you assign an app team privileges to a resource group, you want to ensure you control everything around their deployments to include which IP address they choose for their virtual machine.  If they choose an IP address in the wrong subnet, the validation will fail for their deployments.

## Try on Portal

[![Deploy to Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#blade/Microsoft_Azure_Policy/CreatePolicyDefinitionBlade/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fjamasten%2FAzurePolicies%2Fmaster%2Fpolicies%2Fnetworking%2FrestrictSubnet%2Fpolicy.json)
[![Deploy to Azure Gov](https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/1-CONTRIBUTION-GUIDE/images/deploytoazuregov.svg?sanitize=true)](https://portal.azure.us/?#blade/Microsoft_Azure_Policy/CreatePolicyDefinitionBlade/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fjamasten%2FAzurePolicies%2Fmaster%2Fpolicies%2Fnetworking%2FrestrictSubnet%2Fpolicy.json)

## Try with PowerShell

````powershell

$definition = New-AzPolicyDefinition `
    -Name 'RestrictSubnet_Deny' `
    -DisplayName 'RestrictSubnet_Deny' `
    -Description 'This policy restricts VM network interfaces to a subnet based on the resource group.' `
    -Policy 'https://raw.githubusercontent.com/jamasten/AzurePolicies/master/policies/networking/restrictSubnet/policy.rules.json' `
    -Parameter 'https://raw.githubusercontent.com/jamasten/AzurePolicies/master/policies/networking/restrictSubnet/policy.parameters.json' `
    -Mode 'All' `
    -Metadata '{"category":"Networking"}'

$ResourceGroupName = '<Input the Resource Group name for the policy assignment>'
$SubnetName = '<Input the Subnet name to restrict virtual machines within the Resource Group>'
$VirtualNetworkName = '<Input the Virtual Network name that contains the associated Subnet>'

New-AzPolicyAssignment `
    -Name $definition.Name `
    -Scope (Get-AzResourceGroup -Name $ResourceGroupName).ResourceId `
    -Subnet ((Get-AzVirtualNetwork -Name $VirtualNetworkName).Subnets | Where-Object {$_.Name -eq $SubnetName}).Id `
    -PolicyDefinition $definition

````

## Try with CLI

````cli

az policy definition create --name 'RestrictSubnet_Deny' --display-name 'RestrictSubnet_Deny' --description 'This policy restricts VM network interfaces to a subnet based on the resource group.' --rules 'https://raw.githubusercontent.com/jamasten/AzurePolicies/master/policies/networking/restrictSubnet/policy.rules.json' --params 'https://raw.githubusercontent.com/jamasten/AzurePolicies/master/policies/networking/restrictSubnet/policy.parameters.json' --allow 'All'

az policy assignment create --name <Assignment Name> --scope <scope> --policy "RestrictSubnet_Deny"

````
