# IRUO TechSprint – Implementacija računarstva u oblaku

Projekt je izrađen u sklopu kolegija **Implementacija računarstva u oblaku (IRUO)**.

Cilj projekta je automatizirati implementaciju cloud infrastrukture za razvojne timove na dvije cloud platforme:

- Microsoft Azure
- OpenStack

Infrastruktura se definira pomoću **Terraform IaC-a**, dok se konfiguracija virtualnih strojeva i Moodle aplikacije automatizira pomoću **Ansiblea**.

Broj razvojnih okruženja nije statički definiran. Korisnici se učitavaju iz CSV datoteke `data/users.csv`, nakon čega Terraform dinamički generira potrebnu infrastrukturu.

Projektna implementacija koristi dva developera (`dev1`, `dev2`) i jednog DevOps Lead korisnika (`lead`) kao testni primjer.

---

# Arhitektura projekta

Projekt implementira isti osnovni koncept na dvije različite cloud platforme.

Svaki developer dobiva izolirano razvojno okruženje koje uključuje:

- zasebnu mrežu
- dvije Moodle virtualne mašine
- privatni load balancer
- block storage
- shared file storage
- object storage za backup
- sigurnosna pravila
- odgovarajuća prava pristupa

Centralni **Jump Host** predstavlja jedinu javno dostupnu virtualnu mašinu i koristi se za administrativni pristup privatnim Moodle instancama.

Developer okruženja međusobno nisu direktno povezana.

---

# Azure arhitektura

Azure implementacija koristi sljedeće servise:

- Azure Resource Groups
- Azure Virtual Network
- Azure Subnets
- Azure Network Security Groups
- Azure Application Security Groups
- Azure Virtual Machines
- Azure Managed Disks
- Azure Standard Load Balancer
- Azure Storage Account
- Azure Blob Storage
- Azure Files
- Azure RBAC
- Managed Identities
- VNet Peering

Arhitektura koristi centralnu management mrežu i zasebnu mrežu za svakog developera.

Primjer:

    Management VNet
    10.10.100.0/24

    DEV1 VNet
    10.10.1.0/24

    DEV2 VNet
    10.10.2.0/24

Management VNet povezan je s developer VNetovima pomoću **VNet Peeringa**.

Ne postoji direktni peering između developer mreža.

Svaki developer ima dvije Moodle virtualne mašine iza privatnog Azure Standard Load Balancera.

Jump Host je jedina virtualna mašina s Public IP adresom.

Detaljniji opis Azure arhitekture nalazi se u:

    docs/azure-architecture.md

---

# OpenStack arhitektura

OpenStack implementacija koristi:

- Nova – virtualne mašine
- Neutron – mreže, subneti, routeri i security groups
- Cinder – block storage
- Swift – object storage
- Octavia – load balancing
- Terraform – provisioning infrastrukture
- Ansible – konfiguracija operacijskog sustava i Moodle aplikacije

Za svakog developera kreira se zasebna privatna mreža.

Primjer:

    Management network
    10.10.100.0/24

    DEV1 network
    10.10.1.0/24

    DEV2 network
    10.10.2.0/24

Developer mreže međusobno nisu povezane.

Jump Host ima pristup management mreži i dodatne mrežne interfaceove prema developer mrežama.

Na taj način administrator može pristupati Moodle virtualnim mašinama preko Jump Hosta bez direktnog povezivanja developer mreža.

Svaki developer ima:

- dvije Moodle virtualne mašine
- privatni Octavia Load Balancer
- Cinder data disk
- Swift backup container
- shared file storage

U Academy okruženju koristi se **RHEL 8** image.

Zbog ograničenja dostupnog OpenStack Academy flavora koristi se:

    2 vCPU
    2 GB RAM

iako projektni zahtjev predviđa:

    2 vCPU
    4 GB RAM

To ograničenje proizlazi iz dostupnih resursa Academy laboratorija, a ne iz Terraform dizajna.

Detaljniji opis nalazi se u:

    docs/openstack.md

---

# High Availability

Za svakog developera kreiraju se dvije Moodle instance.

Primjer:

    dev1-moodle-1
    dev1-moodle-2

    dev2-moodle-1
    dev2-moodle-2

Instance se nalaze iza privatnog load balancera.

Azure koristi:

    Azure Standard Load Balancer

