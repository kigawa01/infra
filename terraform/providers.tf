terraform {
  required_version = ">= 1.0"
  required_providers {
    local = {
      source  = "hashicorp/local"
      version = "~> 2.0"
    }
    null = {
      source  = "hashicorp/null"
      version = "~> 3.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.23"
    }
    libvirt = {
      source  = "dmacvicar/libvirt"
      version = "~> 0.7"
    }
  }

  backend "s3" {
    skip_credentials_validation = true
    skip_region_validation      = true
    skip_requesting_account_id  = true
    skip_metadata_api_check     = true
    skip_s3_checksum            = true
    use_path_style              = false
  }
}

# Configure the Kubernetes provider (used only if use_ssh_kubectl is false)
provider "kubernetes" {
  config_path    = pathexpand(var.kubernetes_config_path)
  config_context = var.kubernetes_config_context != "" ? var.kubernetes_config_context : null
}

# Configure the libvirt provider for host5 VM management
# Only enabled when host5 module is enabled
provider "libvirt" {
  alias = "host5"
  uri   = "qemu+ssh://${var.ssh_user}@192.168.1.50/system"
}