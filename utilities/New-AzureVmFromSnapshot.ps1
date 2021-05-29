[Cmdletbinding()]
Param(

    # Provide the HypverV Generation for the VM Disk
    [parameter(Mandatory)]
    [ValidateSet("V1", "V2")]
    [string]
    $HyperVGeneration,

    # Determine whether you want to deploy a Public IP Address for your VM
    [parameter(Mandatory=$false)]
    [switch]
    $PublicIpAddress,

    # Provide the name of your resource group
    [parameter(Mandatory)]
    [string]
    $resourceGroupName,

    # Provide the naming suffix for each resource
    [parameter(Mandatory)]
    [string]
    $resourceNameSuffix,

    # Provide the name of the snapshot that will be used to create OS disk
    [parameter(Mandatory)]
    [string]
    $snapshotName,

    # Provide the name of the subnet that will be used for the network interface
    [parameter(Mandatory)]
    [string]
    $subnetName,

    # Provide the Subscription ID
    [parameter(Mandatory)]
    [string]
    $subscriptionId,

    # Provide the size of the virtual machine
    [parameter(Mandatory)]
    [string]
    $virtualMachineSize,

    # Provide the name of an existing virtual network where the virtual machine NIC will be added
    [parameter(Mandatory)]
    [string]
    $virtualNetworkName,

    # Provide the name of an existing virtual network resource group where the virtual machine NIC will be added
    [parameter(Mandatory)]
    [string]
    $virtualNetworkResourceGroupName

)

# Set the context to the subscription Id where Managed Disk will be created
Select-AzSubscription -SubscriptionId $SubscriptionId

# Get the snapshot
$snapshot = Get-AzSnapshot -ResourceGroupName $resourceGroupName -SnapshotName $snapshotName

# Create the disk configuration
$diskConfig = New-AzDiskConfig -Location $snapshot.Location -SourceResourceId $snapshot.Id -CreateOption Copy -HyperVGeneration $HyperVGeneration

# Create a new disk
$disk = New-AzDisk -Disk $diskConfig -ResourceGroupName $resourceGroupName -DiskName ('disk-'+$resourceNameSuffix)

# Initialize virtual machine configuration
$VirtualMachine = New-AzVMConfig -VMName ('vm-'+$resourceNameSuffix) -VMSize $virtualMachineSize

# Use the Managed Disk Resource Id to attach it to the virtual machine. Please change the OS type to linux if OS disk has linux OS
$VirtualMachine = Set-AzVMOSDisk -VM $VirtualMachine -ManagedDiskId $disk.Id -CreateOption Attach -Windows

# Create a public IP for the VM
if($PublicIpAddress)
{
    $publicIp = New-AzPublicIpAddress -Name ('pip-'+$resourceNameSuffix) -ResourceGroupName $resourceGroupName -Location $snapshot.Location -AllocationMethod Dynamic
}

# Get the virtual network where virtual machine will be hosted
$vnet = Get-AzVirtualNetwork -Name $virtualNetworkName -ResourceGroupName $virtualNetworkResourceGroupName

# Create Network Interface in the first subnet of the virtual network
$nic = New-AzNetworkInterface -Name ('nic-'+$resourceNameSuffix) -ResourceGroupName $resourceGroupName -Location $snapshot.Location -SubnetId ($vnet.Subnets | Where-Object {$_.Name -eq $subnetName}).Id -PublicIpAddressId $publicIp.Id

# Add Network Interface to Virtual Machine
$VirtualMachine = Add-AzVMNetworkInterface -VM $VirtualMachine -Id $nic.Id

# Disable Boot Diagnostics
$VirtualMachine = Set-AzVMBootDiagnostic -VM $virtualMachine -Disable

# Create the virtual machine with Managed Disk
New-AzVM -VM $VirtualMachine -ResourceGroupName $resourceGroupName -Location $snapshot.Location