# OpenStack Implementation

## 1. Overview

The OpenStack implementation provides an Infrastructure as Code solution for the TechSprint developer environment.

Terraform is used to provision the infrastructure, while Ansible is used for operating system and Moodle configuration.

The deployment is driven by the shared CSV file located in `data/users.csv`. The implementation dynamically creates resources for users with the `developer` role and recognizes users with the `lead` role.

The tested input contains:

- `dev1` - developer
- `dev2` - developer
- `lead` - DevOps Lead

The implementation is designed so that additional developers can be added to the CSV file without manually defining another set of Terraform resources.

---

## 2. Architecture

Each developer receives an isolated OpenStack environment consisting of:

- one private developer network
- one private subnet
- one router with external network connectivity
- one security group
- two Moodle application instances
- one dedicated Cinder data volume per Moodle instance
- one private load balancer
- one Swift object storage container for backups
- shared file storage between the two Moodle nodes

A separate management network contains the central Jump Host.

The Jump Host is the only compute instance intended to have a Floating IP and therefore represents the administrative entry point into the environment.

Moodle instances do not receive Floating IP addresses.

The Jump Host is connected to the management network and directly to each developer network. This allows administrative SSH access to Moodle servers without establishing direct connectivity between developer environments.

---

## 3. Network Isolation

Developer networks are generated dynamically from the `10.10.0.0/16` address space.

For the current test input:

| Environment | Network |
|---|---|
| dev1 | `10.10.1.0/24` |
| dev2 | `10.10.2.0/24` |
| management | `10.10.100.0/24` |

There is no direct connection between the `dev1` and `dev2` networks.

Each developer network has its own router connected to the external OpenStack network. This provides Internet egress while preserving isolation between developer environments.

The Jump Host is connected to each developer network using additional network interfaces.

---

## 4. Moodle Compute Instances

Two Moodle instances are defined for every developer in order to provide a highly available application topology.

For the current test input:

| Instance | Private IP |
|---|---|
| dev1-moodle-1 | `10.10.1.11` |
| dev1-moodle-2 | `10.10.1.12` |
| dev2-moodle-1 | `10.10.2.11` |
| dev2-moodle-2 | `10.10.2.12` |

Explicit Neutron ports and fixed IP addresses are used to provide deterministic addressing.

The instances use the `rhel8` image.

The Academy environment provides the `default` flavor with:

- 2 vCPU
- 2 GB RAM
- 10 GB root disk

The project specification requests 2 vCPU and 4 GB RAM for application VMs. A matching 4 GB flavor was not available to the student in the Academy environment, therefore the closest available `default` flavor is used for the lab implementation.

This is an Academy environment limitation rather than the intended production sizing.

---

## 5. Security

Security groups are created using Terraform.

### Jump Host

The Jump Host security group permits SSH access on TCP port 22.

The Jump Host is the only compute instance exposed using a Floating IP.

### Moodle Servers

Each developer has a separate Moodle security group.

The Moodle servers permit:

- SSH on TCP/22 from their own developer network
- HTTP on TCP/80 from their own developer network

Moodle servers do not have Floating IP addresses.

Administrative access is performed through the Jump Host using SSH ProxyJump.

This design ensures that application servers are not directly exposed to the external network.

---

## 6. Load Balancing and High Availability

Each developer receives a private OpenStack Octavia load balancer.

The load-balancing configuration contains:

- one private load balancer per developer
- HTTP listener on TCP port 80
- round-robin pool
- two Moodle backend members
- HTTP health monitor

The health monitor checks:

`/moodle-health.html`

Ansible creates this health endpoint on the Moodle servers.

The load balancer VIP remains private and is not assigned a Floating IP.

This provides a two-node application topology and load-balancing configuration for each developer environment.

The Academy Octavia API accepted load balancer creation during testing. A test load balancer received a private VIP and entered the `PENDING_CREATE` state. The student account did not have sufficient permissions to inspect the underlying Amphora infrastructure.

The configuration therefore demonstrates the required load-balancing architecture, while complete runtime verification was limited by the Academy environment.

---

## 7. Block Storage

Every Moodle instance receives a dedicated 10 GB Cinder data volume.

For two developers with two Moodle nodes each, Terraform therefore defines four separate data volumes.

Ansible:

