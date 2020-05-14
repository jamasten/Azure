# Login first with Connect-AzAccount if not using Cloud Shell

# Get a reference to the new blueprint object, we'll use it in subsequent steps
$Blueprint = New-AzBlueprint -Name 'MyBlueprint' -BlueprintFile .\blueprint.json

# Use the reference to the new blueprint object from the previous steps
New-AzBlueprintArtifact -Blueprint $blueprint -Name 'roleContributor' -ArtifactFile .\artifacts\roleContributor.json