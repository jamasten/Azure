# Naming Standard

## Components
| Component | Description | Example |
| ----------- | ----------- | ----------- |
| BusinessUnit | Top-level division of your company that owns the subscription or workload the resource belongs to. In smaller organizations, this may represent a single corporate top-level organizational element. | fin, mktg, product, it, corp |
| App/ServiceName | Name of the application, workload, or service associated with the resource. | navigator, emissions, sharepoint, hadoop |
| Environment | The stage of the workload's development lifecycle that the resource is supporting. | prod, dev, qa, stage, test, sandbox, shared |
| Region | Azure region where the resource is deployed. | westus, eastus, usgovva, usgovtx, usgovaz |
| Performance Type | (p)remium, (s)tandard |

## Resource Type Prefixes
| Resource | Prefix |
| ----------- | ----------- |
| App Services | azapp- |
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
| Function Apps |	azfun- |
| Gateway connection |	vnetgwcn- |
| HDInsight - Spark | hdis- |
| HDInsight - Hadoop | hdihd- |
| HDInsight - R server| hdir- |
| HDInsight - HBase | hdihb- |
| Load Balancer |	lb- |
| NIC |	nic- |
| Notification Hub | anh- |
| Notification Hub Namespace | anhns- |
| NSG |	nsg- |
| Power BI Embedded | pbiemb |
| Public IP |	pip- |
| Resource Group | rg- |
| Service Bus |	sb- |
| Service Bus Queues | sbq- |
| SQL Data Warehouse | sqldw- |
| SQL Server Stretch Database | sqlstrdb- |
| Storage Account |	stor |
| StorSimple | ssimp |
| Stream analytics | asa- |
| Subnet | snet- |
| Virtual Machines | vm- |
| Virtual Network |	vnet- |
| Virtual Network Gateway |	vnetgw- |

## Convention
| Type | Scope | Format | Example |
| ----------- | ----------- | ----------- | ----------- |
| DNS Label | Global | (VM Name).(Region).cloudapp.azure.com | vmdcdeveastus01.eastus.cloudapp.azure.com
| Load Balancer | Resource Group | lb-(App Name Or Role)(Environment)(###) Lb-Sharepoint-Dev-001
| Network Security Group | Subnet Or NIC | nsg-(Subnet or VM Name with Ordinal)-(SubscriptionType)-(Region) | nsg-shared-eastus |
| Public IP | Resource Group | pip-(Virtual Machine Name)-(Ordinal) | pip-vmdcdeveastus01-01 |
| Resource Groups | Subscription | rg-(App/ServiceName)-(SubscriptionType)-(Region) | rg-shared-dev-eastus |
| Site-To-Site Connections | Resource Group | cn-(Local Gateway Name)-to-(Virtual Gateway Name) | cn-lgw-shared-eastus-to-vgw-shared-eastus |
| Storage Account | Global | stor(PerformanceType)(ApplicationName)(Environment)(Region)(Ordinal) | storpwvddeveastus01
| Subnet | Virtual Network | snet-(SubscriptionType)-(Region) | snet-shared-eastus |
| Virtual Machine | Resource Group | vm(ApplicationName)(Environment)(Region)(Ordinal) | vmdcdeveastus01 |
| Virtual Network | Resource Group | vnet-(SubscriptionType)-(Region) | vnet-shared-eastus |
| Virtual Network Connections | Resource Group | cn-(SubscriptionType1)-(Region1)-to-(SubscriptionType2)-(Region2) | cn-shared-eastus-to-shared-westus |
| Virtual Network Local Gateway | Virtual Gateway | vnetlgw-(Subscriptiontype)-(Region) | vnetlgw-shared-eastus |
| Virtual Network Virtual Gateway | Virtual Network | vnetvgw-(SubscriptionType)-(Region) | vnetvgw-shared-eastus |










NIC Resource Group Nic-(##)-(Vmname)-(Subscription)(###) Nic-02-Vmhadoop1-Prod-001
App Service Global Azapp-(App Name)-(Environment)-(###).[{Azurewebsites.Net}] Azapp-Navigator-Prod-001.Azurewebsites.Net
Function App Global Azfun-(App Name)-(Environment)-(###).[{Azurewebsites.Net}] Azfun-Navigator-Prod-001.Azurewebsites.Net
Cloud Services Global Azcs-(App Name)-(Environment)-(###).[{Cloudapp.Net}] Azcs-Navigator-Prod-001.Azurewebsites.Net
Service Bus Global Sb-(App Name)-(Environment).[{Servicebus.Windows.Net}] Sb-Navigator-Prod
Service Bus Queues Service Bus Sbq-(Query Descriptor) Sbq-Messagequery
Azure SQL Database Global Sqldb-(App Name)-(Environment) Sqldb-Navigator-Prod
Azure Cosmos DB (Document Database) Global Cosdb-(App Name)-(Environment) Cosdb-Navigator-Prod
Azure Cache For Redis Global Redis-(App Name)-(Environment) Redis-Navigator-Prod
Azure Database For Mysql Global Mysql-(App Name)-(Environment) Mysql-Navigator-Prod
SQL Data Warehouse Global Sqldw-(App Name)-(Environment) Sqldw-Navigator-Prod
SQL Server Stretch Database Azure SQL Database Sqlstrdb-(App Name)-(Environment) Sqlstrdb-Navigator-Prod
Azure Storage Account - General Use Global St(Storage Name)(###) Stnavigatordata001
Azure Storage Account - Diagnostic Logs Global Stdiag(First 2 Letters Of Subscription Name And Number)(Region)(###) Stdiagsh001eastus2001
Storsimple Global Ssimp(App Name)(Environment) Ssimpnavigatorprod  
Asset Type Scope Format Example
Azure Search Global Srch-(App Name)-(Environment) Srch-Navigator-Prod
Cognitive Services Resource Group Cs-(App Name)-(Environment) Cs-Navigator-Prod
Azure Machine Learning Workspace Resource Group Aml-(App Name)-(Environment) Aml-Navigator-Prod  
Asset Type Scope Format Example
Azure Data Factory Global Df-(App Name)(Environment) Df-Navigator-Prod
Azure Data Lake Storage Global Dls(App Name)(Environment) Dlsnavigatorprod
Azure Data Lake Analytics Global Dla(App Name)(Environment) Dlanavigatorprod
Hdinsight - Spark Global Hdis-(App Name)-(Environment) Hdis-Navigator-Prod
Hdinsight - Hadoop Global Hdihd-(App Name)-(Environment) Hdihd-Hadoop-Prod
Hdinsight - R Server Global Hdir-(App Name)-(Environment) Hdir-Navigator-Prod
Hdinsight - Hbase Global Hdihb-(App Name)-(Environment) Hdihb-Navigator-Prod
Power BI Embedded Global Pbiemb(App Name)(Environment) Pbiem-Navigator-Prod   
Asset Type Scope Format Example
Azure Stream Analytics On Iot Edge Resource Group Asa-(App Name)-(Environment) Asa-Navigator-Prod
Azure Iot Hub Global Aih-(App Name)-(Environment) Aih-Navigator-Prod
Event Hub Global Evh-(App Name)-(Environment) Evh-Navigator-Prod
Notification Hub Resource Group Anh-(App Name)-(Environment) Evh-Navigator-Prod
Notification Hub Namespace Global Anhns-(App Name)-(Environment) Anhns-Navigator-Prod
