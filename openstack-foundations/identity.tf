# AD groups + role bindings. Human users/groups live in AD (read-only in
# Keystone), so Terraform only resolves the groups and binds them to roles — it
# cannot create them. This replaces the project scope of 07-setup-group-roles.sh.

data "openstack_identity_role_v3" "admin" {
  name = var.admin_role_name
}

data "openstack_identity_group_v3" "admin" {
  for_each  = toset(var.admin_groups)
  name      = each.value
  domain_id = var.ldap_domain_id
}

# admin role for each (project x admin group). Role assignments are idempotent at
# the API, so this reconciles the existing puppet-made bindings without import.
resource "openstack_identity_role_assignment_v3" "project_admin" {
  for_each = {
    for pair in setproduct(keys(var.projects), var.admin_groups) :
    "${pair[0]}::${pair[1]}" => { project = pair[0], group = pair[1] }
  }

  project_id = module.project[each.value.project].id
  group_id   = data.openstack_identity_group_v3.admin[each.value.group].id
  role_id    = data.openstack_identity_role_v3.admin.id
}
