param(
    [Parameter(Mandatory)]
    [string]$NicName,

    [Parameter(Mandatory)]
    [string]$ResourceGroupName,

    [Parameter(Mandatory)]
    [string]$VirtualMachineName
)

Stop-AzVM -ResourceGroup $ResourceGroupName -Name $VirtualMachineName
$nic = Get-AzNetworkInterface -ResourceGroupName $ResourceGroupName -Name $NicName
$nic.EnableAcceleratedNetworking = $true
$nic | Set-AzNetworkInterface
Start-AzVM -ResourceGroup $ResourceGroupName -Name $VirtualMachineName