OpenStack koristi:

    Octavia Load Balancer

Load balanceri distribuiraju HTTP promet između dvije Moodle instance.

Implementacija predstavlja infrastrukturnu simulaciju visoke dostupnosti. Potpuna produkcijska Moodle HA implementacija zahtijevala bi dodatnu konfiguraciju zajedničke baze podataka, session managementa i potpuno redundantnog shared storage sustava.

---

# Storage

Projekt koristi tri tipa storagea.

## Block storage

Svaka Moodle virtualna mašina ima dodatni data disk.

Azure:

    Azure Managed Disk
    10 GB

OpenStack:

    Cinder Volume
    10 GB

Disk se koristi za aplikacijske podatke.

---

## Shared file storage

Azure koristi:

    Azure Files

OpenStack Academy okruženje nije omogućilo potvrdu dostupnosti Manila servisa.

Zbog toga je implementiran NFS fallback.

Prva Moodle instanca developera služi kao NFS server, dok druga Moodle instanca automatski montira shared direktorij.

NFS pristup ograničen je samo na developerovu privatnu mrežu.

Ovo predstavlja funkcionalnu laboratorijsku alternativu managed file-storage servisu. U produkcijskom OpenStack okruženju preporučeno bi bilo koristiti Manila ili drugi redundantni shared-storage servis.

---

## Object storage

Azure koristi:

    Azure Blob Storage

OpenStack koristi:

    Swift Object Storage

Za svakog developera kreira se zaseban backup container.

Primjer:

    techsprint-dev1-moodle-backups
    techsprint-dev2-moodle-backups

Backup skripta nalazi se u:

    scripts/backup-openstack.sh

---

# Sigurnost

Projekt koristi princip najmanjih potrebnih privilegija i izolaciju razvojnih okruženja.

Glavne sigurnosne mjere su:

- samo Jump Host ima javni pristup
- Moodle virtualne mašine nemaju Public IP
- developer mreže međusobno nisu direktno povezane
- pristup virtualnim mašinama kontrolira se security pravilima
- storage pristup ograničen je prema developer okruženju
- SSH pristup Moodle instancama izvodi se preko Jump Hosta
- credentiali i private key datoteke nisu spremljeni u Git repozitoriju
- osjetljive Terraform datoteke isključene su pomoću `.gitignore`

---

# IAM i RBAC

## Azure

Azure implementacija koristi:

- Azure RBAC
- Managed Identities
- custom VM Power Operator role

Developer dobiva prava upravljanja vlastitim virtualnim mašinama.

Predviđene operacije uključuju:

- start
- stop
- restart

DevOps Lead ima prava upravljanja developer okruženjima.

Detalji:

    docs/azure-rbac.md

---

## OpenStack

Produkcijski dizajn predviđa zaseban OpenStack projekt za svakog developera te management projekt za DevOps Lead korisnika.

Time se omogućuje stvarna izolacija resursa na Keystone razini.

Academy korisnik nema administratorska prava za:

- kreiranje projekata
- kreiranje korisnika
- kreiranje grupa
- kreiranje custom rola
- izmjenu Keystone policyja

Zbog toga se laboratorijska implementacija izvršava unutar dostupnog projekta `finance`.

Detalji:

    docs/openstack-iam-rbac.md

---

# Automatizacija

Automatizacija koristi CSV datoteku:

    data/users.csv

Primjer sadržaja:

    username,role,environment
    dev1,developer,dev
    dev2,developer,dev
    lead,lead,management

Terraform učitava CSV pomoću funkcije:

    csvdecode()

Na temelju sadržaja CSV datoteke dinamički se kreiraju developer okruženja.

To znači da Terraform konfiguracija nije ograničena samo na `dev1` i `dev2`.

Dodavanjem novog developera u CSV može se generirati dodatno razvojno okruženje bez ručnog dupliciranja Terraform resursa.

---

# Deployment flow

OpenStack deployment automatiziran je skriptom:

    scripts/deploy-openstack.sh

Proces izgleda ovako:

    users.csv
        |
        v
    Terraform
        |
        v
    OpenStack infrastruktura
        |
        v
    Terraform outputs
        |
        v
    generate-ansible-inventory.py
        |
        v
    Ansible inventory
        |
        v
    Ansible playbooks
        |
        v
    Moodle konfiguracija