1. waits for the attached data disk
2. checks whether a filesystem already exists
3. creates an XFS filesystem when required
4. mounts the disk at `/data`
5. creates the Moodle data directory

The data volume is kept separate from the VM root disk.

This provides a separate OS disk and application data disk for every Moodle VM.

---

## 8. Shared File Storage

The Academy environment did not expose the OpenStack Shared File Systems CLI to the student account, so a managed Manila implementation could not be confirmed.

For the lab implementation, shared file storage is provided using NFS without introducing additional virtual machines.

For every developer:

- `moodle-1` acts as the NFS server
- `/data/shared` is exported from its Cinder-backed data disk
- `moodle-2` automatically mounts the shared directory
- access is restricted to the corresponding developer network
- `root_squash` is enabled

The NFS configuration is performed automatically using:

`ansible/playbooks/configure-file-storage.yml`

This provides automatically configured shared file storage while respecting the resource limitations of the Academy environment.

In a production OpenStack environment with Manila available, a managed shared file system would be preferable because the lab NFS design makes the first Moodle node a dependency for the shared filesystem.

---

## 9. Object Storage and Backups

Each developer receives a dedicated Swift container:

`techsprint-<username>-moodle-backups`

For example:

- `techsprint-dev1-moodle-backups`
- `techsprint-dev2-moodle-backups`

The backup script is located at:

`scripts/backup-openstack.sh`

The backup process:

1. connects to the primary Moodle node through the Jump Host
2. creates a MariaDB dump
3. archives the database dump, Moodle application files and Moodle data
4. transfers the archive to the deployment workstation
5. uploads the archive to the developer's Swift container
6. removes temporary backup data

OpenStack credentials remain on the administration/deployment host and are not copied to the Moodle application VMs.

This avoids storing infrastructure credentials on application servers.

Due to Academy IAM restrictions, fully isolated per-application Swift credentials could not be created. In a production environment, dedicated application credentials or equivalent least-privilege credentials should be used.

---

## 10. Moodle Configuration with Ansible

Terraform provisions infrastructure and Ansible performs application configuration.

The main playbooks are:

- `ansible/playbooks/configure-moodle.yml`
- `ansible/playbooks/configure-file-storage.yml`

The Moodle playbook automatically:

- installs Apache
- installs MariaDB
- installs PHP and required packages
- configures the Cinder data disk
- creates the Moodle database
- creates the database user
- downloads Moodle
- performs the Moodle CLI installation
- configures the Moodle data directory
- creates the load balancer health endpoint
- configures the firewall

Passwords are not stored in the Git repository.

The deployment requires the following environment variables:

- `MOODLE_DB_PASSWORD`
- `MOODLE_ADMIN_PASSWORD`

Moodle 4.1 is used for the lab implementation because it is compatible with the software versions available on the RHEL 8 Academy image.

Moodle 4.1 is not intended as a recommendation for a new production deployment. A currently supported Moodle release should be used in production.

---

## 11. Dynamic Ansible Inventory

The Ansible inventory can be generated automatically from Terraform outputs.

The generator is located at:

`scripts/generate-ansible-inventory.py`

Terraform provides information about:

- Jump Host Floating IP
- Moodle private IP addresses
- developer ownership
- instance numbers
- developer network CIDRs

The Python script converts these outputs into an Ansible inventory.

The generated inventory contains:

- `jump_hosts`
- one Moodle group per developer
- `moodle_primary`
- `moodle_secondary`
- combined `moodle` group

SSH access to Moodle servers is configured through the Jump Host using ProxyJump.

Because the inventory is generated from Terraform outputs, IP addresses and developer names do not have to be manually synchronized between Terraform and Ansible.

---

## 12. Automated Deployment

The complete OpenStack deployment is orchestrated by:

`scripts/deploy-openstack.sh`

The script accepts the CSV file as an argument:

```bash
./scripts/deploy-openstack.sh data/users.csv
```

Before execution, the Moodle passwords must be supplied as environment variables and the OpenStack RC file must be sourced.

Example:

```bash
source ~/developer1-finance-rc

export MOODLE_DB_PASSWORD='<password>'
export MOODLE_ADMIN_PASSWORD='<password>'

./scripts/deploy-openstack.sh data/users.csv
```

The deployment script:

