

$Name = '16390df4-2f73-4b42-af13-c801066763df'
$PolicyPath = $HOME + '\Desktop\' + $Name
New-Item -Path $PolicyPath -ItemType Directory
$Policy = Get-AzPolicyDefinition -Name $Name
    
# Download policy data to CSV
$Data = [pscustomobject][ordered]@{
    Description = $Policy.Properties.Description
    DisplayName = $Policy.Properties.DisplayName
    Mode = $Policy.Properties.Mode
}
$Data | Export-Csv -Path ($PolicyPath + '\data.csv') -NoTypeInformation

# Download Policy Metadata
$Policy.Properties.Metadata | ConvertTo-Json -Depth 100 | Out-File -FilePath ($PolicyPath + '\metadata.json')

# Download Policy Rule
$Rule = $([System.Text.RegularExpressions.Regex]::Unescape(($Policy.Properties.PolicyRule | ConvertTo-Json -Depth 100)))
$Rule | Out-File -FilePath ($PolicyPath + '\rule.json')

# Download Policy Parameters
$Policy.Properties.Parameters | ConvertTo-Json -Depth 100 | Out-File -FilePath ($PolicyPath + '\parameters.json')