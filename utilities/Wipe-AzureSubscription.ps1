#############################################################
# Authentication
#############################################################
$Subscription = 'Visual Studio Enterprise Subscription'
if(!(Get-AzSubscription | Where-Object {$_.Name -eq $Subscription}))
{
    Connect-AzAccount `
        -Subscription $Subscription `
        -UseDeviceAuthentication
}
Set-AzContext -Subscription $Subscription


#############################################################
# Variables
#############################################################
$Names = @('wvd','identity','shared','network')
$Locations = @('eastus','westus')
$Environment = 'dev'


#############################################################
# Remove Resource Groups
#############################################################
foreach($Location in $Locations)
{
    foreach($Name in $Names)
    {
            
        try
        {
            Write-Host ''
            Write-Host "STARTED RESOURCE GROUP DELETION: $('rg-' + $Name + '-' + $Environment + '-' + $Location)"

            Remove-AzResourceGroup `
                -Name $('rg-' + $Name + '-' + $Environment + '-' + $Location) `
                -Force `
                -ErrorAction Stop | Out-Null

            Write-Host "COMPLETED RESOURCE GROUP DELETION: $('rg-' + $Name + '-' + $Environment + '-' + $Location)"
        }
        catch
        {
            $_ | Select-Object *
        }
    }
}