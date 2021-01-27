<#
.SYNOPSIS

Exports an Azure Policy Initiative Definition

.DESCRIPTION

The Export-AzurePolicyInitiative.ps1 script exports an initiative definition.  This script will first 
create a directory based on the display name of the initiative on the user's Desktop. Then it exports 
out the initiative defintion properties to either a CSV file or JSON.  Afterwards, the policy 
definitions are exported out using CSV and JSON files.

.PARAMETER InitiativeName

Specifies the Display Name of the initiative defintion to export.

.INPUTS

None. You cannot pipe objects to Export-AzurePolicyInitiative.ps1.

.OUTPUTS

The OUTPUT from this script will be a directory on your filesystem that contains the initiative definition code,
along with all the policy definition code the initiative is dependent on.

.EXAMPLE

PS> .\Export-AzurePolicyInitiative.ps1 -InitiativeName "FedRAMP High"
#>

Param(

    # Specifies the Display Name of the initiative defintion to export
    [parameter(Mandatory=$true)]
    [string]$InitiativeName

)

# Gets the initiative definition's properties using the display name
$Initiative = Get-AzPolicySetDefinition | Where-Object {$_.Properties.DisplayName -eq $InitiativeName}

# Defines the working directory
$InitiativePath = $HOME + '\Desktop\' + $InitiativeName

# Creates a folder to store the initiative definition as code
New-Item -Path $InitiativePath -ItemType Directory

# Creates a CSV file with the Description, DisplayName, and Name values from the initiative definition properties
$InitiativeData = [pscustomobject][ordered]@{
    Description = $Initiative.Properties.Description
    DisplayName = $Initiative.Properties.DisplayName
    Name = $Initiative.Name
}
$InitiativeData | Export-Csv -Path ($InitiativePath + '\data.csv') -NoTypeInformation

# Creates a json file of the initiative definition "Metadata"
$Initiative.Properties.Metadata | ConvertTo-Json -Depth 100 | Out-File -FilePath ($InitiativePath + '\metadata.json')

# Creates a json file of the initiative definition "Policy Definitions"
$Definitions = $([System.Text.RegularExpressions.Regex]::Unescape(($Initiative.Properties.PolicyDefinitions | ConvertTo-Json -Depth 100)))
$Definitions | Out-File -FilePath ($InitiativePath + '\policyDefinitions.json')

# Creates a json file of the initiative definition "Policy Definition Groups"
$Initiative.Properties.PolicyDefinitionGroups | ConvertTo-Json -Depth 100 | Out-File -FilePath ($InitiativePath + '\policyDefinitionGroups.json')

# Creates a json file of the initiative definition "Parameters"
$Initiative.Properties.Parameters | ConvertTo-Json -Depth 100 | Out-File -FilePath ($InitiativePath + '\parameters.json')

# Download Policy Definitions to Initiative folder
foreach($Policy in $Initiative.Properties.PolicyDefinitions)
{
    $Name = $Policy.policyDefinitionId.Split('/')[-1]
    $PolicyPath = $InitiativePath + '\' + $Name
    New-Item -Path $PolicyPath -ItemType Directory
    $Policy = Get-AzPolicyDefinition -Name $Name
    
    # Creates a CSV file with the Description, DisplayName, and Mode values from the policy definition properties
    $Data = [pscustomobject][ordered]@{
        Description = $Policy.Properties.Description
        DisplayName = $Policy.Properties.DisplayName
        Mode = $Policy.Properties.Mode
    }
    $Data | Export-Csv -Path ($PolicyPath + '\data.csv') -NoTypeInformation

    # Creates a json file of the policy definition metadata
    $Policy.Properties.Metadata | ConvertTo-Json -Depth 100 | Out-File -FilePath ($PolicyPath + '\metadata.json')

    # Creates a json file of the policy definition rule while escaping single quotes in the code
    $Rule = $([System.Text.RegularExpressions.Regex]::Unescape(($Policy.Properties.PolicyRule | ConvertTo-Json -Depth 100)))
    $Rule | Out-File -FilePath ($PolicyPath + '\rule.json')

    # Creates a json file of the policy definition parameters
    $Policy.Properties.Parameters | ConvertTo-Json -Depth 100 | Out-File -FilePath ($PolicyPath + '\parameters.json')
}