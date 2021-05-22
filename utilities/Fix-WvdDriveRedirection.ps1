[Cmdletbinding()]
Param(

[parameter(Mandatory)]
[string]$Name,

[parameter(Mandatory)]
[string]$ResourceGroupName

)

$CurrentProperties = (Get-AzWvdHostPool -ResourceGroupName $ResourceGroupName -Name $Name ).CustomRdpProperty

$NewProperties = $CurrentProperties + "drivestoredirect:s:;"

Update-AzWvdHostPool -ResourceGroupName $ResourceGroupName -Name $Name -CustomRdpProperty $NewProperties