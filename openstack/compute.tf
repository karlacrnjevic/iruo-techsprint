resource "openstack_compute_instance_v2" "jump" {
  name        = "techsprint-jump"
  image_name  = var.image_name
  flavor_name = var.flavor_name
  key_pair    = openstack_compute_keypair_v2.techsprint.name

  security_groups = [
    openstack_networking_secgroup_v2.jump.name
  ]

  network {
    uuid = openstack_networking_network_v2.management.id
  }
}

resource "openstack_compute_instance_v2" "moodle" {
  for_each = local.moodle_instances

  name        = "techsprint-${each.value.username}-moodle-${each.value.instance_number}"
  image_name  = var.image_name
  flavor_name = var.flavor_name
  key_pair    = openstack_compute_keypair_v2.techsprint.name

  security_groups = [
    openstack_networking_secgroup_v2.moodle[each.value.username].name
  ]

  network {
    uuid = openstack_networking_network_v2.developer[each.value.username].id
  }
}