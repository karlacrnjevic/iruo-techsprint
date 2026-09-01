resource "azurerm_managed_disk" "developer_data" {
  for_each = local.developers

  name                 = "disk-${each.key}-data"
  location             = azurerm_resource_group.techsprint.location
  resource_group_name  = azurerm_resource_group.techsprint.name
  storage_account_type = "Standard_LRS"
  create_option        = "Empty"
  disk_size_gb         = 10

  tags = local.common_tags
}

resource "azurerm_virtual_machine_data_disk_attachment" "developer_data" {
  for_each = local.developers

  managed_disk_id    = azurerm_managed_disk.developer_data[each.key].id
  virtual_machine_id = azurerm_linux_virtual_machine.developer[each.key].id
  lun                = 0
  caching            = "ReadWrite"
}

resource "azurerm_storage_account" "developer" {
  for_each = local.developers

  name                     = "st${each.key}${substr(md5("${var.resource_group_name}-${each.key}"), 0, 8)}"
  resource_group_name      = azurerm_resource_group.techsprint.name
  location                 = azurerm_resource_group.techsprint.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  min_tls_version          = "TLS1_2"

  tags = local.common_tags
}

resource "azurerm_storage_container" "developer_backups" {
  for_each = local.developers

  name                  = "moodle-backups"
  storage_account_id    = azurerm_storage_account.developer[each.key].id
  container_access_type = "private"
}

resource "azurerm_storage_share" "developer_shared" {
  for_each = local.developers

  name               = "moodle-shared"
  storage_account_id = azurerm_storage_account.developer[each.key].id
  quota              = 5
}
