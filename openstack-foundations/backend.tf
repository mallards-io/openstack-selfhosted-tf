terraform {
  # Remote state on MinIO (s3.mallards.io -> mgmt via Caddy) — the independent
  # plane, NOT Swift. Atlantis supplies AWS_ACCESS_KEY_ID/AWS_SECRET_ACCESS_KEY
  # (the MinIO creds) from Vault. The mallards-tfstate bucket already exists.
  backend "s3" {
    bucket                      = "mallards-tfstate"
    key                         = "openstack/foundations/terraform.tfstate"
    region                      = "us-east-1"
    endpoints                   = { s3 = "https://s3.mallards.io" }
    use_path_style              = true
    skip_credentials_validation = true
    skip_metadata_api_check     = true
    skip_region_validation      = true
    skip_requesting_account_id  = true
  }
}
