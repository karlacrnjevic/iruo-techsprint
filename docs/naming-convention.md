# Naming Convention

Projekt koristi konzistentnu konvenciju imenovanja resursa na Azure i OpenStack platformama.

Cilj konvencije je omogućiti jednostavno prepoznavanje projekta, korisnika, vrste resursa, namjene resursa i okruženja.

## Opća pravila

Nazivi resursa koriste sljedeća pravila:

- mala slova gdje platforma to zahtijeva
- riječi se odvajaju znakom `-`
- prefiks `techsprint` koristi se za resurse projekta gdje je to praktično
- korisnički resursi sadrže korisničko ime, npr. `dev1` ili `dev2`
- management resursi koriste naziv `management`
- nazivi resursa developera generiraju se Terraformom na temelju podataka iz `data/users.csv`, dok centralni management resursi koriste unaprijed definirane nazive

Primjeri:

```text
techsprint-dev1
techsprint-dev2
techsprint-management
```

## Azure

### Resource Groups

Centralni resursi koriste naziv:

```text
rg-techsprint
```

Resursi pojedinog developera koriste naziv developera kako bi se jasno razlikovali od resursa drugih korisnika.

Primjeri:

```text
rg-techsprint-dev1
rg-techsprint-dev2
```

### Virtual Networks

Virtualne mreže koriste prefiks `vnet-`.

Primjeri:

```text
vnet-dev1
vnet-dev2
```

### Subnets

Subneti koriste prefiks `snet-`.

Primjeri:

```text
snet-dev1
snet-dev2
snet-management
```

### Network Security Groups

NSG resursi koriste prefiks `nsg-`.

Primjer:

```text
nsg-dev1
```

### Application Security Groups

ASG resursi koriste prefiks `asg-`.

### Virtual Machines

Moodle instance označene su korisnikom i rednim brojem instance.

Primjeri:

```text
vm-dev1-moodle-1
vm-dev1-moodle-2
vm-dev2-moodle-1
vm-dev2-moodle-2
```

Jump Host koristi zaseban naziv koji jasno označava njegovu funkciju.

Primjer:

```text
vm-techsprint-jump
```

### Load Balancer

Load Balancer resursi koriste prefiks `lb-`.

Primjer:

```text
lb-dev1-internal
```

### Storage

Storage resursi u nazivu sadrže TechSprint projekt i korisnika gdje Azure ograničenja naziva to dopuštaju.

Blob i Azure Files resursi kreiraju se zasebno za svakog developera.

## OpenStack

OpenStack koristi istu logiku odvajanja resursa po developeru.

### Projects

Svaki developer ima vlastiti Keystone projekt.

Primjeri:

```text
techsprint-dev1
techsprint-dev2
```

Centralni administratorski projekt koristi naziv:

```text
techsprint-management
```

### Networks

Developer mreže koriste obrazac:

```text
techsprint-<developer>-network
```

Primjeri:

```text
techsprint-dev1-network
techsprint-dev2-network
```

Management mreža koristi naziv:

```text
techsprint-management-network
```

### Instances

Moodle instance koriste naziv developera i redni broj.

Primjeri:

```text
techsprint-dev1-moodle-1
techsprint-dev1-moodle-2
techsprint-dev2-moodle-1
techsprint-dev2-moodle-2
```

Jump Host koristi zaseban naziv:

```text
techsprint-jump
```

### Volumes

Data diskovi vezani su uz odgovarajuću Moodle instancu.

Primjer:

```text
techsprint-dev1-moodle-1-data
```

### Object Storage

Swift container koristi naziv developera.

Obrazac:

```text
techsprint-<developer>-moodle-backups
```

Primjeri:

```text
techsprint-dev1-moodle-backups
techsprint-dev2-moodle-backups
```

### Load Balancer

Octavia Load Balancer koristi obrazac:

```text
techsprint-<developer>-lb
```

## Tagging

Gdje platforma podržava tagove ili metadata vrijednosti, svi resursi koriste najmanje:

```text
project     = techsprint
environment = testing
```

Resursi vezani uz developera dodatno koriste oznaku vlasnika:

```text
owner = <username>
```

Primjer:

```text
project     = techsprint
environment = testing
owner       = dev1
```

Za resurse s posebnom funkcijom koristi se i oznaka uloge.

Primjeri:

```text
role = developer
role = management
role = jump-host
```

## Svrha konvencije

Ovakva konvencija omogućuje:

- jednostavno razlikovanje i prepoznavanje resursa
- jasno vlasništvo nad resursima
- lakšu automatizaciju kroz Terraform
- lakše filtriranje i administraciju resursa
- jasno odvajanje infrastrukture developera
- konzistentnost između dokumentacije i IaC implementacije