Dinamički Ansible inventory generira:

    scripts/generate-ansible-inventory.py

Na taj način Terraform i Ansible ostaju povezani bez ručnog unosa IP adresa.

---

# Ansible

Ansible se koristi nakon provisioning faze za konfiguraciju virtualnih mašina.

Konfiguracija se nalazi u:

    ansible/

Glavni playbookovi su:

    ansible/playbooks/configure-moodle.yml
    ansible/playbooks/configure-file-storage.yml

`configure-moodle.yml` konfigurira:

- Apache HTTP Server
- MariaDB
- PHP
- Moodle
- data disk
- Moodle bazu
- Moodle administratora
- firewall
- health endpoint

`configure-file-storage.yml` konfigurira shared NFS storage između dvije Moodle instance istog developera.

SSH pristup privatnim Moodle virtualnim mašinama koristi Jump Host pomoću ProxyJump konfiguracije.

---

# Backup

OpenStack backup automatizacija nalazi se u:

    scripts/backup-openstack.sh

Backup uključuje:

- MariaDB dump
- Moodle aplikacijske datoteke
- Moodle data direktorij

Backup se zatim sprema u developerov Swift container.

Na taj način svaki developer ima odvojeni object-storage prostor za backup.

---

# Naming convention

Resursi koriste konzistentnu naming konvenciju.

Primjeri:

    techsprint-dev1-moodle-1
    techsprint-dev1-moodle-2
    techsprint-dev1-network
    techsprint-dev1-moodle-sg
    techsprint-dev1-moodle-backups

Detaljniji opis naming konvencije nalazi se u:

    docs/naming-convention.md
    docs/naming-and-tagging.md

---

# Tagging i metadata

Resursi koriste standardne oznake:

    project:techsprint
    environment:testing

Dodatno se koriste oznake:

    owner:<developer>
    role:<resource-role>

Primjer:

    project:techsprint
    environment:testing
    owner:dev1
    role:moodle

Azure koristi Azure tags, dok OpenStack koristi tags ili metadata ovisno o mogućnostima pojedinog resursa i Terraform providera.

---

# Struktura repozitorija

    iruo-techsprint/
    |
    +-- README.md
    +-- .gitignore
    |
    +-- data/
    |   +-- users.csv
    |
    +-- azure/
    |   +-- full/
    |   |   +-- versions.tf
    |   |   +-- providers.tf
    |   |   +-- variables.tf
    |   |   +-- locals.tf
    |   |   +-- resource-group.tf
    |   |   +-- network.tf
    |   |   +-- security.tf
    |   |   +-- asg.tf
    |   |   +-- compute.tf
    |   |   +-- loadbalancer.tf
    |   |   +-- storage.tf
    |   |   +-- storage-rbac.tf
    |   |   +-- storage-smb-oauth.tf
    |   |   +-- iam.tf
    |   |   +-- outputs.tf
    |   |   +-- .terraform.lock.hcl
    |   |
    |   +-- starter-test/
    |       +-- README.md
    |
    +-- openstack/
    |   +-- versions.tf
    |   +-- providers.tf
    |   +-- variables.tf
    |   +-- locals.tf
    |   +-- network.tf
    |   +-- jump-network.tf
    |   +-- security.tf
    |   +-- keypair.tf
    |   +-- moodle-ports.tf
    |   +-- compute.tf
    |   +-- floating-ip.tf
    |   +-- loadbalancer.tf
    |   +-- storage.tf
    |   +-- object-storage.tf
    |   +-- outputs.tf
    |
    +-- ansible/
    |   +-- ansible.cfg
    |   +-- inventory/
    |   |   +-- inventory.ini
    |   +-- playbooks/
    |       +-- configure-moodle.yml
    |       +-- configure-file-storage.yml
    |
    +-- scripts/
    |   +-- deploy-azure.sh
    |   +-- deploy-openstack.sh
    |   +-- generate-ansible-inventory.py
    |   +-- backup-openstack.sh
    |
    +-- diagrams/
    |   +-- azure-architecture.drawio
    |   +-- azure-architecture.png
    |   +-- openstack-architecture.drawio
    |   +-- openstack-architecture.png
    |
    +-- docs/
        +-- azure-architecture.md
        +-- azure-cost-estimate.md
        +-- azure-lb-vs-app-gateway.md
        +-- azure-limitations.md
        +-- azure-rbac.md
        +-- azure-resource-selection.md
        +-- naming-and-tagging.md
        +-- naming-convention.md
        +-- openstack-iam-rbac.md
        +-- openstack.md

