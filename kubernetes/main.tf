# Kubernetes manifests deployment

locals {
  # Discover all manifest files in the manifests directory
  manifest_files_glob = fileset("${path.module}/../../terraform/kubernetes/manifests", "**/*.{yml,yaml}")

  # List of all manifest files for local kubectl method
  all_manifest_file_paths = [
    for file_path in local.manifest_files_glob :
    "${path.module}/../../terraform/kubernetes/manifests/${file_path}"
  ]
}

# Apply manifests locally using kubectl (Kubernetes provider mode)
resource "null_resource" "apply_k8s_locally" {
  provisioner "local-exec" {
    command = "kubectl apply -f ${join(" -f ", local.all_manifest_file_paths)}"
    working_dir = path.root
  }

  triggers = {
    # Trigger on any manifest file changes
    manifests_hash = join("-", [
      for file_path in local.manifest_files_glob :
      filemd5("${path.module}/../../terraform/kubernetes/manifests/${file_path}")
    ])
  }
}
