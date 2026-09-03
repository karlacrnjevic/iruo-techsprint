# Azure Resource Selection

## Virtual Machines

TechSprint uses B-series Linux virtual machines with 2 vCPUs and 4 GB RAM.

This configuration satisfies the required compute specification while keeping
the cost appropriate for a development and testing environment.

Four virtual machines host Moodle application instances and one central
virtual machine acts as the Jump Host.

## Load Balancer

Each developer environment uses an Internal Standard Azure Load Balancer.

The Load Balancer distributes HTTP traffic between the two Moodle instances
belonging to the developer and uses an HTTP health probe to determine whether
a backend node is available.

The frontend is private because application virtual machines must not be
directly accessible from the Internet.

Azure Application Gateway was not selected because the testing environment
does not require advanced Layer 7 features such as Web Application Firewall,
TLS termination, host-based routing or URL-based routing.

A detailed comparison is available in:

`docs/azure-lb-vs-app-gateway.md`

## Object Storage

Azure Blob Storage provides object storage.

Each developer receives a private Blob container for backup/object data.

Moodle virtual machines access the storage through System Assigned Managed
Identity and Azure RBAC rather than embedded storage credentials.

BlobFuse2 is used to expose Blob Storage through the Linux filesystem.

## File Storage

Azure Files provides shared file storage.

Each developer receives a dedicated file share that can be mounted by both
Moodle instances belonging to that developer.

Managed Identity authentication is used to avoid storing storage account keys
inside the virtual machines.

## Managed Disks

Each Moodle VM contains:

- an OS disk
- an additional managed data disk

The additional disk stores Moodle application data.

Standard LRS was selected because the infrastructure represents a testing
environment and does not require Premium SSD performance.

## Storage Redundancy

Locally Redundant Storage (LRS) is used.

LRS provides Azure-managed local redundancy while avoiding the additional
cost and complexity of geo-redundant storage, which is not required for this
testing environment.

## Networking

Every developer receives an isolated Virtual Network.

Developer VNets are connected only to the management network required for
administrative access.

There is no direct developer-to-developer VNet peering.

Only the central Jump Host receives a public IP address.

The Moodle virtual machines remain private.

## Security

Network Security Groups and Application Security Groups restrict network
access.

Azure RBAC restricts VM power operations so that developers can control only
their own environment, while the TechSprint lead can control all developer
VMs.

System Assigned Managed Identities provide application VMs with
least-privilege access to their corresponding storage resources.
