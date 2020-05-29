$User = (Get-AzContext).Account.Id
$TimeStamp = Get-Date -F 'yyyyMMddhhmmss'
$Name =  $User.Split('@')[0] + '_' + $TimeStamp
$UserObjectId = (Get-AzADUser -UserPrincipalName $User).Id

New-AzSubscriptionDeployment `
  -Name $Name `
  -Location 'eastus' `
  -TemplateFile '.\subscription.json' `
  -NamePrefixExternal 'jamasten' `
  -NamePrefixInternal 'ceastus' `
  -UserObjectId $UserObjectId `
  -SubnetId "[parameters('SubnetId')]" `
  -LocationFromTemplate 'eastus'