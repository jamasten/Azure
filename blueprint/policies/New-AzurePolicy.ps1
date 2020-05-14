$VirtualNetwork = 'ceastusvn1'
$Subnet = 'Shared'
$ResourceGroup = 'Shared'

# Get a reference to the resource group that will be the scope of the assignment
$Rg = Get-AzResourceGroup -Name $ResourceGroup

# Get a reference to the built-in policy definition that will be assigned
$Definition = Get-AzPolicyDefinition | Where-Object { $_.Properties.DisplayName -eq 'Restrict VM network interfaces to a subnet'}

$SubnetId = (Get-AzVirtualNetwork -Name $VirtualNetwork).Subnets.Id | Where-Object {$_ -like $("*/" + $Subnet)}

# Create the policy assignment with the built-in definition against your resource group
New-AzPolicyAssignment `
    -Name "Restrict network interfaces to $Subnet subnet" `
    -DisplayName "Restrict network interfaces to $Subnet subnet" `
    -Scope $Rg.ResourceId `
    -PolicyDefinition $Definition `
    -SubnetId $SubnetId