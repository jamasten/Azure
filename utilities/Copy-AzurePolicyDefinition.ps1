$Path = "$HOME\Desktop"
$PolicyName = '2ef3cc79-733e-48ed-ab6f-7bf439e9b406'

# Download Azure policy to file system
New-Item -Path $($Path + '\' + $PolicyName) -ItemType Directory
$NewPolicy = $([System.Text.RegularExpressions.Regex]::Unescape($(Get-AzPolicyDefinition -Name $PolicyName | ConvertTo-Json -Depth 100)))
$NewPolicy | Out-File -FilePath $($Path + '\' + $PolicyName + '\' + $PolicyName + '.json')

# Create policy definitons in destination cloud subscription
$File = Get-Item -Path $($Path + '\' + $PolicyName + '\' + $PolicyName + '.json')
$Content = Get-Content -Path $File.FullName | ConvertFrom-Json
$Description = $Content.Properties.Description
$DisplayName = $Content.Properties.DisplayName + '_test'
$Metadata = $Content.Properties.Metadata | ConvertTo-Json -Depth 100
$PolicyRule = $([System.Text.RegularExpressions.Regex]::Unescape($($Content.Properties.PolicyRule | ConvertTo-Json -Depth 100)))

New-AzPolicyDefinition -Name $File.Name.Split('.')[0] -Policy $PolicyRule -DisplayName $DisplayName -Description $Description -Metadata $Metadata -ErrorAction Stop