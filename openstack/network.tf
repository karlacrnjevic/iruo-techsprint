resource "openstack_networking_network_v2" "developer" {
  for_each = local.developers

  name           = "techsprint-${each.key}-network"
  admin_state_up = true
}

resource "openstack_networking_subnet_v2" "developer" {
  for_each = local.developers

  name       = "techsprint-${each.key}-subnet"
  network_id = openstack_networking_network_v2.developer[each.key].id
  cidr       = local.developer_networks[each.key]
  ip_version = 4

  dns_nameservers = [
    "8.8.8.8"
  ]
}