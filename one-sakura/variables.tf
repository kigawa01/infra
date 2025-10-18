variable "ssh_user" {
  description = "SSH username for remote connection"
  type        = string
  default     = "kigawa"
}

variable "ssh_key_path" {
  description = "Path to SSH private key file"
  type        = string
  default     = ""
}

variable "sudo_password" {
  description = "Sudo password for executing commands with elevated privileges"
  type        = string
  default     = ""
  sensitive   = true
}

variable "nginx_server_name" {
  description = "Nginx server name"
  type        = string
  default     = "0.0.0.0"
}
