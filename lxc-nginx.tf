# LXC Nginx configuration files
resource "local_file" "lxc_nginx_install_script" {
  count = var.lxc_nginx_enabled ? 1 : 0

  filename = "${path.module}/generated/install_lxc_nginx.sh"
  content = templatefile("${path.module}/templates/nginx_install.sh.tpl", {})

  file_permission = "0755"
}

resource "local_file" "lxc_nginx_config" {
  count = var.lxc_nginx_enabled ? 1 : 0

  filename = "${path.module}/generated/lxc_nginx.conf"
  content = templatefile("${path.module}/templates/lxc_nginx.conf.tpl", {
    server_name = var.lxc_nginx_server_name
  })

  file_permission = "0644"
}

resource "local_file" "lxc_nginx_stream_config" {
  count = var.lxc_nginx_enabled ? 1 : 0

  filename = "${path.module}/generated/lxc_proxy.stream.conf"
  content = templatefile("${path.module}/templates/lxc_stream.conf.tpl", {})

  file_permission = "0644"
}

# Test SSH connection to lxc-nginx host
resource "null_resource" "test_lxc_nginx_ssh_connection" {
  count = var.lxc_nginx_enabled ? 1 : 0

  connection {
    type        = "ssh"
    host        = var.lxc_nginx_target_host == "lxc-nginx" ? "192.168.3.100" : var.lxc_nginx_target_host
    user        = "root"
    private_key = var.ssh_key_path != "" ? file(var.ssh_key_path) : file("./ssh-keys/id_ed25519")
    timeout     = "30s"
    agent       = false
  }

  provisioner "remote-exec" {
    inline = [
      "echo 'SSH connection test successful for LXC nginx installation on ${var.lxc_nginx_target_host}'",
      "whoami",
      "uname -a"
    ]
  }
}

# Install and configure Nginx on LXC host
resource "null_resource" "install_lxc_nginx" {
  count = var.lxc_nginx_enabled ? 1 : 0

  depends_on = [
    local_file.lxc_nginx_install_script,
    local_file.lxc_nginx_config,
    local_file.lxc_nginx_stream_config,
    null_resource.test_lxc_nginx_ssh_connection
  ]

  connection {
    type        = "ssh"
    host        = var.lxc_nginx_target_host == "lxc-nginx" ? "192.168.3.100" : var.lxc_nginx_target_host
    user        = "root"
    private_key = var.ssh_key_path != "" ? file(var.ssh_key_path) : file("./ssh-keys/id_ed25519")
    timeout     = "5m"
    agent       = false
  }

  # Upload nginx installation script
  provisioner "file" {
    source      = local_file.lxc_nginx_install_script[0].filename
    destination = local.home.gate.nginx.install.script.tmpPath
  }

  # Execute nginx installation and configuration
  provisioner "remote-exec" {
    inline = [
      "chmod +x ${local.home.gate.nginx.install.script.tmpPath}",
      # Set non-interactive installation options
      "export DEBIAN_FRONTEND=noninteractive",
      "export UCF_FORCE_CONFFNEW=YES",
      "export NEEDRESTART_MODE=a",
      local.home.gate.nginx.install.script.tmpPath,
    ]
  }
  # Upload nginx configuration
  provisioner "file" {
    source      = local_file.lxc_nginx_config[0].filename
    destination = "/tmp/nginx.conf"
  }

  # Upload nginx stream configuration
  provisioner "file" {
    source      = local_file.lxc_nginx_stream_config[0].filename
    destination = local.home.gate.nginx.conf.proxy.tmpPath
  }

  # Execute nginx installation and configuration
  provisioner "remote-exec" {
    inline = [
      # Clean up existing stream configurations
      "rm -f /etc/nginx/stream.conf.d/*",
      "cp /tmp/nginx.conf /etc/nginx/nginx.conf",
      "mkdir -p /etc/nginx/stream.conf.d",
      "cp ${local.home.gate.nginx.conf.proxy.tmpPath} /etc/nginx/stream.conf.d/lxc_proxy.stream.conf",
      "nginx -t",
      "systemctl reload nginx",
      "systemctl is-active nginx && echo 'Nginx is running' || echo 'Nginx is not running'",
      "echo 'LXC Nginx installation and configuration completed!'"
    ]
  }
  triggers = {
    script_hash = local_file.lxc_nginx_install_script[0].content_md5
    config_hash = local_file.lxc_nginx_config[0].content_md5
    stream_hash = local_file.lxc_nginx_stream_config[0].content_md5
  }
}
