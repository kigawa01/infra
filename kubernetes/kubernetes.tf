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
