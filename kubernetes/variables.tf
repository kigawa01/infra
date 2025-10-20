variable "environment" {
  description = "Environment name"
  type        = string
  default     = "prod"
}

variable "kubernetes_config_path" {
  description = "Path to the Kubernetes config file"
  type        = string
  default     = "~/.kube/config"
}

variable "apply_one_dev_manifests" {
  description = "Whether to apply the one-dev manifests"
  type        = bool
  default     = false
}

variable "proxy_namespace" {
  description = "The namespace for the proxy resources"
  type        = string
  default     = "infra"
}
