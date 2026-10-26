terraform {
  required_version = ">= 1.0"
  required_providers {
    null = {
      source  = "hashicorp/null"
      version = "~> 3.0"
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.0"
    }
  }

  # Backend configuration is managed by kinfra CLI.
  # When running via `kinfra deploy`, the S3 backend config is automatically
  # populated from Bitwarden credentials.
  # For local development, run: terraform init -backend=false
  # backend "s3" {
  #   region                      = "auto"
  #   skip_credentials_validation = true
  #   skip_region_validation      = true
  #   skip_requesting_account_id  = true
  #   skip_metadata_api_check     = true
  #   skip_s3_checksum            = true
  #   use_path_style              = false
  # }
}
