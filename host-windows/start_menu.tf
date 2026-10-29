# Start menu pins (captured start2.bin, restored as-is)
# Refresh the capture after changing pins:
#   Copy-Item "$env:LOCALAPPDATA\Packages\Microsoft.Windows.StartMenuExperienceHost_cw5n1h2txyewy\LocalState\start2.bin" host-windows\start2.bin
resource "null_resource" "start_menu_pins" {
  triggers = {
    start2_bin = filemd5("${path.module}/start2.bin")
  }

  provisioner "local-exec" {
    interpreter = ["powershell", "-NoProfile", "-Command"]
    command     = <<-EOT
      $dest = "$env:LOCALAPPDATA\Packages\Microsoft.Windows.StartMenuExperienceHost_cw5n1h2txyewy\LocalState\start2.bin"
      Stop-Process -Name StartMenuExperienceHost -Force -ErrorAction SilentlyContinue
      Copy-Item -Path "${path.module}/start2.bin" -Destination $dest -Force
    EOT
  }
}
