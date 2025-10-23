# Kubernetes manifests deployment

locals {
  proxy_manifests = {
    "configmap.yml"  = templatefile("${path.module}/manifests/proxy/configmap.yml.tpl", { namespace = var.proxy_namespace }),
    "deployment.yml" = templatefile("${path.module}/manifests/proxy/deployment.yml.tpl", { namespace = var.proxy_namespace }),
    "service.yml"    = templatefile("${path.module}/manifests/proxy/service.yml.tpl", { namespace = var.proxy_namespace }),
  }
}

resource "local_file" "proxy_manifests" {
  for_each = local.proxy_manifests
  content  = each.value
  filename = "${path.module}/generated/proxy/${each.key}"
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
