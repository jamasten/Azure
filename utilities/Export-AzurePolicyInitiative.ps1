Param(

    [parameter(Mandatory=$true)]
    [string]$InitiativeName

)

# Get the initiative's properties using the name
$Initiative = Get-AzPolicySetDefinition | Where-Object {$_.Properties.DisplayName -eq $InitiativeName}

# Define the working directory and create a folder for the initiative
$InitiativePath = $HOME + '\Desktop\' + $InitiativeName
New-Item -Path $InitiativePath -ItemType Directory

# Download Initiative Data
$InitiativeData = [pscustomobject][ordered]@{
    Description = $Initiative.Properties.Description
    DisplayName = $Initiative.Properties.DisplayName
    Name = $Initiative.Name
}
$InitiativeData | Export-Csv -Path ($InitiativePath + '\data.csv') -NoTypeInformation

# Download Initiative Metadata
$Initiative.Properties.Metadata | ConvertTo-Json -Depth 100 | Out-File -FilePath ($InitiativePath + '\metadata.json')

# Download Policy Definitions
$Definitions = $([System.Text.RegularExpressions.Regex]::Unescape(($Initiative.Properties.PolicyDefinitions | ConvertTo-Json -Depth 100)))
$Definitions | Out-File -FilePath ($InitiativePath + '\policyDefinitions.json')

# Download Policy Definition Groups
$Initiative.Properties.PolicyDefinitionGroups | ConvertTo-Json -Depth 100 | Out-File -FilePath ($InitiativePath + '\policyDefinitionGroups.json')

# Download Policy Parameters
$Initiative.Properties.Parameters | ConvertTo-Json -Depth 100 | Out-File -FilePath ($InitiativePath + '\parameters.json')

# Download Policy Definitions to Initiative folder
foreach($Policy in $Initiative.Properties.PolicyDefinitions)
{
    $Name = $Policy.policyDefinitionId.Split('/')[-1]
    $PolicyPath = $InitiativePath + '\' + $Name
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
}