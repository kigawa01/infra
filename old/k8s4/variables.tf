variable "environment" {
  description = "Environment name"
  type        = string
  default     = "prod"
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

variable "node_exporter_version" {
  description = "Node Exporter version to install"
  type        = string
  default     = "1.6.1"
}

variable "node_exporter_port" {
  description = "Node Exporter port"
  type        = number
  default     = 9100
}
