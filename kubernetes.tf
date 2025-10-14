# Kubernetes module
module "kubernetes" {
  source = "terraform/kubernetes"

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