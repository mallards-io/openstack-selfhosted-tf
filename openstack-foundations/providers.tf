# Auth comes from clouds.yaml (see README): a Keystone application credential
# named by var.os_cloud, NOT the admin password.
provider "openstack" {
  cloud = var.os_cloud
}
