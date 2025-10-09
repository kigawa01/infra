variable "environment" {
  description = "Environment name"
  type        = string
}

variable "target_host" {
  description = "Target host IP address for Kubernetes operations"
  type        = string
  default     = "k8s4"
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

# Kubernetes configuration variables
variable "kubernetes_config_path" {
  description = "Path to the Kubernetes config file"
  type        = string
  default     = "/home/kigawa/.kube/config"
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
  default     = false
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

variable "apply_one_dev_manifests" {
  description = "Whether to apply one/dev Kubernetes manifests"
  type        = bool
  default     = false
}

# Host module configuration
variable "enable_one_sakura" {
  description = "Whether to enable one-sakura host configuration"
  type        = bool
  default     = true
}

variable "enable_k8s4" {
  description = "Whether to enable k8s4 host configuration"
  type        = bool
  default     = true
}

variable "enable_lxc_nginx" {
  description = "Whether to enable lxc-nginx host configuration"
  type        = bool
  default     = false
}