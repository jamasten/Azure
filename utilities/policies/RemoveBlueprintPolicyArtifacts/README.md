# Remove Azure Policy Artifacts Assigned By An Azure Blueprint

Use the code below to remove policy artifacts that were assigned by an Azure Blueprint.

!!!WARNING!!! This script will remove all matching policy assignments at the blueprint assignment's scope.  For instance, if you assign the "allowed locations" policy with one blueprint and assign the "allowed locations" policy again with another blueprint in the same subscription, there is no way to differentiate between the two so the script deletes both.

## Try with PowerShell

````powershell

$name = '<Input the name of the Blueprint Assignment>'
$bpAssignment = Get-AzBlueprintAssignment | Where-Object {$_.Name -eq $name}
$scope = $bpAssignment.BlueprintId.Split('/')[1]
switch($scope)
{
    providers {$bpDefinition = Get-AzBlueprint -Name $bpAssignment.BlueprintId.Split('/')[-3] -Version $bpAssignment.BlueprintId.Split('/')[-1] -ManagementGroupId $bpAssignment.BlueprintId.Split('/')[4]}
    subscriptions {$bpDefinition = Get-AzBlueprint -Name $bpAssignment.BlueprintId.Split('/')[-3] -Version $bpAssignment.BlueprintId.Split('/')[-1] -SubscriptionId $bpAssignment.BlueprintId.Split('/')[2]}
}
$bpArtifacts = Get-AzBlueprintArtifact -Blueprint $bpDefinition
foreach($artifact in $bpArtifacts)
{
    if($artifact.PolicyDefinitionId)
    {
        $assignments = Get-AzPolicyAssignment -PolicyDefinitionId $artifact.PolicyDefinitionId -Scope $bpAssignment.Scope -ErrorAction SilentlyContinue
        if($assignments)
        {
            foreach($assignment in $assignments)
            {
                Remove-AzPolicyAssignment -Id $assignment.PolicyAssignmentId | Out-Null
            }
        }
    }
}

````
