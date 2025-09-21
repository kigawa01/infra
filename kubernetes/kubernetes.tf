# Apply Kubernetes manifests
locals {
  # Discover all manifest files in the manifests directory
  manifest_files_glob = var.apply_k8s_manifests ? fileset("${path.module}/manifests", "**/*.{yml,yaml}") : []
  
  # Create a map of manifest files to their content
  manifest_files_content = var.apply_k8s_manifests ? {
    for file_path in local.manifest_files_glob :
    file_path => file("${path.module}/manifests/${file_path}")
  } : {}
  
  # Parse all manifest files into Terraform-compatible format
  manifest_files_parsed = var.apply_k8s_manifests && !var.use_ssh_kubectl ? {
    for file_path, content in local.manifest_files_content :
    file_path => content != "" ? [
      for doc in split("---", content) :
      yamldecode(doc) if trimspace(doc) != "" && !startswith(trimspace(doc), "#")
    ] : []
  } : {
    for file_path in local.manifest_files_glob :
    file_path => []
  }
  
  # Flatten all manifests into a single list with file path info
  all_manifests = var.apply_k8s_manifests && !var.use_ssh_kubectl ? flatten([
    for file_path, manifests in local.manifest_files_parsed :
    [
      for idx, manifest in manifests :
      {
        key      = "${file_path}-${idx}"
        manifest = manifest
        file_path = file_path
      }
    ]
  ]) : []
  
  
  # List of all manifest files to copy for SSH+kubectl method (dynamically discovered)
  all_manifest_file_paths = var.apply_k8s_manifests ? [
    for file_path in local.manifest_files_glob :
    "${path.root}/kubernetes/manifests/${file_path}"
  ] : []
  
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
    manifests_to_copy   = join(" ", local.all_manifest_file_paths)
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
    # Trigger on any manifest file changes
    manifests_hash = var.apply_k8s_manifests ? join("-", [
      for file_path in local.manifest_files_glob : 
      filemd5("${path.root}/kubernetes/manifests/${file_path}")
    ]) : ""
  }
}

# Apply all discovered manifests using Kubernetes provider (if use_ssh_kubectl is false)
resource "kubernetes_manifest" "all_manifests" {
  count = var.apply_k8s_manifests && !var.use_ssh_kubectl ? length(local.all_manifests) : 0
  
  manifest = local.all_manifests[count.index].manifest
  
  field_manager {
    # Force conflicts with server-side apply
    force_conflicts = true
  }
}
