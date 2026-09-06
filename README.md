# IRUO TechSprint – Implementacija računarstva u oblaku

Projekt je izrađen u sklopu kolegija **Implementacija računarstva u oblaku (IRUO)**.

Cilj projekta je izraditi automatizirano cloud okruženje za razvojni tim koristeći dvije različite cloud platforme:

- Microsoft Azure
- OpenStack

Infrastruktura se definira pomoću **Terraform IaC-a**, dok se konfiguracija virtualnih strojeva automatizira pomoću **Ansiblea**.

Korisnici i njihove uloge definirani su u CSV datoteci, a infrastruktura se dinamički generira na temelju tog ulaza.

---

# Arhitektura projekta

Projekt implementira dva cloud okruženja koja koriste isti osnovni koncept:

- zasebno okruženje za svakog developera
- dvije Moodle instance po developeru
- privatni workload
- centralni Jump Host
- load balancing
- block storage
- shared file storage
- object storage
- IAM/RBAC
- mrežna izolacija
- automatizirani deployment

Broj developer okruženja definira se kroz:

    data/users.csv

Primjer:

    username,role,environment
    dev1,developer,dev
    dev2,developer,dev
    lead,lead,management

Terraform koristi `csvdecode()` i na temelju korisničkih podataka dinamički generira potrebne resurse.

---

# Azure arhitektura

Azure implementacija koristi centralni management Resource Group i zasebni Resource Group za svakog developera.

Svaki developer dobiva vlastiti izolirani VNet.

Primjer:

    dev1 -> 10.10.1.0/24
    dev2 -> 10.10.2.0/24

Management VNet koristi:

    10.10.100.0/24

Management VNet povezan je s developer VNetovima pomoću VNet Peeringa.

Developer mreže nisu međusobno povezane.

Samo Jump Host ima javnu IP adresu.

Moodle virtualne mašine nemaju direktan javni pristup.

![Azure Architecture](diagrams/azure-architecture.png)

Detaljna Azure arhitektura opisana je u:

    docs/azure-architecture.md

---

# Azure Compute

Za svakog developera Terraform kreira dvije Moodle virtualne mašine.

Konfiguracija:

    OS: Ubuntu 22.04
    VM size: Standard_B2s
    vCPU: 2
    RAM: 4 GB

Svaka Moodle virtualna mašina ima:

- OS disk
- dodatni 10 GB managed data disk
- privatnu IP adresu
- system-assigned Managed Identity
- članstvo u odgovarajućem Application Security Groupu

Dvije Moodle instance predstavljaju osnovu za simulaciju visoke dostupnosti.

---

# Azure Networking

Azure mrežni dizajn uključuje:

- management VNet
- zaseban VNet za svakog developera
- developer subnet
- management subnet
- VNet Peering između management i developer mreža
- NSG pravila
- Application Security Groups

Developer mreže nisu direktno povezane jedna s drugom.

Na taj način je osigurana izolacija developer workloadova.

---

# Azure Load Balancer

Za svakog developera kreira se zaseban privatni Azure Standard Load Balancer.

Load Balancer koristi:

    Protocol: HTTP
    Port: 80
    Health endpoint: /moodle-health.html

Backend pool sadrži dvije Moodle instance pripadajućeg developera.

Za projekt je odabran Azure Load Balancer umjesto Application Gatewaya jer je za zahtjeve projekta dovoljan jednostavan privatni load balancing.

Detaljno obrazloženje nalazi se u:

    docs/azure-lb-vs-app-gateway.md

---

# Azure Storage

Za svakog developera kreira se zaseban Storage Account.

Koriste se dvije vrste storagea:

## Blob Storage

Koristi se za backup Moodle podataka.

Container:

    moodle-backups

## Azure Files

Koristi se kao shared file storage između Moodle instanci istog developera.

Pristup storage resursima dodatno je ograničen pomoću Managed Identity i Azure RBAC konfiguracije.

---

# Azure IAM i RBAC

Projekt definira prilagođenu Azure RBAC ulogu:

    TechSprint VM Power Operator

Developer treba moći upravljati samo vlastitim virtualnim mašinama.

Predviđene operacije uključuju:

- start
- stop
- restart

DevOps Lead ima pristup svim developer okruženjima.

