resource "openstack_networking_secgroup_v2" "this" {
  region               = var.region
  name                 = var.name
  tenant_id            = var.tenant_id
  description          = var.description
  delete_default_rules = var.delete_default_rules
  tags                 = var.tags
}

resource "openstack_networking_secgroup_rule_v2" "this" {
  count = length(var.rules)

  security_group_id = openstack_networking_secgroup_v2.this.id
  region            = var.region
  tenant_id         = var.tenant_id
  description       = var.rules[count.index].description
  direction         = var.rules[count.index].direction
  ethertype         = var.rules[count.index].ethertype
  protocol          = var.rules[count.index].protocol
  port_range_min    = var.rules[count.index].port_range_min
  port_range_max    = var.rules[count.index].port_range_max
  remote_ip_prefix  = var.rules[count.index].remote_ip_prefix
  remote_group_id   = var.rules[count.index].remote_group_id
}
