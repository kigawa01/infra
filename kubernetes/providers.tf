
module "shared" {
  source = "../shared"
}
terraform {
  required_version = ">= 1.0"
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.23"
    }
    null = {
      source  = "hashicorp/null"
      version = "~> 3.0"
    }
  }

  backend "s3" {
    key                         = "kinfra"
    region                      = "auto"
    bucket                      = module.shared.bucket
    access_key                  = var.access_key
    endpoint                    = var.endpoint
    secret_key                  = var.secret_key
    skip_credentials_validation = true
    skip_region_validation      = true
    skip_requesting_account_id  = true
    skip_metadata_api_check     = true
    skip_s3_checksum            = true
    use_path_style              = false
  }
}

# Configure the Kubernetes provider
provider "kubernetes" {
}
