resource "azurerm_role_assignment" "developer" {
  for_each = var.developer_principal_ids

  scope                = azurerm_resource_group.techsprint.id
  role_definition_name = "Reader"
  principal_id         = each.value
}

resource "azurerm_role_assignment" "lead" {
  count = var.lead_principal_id != "" ? 1 : 0

  scope                = azurerm_resource_group.techsprint.id
  role_definition_name = "Contributor"
  principal_id         = var.lead_principal_id
}
