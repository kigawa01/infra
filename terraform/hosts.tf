# Host-specific module configurations

# one-sakura host (Nginx installation)
module "one_sakura" {
  source = "./host/one-sakura"
  count  = var.enable_one_sakura ? 1 : 0

  nginx_enabled      = true
  nginx_server_name  = "0.0.0.0"
  nginx_target_host  = "one-sakura"
  ssh_user           = var.ssh_user
  ssh_key_path       = var.ssh_key_path
  sudo_password      = var.sudo_password
}

# k8s4 host (Node Exporter installation)
module "k8s4" {
  source = "./host/k8s4"
  count  = var.enable_k8s4 ? 1 : 0

  node_exporter_enabled = true
  node_exporter_version = "1.6.1"
  node_exporter_port    = 9100
  target_host           = "k8s4"
  ssh_user              = var.ssh_user
  ssh_key_path          = var.ssh_key_path
  sudo_password         = var.sudo_password
}

# lxc-nginx host (LXC Nginx installation)
module "lxc_nginx" {
  source = "./host/lxc-nginx"
  count  = var.enable_lxc_nginx ? 1 : 0

  lxc_nginx_enabled      = true
  lxc_nginx_server_name  = "0.0.0.0"
  lxc_nginx_target_host  = "lxc-nginx"
  ssh_key_path           = var.ssh_key_path
}

# host5 (192.168.1.50) host (Node Exporter installation)
module "host5" {
  source = "./host/host5"
  count  = var.enable_host5 ? 1 : 0

  node_exporter_enabled = true
  node_exporter_version = "1.6.1"
  node_exporter_port    = 9100
  target_host           = "host5"
  ssh_user              = var.ssh_user
  ssh_key_path          = var.ssh_key_path
  sudo_password         = var.sudo_password
}