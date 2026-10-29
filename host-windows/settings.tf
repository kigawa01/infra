# Windows settings (per-user registry)
resource "null_resource" "windows_settings" {
  triggers = {
    show_file_extensions = var.show_file_extensions
    app_dark_mode        = var.app_dark_mode
  }

  provisioner "local-exec" {
    interpreter = ["powershell", "-NoProfile", "-Command"]
    command     = <<-EOT
      Set-ItemProperty 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' -Name HideFileExt -Value ${var.show_file_extensions ? 0 : 1}
      Set-ItemProperty 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize' -Name AppsUseLightTheme -Value ${var.app_dark_mode ? 0 : 1}
    EOT
  }
}