Azure Entra korisnici nisu automatski kreirani zbog ograničenja studentske Azure pretplate.

Terraform zato podržava unos postojećih principal ID vrijednosti.

Detalji se nalaze u:

    docs/azure-rbac.md

---

# Azure ograničenja

Azure implementacija nije mogla biti potpuno runtime deployana zbog ograničenja pretplate:

    Azure for Students Starter

Pretplata ne dopušta registraciju svih potrebnih Azure resource providera, uključujući servise potrebne za Compute, Network i Storage resurse.

Zbog toga je Azure Terraform konfiguracija razvijena i validirana, ali finalni deployment cijele infrastrukture nije izvršen.

Detalji se nalaze u:

    docs/azure-limitations.md

---

# OpenStack arhitektura

OpenStack implementacija koristi:

- Nova
- Neutron
- Cinder
- Swift
- Octavia

Za svakog developera kreira se zasebna privatna mreža.

Primjer:

    dev1 -> 10.10.1.0/24
    dev2 -> 10.10.2.0/24

Management mreža koristi:

    10.10.100.0/24

Samo Jump Host koristi Floating IP.

Moodle instance nemaju Floating IP i nisu direktno dostupne s Interneta.

![OpenStack Architecture](diagrams/openstack-architecture.png)

Detaljna OpenStack implementacija opisana je u:

    docs/openstack.md

---

# OpenStack Jump Host

Jump Host služi kao centralna administratorska točka.

Priključen je na:

- management mrežu
- dev1 mrežu
- dev2 mrežu

Za dodatne developere Terraform može dinamički priključiti dodatne mrežne interfaceove.

Time Jump Host može pristupati developer okruženjima bez potrebe za direktnim povezivanjem developer mreža.

SSH pristup Moodle instancama koristi ProxyJump preko Jump Hosta.

---

# OpenStack Compute

Za svakog developera kreiraju se dvije Moodle instance.

U Red Hat Academy OpenStack laboratoriju koristi se:

    Image: rhel8
    Flavor: default
    vCPU: 2
    RAM: 2 GB

Projektni zahtjev predviđa 4 GB RAM-a, ali dostupni Academy flavor `default` ima 2 GB RAM-a.

To predstavlja ograničenje laboratorijskog okruženja, a ne Terraform dizajna.

Svaka Moodle instanca koristi:

- privatnu statičku IP adresu
- zaseban Neutron port
- developer Security Group
- dodatni Cinder data disk
- metadata oznake projekta i vlasnika

Primjer statičkih IP adresa:

    dev1-moodle-1 -> 10.10.1.11
    dev1-moodle-2 -> 10.10.1.12

    dev2-moodle-1 -> 10.10.2.11
    dev2-moodle-2 -> 10.10.2.12

---

# OpenStack Security Groups

Jump Host Security Group omogućuje SSH pristup.

Za svakog developera kreira se zaseban Moodle Security Group.

Dopušten je:

    SSH 22
    HTTP 80

s odgovarajuće developer mreže.

Moodle virtualne mašine nisu direktno dostupne s javne mreže.

---

# OpenStack Load Balancer

Za svakog developera definiran je zaseban privatni Octavia Load Balancer.

Konfiguracija uključuje:

- Load Balancer
- HTTP Listener
- backend pool
- dvije Moodle instance
- health monitor

Pool algoritam:

    ROUND_ROBIN

Health check koristi:

    /moodle-health.html

Terraform provider koji se koristi u Academy okruženju ne podržava `tags` argument na `openstack_lb_monitor_v2`, pa health monitor nema tagove.

Ostali podržani Octavia resursi koriste projektne tagove.

---

# OpenStack Block Storage

Svaka Moodle virtualna mašina dobiva zaseban Cinder volume.

Veličina:

    10 GB

Disk je namijenjen aplikacijskim i Moodle podacima.

Cinder volume koristi metadata vrijednosti poput:

    project = techsprint
    environment = testing
    role = moodle-data
    owner = <developer>

---

# OpenStack Shared File Storage

Red Hat Academy okruženje nije omogućilo potvrdu dostupnosti Manila servisa.

Zbog toga je implementiran NFS fallback.

Za svakog developera:

- Moodle VM 1 služi kao NFS server
- Moodle VM 2 montira shared direktorij
- shared podaci nalaze se na Cinder-backed `/data` disku

