# Naming Standard

## Components

| Component | Description | Example |
| ----------- | ----------- | ----------- |
| BusinessUnit | Top-level division of your company that owns the subscription or workload the resource belongs to. In smaller organizations, this may represent a single corporate top-level organizational element. | fin, mktg, product, it, corp |
| Application Name | Name of the application, workload, or service associated with the resource. | navigator, emissions, sharepoint, hadoop |
| Environment | The stage of the workload's development lifecycle that the resource is supporting. | prod, dev, qa, stage, test, sandbox, shared |
| Region | Azure region where the resource is deployed. | westus, eastus, usgovva, usgovtx, usgovaz |
| Performance Type | Azure Storage Accout Skus: (p)remium, (s)tandard | p, s |

## Resource Type Prefixes

| Resource | Prefix |
| ----------- | ----------- |
| App Services | azapp- |
| Automation Account | aa- |
| Azure Cosmos DB (Document Database) | cosdb- |
| Azure Cache for Redis | redis- |
| Azure Database for MySQL | mysql- |
| Azure Data Lake Storage | dls |
| Azure Data Lake Analytics | dla |
| Azure IoT Hub | aih- |
| Azure Machine Learning Workspace | aml- |
| Azure Search | srch- |
| Azure SQL Database | sqldb- |
| Cloud Services | azcs- |
| Cognitive Services | cs-
| Data Factory | df- |
| Event Hub | evh- |
| Function Apps | azfun- |
| Gateway connection | vnetgwcn- |
| HDInsight - Spark | hdis- |
| HDInsight - Hadoop | hdihd- |
| HDInsight - R server| hdir- |
| HDInsight - HBase | hdihb- |
| Host Pool | hp- |
| Load Balancer | lb- |
| NIC | nic- |
| Notification Hub | anh- |
| Notification Hub Namespace | anhns- |
| NSG | nsg- |
| Power BI Embedded | pbiemb |
| Public IP | pip- |
| Resource Group | rg- |
| Service Bus | sb- |
| Service Bus Queues | sbq- |
| SQL Data Warehouse | sqldw- |
| SQL Server Stretch Database | sqlstrdb- |
| Storage Account | stor |
| StorSimple | ssimp |
| Stream analytics | asa- |
| Subnet | snet- |
| Virtual Machines | vm- |
| Virtual Network | vnet- |
| Virtual Network Gateway | vnetgw- |
| Windows Virtual Destop Workspace | wvdws- |

## Convention

