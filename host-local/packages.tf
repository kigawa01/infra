# APT packages installation
resource "null_resource" "apt_packages" {
  triggers = {
    package_list = jsonencode(var.apt_packages)
  }

  provisioner "local-exec" {
    command = <<-EOT
      export DEBIAN_FRONTEND=noninteractive
      sudo apt-get update
      sudo apt-get install -y ${join(" ", var.apt_packages)}
    EOT
  }
}

# Tailscale official APT repository (without it apt has no newer tailscale to upgrade to)
resource "null_resource" "tailscale_apt_repo" {
  triggers = {
    keyring_url = var.tailscale_apt_base_url
  }

  provisioner "local-exec" {
    command = <<-EOT
      set -e
      . /etc/os-release
      sudo install -d -m 0755 /usr/share/keyrings
      sudo curl -fsSL ${var.tailscale_apt_base_url}/$${VERSION_CODENAME}.noarmor.gpg -o /usr/share/keyrings/tailscale-archive-keyring.gpg
      curl -fsSL ${var.tailscale_apt_base_url}/$${VERSION_CODENAME}.tailscale-keyring.list | sudo tee /etc/apt/sources.list.d/tailscale.list > /dev/null
    EOT
  }
}

# Upgrade installed APT packages (install alone leaves them at their current version)
resource "null_resource" "apt_upgrade" {
  depends_on = [null_resource.apt_packages, null_resource.tailscale_apt_repo]

  triggers = {
    package_list = jsonencode(var.apt_upgrade_packages)
    revision     = var.apt_upgrade_revision
  }

  provisioner "local-exec" {
    command = <<-EOT
      export DEBIAN_FRONTEND=noninteractive
      sudo apt-get update
      sudo apt-get install -y --only-upgrade ${join(" ", var.apt_upgrade_packages)}
    EOT
  }
}

# Snap packages installation
resource "null_resource" "snap_packages" {
  triggers = {
    package_list = jsonencode(var.snap_packages)
  }

  provisioner "local-exec" {
    command = <<-EOT
      ${join(" && ", [for p in var.snap_packages : "sudo snap install ${p}"])}
    EOT
  }
}

# Snap classic packages installation (kubectl, helm, etc.)
resource "null_resource" "snap_classic_packages" {
  triggers = {
    package_list = jsonencode(var.snap_classic_packages)
  }

  provisioner "local-exec" {
    command = <<-EOT
      ${join(" && ", [for p in var.snap_classic_packages : "sudo snap install ${p} --classic"])}
    EOT
  }
}

# Flatpak packages installation
resource "null_resource" "flatpak_packages" {
  triggers = {
    package_list = jsonencode(var.flatpak_packages)
  }

  provisioner "local-exec" {
    command = <<-EOT
      sudo flatpak remote-add --if-not-exists --system flathub https://flathub.org/repo/flathub.flatpakrepo
      ${join(" && ", [for p in var.flatpak_packages : "flatpak install -y --system flathub ${p}"])}
    EOT
  }
}
