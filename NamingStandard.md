# Naming Standard

## Components
| Component | Description | Example |
| ----------- | ----------- |
| BusinessUnit | Top-level division of your company that owns the subscription or workload the resource belongs to. In smaller organizations, this may represent a single corporate top-level organizational element. | fin, mktg, product, it, corp |
| SubscriptionType | Summary description of the purpose of the subscription containing the resource. Often broken down by deployment environment type or specific workloads. | prod, dev, shared, client |
| App/ServiceName | Name of the application, workload, or service associated with the resource. | navigator, emissions, sharepoint, hadoop |
| Environment | The stage of the workload's development lifecycle that the resource is supporting. | prod, dev, qa, stage, test |
| Region | Azure region where the resource is deployed. | westus, eastus, usgovva, usgovtx, usgovaz |

## Resource Type Prefixes
| Resource | Prefix |
| ----------- | ----------- |
| App Services | azapp- |
| Azure Cosmos DB (Document Database) | cosdb- |
| Azure Cache for Redis | redis- |
| Azure Database for MySQL | mysql- |
| Azure Data Lake Storage | dls- |
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
| Power BI Embedded | pbiemb- |
| Public IP |	pip- |
| Resource Group | rg- |
| Service Bus |	sb- |
| Service Bus Queues | sbq- |
| SQL Data Warehouse | sqldw- |
| SQL Server Stretch Database | sqlstrdb- |
| Storage Account |	stor- |
| StorSimple | ssimp- |
| Stream analytics | asa- |
| Subnet | snet- |
| Virtual Machines | vm- |
| Virtual Network |	vnet- |
| Virtual Network Gateway |	vnetgw- |

## Convention
| Type | Scope | Format | Example |
| ----------- | ----------- |
| Resource Groups | Subscription | rg-<App / Service name>-<Location>-<Subscription type>-<Ordinal> | rg-core |
