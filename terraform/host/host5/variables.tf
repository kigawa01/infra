# host5 (192.168.1.50) - libvirt VM management

variable "ssh_user" {
  description = "SSH username for host5 connection"
  type        = string
  default     = "kigawa"
}

variable "ssh_key_path" {
  description = "Path to SSH private key file"
  type        = string
  default     = ""
}

variable "vm_enabled" {
  description = "Whether to create Ubuntu VM"
  type        = bool
  default     = true
}

variable "vm_name" {
  description = "Name of the VM"
  type        = string
  default     = "ubuntu-vm"
}

variable "vm_vcpu" {
  description = "Number of vCPUs for the VM"
  type        = number
  default     = 2
}

variable "vm_memory" {
  description = "Memory size in MB for the VM"
  type        = number
  default     = 2048
}

variable "vm_disk_size" {
  description = "Disk size in bytes for the VM (default: 20GB)"
  type        = number
  default     = 21474836480
}

variable "ubuntu_version" {
  description = "Ubuntu version to use"
  type        = string
  default     = "24.04"
}

variable "vm_user" {
  description = "Default user for the VM"
  type        = string
  default     = "ubuntu"
}

variable "vm_password" {
  description = "Default password for the VM user"
  type        = string
  default     = "ubuntu"
  sensitive   = true
}