NFS export ograničen je samo na developerovu privatnu mrežu.

Koristi se:

    root_squash

Ovo je laboratorijska zamjena za managed shared storage.

U produkcijskom OpenStack okruženju preporučeno bi bilo koristiti Manila ili drugi redundantni shared-storage servis.

---

# OpenStack Object Storage

Za svakog developera Terraform kreira zaseban Swift container.

Primjer:

    techsprint-dev1-moodle-backups
    techsprint-dev2-moodle-backups

Swift container koristi se za backup Moodle podataka.

Backup automatizacija nalazi se u:

    scripts/backup-openstack.sh

---

# OpenStack IAM i RBAC

Produkcijski dizajn predviđa zaseban OpenStack projekt za svakog developera i management projekt za DevOps Lead korisnika.

Primjer:

    Developer 1 -> Project dev1
    Developer 2 -> Project dev2
    DevOps Lead -> pristup svim developer projektima

Na taj način developer bi imao pristup samo vlastitim cloud resursima.

Red Hat Academy student account nema administratorska prava za:

- stvaranje projekata
- stvaranje korisnika
- stvaranje grupa
- stvaranje custom rola
- promjene Keystone policy konfiguracije

Zbog toga se laboratorijska implementacija izvodi unutar postojećeg projekta:

    finance

Detalji se nalaze u:

    docs/openstack-iam-rbac.md

---

# Automatizacija

Projekt koristi CSV-driven provisioning.

Ulazna datoteka:

    data/users.csv

Terraform učitava korisnike i njihove uloge pomoću:

    csvdecode()

Na temelju toga dinamički generira developer resurse.

Projekt zbog toga nije ograničen na `dev1` i `dev2`.

Dodavanjem novog developera u CSV može se generirati dodatno cloud okruženje bez dupliciranja Terraform konfiguracije.

---

# OpenStack deployment flow

OpenStack deployment automatiziran je pomoću:

    scripts/deploy-openstack.sh

Deployment proces:

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

Dinamički inventory generira:

    scripts/generate-ansible-inventory.py

Na taj način Terraform i Ansible povezani su bez ručnog unosa IP adresa.

---

# Ansible

Ansible konfiguracija nalazi se u:

    ansible/
    ├── ansible.cfg
    ├── inventory/
    │   └── inventory.ini
    └── playbooks/
        ├── configure-file-storage.yml
        └── configure-moodle.yml

Glavni Moodle playbook:

    ansible/playbooks/configure-moodle.yml

automatizira:

- instalaciju Apache HTTP servera
- instalaciju MariaDB
- instalaciju PHP paketa
- konfiguraciju firewalla
- formatiranje i mountanje data diska
- stvaranje Moodle baze
- stvaranje Moodle DB korisnika
- kloniranje Moodle izvornog koda
- Moodle CLI instalaciju
- stvaranje health endpointa

Lozinke se ne pohranjuju u Git repozitorij.

Playbook ih očekuje putem environment varijabli:

    MOODLE_DB_PASSWORD
    MOODLE_ADMIN_PASSWORD

Shared storage konfigurira:

    ansible/playbooks/configure-file-storage.yml

Playbook konfigurira NFS server na primarnoj Moodle instanci te automatski mount na sekundarnoj instanci.

---

# Backup

OpenStack backup automatizacija nalazi se u:

    scripts/backup-openstack.sh

Backup uključuje:

- MariaDB dump
- Moodle aplikacijske datoteke
- Moodle data direktorij

Backup se sprema u odgovarajući Swift Object Storage container developera.

---

# Naming i tagging

Projekt koristi konzistentnu naming konvenciju.

Primjeri:

    techsprint-dev1-moodle-1
    techsprint-dev1-moodle-2
    techsprint-dev1-network
    techsprint-dev1-moodle-sg
    techsprint-dev1-moodle-backups

Standardne oznake:

    project:techsprint
    environment:testing

Dodatne oznake koriste:

    owner:<developer>
    role:<resource-role>

Detalji se nalaze u:

    docs/naming-convention.md
    docs/naming-and-tagging.md

---

# Usporedba Azure i OpenStack rješenja

