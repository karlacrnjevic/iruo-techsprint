# Azure for Students Starter - Environment Validation

The TechSprint Azure infrastructure is implemented in `azure/full`.

The available Azure subscription is **Azure for Students Starter**. During
environment validation, the subscription did not permit registration of the
resource providers required by the full TechSprint infrastructure.

The following providers were tested:

- Microsoft.Compute
- Microsoft.Network
- Microsoft.Storage

Provider registration returned `DisallowedProvider`.

Because of this subscription limitation, resources such as virtual machines,
virtual networks, load balancers and storage accounts cannot be deployed in
this environment.

The complete Terraform implementation is therefore maintained in
`azure/full` and validated using:

```bash
terraform -chdir=azure/full init
terraform -chdir=azure/full validate
