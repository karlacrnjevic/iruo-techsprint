# Azure Environment Limitations

The full Azure TechSprint architecture is implemented in `azure/full`.

The available **Azure for Students Starter** subscription does not permit registration of the required resource providers:

- Microsoft.Compute
- Microsoft.Network
- Microsoft.Storage

Provider registration returned `DisallowedProvider`.

Because these restrictions are imposed by the available subscription, the full environment cannot be runtime deployed using this subscription.

The Terraform implementation has therefore been checked using:

```bash
terraform init
terraform fmt
terraform validate
