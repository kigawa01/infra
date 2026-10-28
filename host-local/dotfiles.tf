# Backup existing dotfiles before overwriting
resource "null_resource" "backup_dotfiles" {
  triggers = {
    # Run only once — the script checks for .bak existence, so re-running is safe but no-op
    always_run = "1"
  }

  provisioner "local-exec" {
    command = <<-EOT
      # Only backup if .bak doesn't already exist
      for f in .bashrc .zshrc .tmux.conf; do
        if [ -f "${var.home_dir}/$f" ] && [ ! -f "${var.home_dir}/$f.bak" ]; then
          cp "${var.home_dir}/$f" "${var.home_dir}/$f.bak"
          echo "Backed up ${var.home_dir}/$f to ${var.home_dir}/$f.bak"
        fi
      done
      # Backup SSH config
      if [ -f "${var.home_dir}/.ssh/config" ] && [ ! -f "${var.home_dir}/.ssh/config.bak" ]; then
        cp "${var.home_dir}/.ssh/config" "${var.home_dir}/.ssh/config.bak"
        echo "Backed up ${var.home_dir}/.ssh/config to ${var.home_dir}/.ssh/config.bak"
      fi
    EOT
  }
}

# .bashrc
resource "local_file" "bashrc" {
  content    = file("${path.module}/dotfiles/bashrc.tpl")
  filename   = "${var.home_dir}/.bashrc"
  depends_on = [null_resource.backup_dotfiles]
}

# .zshrc
resource "local_file" "zshrc" {
  content    = file("${path.module}/dotfiles/zshrc.tpl")
  filename   = "${var.home_dir}/.zshrc"
  depends_on = [null_resource.backup_dotfiles]
}

# .tmux.conf
resource "local_file" "tmux_conf" {
  content    = file("${path.module}/dotfiles/tmux.conf.tpl")
  filename   = "${var.home_dir}/.tmux.conf"
  depends_on = [null_resource.backup_dotfiles]
}

# Creality Print launcher (3D ビュー描画不良の回避設定込み)
resource "local_file" "creality_print_desktop" {
  content = templatefile("${path.module}/dotfiles/creality-print.desktop.tpl", {
    appimage_path = var.creality_print_appimage
  })
  filename        = "${var.home_dir}/.local/share/applications/creality-print.desktop"
  file_permission = "0755"
}

# .ssh/config
resource "local_file" "ssh_config" {
  content    = file("${path.module}/dotfiles/ssh_config.tpl")
  filename   = "${var.home_dir}/.ssh/config"
  file_permission = "0600"
  depends_on = [null_resource.backup_dotfiles]
}
