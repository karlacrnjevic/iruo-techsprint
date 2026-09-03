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

Ovaj repozitorij sadrži Infrastructure as Code konfiguraciju, skripte i dokumentaciju za TechSprint projekt. Projekt obuhvaća implementaciju infrastrukture na Microsoft Azure i OpenStack platformama te automatizaciju potrebnu za kreiranje developerskih okruženja.

## Azure konfiguracija

### `azure/`

Sadrži Terraform konfiguraciju za Azure dio projekta.

### `azure/full/`

Glavna Azure Infrastructure as Code implementacija. Ovdje se nalaze Terraform datoteke koje definiraju kompletnu TechSprint infrastrukturu.

- **`variables.tf`**  
  Definira ulazne varijable koje se koriste tijekom deploymenta, primjerice Azure regiju, nazive resursa, VM veličinu, putanju do CSV datoteke i identifikatore korisnika.

- **`locals.tf`**  
  Priprema podatke koje Terraform koristi interno. Između ostalog obrađuje korisnike iz CSV datoteke te definira developerska okruženja, mrežne raspone, Moodle instance i zajedničke tagove.

- **`resource-group.tf`**  
  Definira centralnu Resource Group te zasebne Resource Groupove za pojedina developerska okruženja.

- **`network.tf`**  
  Definira Azure mrežnu infrastrukturu, uključujući Management VNet, developerske VNete, subnetove i VNet peering između management i developerskih mreža.

- **`security.tf`**  
  Definira Network Security Group pravila kojima se kontrolira mrežni pristup management i developerskim resursima.

- **`asg.tf`**  
  Definira Application Security Groups koji omogućuju grupiranje virtualnih strojeva i primjenu sigurnosnih pravila.

- **`compute.tf`**  
  Definira virtualne strojeve, mrežna sučelja i Jump Host. Developerska okruženja sadrže dvije Moodle instance radi simulacije visoke dostupnosti.

- **`load-balancer.tf`**  
  Definira interne Azure Load Balancere koji distribuiraju HTTP promet prema Moodle instancama pojedinog developerskog okruženja.

- **`storage.tf`**  
  Definira storage resurse developerskih okruženja, uključujući Managed Diskove, Blob Storage i Azure Files.

- **`storage-smb-oauth.tf`**  
  Konfigurira identity-based pristup Azure Files storageu putem Managed Identity mehanizma.

- **`iam.tf`**  
  Definira Azure RBAC model i role assignmente za upravljanje virtualnim strojevima.

- **`outputs.tf`**  
  Definira informacije koje Terraform prikazuje nakon deploymenta.

- **Moodle bootstrap konfiguracija**  
  Koristi se tijekom inicijalizacije virtualnih strojeva za instalaciju i konfiguraciju Moodle aplikacije te montiranje potrebnog storagea.

### `azure/starter-test/`

Sadrži dokumentaciju povezanu s korištenom Azure for Students Starter pretplatom.

Ovaj dio služi za dokumentiranje ograničenja pretplate zbog kojih nije moguće izvršiti puni Azure deployment, iako se glavna Terraform konfiguracija može lokalno validirati.
