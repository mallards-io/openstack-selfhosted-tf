resource "openstack_identity_project_v3" "this" {
  name        = var.name
  description = var.description
  domain_id   = var.domain_id
  enabled     = var.enabled
  tags        = var.tags
}

# Compute quota (nova). Set to null to leave the deployment default.
resource "openstack_compute_quotaset_v2" "this" {
  count = var.compute_quota == null ? 0 : 1

  project_id = openstack_identity_project_v3.this.id
  instances  = var.compute_quota.instances
  cores      = var.compute_quota.cores
  ram        = var.compute_quota.ram
  key_pairs  = var.compute_quota.key_pairs
}

# Network quota (neutron).
resource "openstack_networking_quota_v2" "this" {
  count = var.network_quota == null ? 0 : 1

  project_id          = openstack_identity_project_v3.this.id
  network             = var.network_quota.network
  subnet              = var.network_quota.subnet
  port                = var.network_quota.port
  router              = var.network_quota.router
  floatingip          = var.network_quota.floatingip
  security_group      = var.network_quota.security_group
  security_group_rule = var.network_quota.security_group_rule
}

# Block storage quota (cinder).
resource "openstack_blockstorage_quotaset_v3" "this" {
  count = var.storage_quota == null ? 0 : 1

  project_id = openstack_identity_project_v3.this.id
  volumes    = var.storage_quota.volumes
  snapshots  = var.storage_quota.snapshots
  gigabytes  = var.storage_quota.gigabytes
}
