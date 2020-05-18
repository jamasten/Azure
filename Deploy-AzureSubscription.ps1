$User = (Get-AzContext).Account.Id.Split('@')[0]
$TimeStamp = Get-Date -F 'yyyyMMddhhmmss'
$Name =  $User + '_' + $TimeStamp

New-AzSubscriptionDeployment `
  -Name $Name `
  -Location eastus `
  -TemplateParameterFile '.\subscription.parameter.json' `
  -TemplateFile '.\subscription.json'