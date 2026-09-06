# IRUO TechSprint – Implementacija računarstva u oblaku

Projekt je izrađen u sklopu kolegija **Implementacija računarstva u oblaku (IRUO)**.

Cilj projekta je implementirati automatizirano cloud okruženje za razvojni tim na dvije različite cloud platforme:

- Microsoft Azure
- OpenStack

Infrastruktura se definira pomoću Infrastructure as Code pristupa, prvenstveno koristeći **Terraform**, dok se konfiguracija virtualnih strojeva automatizira pomoću **Ansiblea**.

Korisnici i njihove uloge definirani su u CSV datoteci, a infrastruktura se dinamički generira na temelju tog ulaza.

---

# Tehnologije

Projekt koristi sljedeće tehnologije i servise:

## Infrastructure as Code

- Terraform
- AzureRM provider
- AzAPI provider
- OpenStack Terraform provider

## Configuration Management

- Ansible
- Python

## Microsoft Azure

- Azure Resource Groups
- Virtual Networks
- Subnets
- Network Security Groups
- Application Security Groups
- Virtual Machines
- Managed Disks
- Azure Load Balancer
- Storage Accounts
- Blob Storage
- Azure Files
- Managed Identity
- Azure RBAC
- VNet Peering

## OpenStack

- Nova
- Neutron
- Cinder
- Swift
- Octavia
- Security Groups
- Routers
- Floating IP
- Keypairs

## Ostalo

- Bash
- Git
- GitHub
- Draw.io

---

# Ulazni podaci

Korisnici se definiraju u:

```text
data/users.csv
