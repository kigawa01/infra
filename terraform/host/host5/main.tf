# Terraform libvirt provider configuration for host5
terraform {
  required_providers {
    libvirt = {
      source  = "dmacvicar/libvirt"
      version = "~> 0.7"
    }
  }
}

# Connect to libvirt on host5 via SSH
provider "libvirt" {
  uri = "qemu+ssh://${var.ssh_user}@192.168.1.50/system"
}

# Ubuntu cloud image
resource "libvirt_volume" "ubuntu_base" {
  count  = var.vm_enabled ? 1 : 0
  name   = "${var.vm_name}-base.qcow2"
  pool   = "default"
  source = "https://cloud-images.ubuntu.com/releases/${var.ubuntu_version}/release/ubuntu-${var.ubuntu_version}-server-cloudimg-amd64.img"
  format = "qcow2"
}

# VM disk based on Ubuntu image
resource "libvirt_volume" "ubuntu_disk" {
  count          = var.vm_enabled ? 1 : 0
  name           = "${var.vm_name}-disk.qcow2"
  pool           = "default"
  base_volume_id = libvirt_volume.ubuntu_base[0].id
  size           = var.vm_disk_size
  format         = "qcow2"
}

# Cloud-init configuration
data "template_file" "user_data" {
  count    = var.vm_enabled ? 1 : 0
  template = file("${path.module}/templates/cloud-init.yaml")
  vars = {
    vm_user     = var.vm_user
    vm_password = var.vm_password
    ssh_key     = var.ssh_key_path != "" ? file(var.ssh_key_path) : file("../ssh-keys/id_ed25519.pub")
  }
}

# Cloud-init disk
resource "libvirt_cloudinit_disk" "cloudinit" {
  count     = var.vm_enabled ? 1 : 0
  name      = "${var.vm_name}-cloudinit.iso"
  pool      = "default"
  user_data = data.template_file.user_data[0].rendered
}

# Ubuntu VM
resource "libvirt_domain" "ubuntu_vm" {
  count  = var.vm_enabled ? 1 : 0
  name   = var.vm_name
  memory = var.vm_memory
  vcpu   = var.vm_vcpu

  cloudinit = libvirt_cloudinit_disk.cloudinit[0].id

  disk {
    volume_id = libvirt_volume.ubuntu_disk[0].id
  }

  network_interface {
    network_name   = "default"
    wait_for_lease = true
  }

  console {
    type        = "pty"
    target_type = "serial"
    target_port = "0"
  }

  graphics {
    type        = "spice"
    listen_type = "address"
    autoport    = true
  }
}

# Output VM IP address
output "vm_ip" {
  value       = var.vm_enabled ? libvirt_domain.ubuntu_vm[0].network_interface[0].addresses[0] : null
  description = "IP address of the created VM"
}