Projekt implementira istu osnovnu TechSprint arhitekturu na Microsoft Azure i OpenStack platformama. Iako obje platforme omogućuju implementaciju istih osnovnih cloud koncepata, koriste različite servise i modele upravljanja.

| Funkcionalnost | Microsoft Azure | OpenStack |
|---|---|---|
| Compute | Azure Virtual Machines | Nova |
| Virtualna mreža | Azure Virtual Network (VNet) | Neutron Network |
| Subnet | Azure Subnet | Neutron Subnet |
| Routing | VNet routing / VNet Peering | Neutron Router |
| Javni pristup | Azure Public IP | Neutron Floating IP |
| Load balancing | Azure Standard Load Balancer | Octavia Load Balancer |
| Block storage | Azure Managed Disks | Cinder Volumes |
| Object storage | Azure Blob Storage | Swift Object Storage |
| File storage | Azure Files | Manila / NFS fallback |
| Identity | Microsoft Entra ID | Keystone |
| Autorizacija | Azure RBAC | Keystone Roles / Policies |
| Sigurnost mreže | NSG + ASG | Neutron Security Groups |
| IaC provider | Terraform AzureRM / AzAPI | Terraform OpenStack Provider |
| Administrativni pristup | Jump Host | Jump Host |

## Compute

Na Azure platformi aplikacijske instance implementirane su pomoću **Azure Virtual Machines**, dok OpenStack koristi **Nova** servis.

Azure implementacija koristi `Standard_B2s` virtualne mašine s 2 vCPU i 4 GB RAM-a, što odgovara zahtjevima projekta.

U Red Hat Academy OpenStack okruženju koristi se `default` flavor s 2 vCPU i 2 GB RAM-a jer flavor s traženih 4 GB RAM-a nije dostupan korisniku laboratorija.

## Mreže

Azure koristi **Virtual Networks (VNet)** i VNet Peering, dok OpenStack koristi **Neutron Networks, Subnets i Routers**.

Na obje platforme svaki developer dobiva zasebnu izoliranu mrežu.

Javni pristup omogućen je isključivo Jump Hostu:

- Azure koristi Public IP
- OpenStack koristi Floating IP

Moodle instance ostaju u privatnim mrežama.

## Load balancing

Azure implementacija koristi **Azure Standard Load Balancer**, dok OpenStack koristi **Octavia Load Balancer**.

Na obje platforme load balancer je privatan i distribuira HTTP promet između dvije Moodle instance pripadajućeg developera.

Azure Load Balancer odabran je umjesto Application Gatewaya jer projekt ne zahtijeva napredne Layer 7 funkcionalnosti poput WAF-a, URL-based routinga ili TLS terminacije.

## Block storage

Azure koristi **Managed Disks**, dok OpenStack koristi **Cinder Volumes**.

Svaka Moodle instanca ima OS disk i dodatni 10 GB data disk.

Time je aplikacijski podatkovni disk odvojen od operacijskog sustava.

## Object storage

Azure koristi **Blob Storage**, dok OpenStack koristi **Swift Object Storage**.

Object storage koristi se za pohranu podataka i sigurnosnih kopija povezanih s Moodle okruženjem.

Za svakog developera predviđen je zaseban storage prostor kako bi podaci različitih razvojnih okruženja ostali odvojeni.

## File storage

Azure koristi managed servis **Azure Files**.

OpenStack ekvivalent za shared file storage je **Manila**. Budući da dostupnost Manila servisa nije bilo moguće potvrditi u Red Hat Academy okruženju, OpenStack implementacija koristi NFS fallback na Cinder-backed data disku.

U produkcijskom OpenStack okruženju prednost bi imao Manila ili drugi redundantni managed shared-storage servis.

## IAM i prava pristupa

Azure koristi **Microsoft Entra ID i Azure RBAC**.

OpenStack koristi **Keystone** projekte, korisnike i role.

Na obje platforme arhitektura je dizajnirana tako da developer upravlja samo vlastitim resursima, dok DevOps Lead ima prava upravljanja svim TechSprint okruženjima.

Potpuna Keystone IAM implementacija nije mogla biti primijenjena u Red Hat Academy okruženju jer studentski korisnik nema administratorska prava za kreiranje projekata, korisnika, grupa i rola.

## Infrastructure as Code

Obje implementacije koriste Terraform.

