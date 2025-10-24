# Host-specific module configurations

# one-sakura host (Nginx installation)
module "one_sakura" {
  source = "../old/host/one-sakura"
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
  source = "../old/host/k8s4"
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
  source = "../old/host/lxc-nginx"
  count  = var.enable_lxc_nginx ? 1 : 0

  lxc_nginx_enabled      = true
  lxc_nginx_server_name  = "0.0.0.0"
  lxc_nginx_target_host  = "lxc-nginx"
  ssh_key_path           = var.ssh_key_path
}

# host5 (192.168.1.50) host (libvirt VM management)
# DISABLED: Requires libvirt provider setup and SSH key configuration
# To enable, see terraform/host/host5/README.md
# module "host5" {
#   source = "./host/host5"
#   count  = var.enable_host5 ? 1 : 0
#
#   vm_enabled     = true
#   vm_name        = "ubuntu-vm"
#   vm_vcpu        = 2
#   vm_memory      = 2048
#   vm_disk_size   = 21474836480
#   ubuntu_version = "24.04"
#   vm_user        = "ubuntu"
#   vm_password    = "ubuntu"
#   ssh_user       = var.ssh_user
#   ssh_key_path   = var.ssh_key_path
# }