# host5 (192.168.1.50) Node Exporter installation

# Create Node Exporter installation script
resource "local_file" "node_exporter_script" {
  filename = "${path.module}/generated/install_node_exporter.sh"
  content = templatefile("${path.module}/../../terraform/templates/node_exporter_install.sh.tpl", {
    node_exporter_version = var.node_exporter_version
    node_exporter_port    = var.node_exporter_port
  })

  file_permission = "0755"
}

# Create SSH connection script
resource "local_file" "ssh_install_script" {
  filename = "${path.module}/generated/deploy_to_remote.sh"
  content = templatefile("${path.module}/../../terraform/templates/deploy_remote.sh.tpl", {
    target_host = "192.168.1.50"
    ssh_user    = var.ssh_user
    ssh_key     = var.ssh_key_path
  })

  file_permission = "0755"
}

# Test SSH connection first
resource "null_resource" "test_ssh_connection" {
  connection {
    type        = "ssh"
    host        = "192.168.1.50"
    user        = var.ssh_user
    private_key = var.ssh_key_path != "" ? file(var.ssh_key_path) : file("../../ssh-keys/id_ed25519")
    timeout     = "30s"
    agent       = false
  }

  provisioner "remote-exec" {
    inline = [
      "echo 'SSH connection test successful to host5'",
      "whoami",
      "uname -a"
    ]
  }
}

# Execute Node Exporter installation on remote host
resource "null_resource" "install_node_exporter" {
  depends_on = [
    local_file.node_exporter_script,
    null_resource.test_ssh_connection
  ]

  connection {
    type        = "ssh"
    host        = "192.168.1.50"
    user        = var.ssh_user
    private_key = var.ssh_key_path != "" ? file(var.ssh_key_path) : file("../../ssh-keys/id_ed25519")
    timeout     = "5m"
    agent       = false
  }

  provisioner "file" {
    source      = local_file.node_exporter_script.filename
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
    script_hash = local_file.node_exporter_script.content_md5
  }
}
