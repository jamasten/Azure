$Name = ''
$Group = ''
$File = ''
$Params = @{}


try 
{
    New-AzResourceGroupDeployment `
        -Name $Name `
        -ResourceGroupName $Group `
        -Mode 'Incremental' `
        -TemplateFile $File `
        -TemplateParameterObject $Params `
        -DeploymentDebugLogLevel All `
        -ErrorAction Stop
}
catch 
{
    Write-Host "Deployment Failed: $($Name + '_' + $Group)"
    $_ | Select-Object *
}

$operations = Get-AzResourceGroupDeploymentOperation –DeploymentName $Name –ResourceGroupName $Group
foreach($operation in $operations)
{
    Write-Host $operation.id
    Write-Host "Request:"
    $operation.Properties.Request | ConvertTo-Json -Depth 10
    Write-Host "Response:"
    $operation.Properties.Response | ConvertTo-Json -Depth 10
}