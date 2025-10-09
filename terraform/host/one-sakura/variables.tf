# one-sakura host specific variables

variable "nginx_enabled" {
  description = "Whether to enable nginx installation and configuration"
  type        = bool
  default     = true
}

variable "nginx_server_name" {
  description = "Server name for nginx configuration"
  type        = string
  default     = "0.0.0.0"
}

variable "nginx_target_host" {
  description = "Target host for Nginx installation"
  type        = string
  default     = "one-sakura"
}

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