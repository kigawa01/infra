# Apply Kubernetes manifests
locals {
  # Discover all manifest files in the manifests directory
  manifest_files_glob = var.apply_k8s_manifests ? fileset("${path.module}/manifests", "**/*.{yml,yaml}") : []

  # List of all manifest files for local kubectl method
  all_manifest_file_paths = var.apply_k8s_manifests ? [
    for file_path in local.manifest_files_glob :
    "${path.module}/manifests/${file_path}"
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
      filemd5("${path.module}/manifests/${file_path}")
    ]) : ""
  }
}

# Apply manifests locally using kubectl (if use_ssh_kubectl is false)
resource "null_resource" "apply_k8s_locally" {
  count = var.apply_k8s_manifests && !var.use_ssh_kubectl ? 1 : 0

  provisioner "local-exec" {
    command = "kubectl apply -f ${join(" -f ", local.all_manifest_file_paths)}"
    working_dir = path.root
  }

  triggers = {
    # Trigger on any manifest file changes
    manifests_hash = join("-", [
      for file_path in local.manifest_files_glob :
      filemd5("${path.module}/manifests/${file_path}")
    ])
  }
}
