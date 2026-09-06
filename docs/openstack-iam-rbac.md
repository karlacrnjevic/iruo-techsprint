# OpenStack IAM and RBAC Design

## Goal

The TechSprint environment requires the following access model:

- each developer can start, stop and reboot only their own virtual machines;
- developers must not be able to manage virtual machines belonging to other developers;
- the DevOps Lead can manage all developer virtual machines;
- application virtual machines are not directly exposed to the public network.

## Recommended OpenStack design

The required isolation is implemented by using one OpenStack project per developer.

Example for the test input:

- `techsprint-dev1`
- `techsprint-dev2`
- `techsprint-management`

Each developer is a member only of their own project.

The DevOps Lead is assigned to all developer projects and to the management project.

This creates a natural OpenStack authorization boundary because Nova resources belong to a project.

## User and group structure

Example identity structure:

```text
TechSprint
|
+-- techsprint-dev1 project
|   |
|   +-- dev1
|       +-- VM Power Operator
|
+-- techsprint-dev2 project
|   |
|   +-- dev2
|       +-- VM Power Operator
|
+-- techsprint-management project
    |
    +-- lead
        +-- management role
he DevOps Lead additionally receives the required VM management role on:

techsprint-dev1
techsprint-dev2
any additional developer project generated from the CSV input

The same model therefore scales to a variable number of developers.

VM power management

The intended developer role permits the required Nova lifecycle operations:

start
stop
reboot

The role must not include administrative operations such as:

deleting other users' infrastructure;
changing OpenStack quotas;
managing Keystone users and roles;
modifying provider networks;
performing administrative Nova recovery actions.

Project isolation is used to ensure that a developer cannot perform lifecycle operations on another developer's VMs.

DevOps Lead

The DevOps Lead requires VM lifecycle permissions across all developer projects.

This allows the lead to:

start developer VMs;
stop developer VMs;
reboot developer VMs;
troubleshoot developer environments.

The lead does not require unrestricted OpenStack cloud administrator permissions.

This follows the principle of least privilege.

CSV-driven model

The deployment input is:

username,role,environment
dev1,developer,dev
dev2,developer,dev
lead,lead,management

For a production OpenStack deployment, the automation would create one project for every CSV entry with the developer role and assign the corresponding user to that project.

The lead user would receive the required role assignments across all generated developer projects.

Therefore the IAM model is not conceptually limited to dev1 and dev2.

Academy environment limitation

The Red Hat Academy OpenStack environment provides the project used for the lab but does not provide the student account with administrative Keystone permissions required to create and manage the complete IAM hierarchy.

Identity administration attempts returned HTTP 403 responses.

For example, listing Keystone services returned:

You are not authorized to perform the requested action:
identity:list_services. (HTTP 403)

Administrative Nova recovery operations were also denied by policy.

Because of these restrictions, the student account cannot create:

additional OpenStack projects;
cloud-wide roles;
the complete user/group/project hierarchy required by this design;
administrative policy changes.

For this reason, the Academy runtime infrastructure is deployed inside the provided finance project.

The production IAM architecture described above represents the intended deployment where administrative OpenStack credentials are available.

The limitation is caused by permissions of the shared educational cloud and is not bypassed by the deployment automation.

Security rationale

Using separate projects provides stronger isolation than placing all developers into one OpenStack project and relying only on VM naming or metadata.

Metadata such as:

owner=dev1
owner=dev2

is useful for identification, automation and auditing, but metadata itself is not an authorization boundary.

The authorization boundary must be enforced by OpenStack projects and RBAC policies.

Academy implementation

The Academy deployment still labels resources with ownership metadata where supported:

project=techsprint
environment=testing
owner=<developer>

This allows resources to be associated with the appropriate developer even though the Academy tenant cannot reproduce the full Keystone hierarchy.

Production recommendation

With an unrestricted OpenStack environment, the deployment workflow should be:

users.csv
    |
    v
create developer projects
    |
    +--> create/resolve developer identities
    |
    +--> assign VM Power Operator role
    |
    +--> deploy developer infrastructure
    |
    +--> assign DevOps Lead across developer projects

This design provides:

developer isolation;
least privilege;
scalable CSV-driven provisioning;
centralized DevOps Lead access.