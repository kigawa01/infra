module "k8s" {
  source = "../shared/k8s-host"
  user   = module.shared.ssh_user
  host   = module.shared.host1_ip_network
}
