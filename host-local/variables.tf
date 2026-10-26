variable "username" {
  description = "Local username"
  type        = string
  default     = "kigawa"
}

variable "home_dir" {
  description = "Home directory path"
  type        = string
  default     = "/home/kigawa"
}

# APT packages to install
variable "apt_packages" {
  description = "List of APT packages to install"
  type        = list(string)
  default = [
    "git",
    "gh",
    "curl",
    "wget",
    "tmux",
    "neovim",
    "docker-ce",
    "docker-ce-cli",
    "containerd.io",
    "docker-buildx-plugin",
    "docker-compose-plugin",
    "tailscale",
    "nvidia-driver-580",
    "ffmpeg",
    "gcc",
    "g++",
    "make",
    "cmake",
    "nodejs",
    "npm",
    "python3",
    "python3-pip",
    "php",
    "openjdk-25-jdk",
    "code",
    "claude-desktop",
    "1password",
    "google-chrome-stable",
    "chromium-browser",
    "firefox",
    "zoom",
    "steam-launcher",
    "adb",
    "apache2",
    "azure-cli",
  ]
}

# Snap packages to install
variable "snap_packages" {
  description = "List of snap packages to install"
  type        = list(string)
  default = [
    "aws-cli",
    "bitwarden",
    "chromium",
    "firefox",
    "helm",
    "kubectl",
    "slack",
  ]
}

# Snap packages that require --classic flag
variable "snap_classic_packages" {
  description = "List of snap packages requiring --classic flag"
  type        = list(string)
  default = [
    "kubectl",
    "helm",
  ]
}

# Flatpak packages to install
variable "flatpak_packages" {
  description = "List of flatpak packages to install"
  type        = list(string)
  default = [
    "com.obsproject.Studio",
  ]
}

# systemd services to enable
variable "enabled_services" {
  description = "List of systemd services to enable"
  type        = list(string)
  default = [
    "docker",
    "ollama",
    "tailscaled",
    "ssh",
  ]
}
