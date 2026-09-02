data "azurerm_subscription" "current" {}

resource "azurerm_role_definition" "vm_power_operator" {
  name  = "TechSprint VM Power Operator"
  scope = data.azurerm_subscription.current.id

  description = "Allows TechSprint users to read and control the power state of virtual machines."

  permissions {
    actions = [
      "Microsoft.Compute/virtualMachines/read",
      "Microsoft.Compute/virtualMachines/instanceView/read",
      "Microsoft.Compute/virtualMachines/start/action",
      "Microsoft.Compute/virtualMachines/restart/action",
      "Microsoft.Compute/virtualMachines/powerOff/action",
      "Microsoft.Compute/virtualMachines/deallocate/action"
    ]

    not_actions = []
  }

  assignable_scopes = [
    data.azurerm_subscription.current.id
  ]
}

resource "azurerm_role_assignment" "developer_vm" {
  for_each = {
    for username, principal_id in var.developer_principal_ids :
    username => principal_id
    if contains(keys(local.developers), username)
  }

  scope              = azurerm_resource_group.developer[each.key].id
  role_definition_id = azurerm_role_definition.vm_power_operator.role_definition_resource_id
  principal_id       = each.value
}

resource "azurerm_role_assignment" "lead_vm" {
  for_each = var.lead_principal_id != "" ? local.developers : {}

  scope              = azurerm_resource_group.developer[each.key].id
  role_definition_id = azurerm_role_definition.vm_power_operator.role_definition_resource_id
  principal_id       = var.lead_principal_id
}