---

# Opis Azure Terraform datoteka

## `versions.tf`

Definira minimalnu Terraform verziju i potrebne providere.

## `providers.tf`

Konfigurira AzureRM i AzAPI providere.

## `variables.tf`

Definira ulazne varijable poput:

- Azure lokacije
- resource group naziva
- CSV putanje
- VM sizea
- administrator konfiguracije
- RBAC principal ID vrijednosti

## `locals.tf`

Učitava korisnike iz CSV datoteke i generira strukture podataka koje Terraform koristi za dinamičko kreiranje resursa.

## `resource-group.tf`

Kreira centralni management Resource Group i developer Resource Groupove.

## `network.tf`

Kreira:

- management VNet
- developer VNetove
- subnete
- VNet peering

Developer mreže ostaju međusobno izolirane.

## `security.tf`

Definira Network Security Groups i sigurnosna pravila.

## `asg.tf`

Definira Application Security Groups za grupiranje virtualnih mašina prema njihovoj ulozi.

## `compute.tf`

Kreira:

- Jump Host
- dvije Moodle virtualne mašine po developeru
- mrežne interfaceove
- OS diskove
- dodatne data diskove
- Managed Identities

## `loadbalancer.tf`

Kreira privatni Azure Standard Load Balancer za svakog developera.

Load balancer koristi health probe:

    /moodle-health.html

## `storage.tf`

Kreira developer storage accountove, Blob container i Azure Files share.

## `storage-rbac.tf`

Definira storage RBAC prava.

## `storage-smb-oauth.tf`

Konfigurira pristup Azure Files storageu.

## `iam.tf`

Definira RBAC model i custom VM Power Operator role.

## `outputs.tf`

Izlaže ključne podatke o kreiranoj infrastrukturi.

---

# Opis OpenStack Terraform datoteka

## `versions.tf`

Definira Terraform i OpenStack provider zahtjeve.

## `providers.tf`

Konfigurira OpenStack provider.

## `variables.tf`

Definira ulazne parametre OpenStack deploymenta.

## `locals.tf`

Učitava korisnike iz CSV datoteke i dinamički generira:

- developere
- lead korisnike
- developer mreže
- Moodle instance
- statičke Moodle IP adrese

## `network.tf`

Kreira:

- management mrežu
- developer mreže
- subnete
- routere
- povezivanje prema external provider mreži

## `jump-network.tf`

Dodaje Jump Hostu dodatne mrežne interfaceove prema developer mrežama.

To omogućuje administrativni pristup bez međusobnog povezivanja developer mreža.

## `security.tf`

Kreira security groups za:

- Jump Host
- Moodle instance

Moodle instance nisu direktno dostupne s Interneta.

## `keypair.tf`

Konfigurira SSH keypair za pristup virtualnim mašinama.

## `moodle-ports.tf`

Kreira eksplicitne Neutron portove sa statičkim IP adresama za Moodle virtualne mašine.

## `compute.tf`

Kreira Jump Host i dvije Moodle instance po developeru.

## `floating-ip.tf`

Kreira i povezuje Floating IP samo s Jump Hostom.

## `loadbalancer.tf`

Kreira privatni Octavia load balancer za svakog developera.

Konfigurira:

- load balancer
- listener
- pool
- dvije Moodle member instance
- HTTP health monitor

## `storage.tf`

Kreira zaseban Cinder data volume za svaku Moodle virtualnu mašinu i povezuje ga s odgovarajućom instancom.

## `object-storage.tf`

Kreira zaseban Swift backup container za svakog developera.

## `outputs.tf`

Izlaže:

- Jump Host adresu
- Moodle IP adrese
- developer mreže
- load balancer VIP adrese
- ostale podatke potrebne za automatizaciju

---

# Opis skripti

## `deploy-azure.sh`

Služi za automatizirano pokretanje Azure Terraform deploymenta.

## `deploy-openstack.sh`

Predstavlja glavni OpenStack deployment workflow.

Skripta:

