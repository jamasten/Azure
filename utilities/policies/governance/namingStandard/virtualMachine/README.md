# Deny an Azure virtual machine deployment based on the naming standard

This Azure policy governs the naming standard / convention for virtual machines within the specified scope.  The policy was developed to support a 3 tier application in 2 locations that all reside in the same resource group.  Ideally, this policy would be assigned to a resource group when the resource group is created.

## Try on Portal

[![Deploy to Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#blade/Microsoft_Azure_Policy/CreatePolicyDefinitionBlade/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fjamasten%2FAzurePolicies%2Fmaster%2Fpolicies%2Fgovernance%2FnamingStandard%2FvirtualMachine%2Fpolicy.json)
[![Deploy to Azure Gov](https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/1-CONTRIBUTION-GUIDE/images/deploytoazuregov.svg?sanitize=true)](https://portal.azure.us/?#blade/Microsoft_Azure_Policy/CreatePolicyDefinitionBlade/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fjamasten%2FAzurePolicies%2Fmaster%2Fpolicies%2Fgovernance%2FnamingStandard%2FvirtualMachine%2Fpolicy.json)

## Try with PowerShell

````powershell

$definition = New-AzPolicyDefinition `
    -Name 'NamingStandard_VirtualMachine_Deny' `
    -DisplayName 'NamingStandard_VirtualMachine_Deny' `
    -Description 'This policy governs the naming standard for virtual machines.' `
    -Policy 'https://raw.githubusercontent.com/jamasten/AzurePolicies/master/policies/governance/namingStandard/virtualMachine/policy.rules.json' `
    -Parameter 'https://github.com/jamasten/AzurePolicies/blob/master/policies/governance/namingStandard/virtualMachine/policy.parameters.json' `
    -Mode 'All' `
    -Metadata '{"category":"Governance"}'

New-AzPolicyAssignment `
    -Name '<Assignment Name>' `
    -Scope '<Scope>' `
    -Tier1 '<App Tier 1 Abbreviation>' `
    -Tier2 '<App Tier 2 Abbreviation>' `
    -Tier3 '<App Tier 3 Abbreviation>' `
    -Environment '<Environment Abbreviation>' `
    -Location1 '<Primary Location Abbreviation>' `
    -Location2 '<Secondary Location Abbreviation>' `
    -PolicyDefinition $definition

````

## Try with CLI

````cli

az policy definition create --name 'NamingStandard_VirtualMachine_Deny' --display-name 'NamingStandard_VirtualMachine_Deny' --description 'This policy governs the naming standard for virtual machines.' --rules 'https://raw.githubusercontent.com/jamasten/AzurePolicies/master/policies/governance/namingStandard/virtualMachine/policy.rules.json' --params 'https://github.com/jamasten/AzurePolicies/blob/master/policies/governance/namingStandard/virtualMachine/policy.parameters.json' --mode All

az policy assignment create --name <Assignment Name> --scope <scope> --policy "NamingStandard_VirtualMachine_Deny"

````
