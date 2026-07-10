# Composes the project module for every project in var.projects.
# Sourced from the GitLab module repo. Bump ref=main -> a release tag
# (e.g. ?ref=v0.1.0) once release-please cuts the module's first release.
module "project" {
  source   = "../modules/project"
  for_each = var.projects

  name          = each.key
  description   = each.value.description
  domain_id     = var.ldap_domain_id # mall-* projects live in the mallards-io domain
  tags          = ["tier:${each.value.tier}", "env:${each.value.env}"]
  compute_quota = each.value.compute_quota
  network_quota = each.value.network_quota
  storage_quota = each.value.storage_quota
}
