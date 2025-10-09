# Test SSH connection first
resource "null_resource" "test_ssh_connection" {
  count = var.node_exporter_enabled ? 1 : 0

  connection {
    type        = "ssh"
    host        = var.target_host == "host5" ? "192.168.1.50" : var.target_host
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

# Install Node Exporter on remote host
resource "null_resource" "install_node_exporter" {
  count = var.node_exporter_enabled ? 1 : 0

  depends_on = [
    null_resource.test_ssh_connection
  ]

  connection {
    type        = "ssh"
    host        = var.target_host == "host5" ? "192.168.1.50" : var.target_host
    user        = var.ssh_user
    private_key = var.ssh_key_path != "" ? file(var.ssh_key_path) : file("../ssh-keys/id_ed25519")
    timeout     = "5m"
    agent       = false
  }

  provisioner "remote-exec" {
    inline = [
      # Download and install Node Exporter
      "cd /tmp",
      "wget -q https://github.com/prometheus/node_exporter/releases/download/v${var.node_exporter_version}/node_exporter-${var.node_exporter_version}.linux-amd64.tar.gz",
      "tar xzf node_exporter-${var.node_exporter_version}.linux-amd64.tar.gz",
      <<-EOT
      if [ -n "${var.sudo_password}" ]; then
        echo "Installing Node Exporter with provided sudo password"
        echo '${var.sudo_password}' | sudo -S cp node_exporter-${var.node_exporter_version}.linux-amd64/node_exporter /usr/local/bin/
        echo '${var.sudo_password}' | sudo -S chown root:root /usr/local/bin/node_exporter
      else
        echo "Installing Node Exporter with passwordless sudo"
        sudo -n cp node_exporter-${var.node_exporter_version}.linux-amd64/node_exporter /usr/local/bin/ || (echo 'Sudo requires password' && sudo -S cp node_exporter-${var.node_exporter_version}.linux-amd64/node_exporter /usr/local/bin/ < /dev/null)
        sudo -n chown root:root /usr/local/bin/node_exporter || sudo -S chown root:root /usr/local/bin/node_exporter < /dev/null
      fi
      EOT
      ,
      # Create systemd service
      <<-EOT
      if [ -n "${var.sudo_password}" ]; then
        echo '${var.sudo_password}' | sudo -S tee /etc/systemd/system/node_exporter.service > /dev/null <<'SYSTEMD'
[Unit]
Description=Prometheus Node Exporter
After=network.target

[Service]
Type=simple
User=nobody
ExecStart=/usr/local/bin/node_exporter --web.listen-address=:${var.node_exporter_port}
Restart=on-failure

[Install]
WantedBy=multi-user.target
SYSTEMD
      else
        sudo -n tee /etc/systemd/system/node_exporter.service > /dev/null <<'SYSTEMD' || sudo -S tee /etc/systemd/system/node_exporter.service > /dev/null <<'SYSTEMD' < /dev/null
[Unit]
Description=Prometheus Node Exporter
After=network.target

[Service]
Type=simple
User=nobody
ExecStart=/usr/local/bin/node_exporter --web.listen-address=:${var.node_exporter_port}
Restart=on-failure

[Install]
WantedBy=multi-user.target
SYSTEMD
      fi
      EOT
      ,
      # Start and enable the service
      <<-EOT
      if [ -n "${var.sudo_password}" ]; then
        echo '${var.sudo_password}' | sudo -S systemctl daemon-reload
        echo '${var.sudo_password}' | sudo -S systemctl enable node_exporter
        echo '${var.sudo_password}' | sudo -S systemctl restart node_exporter
      else
        sudo -n systemctl daemon-reload || sudo -S systemctl daemon-reload < /dev/null
        sudo -n systemctl enable node_exporter || sudo -S systemctl enable node_exporter < /dev/null
        sudo -n systemctl restart node_exporter || sudo -S systemctl restart node_exporter < /dev/null
      fi
      EOT
      ,
      # Cleanup
      "rm -rf /tmp/node_exporter-${var.node_exporter_version}.linux-amd64*",
      "echo 'Node Exporter installation completed successfully'"
    ]
  }

  triggers = {
    version = var.node_exporter_version
  }
}