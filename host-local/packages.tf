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

# Upgrade installed APT packages (install alone leaves them at their current version)
resource "null_resource" "apt_upgrade" {
  depends_on = [null_resource.apt_packages]

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
