resource "openstack_compute_keypair_v2" "this" {
  region = var.region
  name   = var.name
  # When public_key is empty, OpenStack generates a keypair and returns the
  # private key (exposed as a sensitive output). Otherwise the supplied key is
  # imported.
  public_key = var.public_key != "" ? var.public_key : null
}
