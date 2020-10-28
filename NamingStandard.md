# Naming Standard

## Components

| Component | Description | Example |
| ----------- | ----------- | ----------- |
| BusinessUnit | Top-level division of your company that owns the subscription or workload the resource belongs to. In smaller organizations, this may represent a single corporate top-level organizational element. | fin, mktg, product, it, corp |
| Application Name | Name of the application, workload, or service associated with the resource. | bing, dc, docs, technet |
| EnvironmentAbbreviation | The stage of the workload's development lifecycle that the resource is supporting : (d)evelopment, (p)roduction, (t)est | d, p, t |
| Region | Azure region where the resource is deployed. | eastus, usgovarizona, usgovvirgina, westus2 |
| Performance Type | Azure Storage Accout Skus: (p)remium, (s)tandard | p, s |

## Resource Type Prefixes

| Resource | Prefix |
| ----------- | ----------- |
| App Services | app- |
| Automation Account | aa- |
| Azure Cosmos DB (Document Database) | cosmos- |
| Azure Cache for Redis | redis- |
| Azure Database for MySQL | mysql- |
| Azure Data Lake Storage | dls |
| Azure Data Lake Analytics | dla |
| Azure IoT Hub | aih- |
| Azure Machine Learning Workspace | mlw- |
| Azure Search | srch- |
| Azure SQL Database | sqldb- |
| Cloud Services | cldsvc- |
| Cognitive Services | cogsvc- |
| Data Factory | df- |
| Event Hub | ehub- |
| Function Apps | func- |
| Gateway connection | gwcn- |
| HDInsight - Spark | hdisp- |
| HDInsight - Hadoop | hdihd- |
| HDInsight - R server| hdir- |
| HDInsight - HBase | hdihb- |
| Host Pool | hp- |
| Load Balancer | lb- |
| NIC | nic- |
| Notification Hub | nhub- |
| Notification Hub Namespace | nhubns- |
| NSG | nsg- |
| Power BI Embedded | pbie |
| Public IP | pip- |
| Resource Group | rg- |
| Service Bus | sb- |
| Service Bus Queues | sbq- |
| SQL Data Warehouse | sqldw- |
| SQL Server Stretch Database | sqlssdb- |
| Storage Account | stor |
| StorSimple | storsimp |
| Stream analytics | sa- |
| Subnet | snet- |
| Virtual Machines | vm- |
| Virtual Network | vnet- |
| Virtual Network Gateway | gw- |
| Windows Virtual Destop Workspace | ws- |

## Convention

