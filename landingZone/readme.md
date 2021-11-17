# Azure Landing Zone

## Deployment Options

### Azure Portal

### PowerShell

### Azure CLI

## Description

A landing zone is the core infrastructure needed to support a workload in Azure.  Typically this involves your networking and identity.

This solution deploys 3 basic landing zones in 1 deployment.  This allows you to test 3 identity scenarios in Azure:

1. Active Directory Domain Services on Azure IaaS virtual machines
1. Azure Active Directory Domain Services with a managed domain
1. Azure Active Directory

Each identity architecture is established in its own, isolated virtual network.

For someone testing Azure Virtual Desktop, having all 3 scenarios allows you to validate functionality across all identity architectures.  Virtual machines can be joined to any of the directories.

## Prerequisites

This solution deploys Azure ADDS.  There are prerequisites to deploy Azure ADDS in an Azure subscription and are contained in the "preDeployment.ps1" script file.

## Post Deployment

While most of the infrastructure is deployed using the templates and scripts, Azure AD Connect cannot be automated.  Since this solution is meant for a lab or development, Azure AD Connect can be installed on the IaaS domain controller.  The directions can be found [here](https://docs.microsoft.com/en-us/azure/active-directory/hybrid/how-to-connect-install-express).
