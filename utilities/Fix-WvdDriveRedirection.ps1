$ResourceGroupName = ""
$Name = ""

$CurrentProperties = (Get-AzWvdHostPool -ResourceGroupName $ResourceGroupName -Name $Name ).CustomRdpProperty

$NewProperties = $CurrentProperties + "drivestoredirect:s:;"

Update-AzWvdHostPool -ResourceGroupName $ResourceGroupName -Name $Name -CustomRdpProperty $NewProperties