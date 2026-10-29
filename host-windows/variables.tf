variable "winget_packages" {
  description = "List of winget package IDs to install"
  type        = list(string)
  default = [
    "Anthropic.Claude",
    "Bitwarden.Bitwarden",
    "Docker.DockerDesktop",
    "Git.Git",
    "GitHub.cli",
    "Hashicorp.Terraform",
    "JetBrains.Toolbox",
    "KDE.Krita",
    "Logitech.OptionsPlus",
    "Microsoft.DotNet.SDK.8",
    "Microsoft.Outlook",
    "Microsoft.WSL",
    "Microsoft.WindowsTerminal",
    "Rye.Rye",
    "Tailscale.Tailscale",
  ]
}

variable "show_file_extensions" {
  description = "Show file extensions in Explorer"
  type        = bool
  default     = true
}

variable "app_dark_mode" {
  description = "Use dark mode for apps"
  type        = bool
  default     = true
}
