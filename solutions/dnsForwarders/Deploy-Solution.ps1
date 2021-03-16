New-AzResourceGroupDeployment `
    -Name (Get-Date -F 'yyyyMMdd_hhmmss') `
    -ResourceGroupName rg-dns-p-eastus `
    -TemplateFile "C:\Users\jamasten\GitHub\Azure\solutions\dnsForwarders\template.json" `
    -SubnetId '/subscriptions/3764b123-4849-4395-8e6e-ca6d68d8d4b4/resourceGroups/rg-network-d-eastus/providers/Microsoft.Network/virtualNetworks/vnet-d-eastus/subnets/snet-servers-d-eastus' `
    -VmUsername 'rebukem'