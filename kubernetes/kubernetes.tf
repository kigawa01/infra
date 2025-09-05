# Apply Kubernetes manifests
locals {
  # Read and parse the Kubernetes manifests
  ingress_yaml = var.apply_k8s_manifests ? file("${path.module}/manifests/ingress.yml") : ""
  prometheus_yaml = var.apply_k8s_manifests ? file("${path.module}/manifests/prometheus.yml") : ""
  pve_exporter_yaml = var.apply_k8s_manifests ? file("${path.module}/manifests/pve-exporter.yml") : ""
  nginx_exporter_yaml = var.apply_k8s_manifests && var.apply_nginx_exporter ? file("${path.module}/manifests/nginx-exporter.yml") : ""
  
  # Parse the YAML files into Terraform-compatible format (only used if use_ssh_kubectl is false)
  ingress_manifest = var.apply_k8s_manifests && !var.use_ssh_kubectl && local.ingress_yaml != "" ? yamldecode(local.ingress_yaml) : null
  prometheus_manifest = var.apply_k8s_manifests && !var.use_ssh_kubectl && local.prometheus_yaml != "" ? yamldecode(local.prometheus_yaml) : null
  
  # The pve-exporter.yml file contains multiple manifests, so we need to split them
  pve_exporter_manifests = var.apply_k8s_manifests && !var.use_ssh_kubectl && local.pve_exporter_yaml != "" ? [
    for doc in split("---", local.pve_exporter_yaml) : 
    yamldecode(doc) if trimspace(doc) != ""
  ] : null
  
  # Only parse nginx-exporter.yml if apply_nginx_exporter is true
  # Note: This file is commented out, so it would need to be uncommented before use
  nginx_exporter_manifest = var.apply_k8s_manifests && var.apply_nginx_exporter && !var.use_ssh_kubectl && local.nginx_exporter_yaml != "" ? yamldecode(local.nginx_exporter_yaml) : null
  
  # List of manifest files to copy for SSH+kubectl method
  manifest_files = [
    "${path.root}/kubernetes/manifests/ingress.yml",
    "${path.root}/kubernetes/manifests/prometheus.yml",
    "${path.root}/kubernetes/manifests/pve-exporter.yml",
    var.apply_nginx_exporter ? "${path.root}/kubernetes/manifests/nginx-exporter.yml" : ""
  ]
  
  # Filter out empty strings from the list
  manifest_files_filtered = [for f in local.manifest_files : f if f != ""]
  
  # SSH options for secure connections
  ssh_options = var.ssh_key_path != "" ? "-i ${var.ssh_key_path} -o StrictHostKeyChecking=no" : "-o StrictHostKeyChecking=no"
}

# Create kubectl apply script for SSH method
resource "local_file" "kubectl_apply_script" {
  count = var.apply_k8s_manifests && var.use_ssh_kubectl ? 1 : 0
  
  filename = "${path.root}/generated/kubectl_apply.sh"
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
    command = "${path.root}/generated/kubectl_apply.sh"
  }
  
  triggers = {
    script_hash = local_file.kubectl_apply_script[0].content_md5
    # Also trigger on manifest changes
    ingress_hash = var.apply_k8s_manifests ? filemd5("${path.root}/kubernetes/manifests/ingress.yml") : ""
    prometheus_hash = var.apply_k8s_manifests ? filemd5("${path.root}/kubernetes/manifests/prometheus.yml") : ""
    pve_exporter_hash = var.apply_k8s_manifests ? filemd5("${path.root}/kubernetes/manifests/pve-exporter.yml") : ""
    nginx_exporter_hash = var.apply_k8s_manifests && var.apply_nginx_exporter ? filemd5("${path.root}/kubernetes/manifests/nginx-exporter.yml") : ""
  }
}

# Apply the Ingress manifest using Kubernetes provider (if use_ssh_kubectl is false)
resource "kubernetes_manifest" "prometheus_ingress" {
  count = var.apply_k8s_manifests && !var.use_ssh_kubectl && local.ingress_manifest != null ? 1 : 0
  
  manifest = local.ingress_manifest
  
  field_manager {
    # Force conflicts with server-side apply
    force_conflicts = true
  }
}

# Apply the Prometheus manifest using Kubernetes provider (if use_ssh_kubectl is false)
resource "kubernetes_manifest" "prometheus_application" {
  count = var.apply_k8s_manifests && !var.use_ssh_kubectl && local.prometheus_manifest != null ? 1 : 0
  
  manifest = local.prometheus_manifest
  
  field_manager {
    # Force conflicts with server-side apply
    force_conflicts = true
  }
}

# Apply the PVE Exporter manifests using Kubernetes provider (if use_ssh_kubectl is false)
resource "kubernetes_manifest" "pve_exporter" {
  count = var.apply_k8s_manifests && !var.use_ssh_kubectl && local.pve_exporter_manifests != null ? length(local.pve_exporter_manifests) : 0
  
  manifest = local.pve_exporter_manifests[count.index]
  
  field_manager {
    # Force conflicts with server-side apply
    force_conflicts = true
  }
}

# Apply the Nginx Exporter manifest using Kubernetes provider (if use_ssh_kubectl is false and enabled)
resource "kubernetes_manifest" "nginx_exporter" {
  count = var.apply_k8s_manifests && var.apply_nginx_exporter && !var.use_ssh_kubectl && local.nginx_exporter_manifest != null ? 1 : 0
  
  manifest = local.nginx_exporter_manifest
  
  field_manager {
    # Force conflicts with server-side apply
    force_conflicts = true
  }
}