| Type | Scope | Format | Example |
| ----------- | ----------- | ----------- | ----------- |
| App Service | Global | app-(ApplicationName)-(EnvironmentAbbreviation)-(Region)-(Ordinal).azurewebsites.net | app-jm-d-eastus-0.azurewebsites.net |
| Automation Account | Global | aa-(DomainAbbreviation)-(Optional: ApplicationName or Usage)-(EnvironmentAbbreviation)-(Region) | aa-jm-d-eastus or aa-jm-updates-d-eastus |
| Availability Set | Resource Group | as-(ApplicationName or Role)-(EnvironmentAbbreviation)-(Region) | as-dc-d-eastus |
| Azure Cache For Redis | Global | redis-(DomainAbbreviation)-(ApplicationName)-(EnvironmentAbbreviation)-(Region) | redis-jm-bing-d-eastus |
| Azure Cosmos DB (Document Database) | Global | cosmos-(DomainAbbreviation)-(ApplicationName)-(EnvironmentAbbreviation)-(Region) | cosmos-jm-bing-d-eastus |
| Azure Data Factory | Global | df-(DomainAbbreviation)-(ApplicationName)-(EnvironmentAbbreviation)-(Region) | df-jm-bing-dev-eastus |
| Azure Data Lake Analytics | Global | dla-(DomainAbbreviation)-(ApplicationName)-(EnvironmentAbbreviation)-(Region) | dla-jm-bing-d-eastus |
| Azure Data Lake Storage | Global | dls-(DomainAbbreviation)-(ApplicationName)-(EnvironmentAbbreviation)-(Region) | dls-jm-bing-d-eastus |
| Azure Database For MySQL | Global | mysql-(DomainAbbreviation)-(ApplicationName)-(EnvironmentAbbreviation)-(Region) | mysql-jm-bing-d-eastus |
| Azure Iot Hub | Global | iothub-(DomainAbbreviation)-(ApplicationName)-(EnvironmentAbbreviation)-(Region) | iothub-jm-bing-d-eastus |
| Azure Machine Learning Workspace | Resource Group | mlw-(ApplicationName)-(EnvironmentAbbreviation)-(Region) | mlw-bing-d-eastus |
| Azure Search | Global | srch-(DomainAbbreviation)-(ApplicationName)-(EnvironmentAbbreviation)-(Region) | srch-jm-bing-d-eastus |
| Azure SQL Database | Global | sqldb-(DomainAbbreviation)-(ApplicationName)-(EnvironmentAbbreviation)-(Region) | sqldb-jm-bing-d-eastus |
| Azure Stream Analytics on Iot Edge | Resource Group | sa-(ApplicationName)-(EnvironmentAbbreviation)-(Region) | sa-bing-d-eastus |
| Cloud Services | Global | cldsvc-(DomainAbbreviation)-(ApplicationName)-(EnvironmentAbbreviation)-(Region)-(Ordinal).cloudapp.net | cldsvc-jm-bing-d-eastus-0.azurewebsites.net |
| Cognitive Services | Resource Group | cogsvc-(ApplicationName)-(EnvironmentAbbreviation)-(Region) | cogsvc-bing-d-eastus |
| Disk | Resource Group | disk-(ApplicationName or Role)-(EnvironmentAbbreviation)-(Region)-(VM Ordinal)-(Disk Ordinal) | disk-dc-d-eastus-0-0 |
| DNS Label | Global | vm-(ApplicationName or Role)-(EnvironmentAbbreviation)-(Region)-(VM Ordinal).(Region).cloudapp.azure.com | vm-dc-d-eastus-0.eastus.cloudapp.azure.com |
| Event Hub | Global | eh-(ApplicationName)-(EnvironmentAbbreviation)-(Region) | eh-bing-d-eastus |
| Function App | Global | func-(DomainAbbreviation)-(ApplicatonName)-(EnvironmentAbbreviation)-(Region)-(Ordinal).azurewebsites.net | func-jm-bing-d-eastus-0.azurewebsites.net |
| Hdinsight - Hadoop | Global | hdihd-(DomainAbbreviation)-(ApplicationName)-(EnvironmentAbbreviation)-(Region) | hdihd-jm-bing-d-eastus |
| Hdinsight - Hbase | Global | hdihb-(DomainAbbreviation)-(ApplicationName)-(EnvironmentAbbreviation)-(Region) | hdihb-jm-bing-d-eastus |
| Hdinsight - R Server | Global | hdir-(DomainAbbreviation)-(ApplicationName)-(EnvironmentAbbreviation)-(Region) | hdir-jm-bing-d-eastus |
| Hdinsight - Spark | Global | hdis-(DomainAbbreviation)-(ApplicationName)-(EnvironmentAbbreviation)-(Region) | hdis-jm-bing-dev-eastus |
| Host Pool (WVD) |  | hp-(Workload or Group Type)-(EnvironmentAbbreviation)-(Region) | hp-vdi-d-eastus |
| Key Vault | Resource Group | kv-(DomainAbbreviation)-(ApplicationName or Usage)-(EnvironmentAbbreviation)-(Region) | kv-jm-wiki-d-eastus or kv-jm-d-eastus |
| Load Balancer | Resource Group | lb-(ApplicationName)-(Tier)-(EnvironmentAbbreviation)-(Region)-(Ordinal) | lb-bing-front-d-eastus-0 |
| Log Analytics Workspace | Resource Group | law-(ApplicationName)-(EnvironmentAbbreviation)-(Region)-(Ordinal) | law-bing-d-eastus |
| Network Interface Card | Resource Group | nic-(ApplicationName)-(EnvironmentAbbreviation)-(Region)-(VM Ordinal)-(Ordinal) | nic-dc-d-eastus-0-0 |
| Network Security Group | Subnet Or NIC | nsg-(Subnet)-(EnvironmentAbbreviation)-(Region) OR nsg-(ApplicationName or Role)-(EnvironmentAbbreviation)-(Region)-(VM Ordinal)  | nsg-shared-d-eastus or nsg-dc-d-eastus-0 |
| Network Watcher | Resource Group | nw-(EnvironmentAbbreviation)-(Region) | nw-d-eastus |
| Notification Hub | Resource Group | nh-(ApplicationName)-(EnvironmentAbbreviation)-(Region) | nh-bing-d-eastus |
| Notification Hub Namespace | Global | nhns-(DomainAbbreviation)-(ApplicationName)-(EnvironmentAbbreviation)-(Region) | nhns-jm-bing-dev-eastus |
| Power BI Embedded | Global | pbiemb-(DomainAbbreviation)-(ApplicationName)-(EnvironmentAbbreviation)-(Region) | pbiem-jm-bing-d-eastus |
| Public IP | Resource Group | pip-(ApplicationName or Role or Azure Service)-(EnvironmentAbbreviation)-(Region)-(OPTIONAL: VM Ordinal)-(OPTIONAL: Ordinal) | pip-bing-d-eastus-0 or pip-dc-d-eastus-0-0 or pip-bastion-d-eastus |
| Resource Groups | Subscription | rg-(ApplicationName or Service)-(EnvironmentAbbreviation)-(Region) | rg-bing-d-eastus or rg-identity-d-eastus |
| Service Bus | Global | sb-(DomainAbbreviation)-(ApplicationName)-(EnvironmentAbbreviation)-(Region).servicebus.windows.net | sb-jm-bing-dev-eastus |
| Service Bus Queues | Service Bus | sbq-(Query Descriptor)-(EnvironmentAbbreviation)-(Region) | sbq-messagequery-d-eastus |
| Site-To-Site Connections | Resource Group | cn-(Local Gateway Name)-to-(Virtual Gateway Name) | cn-lgw-d-eastus-to-vgw-d-eastus |
| SQL Data Warehouse | Global | sqldw-(DomainAbbreviation)-(ApplicationName)-(EnvironmentAbbreviation)-(Region) | sqldw-jm-bing-d-eastus |
| SQL Server Stretch Database | Azure SQL Database | sqlstrdb-(ApplicationName)-(EnvironmentAbbreviation)-(Region) | sqlstrdb-bing-d-eastus |
| Storage Account | Global | stor(DomainAbbreviation)(ApplicationName or Usage)(EnvironmentAbbreviation)(Region)(PerformanceType)(OPTIONAL: Ordinal) | storjmbingdeastuss or storjmwvddeastusp0  |
| Storsimple | Global | storsimp-(DomainAbbreviation)-(ApplicationName)-(EnvironmentAbbreviation)-(Region) | storsimp-jm-bing-d-eastus |  
| Subnet | Virtual Network | snet-(Usage)-(EnvironmentAbbreviation)-(Region) | snet-servers-d-eastus |
| Virtual Machine | Resource Group | vm-(ApplicationName or Role)-(EnvironmentAbbreviation)-(RegionAbbreviation)-(Ordinal) | vm-dc-d-eus-0 |
| Virtual Network | Resource Group | vnet-(EnvironmentAbbreviation)-(Region) | vnet-d-eastus |
| Virtual Network Connections | Resource Group | cn-(EnvironmentAbbreviation)-(Region1)-to-(EnvironmentAbbreviation)-(Region2) | cn-d-eastus-to-d-westus2 |
| Virtual Network Local Gateway | Virtual Gateway | lgw-(EnvironmentAbbreviation)-(Region) | lgw-d-eastus |
| Virtual Network Virtual Gateway | Virtual Network | vgw-(EnvironmentAbbreviation)-(Region) | vgw-d-eastus |
| Windows Virtual Desktop Workspace | ws-(AzureService)-(EnvironmentAbbreviation)-(Region)-(Ordinal) | ws-wvd-d-eastus-0 |
