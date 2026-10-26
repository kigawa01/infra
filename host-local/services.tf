# Enable systemd services
resource "null_resource" "enable_services" {
  triggers = {
    services = jsonencode(var.enabled_services)
  }

  provisioner "local-exec" {
    command = <<-EOT
      ${join(" && ", [for s in var.enabled_services : "sudo systemctl enable ${s}"])}
    EOT
  }
}

# Ensure services are running
resource "null_resource" "ensure_running" {
  triggers = {
    services = jsonencode(var.enabled_services)
  }

  provisioner "local-exec" {
    command = <<-EOT
      ${join(" && ", [for s in var.enabled_services : "sudo systemctl start ${s} || true"])}
    EOT
  }
}
