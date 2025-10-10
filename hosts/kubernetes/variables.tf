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

variable "kubernetes_config_context" {
  description = "Kubernetes config context to use"
  type        = string
  default     = ""
}
