locals {
  # Always tag instances as terraform-managed, mirroring the GCP labels convention.
  managed_metadata = merge({ "managed-by" = "terraform" }, var.metadata)

  # Resolve the boot image ID when booting from volume with only an image name.
  boot_image_id = var.image_id != null ? var.image_id : try(data.openstack_images_image_v2.boot[0].id, null)
}

# Only needed for boot-from-volume when the caller gave image_name (not image_id).
data "openstack_images_image_v2" "boot" {
  count       = var.block_device != null && var.image_id == null ? 1 : 0
  region      = var.region
  name        = var.image_name
  most_recent = true
}

resource "openstack_compute_instance_v2" "this" {
  region            = var.region
  name              = var.name
  flavor_name       = var.flavor_name
  flavor_id         = var.flavor_id
  key_pair          = var.key_pair
  security_groups   = var.security_groups
  availability_zone = var.availability_zone
  user_data         = var.user_data
  config_drive      = var.config_drive
  metadata          = local.managed_metadata

  # Boot from image (ephemeral disk) unless a block_device is supplied.
  image_name = var.block_device == null ? var.image_name : null
  image_id   = var.block_device == null ? var.image_id : null

  dynamic "network" {
    for_each = var.networks
    content {
      name        = network.value.name
      uuid        = network.value.uuid
      fixed_ip_v4 = network.value.fixed_ip_v4
      port        = network.value.port
    }
  }

  # Boot from a Cinder volume (persistent root disk) when block_device is set.
  dynamic "block_device" {
    for_each = var.block_device == null ? [] : [var.block_device]
    content {
      uuid                  = local.boot_image_id
      source_type           = block_device.value.source_type
      destination_type      = "volume"
      volume_size           = block_device.value.volume_size
      volume_type           = block_device.value.volume_type
      boot_index            = 0
      delete_on_termination = block_device.value.delete_on_termination
    }
  }
}
