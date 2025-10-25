# Outputs are now managed through individual host modules
# See host/*/outputs.tf for module-specific outputs
output "bucket" {
  value = var.bucket
}