# Create Node Exporter installation script
resource "local_file" "node_exporter_script" {
  count = var.node_exporter_enabled ? 1 : 0

  filename = "${path.module}/generated/install_node_exporter.sh"
  content = templatefile("${path.module}/templates/node_exporter_install.sh.tpl", {
    node_exporter_version = var.node_exporter_version
    node_exporter_port    = var.node_exporter_port
  })

  file_permission = "0755"
}

# Create SSH connection script
resource "local_file" "ssh_install_script" {
  count = var.node_exporter_enabled ? 1 : 0

  filename = "${path.module}/generated/deploy_to_remote.sh"
  content = templatefile("${path.module}/templates/deploy_remote.sh.tpl", {
    target_host = var.target_host
    ssh_user    = var.ssh_user
    ssh_key     = var.ssh_key_path
  })

  file_permission = "0755"
}

# Test SSH connection first
resource "null_resource" "test_ssh_connection" {
  count = var.node_exporter_enabled ? 1 : 0

  connection {
    type        = "ssh"
    host        = var.target_host == "k8s4" ? "192.168.1.120" : var.target_host
    user        = var.ssh_user
    private_key = var.ssh_key_path != "" ? file(var.ssh_key_path) : file("../ssh-keys/id_ed25519")
    timeout     = "30s"
    agent       = false
  }

  provisioner "remote-exec" {
    inline = [
      "echo 'SSH connection test successful to ${var.target_host}'",
      "whoami",
      "uname -a"
    ]
  }
}

# Execute Node Exporter installation on remote host
resource "null_resource" "install_node_exporter" {
  count = var.node_exporter_enabled ? 1 : 0

  depends_on = [
    local_file.node_exporter_script,
    null_resource.test_ssh_connection
  ]

  connection {
    type        = "ssh"
    host        = var.target_host == "k8s4" ? "192.168.1.120" : var.target_host
    user        = var.ssh_user
    private_key = var.ssh_key_path != "" ? file(var.ssh_key_path) : file("../ssh-keys/id_ed25519")
    timeout     = "5m"
    agent       = false
  }

  provisioner "file" {
    source      = local_file.node_exporter_script[0].filename
    destination = "/tmp/install_node_exporter.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/install_node_exporter.sh",
      <<-EOT
      if [ -n "${var.sudo_password}" ]; then
        echo "Using provided sudo password"
        echo '${var.sudo_password}' | sudo -S /tmp/install_node_exporter.sh
      else
        echo "No sudo password provided, trying passwordless sudo"
        sudo -n /tmp/install_node_exporter.sh || (echo 'Sudo requires password, trying alternative method' && DEBIAN_FRONTEND=noninteractive sudo -S /tmp/install_node_exporter.sh < /dev/null)
      fi
      EOT
    ]
  }

  triggers = {
    script_hash = local_file.node_exporter_script[0].content_md5
  }
}