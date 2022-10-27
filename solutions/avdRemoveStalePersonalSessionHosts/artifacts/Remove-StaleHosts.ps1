[CmdletBinding(SupportsShouldProcess)]
param(
	[Parameter(Mandatory)]
	$WebHookData
)


$Parameters = ConvertFrom-Json -InputObject $WebHookData.RequestBody
$EnvironmentName = $Parameters.PSObject.Properties['EnvironmentName'].Value
$HostPoolName = $Parameters.PSObject.Properties['HostPoolName'].Value
$HostPoolResourceGroupName = $Parameters.PSObject.Properties['HostPoolResourceGroupName'].Value
$SessionHostExpirationInDays = $Parameters.PSObject.Properties['SessionHostExpirationInDays'].Value
$SubscriptionId = $Parameters.PSObject.Properties['SubscriptionId'].Value
$TenantId = $Parameters.PSObject.Properties['TenantId'].Value
$WorkspaceId = $Parameters.PSObject.Properties['WorkspaceId'].Value


$ErrorActionPreference = 'Stop'

try
{
    # Import Modules
    Import-Module -Name 'Az.Accounts','Az.Compute','Az.Resources'
    Write-Output "Imported required modules"

    # Connect to Azure using the Managed Identity
    Connect-AzAccount -Environment $EnvironmentName -Subscription $SubscriptionId -Tenant $TenantId -Identity | Out-Null
    Write-Output "Connected to Azure"

    # Get the resource IDs for the AVD session hosts in the target host pool
    $SessionHosts = (Get-AzWvdSessionHost -ResourceGroupName $HostPoolResourceGroupName  -HostPoolName $HostPoolName).ResourceId
    foreach($SessionHost in $SessionHosts)
    {
        # Get the resource ID of the managed disk used for the operating system on the session host
        $VirtualMachine = Get-AzVM -ResourceId $SessionHost
        $SessionHostDisk = $VirtualMachine.StorageProfile.OsDisk.ManagedDisk.Id
        
        # Get the creation date / time of the session host disk to determine if the session host has existed during the expriation time frame
        $Disk = Get-AzDisk -ResourceGroupName $SessionHostDisk.Split('/')[4] -DiskName $SessionHostDisk.Split('/')[-1]
        $DiskCreationDate = $Disk.TimeCreated
        
        # Get the expiration date by subtracting the expiration in days param from the current date
        $ExpirationDate = (Get-Date).AddDays(-$SessionHostExpirationInDays)
        if($DiskCreationDate -gt $ExpirationDate)
        {
            $SessionHostName = $SessionHost.Split('/')[-1]
            $Query = "WVDConnections | where State == 'Connected' | where _ResourceId has '$HostPoolName' | where SessionHostName == '$SessionHostName'"
            $Results = (Invoke-AzOperationalInsightsQuery -WorkspaceId $WorkspaceId -Query $Query -Timespan (New-TimeSpan -Days $SessionHostExpirationInDays)).Results
            if(!$Results)
            {
                # Remove the session host from the host pool
                Remove-AzWvdSessionHost `
                    -ResourceGroupName $HostPoolResourceGroup `
                    -HostPoolName $HostPoolName `
                    -Name $SessionHostName `
                    | Out-Null

                # Remove the virtual machine
                $VirtualMachine | Remove-AzVM -Force

                # Delay to ensure NIC and disk can be removed automatically if using the newer VM API
                Start-Sleep -Seconds 60

                # Remove the network interface
                $NetworkInterface = Get-AzNetworkInterface -ResourceGroupName $VirtualMachine.ResourceGroupName -Name $VirtualMachine.NetworkProfile.NetworkInterfaces[0].Id.Split('/')[-1] -ErrorAction 'SilentlyContinue'
                if($NetworkInterface)
                {
                    $NetworkInterface | Remove-AzNetworkInterface -Force
                }

                # Remove the disk
                $Disk = Get-AzDisk -ResourceGroupName $SessionHostDisk.Split('/')[4] -DiskName $SessionHostDisk.Split('/')[-1] -ErrorAction 'SilentlyContinue'
                if($Disk)
                {
                    $Disk | Remove-AzDisk -Force
                }
            }
        }
    }
}
catch 
{
    Write-Output $_.Exception
    throw
}