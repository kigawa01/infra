# winget packages installation (skips packages that are already installed)
resource "null_resource" "winget_packages" {
  triggers = {
    package_list = jsonencode(var.winget_packages)
  }

  provisioner "local-exec" {
    interpreter = ["powershell", "-NoProfile", "-Command"]
    command     = <<-EOT
      foreach ($id in @(${join(",", [for p in var.winget_packages : "'${p}'"])})) {
        winget list --id $id --exact --accept-source-agreements | Out-Null
        if ($LASTEXITCODE -ne 0) {
          winget install --id $id --exact --silent --accept-package-agreements --accept-source-agreements
        }
      }
    EOT
  }
}
