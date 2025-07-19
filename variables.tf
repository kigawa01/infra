variable "environment" {
  description = "Environment name"
  type        = string
}

variable "target_host" {
  description = "Target host IP address for Node Exporter installation and Kubernetes operations"
  type        = string
  default     = "192.168.1.50"
}

variable "ssh_user" {
  description = "SSH username for remote connection"
  type        = string
  default     = "kigawa"
}

variable "ssh_key_path" {
  description = "Path to SSH private key file (should be outside git's scope, e.g., ~/.ssh/infra_[environment]_key)"
  type        = string
  default     = ""
}

variable "ssh_password" {
  description = "SSH password (use if SSH key is not available)"
  type        = string
  default     = ""
  sensitive   = true
}

variable "sudo_password" {
  description = "Sudo password for executing commands with elevated privileges"
  type        = string
  default     = ""
  sensitive   = true
}

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

# Kubernetes configuration variables
variable "kubernetes_config_path" {
  description = "Path to the Kubernetes config file"
  type        = string
  default     = "~/.kube/config"
}

variable "kubernetes_config_context" {
  description = "Kubernetes config context to use"
  type        = string
  default     = ""
}

variable "apply_k8s_manifests" {
  description = "Whether to apply Kubernetes manifests"
  type        = bool
  default     = true
}

variable "apply_nginx_exporter" {
  description = "Whether to apply the nginx-exporter manifest (which is commented out by default)"
  type        = bool
  default     = false
}

variable "use_ssh_kubectl" {
  description = "Whether to use SSH+kubectl instead of the Kubernetes provider for applying manifests"
  type        = bool
  default     = true
}

variable "remote_manifests_dir" {
  description = "Directory on the remote host where Kubernetes manifests will be copied"
  type        = string
  default     = "/tmp/k8s-manifests"
}

variable "remote_kubectl_context" {
  description = "Kubectl context to use on the remote host (leave empty to use the current context)"
  type        = string
  default     = ""
}