1. provjerava ulazne parametre
2. provjerava potrebne environment varijable
3. provjerava OpenStack credentials
4. izvršava Terraform init
5. izvršava Terraform validate
6. izvršava Terraform apply
7. sprema Terraform output
8. generira Ansible inventory
9. pokreće Moodle Ansible konfiguraciju
10. konfigurira shared file storage

## `generate-ansible-inventory.py`

Dinamički generira Ansible inventory iz Terraform outputa.

## `backup-openstack.sh`

Automatizira backup Moodle baze i aplikacijskih podataka u Swift Object Storage.

---

# Dokumentacija

Dodatna dokumentacija nalazi se u direktoriju:

    docs/

Dokumenti uključuju:

- `azure-architecture.md` – detaljan opis Azure arhitekture
- `azure-cost-estimate.md` – procjena Azure troškova
- `azure-lb-vs-app-gateway.md` – usporedba Load Balancera i Application Gatewaya
- `azure-limitations.md` – ograničenja Azure Students Starter pretplate
- `azure-rbac.md` – Azure RBAC model
- `azure-resource-selection.md` – obrazloženje izbora Azure servisa
- `naming-and-tagging.md` – naming i tagging pravila
- `naming-convention.md` – naming konvencija
- `openstack-iam-rbac.md` – OpenStack IAM/RBAC dizajn
- `openstack.md` – detaljna OpenStack implementacija i ograničenja

---

# Validacija

Azure Terraform konfiguracija prošla je Terraform sintaksnu i konfiguracijsku validaciju.

Potpuni Azure runtime deployment nije bilo moguće izvršiti zbog ograničenja **Azure for Students Starter** pretplate i nedostupne registracije potrebnih resource providera.

OpenStack Terraform konfiguracija uspješno je prošla:

    terraform validate

Ansible playbookovi uspješno su prošli syntax check.

Python inventory generator uspješno je provjeren pomoću:

    python3 -m py_compile

Shell deployment i backup skripte provjerene su pomoću:

    bash -n

Dio OpenStack infrastrukture uspješno je testiran u Red Hat Academy okruženju, uključujući networking, Jump Host i Terraform provisioning.

---

# Ograničenja OpenStack Academy okruženja

Finalni end-to-end OpenStack deployment nije mogao biti dovršen zbog infrastrukturnih ograničenja Academy laboratorija.

Tijekom testiranja pojavila se Nova greška:

    No valid host was found. There are not enough hosts available.

To ukazuje na nedostatak dostupnog compute kapaciteta u Academy okruženju.

Dodatno:

- Keystone administratorske operacije vraćaju HTTP 403
- dostupni flavor ima 2 GB RAM-a umjesto projektom traženih 4 GB
- Octavia testni load balancer ostao je u `PENDING_CREATE` stanju
- dostupnost Manila servisa nije bilo moguće potvrditi

Zbog navedenih ograničenja finalna konfiguracija nije predstavljena kao potpuno runtime verificirani deployment.

Terraform konfiguracija i automatizacijski kod dovršeni su i validirani u granicama dostupnog laboratorijskog okruženja.

---

# Skalabilnost

Projekt nije ograničen na dva developera.

Broj developer okruženja kontrolira se putem:

    data/users.csv

Dodavanjem novog retka, primjerice:

    dev3,developer,dev

Terraform može generirati dodatno izolirano developer okruženje bez dupliciranja infrastrukturnog koda.

To uključuje novu mrežu, Moodle instance, load balancer, storage i sigurnosne resurse.

---

# Status projekta

Implementirano:

- Azure Terraform infrastruktura
- OpenStack Terraform infrastruktura
- CSV-driven provisioning
- dvije Moodle instance po developeru
- izolirane developer mreže
- centralni Jump Host
- privatni load balancing
- block storage
- shared storage
- object storage
- security groups / NSG
- Azure RBAC dizajn
- OpenStack IAM/RBAC dizajn
- Managed Identities
- Terraform tagging i metadata
- Ansible Moodle konfiguracija
- automatski Ansible inventory
- OpenStack deployment skripta
- Azure deployment skripta
- OpenStack backup skripta
- arhitekturna dokumentacija
- naming convention
- Azure cost estimate
- dokumentirana ograničenja laboratorijskih okruženja

Projekt demonstrira automatizirani Infrastructure as Code pristup implementaciji izoliranih razvojnih cloud okruženja na Microsoft Azure i OpenStack platformama.