| Type | Scope | Format | Example |
| ----------- | ----------- | ----------- | ----------- |
| App Service | Global | app-(ApplicationName)-(Environment)-(Region)-(Ordinal).azurewebsites.net | app-jmasten-dev-eastus-0.azurewebsites.net |
| Automation Account | Global | aa(DomainPrefix)(ApplicationName or Usage)(Environment)(Region) | aajmastenwikideveastus or aajmastenupdatedeveastus |
| Availability Set | Resource Group | as-vm(ApplicationName)(Environment)(Region) | as-vmdcdeveastus |
| Azure Cache For Redis | Global | redis-(ApplicationName)-(Environment)-(Region) | redis-jmasten-dev-eastus |
| Azure Cosmos DB (Document Database) | Global | cosdb-(ApplicationName)-(Environment)-(Region) | cosdb-jmasten-dev-eastus |
| Azure Data Factory | Global | adf-(ApplicationName)-(Environment)-(Region) | adf-jmasten-dev-eastus |
| Azure Data Lake Analytics | Global | adla(ApplicationName)(Environment)(Region) | adlajmastendeveastus |
| Azure Data Lake Storage | Global | adls(ApplicationName)(Environment)(Region) | adlsjmastendeveastus |
| Azure Database For MySQL | Global | mysql-(ApplicationName)-(Environment)-(Region) | mysql-jmasten-dev-eastus |
| Azure Iot Hub | Global | aih-(ApplicationName)-(Environment)-(Region) | aih-jmasten-dev-eastus |
| Azure Machine Learning Workspace | Resource Group | aml-(ApplicationName)-(Environment)-(Region) | aml-jmasten-dev-eastus |
| Azure Search | Global | srch-(ApplicationName)-(Environment)-(Region) | srch-jmasten-dev-eastus |
| Azure SQL Database | Global | sqldb-(ApplicationName)-(Environment)-(Region) | sqldb-jmasten-dev-eastus |
| Azure Stream Analytics on Iot Edge | Resource Group | asa-(ApplicationName)-(Environment)-(Region) | asa-jmasten-dev-eastus |
| Cloud Services | Global | cldsvc-(ApplicationName)-(Environment)-(Region)-(Ordinal).cloudapp.net | cldsvc-jmasten-dev-eastus-0.azurewebsites.net |
| Cognitive Services | Resource Group | cogsvc-(ApplicationName)-(Environment)-(Region) | cogsvc-jmasten-dev-eastus |
| Disk | Resource Group | disk-vm(ApplicationName)(Environment)(Region)(VM Ordinal)-(Ordinal) | disk-vmdcdeveastus0-0 |
| DNS Label | Global | vm(ApplicationName)(Environment)(Region)(VM Ordinal).(Region).cloudapp.azure.com | vmdcdeveastus0.eastus.cloudapp.azure.com |
| Event Hub | Global | eh-(ApplicationName)-(Environment)-(Region) | eh-jmasten-dev-eastus |
| Function App | Global | func-(ApplicatonName)-(Environment)-(Region)-(Ordinal).azurewebsites.net | func-jmasten-dev-eastus-0.azurewebsites.net |
| Hdinsight - Hadoop | Global | hdihd-(ApplicationName)-(Environment)-(Region) | hdihd-jmasten-dev-eastus |
| Hdinsight - Hbase | Global | hdihb-(ApplicationName)-(Environment)-(Region) | hdihb-jmasten-dev-eastus |
| Hdinsight - R Server | Global | hdir-(ApplicationName)-(Environment)-(Region) | hdir-jmasten-dev-eastus |
| Hdinsight - Spark | Global | hdis-(ApplicationName)-(Environment)-(Region) | hdis-jmasten-dev-eastus |
| Host Pool (WVD) | hp-(Workload or Group Type)-(Environment)-(Region) | hp-vdi-dev-eastus |
| Key Vault | Resource Group | kv(DomainPrefix)(ApplicationName or Usage)(Environment)(Region) | kvjmastenwikideveastus or kvjmastenencdeveastus |
| Load Balancer | Resource Group | lb-(ApplicationName)-(Environment)-(Region)-(Ordinal) | lb-jmasten-dev-eastus-0 |
| Log Analytics Workspace | Resource Group | law-(ApplicationName)-(Environment)-(Region)-(Ordinal) | law-dev-eastus |
| Network Interface Card | Resource Group | nic-vm(ApplicationName)(Environment)(Region)(VM Ordinal)-(Ordinal) | nic-vmdcdeveastus0-0 |
| Network Security Group | Subnet Or NIC | nsg-(Subnet)-(Environment)-(Region) OR nsg-(VM Name)  | nsg-shared-dev-eastus or nsg-vmdcdeveastus0 |
| Network Watcher | Resource Group | nw-(Environment)-(Region) | nw-dev-eastus |
| Notification Hub | Resource Group | nh-(ApplicationName)-(Environment)-(Region) | nh-jmasten-dev-eastus |
| Notification Hub Namespace | Global | nhns-(ApplicationName)-(Environment)-(Region) | nhns-jmasten-dev-eastus |
| Power BI Embedded | Global | pbiemb-(ApplicationName)-(Environment)-(Region) | pbiem-jmasten-dev-eastus |
| Public IP | Resource Group | pip-(ApplicationName)(Environment)(Region)(Ordinal)-(Ordinal) | pip-dcdeveastus0-0 |
| Resource Groups | Subscription | rg-(ApplicationName)-(SubscriptionType)-(Region) | rg-shared-dev-eastus |
| Service Bus | Global | sb-(ApplicationName)-(Environment)-(Region).servicebus.windows.net | sb-jmasten-dev-eastus |
| Service Bus Queues | Service Bus | sbq-(Query Descriptor) | sbq-messagequery |
| Site-To-Site Connections | Resource Group | cn-(Local Gateway Name)-to-(Virtual Gateway Name) | cn-lgw-shared-eastus-to-vgw-shared-eastus |
| SQL Data Warehouse | Global | sqldw-(ApplicationName)-(Environment)-(Region) | sqldw-jmasten-dev-eastus |
| SQL Server Stretch Database | Azure SQL Database | sqlstrdb-(ApplicationName)-(Environment)-(Region) | sqlstrdb-jmasten-dev-eastus |
| Storage Account | Global | stor(PerformanceType)(DomainPrefix)(ApplicationName or Usage)(Environment)(Region)(Ordinal) | storsjmastenwikideveastus or storpjmastenwvddeveastus  |
| Storsimple | Global | storsimp(ApplicationName)(Environment)(Region) | storsimpjmastendeveastus |  
| Subnet | Virtual Network | snet-(Usage)-(Environment)-(Region) | snet-wvd-dev-eastus |
| Virtual Machine | Resource Group | vm(ApplicationName)(Environment)(Region)(Ordinal) | vmdcdeveastus0 |
| Virtual Network | Resource Group | vnet-(Environment)-(Region) | vnet-dev-eastus |
| Virtual Network Connections | Resource Group | cn-(Environment)-(Region1)-to-(Environment)-(Region2) | cn-dev-eastus-to-dev-westus |
| Virtual Network Local Gateway | Virtual Gateway | vnetlgw-(Environment)-(Region) | vnetlgw-dev-eastus |
| Virtual Network Virtual Gateway | Virtual Network | vnetvgw-(Environment)-(Region) | vnetvgw-dev-eastus |
| Windows Virtual Desktop Workspace | wvdws-(Environment)-(Region)-(Ordinal) | wvdws-dev-eastus-01 |
