$VmName = ''
$VmResourceGroupName = ''
$Credential = Get-Credential -Message 'Input local administrator credential'

$VM = Get-AzVM `
    -ResourceGroupName $VmResourceGroupName `
    -Name $VmName

Set-AzVMOperatingSystem `
    -VM $VM `
    -ComputerName $VmName `
    -Credential $Credential `
    -PatchMode "AutomaticByOS" `
    -Windows