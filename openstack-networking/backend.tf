terraform {
  # Remote state on MinIO (s3.mallards.io -> mgmt via Caddy) — NOT Swift. Uncomment
  # once the bucket exists; local state until then. Creds via AWS_ACCESS_KEY_ID/SECRET.
  # backend "s3" {
  #   bucket                      = "mallards-tfstate"
  #   key                         = "openstack/networking/terraform.tfstate"
  #   region                      = "us-east-1"
  #   endpoints                   = { s3 = "https://s3.mallards.io" }
  #   use_path_style              = true
  #   skip_credentials_validation = true
  #   skip_metadata_api_check     = true
  #   skip_region_validation      = true
  #   skip_requesting_account_id  = true
  # }
}
