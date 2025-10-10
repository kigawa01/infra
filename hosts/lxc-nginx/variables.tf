variable "environment" {
  description = "Environment name"
  type        = string
  default     = "prod"
}

variable "ssh_key_path" {
  description = "Path to SSH private key file"
  type        = string
  default     = ""
}

variable "lxc_nginx_server_name" {
  description = "LXC Nginx server name"
  type        = string
  default     = "0.0.0.0"
}
