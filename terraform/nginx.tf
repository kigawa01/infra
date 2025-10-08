# Create Nginx installation script
resource "local_file" "nginx_install_script" {
  count = var.nginx_enabled ? 1 : 0

  filename = "${path.module}/generated/install_nginx.sh"
  content = templatefile("${path.module}/templates/nginx_install.sh.tpl", {})

  file_permission = "0755"
}

# Create Nginx configuration file
resource "local_file" "nginx_config" {
  count = var.nginx_enabled ? 1 : 0

  filename = "${path.module}/generated/nginx.conf"
  content = templatefile("${path.module}/templates/nginx_default.conf.tpl", {
    server_name = var.nginx_server_name
  })

  file_permission = "0644"
}

# Create Nginx stream configuration file
resource "local_file" "nginx_stream_config" {
  count = var.nginx_enabled ? 1 : 0

  filename = "${path.module}/generated/proxy.stream.conf"
  content = templatefile("${path.module}/templates/nginx_stream.conf.tpl", {})

  file_permission = "0644"
}

# Test SSH connection to target host for nginx installation
resource "null_resource" "test_nginx_ssh_connection" {
  count = var.nginx_enabled ? 1 : 0

  connection {
    type        = "ssh"
    host        = var.nginx_target_host == "one-sakura" ? "133.242.178.198" : var.nginx_target_host
    user        = var.ssh_user
    private_key = var.ssh_key_path != "" ? file(var.ssh_key_path) : file("../ssh-keys/id_ed25519")
    timeout     = "30s"
    agent       = false
  }

  provisioner "remote-exec" {
    inline = [
      "echo 'SSH connection test successful for nginx installation on ${var.target_host}'",
      "whoami",
      "uname -a"
    ]
  }
}

# Install and configure Nginx on remote host
resource "null_resource" "install_nginx" {
  count = var.nginx_enabled ? 1 : 0

  depends_on = [
    local_file.nginx_install_script,
    local_file.nginx_config,
    local_file.nginx_stream_config,
    null_resource.test_nginx_ssh_connection
  ]

  connection {
    type        = "ssh"
    host        = var.nginx_target_host == "one-sakura" ? "133.242.178.198" : var.nginx_target_host
    user        = var.ssh_user
    private_key = var.ssh_key_path != "" ? file(var.ssh_key_path) : file("../ssh-keys/id_ed25519")
    timeout     = "5m"
    agent       = false
  }

  # Upload nginx installation script
  provisioner "file" {
    source      = local_file.nginx_install_script[0].filename
    destination = "/tmp/install_nginx.sh"
  }

  # Upload nginx configuration
  provisioner "file" {
    source      = local_file.nginx_config[0].filename
    destination = "/tmp/nginx.conf"
  }

  # Upload nginx stream configuration
  provisioner "file" {
    source      = local_file.nginx_stream_config[0].filename
    destination = "/tmp/proxy.stream.conf"
  }

  # Execute nginx installation and configuration
  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/install_nginx.sh",
      <<-EOT
if [ -n "${var.sudo_password}" ]; then
  echo "Using provided sudo password for nginx installation"
  echo '${var.sudo_password}' | sudo -S /tmp/install_nginx.sh
else
  echo "No sudo password provided, trying passwordless sudo for nginx installation"
  sudo -n /tmp/install_nginx.sh || (echo 'Sudo requires password for nginx installation' && DEBIAN_FRONTEND=noninteractive sudo -S /tmp/install_nginx.sh < /dev/null)
fi
EOT
      ,
      "sudo cp /tmp/nginx.conf /etc/nginx/nginx.conf",
      "sudo mkdir -p /etc/nginx/stream.conf.d",
      "sudo cp /tmp/proxy.stream.conf /etc/nginx/stream.conf.d/proxy.stream.conf",
      "sudo nginx -t",
      "sudo systemctl reload nginx",
      "echo 'Nginx installation and configuration completed!'"
    ]
  }

  triggers = {
    script_hash = local_file.nginx_install_script[0].content_md5
    config_hash = local_file.nginx_config[0].content_md5
    stream_hash = local_file.nginx_stream_config[0].content_md5
  }
}