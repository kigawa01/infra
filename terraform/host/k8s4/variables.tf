# k8s4 host specific variables

variable "node_exporter_enabled" {
  description = "Whether to enable Prometheus Node Exporter"
  type        = bool
  default     = true
}

variable "node_exporter_version" {
  description = "Version of Prometheus Node Exporter to install"
  type        = string
  default     = "1.6.1"
}

variable "node_exporter_port" {
  description = "Port for Prometheus Node Exporter"
  type        = number
  default     = 9100
}

variable "target_host" {
  description = "Target host IP address for Node Exporter installation"
  type        = string
  default     = "k8s4"
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