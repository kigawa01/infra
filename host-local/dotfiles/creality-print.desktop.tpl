[Desktop Entry]
# Wayland + NVIDIA/Intel 混在環境で 3D ビューが描画されない問題の回避:
# XWayland で起動し、GL/EGL を Mesa に固定する (NVIDIA 経路は segfault する)
Exec=env GDK_BACKEND=x11 __GLX_VENDOR_LIBRARY_NAME=mesa __EGL_VENDOR_LIBRARY_FILENAMES=/usr/share/glvnd/egl_vendor.d/50_mesa.json ${appimage_path}
Version=1.0
Type=Application
Categories=Development
Name=Creality Print
Terminal=false