1. validates the supplied CSV path
2. checks the required Moodle password environment variables
3. verifies that OpenStack credentials are loaded
4. initializes Terraform
5. validates the Terraform configuration
6. applies the infrastructure
7. reads Terraform outputs
8. dynamically generates the Ansible inventory
9. configures Moodle
10. configures shared file storage

The same workflow can process a variable number of developers because the infrastructure resources and Ansible inventory are derived from the CSV input.

The solution was designed and validated using the required test structure of two developers and one DevOps Lead.

---

## 13. IAM and RBAC Design

The intended production authorization model uses separate OpenStack projects for developer environments.

Each developer should be a member only of their own OpenStack project, allowing them to manage the lifecycle of their own virtual machines without receiving permissions over other developer environments.

For example:

- `dev1` belongs to the dev1 OpenStack project
- `dev2` belongs to the dev2 OpenStack project
- the DevOps Lead receives the required role across all developer projects

This design provides a real authorization boundary.

Assigning different Keystone roles to developers inside one shared OpenStack project would not by itself enforce per-VM ownership because instance metadata such as `owner=dev1` is not an authorization boundary.

The Red Hat Academy student account does not have the administrative Keystone permissions required to create:

- projects
- users
- groups
- roles
- policy rules

Consequently, runtime resources are created inside the provided `finance` project and the intended production IAM design is documented separately in:

`docs/openstack-iam-rbac.md`

This is an Academy authorization limitation rather than a limitation of the proposed production architecture.

---

## 14. Naming Convention

Resources follow a consistent TechSprint naming convention.

The general pattern is:

`techsprint-<owner>-<resource>`

Examples include:

- `techsprint-dev1-network`
- `techsprint-dev1-subnet`
- `techsprint-dev1-router`
- `techsprint-dev1-moodle-1`
- `techsprint-dev1-moodle-2`
- `techsprint-dev1-moodle-1-data`
- `techsprint-dev1-lb`
- `techsprint-dev1-moodle-backups`
- `techsprint-jump-sg`

Management resources use descriptive names such as:

- `techsprint-management-network`
- `techsprint-management-subnet`
- `techsprint-management-router`

The naming convention makes the resource purpose and ownership visible directly from the resource name.

---

## 15. Tags and Metadata

TechSprint resources are tagged wherever the OpenStack service and Terraform provider support tags.

The primary tags are:

- `project:techsprint`
- `environment:testing`

Developer-specific resources additionally use:

- `owner:<username>`

Role-specific resources can use:

- `role:moodle`
- `role:jump-host`
- `role:management`

Examples:

```text
project:techsprint
environment:testing
owner:dev1
role:moodle
```

Tags are applied to supported resources including:

- networks
- subnets
- routers
- security groups
- Moodle Neutron ports
- Floating IP
- load balancers
- load balancer listeners
- load balancer pools
- load balancer members

For resources where metadata is more appropriate, equivalent metadata is used.

Metadata is used for:

- compute instances
- Cinder volumes
- Swift containers

Relationship/helper resources do not require separate tagging, including:

- router interfaces
- compute interface attachments
- volume attachments
- Floating IP associations
- security group rules

The Academy OpenStack Terraform provider does not support the `tags` argument for `openstack_lb_monitor_v2`.

The load balancer health monitor is therefore identified using its TechSprint naming convention instead.

---

## 16. Red Hat Academy Environment

The implementation was developed and tested using the Red Hat Academy OpenStack environment.

The student account uses the provided `finance` project.

The OpenStack credentials are loaded using the provided RC file:

```bash
source ~/developer1-finance-rc
```

Terraform was configured with the OpenStack provider available in the Academy workstation environment.

The final Terraform configuration successfully passes:

```bash
terraform validate
```

However, the Academy environment introduced several runtime restrictions that prevented a complete final end-to-end deployment.

---

## 17. Academy Compute Capacity Limitation

During earlier testing, OpenStack successfully created infrastructure resources and the Jump Host.

When the final deterministic Moodle VM configuration was deployed, Nova returned:

```text
No valid host was found. There are not enough hosts available.
```

The newly requested Moodle instances entered the `ERROR` state.

This error is generated by the OpenStack Nova scheduler when it cannot find a compute host capable of satisfying the request.

The final Moodle VM deployment could therefore not be completed in the Academy environment.

