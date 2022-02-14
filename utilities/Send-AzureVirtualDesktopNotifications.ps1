$HostPoolName = ''
$ResourceGroupName = ''
$Time = '18:00EST'

$Sessions = Get-AzWvdUserSession -HostPoolName $HostPoolName -ResourceGroupName $ResourceGroupName
foreach($Session in $Sessions)
{
    $SessionHostName = $Session.Id.split('/')[-3]
    $UserSessionId = $Session.Id.split('/')[-1]

    Send-AzWvdUserSessionMessage  `
        -ResourceGroupName $ResourceGroupName `
        -HostPoolName $HostPoolName `
        -SessionHostName $SessionHostName `
        -UserSessionId $UserSessionId `
        -MessageBody "Maintenance will begin in 1 hour at $Time" `
        -MessageTitle 'Upcoming Maintenance'
}