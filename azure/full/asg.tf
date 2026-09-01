resource "azurerm_application_security_group" "developer" {
  for_each = local.developers

  name                = "asg-${each.key}"
  location            = azurerm_resource_group.techsprint.location
  resource_group_name = azurerm_resource_group.techsprint.name

  tags = local.common_tags
}

resource "azurerm_network_interface_application_security_group_association" "developer" {
  for_each = local.developers

  network_interface_id          = azurerm_network_interface.developer[each.key].id
  application_security_group_id = azurerm_application_security_group.developer[each.key].id
}

resource "azurerm_application_security_group" "management" {
  name                = "asg-management"
  location            = azurerm_resource_group.techsprint.location
  resource_group_name = azurerm_resource_group.techsprint.name

  tags = local.common_tags
}

resource "azurerm_network_interface_application_security_group_association" "management" {
  network_interface_id          = azurerm_network_interface.jump.id
  application_security_group_id = azurerm_application_security_group.management.id
}
