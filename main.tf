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
  config_path    = var.kubernetes_config_path
  config_context = var.kubernetes_config_context
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
    host        = var.target_host
    user        = var.ssh_user
    private_key = var.ssh_key_path != "" ? file(var.ssh_key_path) : null
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
    host        = var.target_host
    user        = var.ssh_user
    private_key = var.ssh_key_path != "" ? file(var.ssh_key_path) : null
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
# Apply Kubernetes manifests
locals {
  # Read and parse the Kubernetes manifests
  ingress_yaml = var.apply_k8s_manifests ? file("${path.module}/kubernetes/manifests/ingress.yml") : ""
  prometheus_yaml = var.apply_k8s_manifests ? file("${path.module}/kubernetes/manifests/prometheus.yml") : ""
  pve_exporter_yaml = var.apply_k8s_manifests ? file("${path.module}/kubernetes/manifests/pve-exporter.yml") : ""
  nginx_exporter_yaml = var.apply_k8s_manifests && var.apply_nginx_exporter ? file("${path.module}/kubernetes/manifests/nginx-exporter.yml") : ""
  
  # Parse the YAML files into Terraform-compatible format (only used if use_ssh_kubectl is false)
  ingress_manifest = var.apply_k8s_manifests && !var.use_ssh_kubectl ? yamldecode(local.ingress_yaml) : {}
  prometheus_manifest = var.apply_k8s_manifests && !var.use_ssh_kubectl ? yamldecode(local.prometheus_yaml) : {}
  
  # The pve-exporter.yml file contains multiple manifests, so we need to split them
  pve_exporter_manifests = var.apply_k8s_manifests && !var.use_ssh_kubectl ? [
    for doc in split("---", local.pve_exporter_yaml) : 
    yamldecode(doc) if trimspace(doc) != ""
  ] : []
  
  # Only parse nginx-exporter.yml if apply_nginx_exporter is true
  # Note: This file is commented out, so it would need to be uncommented before use
  nginx_exporter_manifest = var.apply_k8s_manifests && var.apply_nginx_exporter && !var.use_ssh_kubectl ? yamldecode(local.nginx_exporter_yaml) : {}
  
  # List of manifest files to copy for SSH+kubectl method
  manifest_files = [
    "${path.module}/kubernetes/manifests/ingress.yml",
    "${path.module}/kubernetes/manifests/prometheus.yml",
    "${path.module}/kubernetes/manifests/pve-exporter.yml",
    var.apply_nginx_exporter ? "${path.module}/kubernetes/manifests/nginx-exporter.yml" : ""
  ]
  
  # Filter out empty strings from the list
  manifest_files_filtered = [for f in local.manifest_files : f if f != ""]
  
  # SSH options for secure connections
  ssh_options = var.ssh_key_path != "" ? "-i ${var.ssh_key_path} -o StrictHostKeyChecking=no" : "-o StrictHostKeyChecking=no"
}

# Create kubectl apply script for SSH method
resource "local_file" "kubectl_apply_script" {
  count = var.apply_k8s_manifests && var.use_ssh_kubectl ? 1 : 0
  
  filename = "${path.module}/generated/kubectl_apply.sh"
  content = templatefile("${path.module}/templates/kubectl_apply.sh.tpl", {
    target_host         = var.target_host
    ssh_user            = var.ssh_user
    ssh_key             = var.ssh_key_path
    ssh_options         = local.ssh_options
    remote_manifests_dir = var.remote_manifests_dir
    kubectl_context     = var.remote_kubectl_context
    apply_nginx_exporter = var.apply_nginx_exporter ? "true" : "false"
    manifests_to_copy   = join(" ", local.manifest_files_filtered)
  })
  
  file_permission = "0755"
}

# Test SSH connection to Kubernetes server
resource "null_resource" "test_k8s_ssh_connection" {
  count = var.apply_k8s_manifests && var.use_ssh_kubectl ? 1 : 0
  
  connection {
    type        = "ssh"
    host        = var.target_host
    user        = var.ssh_user
    private_key = var.ssh_key_path != "" ? file(var.ssh_key_path) : null
    password    = var.ssh_password != "" ? var.ssh_password : null
    timeout     = "30s"
    agent       = false
  }
  
  provisioner "remote-exec" {
    inline = [
      "echo 'SSH connection test successful to ${var.target_host}'",
      "which kubectl || echo 'WARNING: kubectl not found on remote host'"
    ]
  }
}

# Execute kubectl apply via SSH
resource "null_resource" "apply_k8s_via_ssh" {
  count = var.apply_k8s_manifests && var.use_ssh_kubectl ? 1 : 0
  
  depends_on = [
    local_file.kubectl_apply_script,
    null_resource.test_k8s_ssh_connection
  ]
  
  provisioner "local-exec" {
    command = "${path.module}/generated/kubectl_apply.sh"
  }
  
  triggers = {
    script_hash = local_file.kubectl_apply_script[0].content_md5
    # Also trigger on manifest changes
    ingress_hash = var.apply_k8s_manifests ? filemd5("${path.module}/kubernetes/manifests/ingress.yml") : ""
    prometheus_hash = var.apply_k8s_manifests ? filemd5("${path.module}/kubernetes/manifests/prometheus.yml") : ""
    pve_exporter_hash = var.apply_k8s_manifests ? filemd5("${path.module}/kubernetes/manifests/pve-exporter.yml") : ""
    nginx_exporter_hash = var.apply_k8s_manifests && var.apply_nginx_exporter ? filemd5("${path.module}/kubernetes/manifests/nginx-exporter.yml") : ""
  }
}

# Apply the Ingress manifest using Kubernetes provider (if use_ssh_kubectl is false)
resource "kubernetes_manifest" "prometheus_ingress" {
  count = var.apply_k8s_manifests && !var.use_ssh_kubectl ? 1 : 0
  
  manifest = local.ingress_manifest
  
  field_manager {
    # Force conflicts with server-side apply
    force_conflicts = true
  }
}

# Apply the Prometheus manifest using Kubernetes provider (if use_ssh_kubectl is false)
resource "kubernetes_manifest" "prometheus_application" {
  count = var.apply_k8s_manifests && !var.use_ssh_kubectl ? 1 : 0
  
  manifest = local.prometheus_manifest
  
  field_manager {
    # Force conflicts with server-side apply
    force_conflicts = true
  }
}

# Apply the PVE Exporter manifests using Kubernetes provider (if use_ssh_kubectl is false)
resource "kubernetes_manifest" "pve_exporter" {
  count = var.apply_k8s_manifests && !var.use_ssh_kubectl ? length(local.pve_exporter_manifests) : 0
  
  manifest = local.pve_exporter_manifests[count.index]
  
  field_manager {
    # Force conflicts with server-side apply
    force_conflicts = true
  }
}

# Apply the Nginx Exporter manifest using Kubernetes provider (if use_ssh_kubectl is false and enabled)
resource "kubernetes_manifest" "nginx_exporter" {
  count = var.apply_k8s_manifests && var.apply_nginx_exporter && !var.use_ssh_kubectl ? 1 : 0
  
  manifest = local.nginx_exporter_manifest
  
  field_manager {
    # Force conflicts with server-side apply
    force_conflicts = true
  }
}