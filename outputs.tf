output "target_host" {
  description = "Target host for Node Exporter installation"
  value       = var.target_host
}

output "node_exporter_version" {
  description = "Version of Node Exporter configured"
  value       = var.node_exporter_enabled ? var.node_exporter_version : "disabled"
}

output "node_exporter_port" {
  description = "Port configured for Node Exporter"
  value       = var.node_exporter_enabled ? var.node_exporter_port : "N/A"
}

output "node_exporter_url" {
  description = "URL for accessing Node Exporter metrics"
  value       = var.node_exporter_enabled ? "http://${var.target_host}:${var.node_exporter_port}/metrics" : "N/A"
}

output "installation_status" {
  description = "Installation status message"
  value       = var.node_exporter_enabled ? "Node Exporter installation configured for ${var.target_host}" : "Node Exporter installation disabled"
}