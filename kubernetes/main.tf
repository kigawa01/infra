
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
    region = "auto"
  }
}

# Configure the Kubernetes provider
provider "kubernetes" {
}
