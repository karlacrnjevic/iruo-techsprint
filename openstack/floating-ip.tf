resource "openstack_networking_floatingip_v2" "jump" {
  pool = var.external_network_name
}

resource "openstack_compute_floatingip_associate_v2" "jump" {
  floating_ip = openstack_networking_floatingip_v2.jump.address
  instance_id = openstack_compute_instance_v2.jump.id
}