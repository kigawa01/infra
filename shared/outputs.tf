# Outputs are now managed through individual host modules
# See host/*/outputs.tf for module-specific outputs

output "ssh_key" {
  value = var.ssh_key
}
output "ssh_user" {
  value = var.ssh_user
}
output "host1_ip_network" {
  value = "192.168.1.10"
}