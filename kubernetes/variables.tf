variable "kubernetes_config_path" {
  description = "Path to the Kubernetes config file"
  type        = string
  default     = "~/.kube/config"
}

variable "ssh_user" {
  description = "SSH user"
  type        = string
  default     = "root"
}

variable "ssh_password" {
  description = "SSH password"
  type        = string
  default     = ""
  sensitive   = true
}

variable "target_host" {
  description = "Target host"
  type        = string
  default     = ""
}

variable "proxy_namespace" {
  description = "Proxy namespace"
  type        = string
  default     = "default"
}

variable "apply_k8s_manifests" {
  description = "Apply Kubernetes manifests"
  type        = bool
  default     = true
}

variable "ssh_key_path" {
  description = "SSH key path"
  type        = string
  default     = "~/.ssh/id_rsa"
}

variable "bucket" {
  description = "S3 bucket name"
  type        = string
}

variable "key" {
  description = "S3 object key"
  type        = string
}

variable "access_key" {
  description = "S3 access key"
  type        = string
}

variable "secret_key" {
  description = "S3 secret key"
  type        = string
  sensitive   = true
}

variable "endpoint" {
  description = "S3 endpoint URL"
  type        = string
}