Azure koristi:

    AzureRM
    AzAPI

OpenStack koristi:

    OpenStack Terraform Provider

Isti `data/users.csv` koncept koristi se kao ulaz za dinamičko generiranje developer okruženja, čime se održava isti automatizacijski pristup na obje cloud platforme.

## Zaključak usporedbe

Azure pruža veći broj potpuno upravljanih servisa i integrirani IAM model kroz Entra ID i Azure RBAC, dok OpenStack pruža veću kontrolu nad infrastrukturom i mogućnost implementacije u privatnom cloud okruženju.

S funkcionalne strane obje platforme mogu zadovoljiti TechSprint arhitekturu. Glavna razlika je u načinu upravljanja servisima: Azure većinu komponenti pruža kao managed cloud usluge, dok OpenStack administratoru daje veću kontrolu, ali često zahtijeva više konfiguracije i održavanja.

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
    |       +-- configure-file-storage.yml
    |       +-- configure-moodle.yml
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

Definira potrebnu Terraform verziju i Azure providere.

## `providers.tf`

Konfigurira AzureRM i AzAPI providere.

## `variables.tf`

Definira ulazne parametre poput:

- lokacije
- resource group naziva
- CSV putanje
- VM sizea
- administrator konfiguracije
- RBAC principal ID vrijednosti

## `locals.tf`

Učitava korisnike iz CSV datoteke i generira Terraform strukture koje se koriste za dinamičko kreiranje resursa.

## `resource-group.tf`

Kreira centralni Resource Group i developer Resource Groupove.

## `network.tf`

Kreira:

- management VNet
- developer VNetove
- subnete
- VNet peering

## `security.tf`

Definira Network Security Groups i odgovarajuća sigurnosna pravila.

## `asg.tf`

Definira Application Security Groups.

## `compute.tf`

Kreira:

- Jump Host
- Moodle virtualne mašine
- mrežne interfaceove
- OS diskove
- data diskove
- Managed Identities

## `loadbalancer.tf`

Kreira privatni Azure Standard Load Balancer za svakog developera.

## `storage.tf`

Kreira developer Storage Accounts, Blob Storage i Azure Files.

## `storage-rbac.tf`

Definira storage RBAC prava.

## `storage-smb-oauth.tf`

Konfigurira pristup Azure Files storageu.

## `iam.tf`

Definira RBAC model i custom VM Power Operator role.

## `outputs.tf`

Izlaže podatke o kreiranoj infrastrukturi.

---

# Opis OpenStack Terraform datoteka

## `versions.tf`

Definira Terraform i OpenStack provider zahtjeve.

## `providers.tf`

Konfigurira OpenStack provider.

## `variables.tf`

Definira ulazne parametre deploymenta.

## `locals.tf`

Učitava korisnike iz CSV datoteke i generira:

- developer strukturu
- lead strukturu
- developer mreže
- Moodle instance
- statičke IP adrese

## `network.tf`

Kreira:

- management mrežu
- developer mreže
- subnete
- routere
- povezivanje prema external provider mreži

## `jump-network.tf`

Dodaje Jump Hostu mrežne interfaceove prema developer mrežama.

## `security.tf`

Kreira security groups za Jump Host i Moodle instance.

## `keypair.tf`

Konfigurira SSH keypair.

## `moodle-ports.tf`

Kreira eksplicitne Neutron portove sa statičkim IP adresama.

## `compute.tf`

Kreira Jump Host i dvije Moodle instance po developeru.

## `floating-ip.tf`

Kreira i povezuje Floating IP samo s Jump Hostom.

## `loadbalancer.tf`

Kreira privatni Octavia Load Balancer za svakog developera.

Konfigurira:

- Load Balancer
- Listener
- Pool
- Moodle member instance
- HTTP health monitor

## `storage.tf`

Kreira zaseban Cinder data disk za svaku Moodle virtualnu mašinu.

## `object-storage.tf`

Kreira zaseban Swift backup container za svakog developera.

## `outputs.tf`

Izlaže podatke potrebne za administraciju i daljnju automatizaciju.

---

# Opis skripti

## `deploy-azure.sh`

Služi za automatizirano pokretanje Azure Terraform deploymenta.

## `deploy-openstack.sh`

Glavna je OpenStack deployment skripta.

Izvršava:

