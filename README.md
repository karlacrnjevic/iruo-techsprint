# IRUO TechSprint

Projekt iz kolegija Implementacija računarstva u oblaku.

Cilj projekta je automatizirana implementacija izoliranih testnih okolina za Moodle aplikaciju koristeći Microsoft Azure i OpenStack.

## Tehnologije

- Terraform
- Ansible
- Microsoft Azure
- OpenStack
- Git
- GitHub

Azure Network and Security

![TechSprint Azure Architecture](diagrams/azure-architecture.png)

Dijagram prikazuje cjelokupnu arhitekturu Azure infrastrukture za TechSprint okruženje. Centralni Jump Host omogućuje administrativni pristup dvama međusobno izoliranim developerskim okruženjima putem VNet peeringa. Svako developersko okruženje sadrži dvije Moodle virtualne instance iza internog Load Balancera, zasebne Managed Data diskove te vlastiti Storage Account za sigurnosne kopije i dijeljene datoteke. Javno je dostupan isključivo Jump Host, dok Moodle instance ostaju unutar privatnih mreža.
