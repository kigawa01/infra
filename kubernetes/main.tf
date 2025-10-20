# Kubernetes manifests deployment

locals {
  proxy_manifests = {
    "configmap.yml"  = templatefile("${path.module}/manifests/proxy/configmap.yml.tpl", { namespace = var.proxy_namespace }),
    "deployment.yml" = templatefile("${path.module}/manifests/proxy/deployment.yml.tpl", { namespace = var.proxy_namespace }),
    "service.yml"    = templatefile("${path.module}/manifests/proxy/service.yml.tpl", { namespace = var.proxy_namespace }),
  }

  manifest_files_glob = fileset("${path.module}/../../terraform/kubernetes/manifests", "**/*.{yml,yaml}")

  all_manifest_file_paths = [
    for file_path in local.manifest_files_glob :
    "${path.module}/../../terraform/kubernetes/manifests/${file_path}"
  ]
}

resource "local_file" "proxy_manifests" {
  for_each = local.proxy_manifests
  content  = each.value
  filename = "${path.module}/generated/proxy/${each.key}"
}

# Apply non-templated manifests locally using kubectl
resource "null_resource" "apply_k8s_locally" {
  provisioner "local-exec" {
    command     = "kubectl apply -f ${join(" -f ", local.all_manifest_file_paths)}"
    working_dir = path.root
  }

  triggers = {
    manifests_hash = join("-", [
      for file_path in local.manifest_files_glob :
      filemd5("${path.module}/../../terraform/kubernetes/manifests/${file_path}")
    ])
  }
}

# Apply templated proxy manifests locally using kubectl
resource "null_resource" "apply_proxy_manifests" {
  depends_on = [local_file.proxy_manifests]

  provisioner "local-exec" {
    command = "kubectl apply -f ${path.module}/generated/proxy"
  }

  triggers = {
    proxy_manifests_hash = join("-", [
      for file in local_file.proxy_manifests :
      file.content_md5
    ])
  }
}