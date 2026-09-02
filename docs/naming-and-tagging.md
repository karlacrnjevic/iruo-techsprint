# Naming and Tagging Convention

## Naming convention

TechSprint resources use predictable names based on resource type, project and owner.

| Resource | Example |
|---|---|
| Resource Group | `rg-techsprint-dev1` |
| Virtual Network | `vnet-dev1` |
| Virtual Machine | `vm-dev1-moodle-1` |
| Network Interface | `nic-dev1-1` |
| Load Balancer | `lb-dev1-internal` |
| Application Security Group | developer-specific ASG |
| Storage Account | generated developer-specific name |
| Managed Disk | `disk-dev1-moodle-1-data` |
| Jump Host | `vm-techsprint-jump` |

The convention makes the resource type and owner visible directly from the resource name.

## Tags

Common tags are applied through Terraform:

| Tag | Value |
|---|---|
| `project` | `techsprint` |
| `environment` | `testing` |

Developer-owned resources additionally use:

| Tag | Example |
|---|---|
| `owner` | `dev1` |

Resources associated with individual Moodle nodes can additionally contain the instance number.

Example:

```text
project     = techsprint
environment = testing
owner       = dev1
instance    = 1
