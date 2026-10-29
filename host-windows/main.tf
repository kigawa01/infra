terraform {
  required_version = ">= 1.0"
  required_providers {
    null = {
      source  = "hashicorp/null"
      version = "~> 3.0"
    }
  }

  # Backend configuration is managed by kinfra CLI.
  # For local development, run: terraform init -backend=false
}
