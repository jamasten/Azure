Param(

    [parameter(Mandatory=$true)]
    [string]$Path

)

# Importing the Policy Definitions
$Policies = (Get-ChildItem -Path $Path -Directory).Name
foreach($Policy in $Policies)
{
    $PolicyPath = $Path + '\' + $Policy
    $PolicyData = Import-Csv -Path ($PolicyPath + '\data.csv')
    try
    {
        $Test = Get-Content -Path ($PolicyPath + '\parameters.json')
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
        Write-Host "$Policy" -ForegroundColor Red
    }
}

# Importing the Initiative Definition
$InitiativeData = Import-Csv -Path ($Path + '\data.csv')
$TestDefGroups = Get-Content -Path ($Path + '\policyDefinitionGroups.json')
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