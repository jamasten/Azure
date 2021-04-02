# Find the available extension publishers in your location
$Location = 'eastus'
Get-AzVmImagePublisher -Location $Location

# Find the available extension types in your location
$Publisher = 'Microsoft.Compute'
Get-AzVMExtensionImageType -Location $Location -PublisherName $Publisher

# Get the extension versions for the specified type in your location
$Type = 'CustomScriptExtension'
(Get-AzVMExtensionImage -Location $Location -PublisherName Microsoft.Compute -Type $Type).Version