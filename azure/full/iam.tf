resource "azurerm_role_assignment" "developer_vm" {
  for_each = var.developer_principal_ids

  scope                = azurerm_linux_virtual_machine.developer[each.key].id
  role_definition_name = "Virtual Machine Contributor"
  principal_id         = each.value
}

resource "azurerm_role_assignment" "lead_vm" {
  for_each = var.lead_principal_id != "" ? local.developers : {}

  scope                = azurerm_linux_virtual_machine.developer[each.key].id
  role_definition_name = "Virtual Machine Contributor"
  principal_id         = var.lead_principal_id
}
