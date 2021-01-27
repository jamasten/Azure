<#
.SYNOPSIS

Imports an Azure Policy Initiative Definition

.DESCRIPTION

The Import-AzurePolicyInitiative.ps1 script imports an initiative definition that
was exported using Jason Masten's Export-AzurePolicyInitiative.ps1 script.

This script will first create the required policy definitions for the initiative.
Once the policy definitions exist, the initiative definition can and will be created.

.PARAMETER Path

Specifies the location of the exported initiative definition that will be imported.

.INPUTS

None. You cannot pipe objects to Import-AzurePolicyInitiative.ps1.

.OUTPUTS

The OUTPUT from this script will contain the data returned from running the New-AzPolicySetDefiniton cmdlet.

.EXAMPLE

PS> .\Import-AzurePolicyInitiative.ps1 -Path "C:\JasonMasten\Desktop\FedRAMP High"
#>

Param(

    # Specifies the location of the exported initiative definition that will be imported
    [parameter(Mandatory=$true)]
    [string]$Path

)

########################################################################################
# Import Policy Definitions
########################################################################################

# The $Policies variable is set using all the policy definition names that were exported
# using the Export-AzurePolicyInitiative.ps1 script
$Policies = (Get-ChildItem -Path $Path -Directory).Name

# Use the policy name to get all the required data about the policy definition
foreach($Policy in $Policies)
{
    # Sets the path to the policy on the file system
    $PolicyPath = $Path + '\' + $Policy
    
    # Imports the Description, DisplayName, and Mode for the policy definiton
    $PolicyData = Import-Csv -Path ($PolicyPath + '\data.csv')
    try
    {
        # Checks the status of the parameters file to conditionally create a new policy definition
        $Test = Get-Content -Path ($PolicyPath + '\parameters.json')
        
        # If the paramaters.json file has content then the "parameter" parameter is specified
        # with the cmdlet.
        if($Test)
        {
            New-AzPolicyDefinition `
                -Name $Policy `
                -DisplayName $PolicyData.DisplayName `
                -Description $PolicyData.Description `
                -Policy ($PolicyPath + '\rule.json') `
                -Metadata ($PolicyPath + '\metadata.json') `
                -Parameter ($PolicyPath + '\parameters.json') `
                -Mode $PolicyData.Mode `
                -Verbose `
                -ErrorAction Stop | Out-Null
        }

        # If the parameters.json file is empty then the "parameter" parameter is not specified
        # with the cmdlet.
        else
        {
            New-AzPolicyDefinition `
                -Name $Policy `
                -DisplayName $PolicyData.DisplayName `
                -Description $PolicyData.Description `
                -Policy ($PolicyPath + '\rule.json') `
                -Metadata ($PolicyPath + '\metadata.json') `
                -Mode $PolicyData.Mode `
                -Verbose `
                -ErrorAction Stop | Out-Null
        }
    }
    catch
    {
        Write-Host "$Policy :: FAILED" -ForegroundColor Red
        $_ | Select-Object *
    }
}


########################################################################################
# Import Initiative Definition
########################################################################################

# Imports the Description, DisplayName, and Name for the initiative definiton
$InitiativeData = Import-Csv -Path ($Path + '\data.csv')

# Checks the status of the policyDefinitionGroups.json file to conditionally create a new
# initiative definition
$TestDefGroups = Get-Content -Path ($Path + '\policyDefinitionGroups.json')
try
{   
    # If the policyDefinitionGroups.json file has content then the "GroupDefinition" 
    # parameter is specified with the cmdlet.
    if($TestDefGroups)
    {
        New-AzPolicySetDefinition `
            -Name $InitiativeData.Name `
            -DisplayName $InitiativeData.DisplayName `
            -Description $InitiativeData.Description `
            -Metadata ($Path + '\metadata.json') `
            -PolicyDefinition ($Path + '\policyDefinitions.json') `
            -Parameter ($Path + '\parameters.json') `
            -GroupDefinition ($Path + '\policyDefinitionGroups.json') `
            -Verbose `
            -ErrorAction Stop
    }
    # If the policyDefinitionGroups.json file is empty then the "GroupDefinition" 
    # parameter is not specified with the cmdlet.
    else
    {
        New-AzPolicySetDefinition `
            -Name $InitiativeData.Name `
            -DisplayName $InitiativeData.DisplayName `
            -Description $InitiativeData.Description `
            -Metadata ($Path + '\metadata.json') `
            -PolicyDefinition ($Path + '\policyDefinitions.json') `
            -Parameter ($Path + '\parameters.json') `
            -Verbose `
            -ErrorAction Stop
    }
}
catch
{
    $_ | Select-Object *
}