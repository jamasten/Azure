# Azure Virtual Desktop Solution

[**Home**](../readme.md) | [**Features**](./features.md) | [**Design**](./design.md) | [**Prerequisites**](./prerequisites.md) | [**Post Deployment**](./post.md) | [**Troubleshooting**](./troubleshooting.md)

## Design

This Azure Virtual Desktop (AVD) solution will deploy a fully operational AVD [stamp](https://docs.microsoft.com/en-us/azure/architecture/patterns/deployment-stamp) in an Azure subscription. The "StampIndex" parameter in this solution allows each stamp to be identified and scale beyond a single subscription. However, several different stamps could be deployed in one subscription or one large stamp could consume the whole subscription, depending on resource limitations and other considerations like billing. To uniquely name multiple, unrelated stamps within a subscription, input a unique value for the "Identifier" parameter in each deployment.

With this solution you can scale up to Azure's subscription limitations. The code is idempotent, allowing you to scale storage, networking, and sessions hosts but the core management resources will persist and update for an subsequent deployments. Some of those resources are the host pool, application group, and log analytics workspace. See the diagram below for more details about the resources deployed in this solution:

![Solution](../images/solution.png)

Both a personal or pooled host pool can be deployed with this solution. Either option will deploy a desktop application group with a role assignment. Selecting a pooled host pool will deploy the required resources and configurations to fully enable FSLogix. This solution also automates many of the features that are usually enabled manually after deploying an AVD host pool.

## Sharding to Increase Capacity

This solution has been updated to allow sharding. A shard provides additional capacity to an AVD stamp. See the options below for increasing network or storage capacity.

### Network Shard

To add networking capacity to an AVD stamp, a new virtual network should be staged prior to deploying this code. When running a new deployment specify the new values for the "VirtualNetwork", "VirtualNetworkResourceGroup", and "Subnet" parameters. The sessions hosts will be deployed to the new virtual network. The "SessionHostIndex" and "SessionHostCount" parameters will also play into the network shards. For example:

| Shard | VNET           | Subnet  | Session Host Index | Session Host Count |
|-------|----------------|---------|--------------------|--------------------|
| 0     | vnet-p-eus-000 | Clients | 0                  | 250                |
| 1     | vnet-p-eus-001 | Clients | 250                | 250                |
| 2     | vnet-p-eus-002 | Clients | 500                | 250                |

In this example, each shard will contain 250 session hosts and each set of sessions hosts will be in different VNET.

### Storage Shard

To add storage capacity to an AVD stamp, the "StorageIndex" and "StorageCount" parameters should be modified to your desired capacity. The last two digits in the name for the chosen storage solution will be incremented between each deployment. The "VHDLocations" setting will include all the file shares. The "SecurityPrincipalIds" and "SecurityPrincipalNames" will have an RBAC assignment and NTFS permissions on one storage shard per stamp. Each user in the stamp should only have access to one file share. When the user accesses a session host, their profile will load from their respective file share. 
