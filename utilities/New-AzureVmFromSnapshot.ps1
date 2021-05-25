[Cmdletbinding()]
Param(

    #Provide the subscription Id
    [parameter(Mandatory)]
    [string]
    $subscriptionId,

    #Provide the name of your resource group
    [parameter(Mandatory)]
    [string]
    $resourceGroupName,

    #Provide the name of the snapshot that will be used to create OS disk
    [parameter(Mandatory)]
    [string]
    $snapshotName,

    #Provide the name of the OS disk that will be created using the snapshot
    [parameter(Mandatory)]
    [string]
    $osDiskName,

    #Provide the name of an existing virtual network where the virtual machine NIC will be added
    [parameter(Mandatory)]
    [string]
    $virtualNetworkName,

    #Provide the name of the virtual machine
    [parameter(Mandatory)]
    [string]
    $virtualMachineName,

    #Provide the size of the virtual machine
    #e.g. Standard_DS3
    #Get all the vm sizes in a region using below script:
    #e.g. Get-AzVMSize -Location westus
    [parameter(Mandatory)]
    [string]
    $virtualMachineSize,

    #Provide the name of an existing virtual network resource group where the virtual machine NIC will be added
    [parameter(Mandatory)]
    [string]
    $vnetResourceGroupName

)

#Set the context to the subscription Id where Managed Disk will be created
Select-AzSubscription -SubscriptionId $SubscriptionId

$snapshot = Get-AzSnapshot -ResourceGroupName $resourceGroupName -SnapshotName $snapshotName

$diskConfig = New-AzDiskConfig -Location $snapshot.Location -SourceResourceId $snapshot.Id -CreateOption Copy

$disk = New-AzDisk -Disk $diskConfig -ResourceGroupName $resourceGroupName -DiskName $osDiskName

#Initialize virtual machine configuration
$VirtualMachine = New-AzVMConfig -VMName $virtualMachineName -VMSize $virtualMachineSize

#Use the Managed Disk Resource Id to attach it to the virtual machine. Please change the OS type to linux if OS disk has linux OS
$VirtualMachine = Set-AzVMOSDisk -VM $VirtualMachine -ManagedDiskId $disk.Id -CreateOption Attach -Windows

#Create a public IP for the VM
$publicIp = New-AzPublicIpAddress -Name ($VirtualMachineName.ToLower()+'_ip') -ResourceGroupName $resourceGroupName -Location $snapshot.Location -AllocationMethod Dynamic

#Get the virtual network where virtual machine will be hosted
$vnet = Get-AzVirtualNetwork -Name $virtualNetworkName -ResourceGroupName $vnetResourceGroupName

# Create NIC in the first subnet of the virtual network
$nic = New-AzNetworkInterface -Name ($VirtualMachineName.ToLower()+'_nic') -ResourceGroupName $resourceGroupName -Location $snapshot.Location -SubnetId $vnet.Subnets[0].Id -PublicIpAddressId $publicIp.Id

$VirtualMachine = Add-AzVMNetworkInterface -VM $VirtualMachine -Id $nic.Id

#Disable boot diagnostics
$VirtualMachine = Set-AzVMBootDiagnostic -VM $virtualMachineName -Disable

#Create the virtual machine with Managed Disk
New-AzVM -VM $VirtualMachine -ResourceGroupName $resourceGroupName -Location $snapshot.Location