The error is an infrastructure capacity/scheduling limitation of the shared Academy environment rather than a Terraform syntax error.

For this reason, the final configuration was validated and planned, but repeated deployment attempts were avoided.

---

## 18. Stuck Instance Deletion

During testing, some previously created Moodle instances remained in the `SHUTOFF` state while Nova reported a deleting task state.

The student account does not have permission to reset the administrative Nova instance state.

Attempting administrative state recovery returned HTTP 403.

Because the Academy account cannot perform the required administrative recovery operation, the affected resources could not be repaired by the student.

A Terraform state backup was created before removing obsolete Moodle resources from Terraform state.

This allowed development of the final Terraform configuration to continue without repeatedly waiting for stuck deletion operations.

---

## 19. Academy Octavia Limitation

OpenStack Octavia CLI commands are available in the Academy environment.

A test load balancer creation request was accepted and produced:

- an Octavia load balancer ID
- an Amphora provider assignment
- a private VIP
- `PENDING_CREATE` provisioning status

The load balancer remained in `PENDING_CREATE`.

The student account did not have sufficient permissions to inspect the underlying Amphora infrastructure.

Because Octavia Amphora load balancers depend on infrastructure resources managed internally by OpenStack, the incomplete provisioning is consistent with limitations observed in the shared lab environment.

The Terraform Octavia resource configuration itself passes Terraform validation.

---

## 20. Academy Keystone Limitation

Administrative Keystone operations are restricted for the Academy student account.

For example, service and administrative identity operations can return HTTP 403 authorization errors.

As a result, the student cannot implement the production IAM structure directly in the Academy tenant.

The production design therefore documents separate developer projects and DevOps Lead permissions, while the lab infrastructure uses the provided `finance` project.

---

## 21. Academy Manila Limitation

The OpenStack Shared File Systems command was not exposed through the CLI available to the student.

The student account also does not have sufficient Keystone permissions to inspect the complete OpenStack service catalog through administrative commands.

Therefore, Manila availability could not be reliably confirmed.

Instead of assuming that Manila was unavailable, the project implements a documented NFS fallback using the existing Moodle nodes and Cinder storage.

This allows the shared-storage requirement to be represented without requiring additional Academy compute resources.

---

## 22. Validation Status

The following components were successfully validated during project development:

- Terraform initialization
- Terraform configuration validation
- Terraform planning
- CSV parsing using Terraform
- dynamic per-developer resource definitions
- OpenStack networking configuration
- developer network isolation design
- Jump Host deployment during earlier testing
- Jump Host Floating IP assignment during earlier testing
- OpenStack security group configuration
- deterministic Neutron port configuration
- Cinder volume resource configuration
- Swift container resource configuration
- Octavia Terraform resource configuration
- Octavia API request acceptance
- resource tags and metadata
- Ansible inventory structure
- Ansible playbook syntax
- Moodle configuration playbook syntax
- NFS shared-storage playbook syntax
- Python inventory generator syntax
- deployment shell script syntax
- backup shell script syntax

The final Terraform configuration passes:

```bash
terraform validate
```

A previous complete Terraform plan also successfully generated the expected resource operations.

Full end-to-end runtime deployment of the final configuration could not be completed because the Academy Nova scheduler was unable to allocate hosts for the replacement Moodle virtual machines.

Therefore, the final project does not claim that the complete Moodle environment was successfully runtime-verified end-to-end.

---

## 23. Scalability

The implementation does not manually define infrastructure separately for `dev1` and `dev2`.

Instead, Terraform reads:

`data/users.csv`

and constructs a developer map.

Terraform `for_each` expressions are then used to dynamically create:

- networks
- subnets
- routers
- security groups
- Moodle ports
- Moodle instances
- Cinder volumes
- Swift containers
- load balancers
- listeners
- pools
- members
- health monitors

The Ansible inventory generator also reads the Terraform output dynamically.

Therefore, adding another developer to the CSV does not require manually copying Terraform resources.

For example, adding:

```csv
dev3,developer,dev
```

would cause the infrastructure logic to generate the corresponding dev3 resources during the next deployment.

This satisfies the requirement that the solution support a variable number of users rather than being hardcoded specifically for two developers.

---

## 24. Separation of Responsibilities

The project separates infrastructure provisioning from configuration management.

### Terraform

Terraform is responsible for:

