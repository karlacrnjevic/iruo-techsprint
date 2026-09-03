# Azure Monthly Cost Estimate

## Overview

The monthly cost estimate is based on the complete TechSprint Azure architecture
implemented in `azure/full`.

The estimate represents an environment with:

- 2 developers
- 2 Moodle application instances per developer
- 1 central Jump Host
- 2 internal Load Balancers
- Azure Blob Storage
- Azure Files
- Managed Disks
- 1 public IP address

The calculation was prepared using the Microsoft Azure Pricing Calculator for
the **West Europe** region and the **Pay-as-you-go** pricing model.

## Estimated monthly cost

| Resource | Configuration | Estimated monthly cost |
|---|---|---:|
| Virtual Machines | 5 x B2als v2, Linux, 2 vCPU / 4 GB RAM, 730 h | $157.68 |
| OS Managed Disks | 5 x S4 Standard HDD, 32 GiB | $7.68 |
| Data Managed Disks | 4 x S4 Standard HDD | $6.14 |
| Azure Load Balancer | Standard, 2 LB rules, 10 GB processed | $18.30 |
| Azure Blob Storage | Standard, Hot, LRS, 10 GB | $1.32 |
| Azure Files | HDD Standard, LRS, Transaction Optimized, 10 GiB | $0.63 |
| Standard Public IP | 1 x static IPv4, 730 h | $3.65 |
| **TOTAL** | | **$195.40 / month** |

The approximate annual cost is:

**$2,344.80 per year**

Small differences can occur because the Azure Pricing Calculator rounds
individual prices and Azure pricing can change over time.

## Virtual Machines

The architecture contains five virtual machines:

- `vm-dev1-moodle-1`
- `vm-dev1-moodle-2`
- `vm-dev2-moodle-1`
- `vm-dev2-moodle-2`
- `vm-techsprint-jump`

The estimate assumes that all five virtual machines run continuously for
730 hours per month.

In a real testing environment, developer VMs would normally be deallocated
when not in use, reducing the actual monthly compute cost.

## Managed Disks

Each of the five virtual machines contains an OS disk.

Additionally, each of the four Moodle application instances has one managed
data disk.

Therefore, the estimate includes:

- 5 OS disks
- 4 additional data disks

The Terraform configuration requests a 10 GB Standard LRS data disk for each
Moodle VM. Azure Managed Disks are billed using predefined disk tiers, so the
pricing estimate uses the corresponding S4 Standard HDD tier available in the
Azure Pricing Calculator.

## Load Balancing

The architecture contains two internal Standard Azure Load Balancers:

- one for `dev1`
- one for `dev2`

Each Load Balancer contains one HTTP load-balancing rule.

The estimate therefore includes two Load Balancer rules.

Because the project specification does not define an expected traffic volume,
10 GB of monthly processed data is used as a reasonable assumption for the
testing environment.

## Blob Storage

Each developer has a dedicated Blob container used for object storage and
Moodle backups.

For the cost estimate, a combined storage consumption of 10 GB is assumed.

Configuration:

- Standard performance
- Hot access tier
- LRS redundancy
- West Europe

The estimate also includes a small number of storage operations representing
a testing workload.

## Azure Files

Each developer receives an Azure Files share with a 5 GB quota.

Therefore, the estimated total used capacity is:

- dev1: 5 GB
- dev2: 5 GB
- total: 10 GB

The estimate uses:

- HDD Standard
- Local Redundancy (LRS)
- Pay-as-you-go
- Transaction Optimized access tier

## Public IP Address

Only the central Jump Host has a public IP address.

The estimate therefore includes one Standard static public IPv4 address for
730 hours per month.

Moodle application VMs do not have public IP addresses.

## Resources without significant direct cost

The architecture also contains resources such as:

- Virtual Networks
- Subnets
- Network Security Groups
- Application Security Groups
- Managed Identities
- RBAC assignments
- Resource Groups

These resources are required by the architecture but do not represent the
main direct monthly cost components in this estimate.

## Cost optimization

The environment is intended for development and testing rather than continuous
production operation.

The most effective cost optimization is to deallocate developer VMs when they
are not required.

Additional cost optimizations include:

1. Using B-series virtual machines.
2. Using Standard LRS storage.
3. Keeping development storage capacity small.
4. Removing temporary resources when testing is complete.
5. Allowing developers to start and deallocate only their own VMs.

The custom `TechSprint VM Power Operator` role supports this model by allowing
developers to control the power state of their own virtual machines without
granting broader administrative permissions.

## Pricing assumptions

This estimate is based on Azure Pricing Calculator values captured during
project preparation.

Actual Azure charges can differ depending on:

- current Azure pricing
- subscription agreement
- currency conversion
- actual storage consumption
- number of storage transactions
- network traffic
- VM runtime

The calculated **$195.40 per month** should therefore be considered a precise
project estimate based on the stated assumptions rather than a guaranteed
Azure invoice.

## Subscription limitation

The available Azure for Students Starter subscription does not permit
deployment of the complete architecture.

Therefore, this cost estimate represents the complete infrastructure defined
in `azure/full`.

The subscription limitations encountered during project development are
documented separately in:

`azure/starter-test/README.md`
