$Policies = Get-AzPolicyDefinition | Where-Object {$_.Properties.PolicyType -eq 'Custom'}
foreach($Policy in $Policies)
{
    Remove-AzPolicyDefinition -Id $Policy.PolicyDefinitionId -Force | Out-Null
}