- networking
- routers
- security groups
- compute instances
- Neutron ports
- Floating IP
- block storage
- object storage
- load balancing
- infrastructure outputs

### Ansible

Ansible is responsible for:

- operating system packages
- Apache
- MariaDB
- PHP
- Moodle installation
- disk formatting and mounting
- firewall configuration
- health endpoint
- NFS shared storage

### Shell and Python Automation

Supporting scripts are responsible for:

- deployment orchestration
- Terraform-to-Ansible inventory generation
- Moodle backup creation
- Swift backup upload

This separation keeps infrastructure, configuration management and orchestration responsibilities clearly defined.

---

## 25. Security Considerations

The implementation applies several security principles.

### No direct public Moodle access

Moodle virtual machines do not receive Floating IP addresses.

The Jump Host is the only compute entry point from the external network.

### Network isolation

Each developer has a separate network and subnet.

Developer networks are not directly connected to each other.

### Restricted SSH

Moodle SSH access is limited to the corresponding developer network and administrative access is performed through the Jump Host.

### Secrets

Moodle database and administrator passwords are not stored in Git.

They are supplied using environment variables.

### Backup credentials

OpenStack credentials remain on the deployment workstation rather than being copied to Moodle servers.

### Shared storage

NFS exports are restricted to the appropriate developer network and use `root_squash`.

### Resource ownership

Resources contain naming, tags and metadata indicating project, environment, role and owner where supported.

---

## 26. High Availability Considerations

The project simulates application high availability using two Moodle instances per developer behind an OpenStack load balancer.

This satisfies the required two-node application topology.

However, the lab implementation should not be interpreted as a complete production-grade active-active Moodle architecture.

Production Moodle high availability would additionally require careful design of:

- shared Moodle data
- shared application files where required
- database high availability
- session handling
- cache services
- load balancer redundancy
- backup consistency
- monitoring

The TechSprint implementation focuses on demonstrating the cloud infrastructure architecture and automation principles required by the assignment.

---

## 27. Production Improvements

For a production implementation, the following improvements would be recommended:

- use separate OpenStack projects for each developer
- use managed Manila shared file storage
- use a currently supported Moodle release
- use a currently supported production operating system
- use appropriately sized 4 GB or larger application VM flavors
- use HTTPS instead of plain HTTP
- use centralized secrets management
- use production database high availability
- use shared Moodle storage suitable for active-active operation
- implement centralized monitoring
- implement centralized logging
- configure backup retention policies
- perform automated backup restore testing
- use dedicated least-privilege application credentials
- use highly available load-balancer infrastructure
- implement infrastructure monitoring and alerting

---

## 28. Repository Structure

The main OpenStack-related files are organized as follows:

```text
openstack/
├── compute.tf
├── floating-ip.tf
├── jump-network.tf
├── keypair.tf
├── loadbalancer.tf
├── locals.tf
├── moodle-ports.tf
├── network.tf
├── object-storage.tf
├── outputs.tf
├── providers.tf
├── security.tf
├── storage.tf
├── variables.tf
└── versions.tf

ansible/
├── ansible.cfg
├── inventory/
│   └── inventory.ini
└── playbooks/
    ├── configure-file-storage.yml
    └── configure-moodle.yml

scripts/
├── backup-openstack.sh
├── deploy-openstack.sh
└── generate-ansible-inventory.py

docs/
├── openstack.md
└── openstack-iam-rbac.md

data/
└── users.csv
```

---

## 29. Summary

The OpenStack part of the TechSprint project implements a CSV-driven Infrastructure as Code architecture using Terraform, Ansible, Python and shell automation.

The solution provides:

- isolated developer networks
- a central Jump Host
- two Moodle nodes per developer
- private application addressing
- security groups
- separate block-storage volumes
- shared file storage
- Swift object storage
- automated backups
- private load balancing
- health monitoring
- resource naming
- tags and metadata
- dynamic Ansible inventory
- automated Moodle configuration
- documented IAM/RBAC design
- scalable CSV-driven resource generation

The final Terraform configuration is valid in the Red Hat Academy OpenStack environment.

Complete runtime deployment of the final topology was prevented by Academy infrastructure limitations, most notably Nova compute capacity and restricted administrative permissions.

These limitations are documented explicitly rather than being represented as successfully deployed functionality.