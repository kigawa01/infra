# lxc-nginx host specific variables

variable "lxc_nginx_enabled" {
  description = "Whether to enable LXC nginx installation and configuration"
  type        = bool
  default     = false
}

variable "lxc_nginx_server_name" {
  description = "Server name for LXC nginx configuration"
  type        = string
  default     = "0.0.0.0"
}

variable "lxc_nginx_target_host" {
  description = "Target host for LXC Nginx installation"
  type        = string
  default     = "lxc-nginx"
}

variable "ssh_key_path" {
  description = "Path to SSH private key file"
  type        = string
  default     = ""
}