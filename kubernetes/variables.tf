variable "apply_k8s_manifests" {
  description = "Whether to apply Kubernetes manifests"
  type        = bool
  default     = false
}

variable "apply_nginx_exporter" {
  description = "Whether to apply nginx exporter manifest"
  type        = bool
  default     = false
}

variable "use_ssh_kubectl" {
  description = "Whether to use SSH + kubectl instead of Kubernetes provider"
  type        = bool
  default     = true
}

variable "target_host" {
  description = "Target host for SSH connections"
  type        = string
}

variable "ssh_user" {
  description = "SSH user for connections"
  type        = string
}

variable "ssh_key_path" {
  description = "Path to SSH private key"
  type        = string
  default     = ""
}

variable "ssh_password" {
  description = "SSH password (if not using key)"
  type        = string
  default     = ""
  sensitive   = true
}

variable "remote_manifests_dir" {
  description = "Remote directory for Kubernetes manifests"
  type        = string
  default     = "/tmp/k8s-manifests"
}

variable "remote_kubectl_context" {
  description = "Kubectl context on remote host"
  type        = string
  default     = ""
}