terraform {
  required_version = ">= 1.0"
  required_providers {
    local = {
      source  = "hashicorp/local"
      version = "~> 2.0"
    }
    null = {
      source  = "hashicorp/null"
      version = "~> 3.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.23"
    }
  }
}

# Configure the Kubernetes provider (used only if use_ssh_kubectl is false)
provider "kubernetes" {
  config_path    = pathexpand(var.kubernetes_config_path)
  config_context = var.kubernetes_config_context != "" ? var.kubernetes_config_context : null
}

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
    private_key = var.ssh_key_path != "" ? file(var.ssh_key_path) : file("/home/kigawa/.ssh/key/id_ed25519")
    password    = var.ssh_password != "" ? var.ssh_password : null
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
    private_key = var.ssh_key_path != "" ? file(var.ssh_key_path) : file("/home/kigawa/.ssh/key/id_ed25519")
    password    = var.ssh_password != "" ? var.ssh_password : null
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

  filename = "${path.module}/generated/stream.conf"
  content = templatefile("${path.module}/templates/nginx_stream.conf.tpl", {})

  file_permission = "0644"
}

# Test SSH connection to target host for nginx installation
resource "null_resource" "test_nginx_ssh_connection" {
  count = var.nginx_enabled ? 1 : 0

  connection {
    type        = "ssh"
    host        = var.target_host == "one-sakura" ? "133.242.178.198" : var.target_host
    user        = var.ssh_user
    private_key = var.ssh_key_path != "" ? file(var.ssh_key_path) : file("./ssh-keys/id_ed25519")
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
    host        = var.target_host == "one-sakura" ? "133.242.178.198" : var.target_host
    user        = var.ssh_user
    private_key = var.ssh_key_path != "" ? file(var.ssh_key_path) : file("./ssh-keys/id_ed25519")
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
    destination = "/tmp/stream.conf"
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
      "sudo cp /tmp/stream.conf /etc/nginx/stream.conf.d/stream.conf",
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

# Kubernetes module
module "kubernetes" {
  source = "./kubernetes"

  # Pass all necessary variables to the kubernetes module
  apply_k8s_manifests      = var.apply_k8s_manifests
  apply_nginx_exporter     = var.apply_nginx_exporter
  use_ssh_kubectl          = var.use_ssh_kubectl
  target_host              = var.target_host
  ssh_user                 = var.ssh_user
  ssh_key_path             = var.ssh_key_path
  ssh_password             = var.ssh_password
  remote_manifests_dir     = var.remote_manifests_dir
  remote_kubectl_context   = var.remote_kubectl_context
  apply_one_dev_manifests  = var.apply_one_dev_manifests
}