1. provjeru ulaznih parametara
2. provjeru potrebnih environment varijabli
3. provjeru OpenStack credentiala
4. Terraform init
5. Terraform validate
6. Terraform apply
7. spremanje Terraform outputa
8. generiranje Ansible inventoryja
9. Moodle Ansible konfiguraciju
10. shared storage konfiguraciju

## `generate-ansible-inventory.py`

Generira Ansible inventory iz Terraform outputa.

## `backup-openstack.sh`

Automatizira backup Moodle baze i podataka u Swift Object Storage.

---

# Dokumentacija

Dodatna dokumentacija nalazi se u:

    docs/

Dokumenti uključuju:

- `azure-architecture.md` – detaljan opis Azure arhitekture
- `azure-cost-estimate.md` – procjena Azure troškova
- `azure-lb-vs-app-gateway.md` – obrazloženje izbora load balancing rješenja
- `azure-limitations.md` – ograničenja Azure Students Starter pretplate
- `azure-rbac.md` – Azure RBAC dizajn
- `azure-resource-selection.md` – obrazloženje izbora Azure resursa
- `naming-and-tagging.md` – tagging pravila
- `naming-convention.md` – naming konvencija
- `openstack-iam-rbac.md` – OpenStack IAM/RBAC dizajn
- `openstack.md` – detaljna OpenStack implementacija i ograničenja

---

# Validacija

Azure Terraform konfiguracija razvijena je i validirana u granicama dostupne studentske Azure pretplate.

Potpuni Azure runtime deployment nije bilo moguće izvršiti zbog ograničenja Azure for Students Starter pretplate.

OpenStack Terraform konfiguracija uspješno je prošla:

    terraform validate

Ansible playbookovi prošli su syntax check.

Python inventory generator provjeren je pomoću:

    python3 -m py_compile

Shell skripte provjerene su pomoću:

    bash -n

Dio OpenStack infrastrukture uspješno je kreiran i testiran u Red Hat Academy okruženju, uključujući networking i Jump Host.

---

# Ograničenja OpenStack Academy okruženja

Finalni end-to-end deployment nije mogao biti dovršen zbog infrastrukturnih ograničenja Red Hat Academy laboratorija.

Pri kreiranju novih virtualnih strojeva OpenStack Nova vratila je:

    No valid host was found. There are not enough hosts available.

Problem je povezan s raspoloživim compute kapacitetom laboratorijskog OpenStack okruženja.

Dodatno:

- Keystone administratorske operacije vraćaju HTTP 403
- dostupni flavor ima 2 GB RAM-a umjesto traženih 4 GB
- Octavia testni Load Balancer ostao je u `PENDING_CREATE` stanju
- dostupnost Manila servisa nije bilo moguće potvrditi

Zbog toga projekt ne tvrdi da je finalni OpenStack deployment potpuno runtime izvršen.

Terraform konfiguracija i automatizacijski kod dovršeni su i validirani u granicama dostupnog Academy okruženja.

---

# Skalabilnost

Projekt nije ograničen na dva developera.

Broj developer okruženja definira se u:

    data/users.csv

Dodavanjem novog retka:

    dev3,developer,dev

Terraform može generirati novo izolirano developer okruženje bez ručnog dupliciranja infrastrukturnog koda.

---

# Status projekta

Implementirano je:

- Azure Terraform infrastruktura
- OpenStack Terraform infrastruktura
- CSV-driven provisioning
- dvije Moodle instance po developeru
- izolirane developer mreže
- centralni Jump Host
- privatni load balancing
- block storage
- shared file storage
- object storage
- Security Groups / NSG
- Application Security Groups
- Azure RBAC dizajn
- OpenStack IAM/RBAC dizajn
- Managed Identities
- naming i tagging
- Ansible Moodle konfiguracija
- automatsko generiranje Ansible inventoryja
- OpenStack deployment skripta
- Azure deployment skripta
- OpenStack backup skripta
- Azure arhitekturni dijagram
- OpenStack arhitekturni dijagram
- Azure cost estimate
- dokumentirana ograničenja cloud laboratorijskih okruženja

Projekt demonstrira Infrastructure as Code pristup automatiziranoj implementaciji izoliranih razvojnih cloud okruženja na Microsoft Azure i OpenStack platformama.
