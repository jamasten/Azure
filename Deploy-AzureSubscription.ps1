$User = (Get-AzContext).Account.Id
$TimeStamp = Get-Date -F 'yyyyMMddhhmmss'
$Name =  $User.Split('@')[0] + '_' + $TimeStamp

New-AzSubscriptionDeployment `
  -Name $Name `
  -Location eastus `
  -TemplateFile '.\subscription.json' `
  -NamePrefixExternal 'jamasten' `
  -NamePrefixInternal 'ceastus' `
  -UserObjectId $User