#!/bin/bash
# OCS Desktop for Debian/Ubuntu 自动安装脚本

VERSION="2.8.21"
ARCH=$(uname -m)

# 根据架构确定下载链接
if [ "$ARCH" = "x86_64" ]; then
  DL_URL="https://github.com/ocsjs/ocs-desktop/releases/download/${VERSION}/ocs-${VERSION}-setup-linux-x86_64.AppImage"
  APPIMAGE_NAME="ocs-${VERSION}-setup-linux-x86_64.AppImage"
elif [ "$ARCH" = "aarch64" ] || [ "$ARCH" = "arm64" ]; then
  DL_URL="https://github.com/ocsjs/ocs-desktop/releases/download/${VERSION}/ocs-${VERSION}-setup-linux-arm64.AppImage"
  APPIMAGE_NAME="ocs-${VERSION}-setup-linux-arm64.AppImage"
else
  echo "❌ 不支持的架构: $ARCH"
  exit 1
fi

echo "📦 正在安装依赖..."
sudo apt update
sudo apt install -y wget curl libfuse2 libarchive-tools desktop-file-utils

echo "⬇️ 正在下载 OCS Desktop v${VERSION}..."
wget -q --show-progress -O "$APPIMAGE_NAME" "$DL_URL"
chmod +x "$APPIMAGE_NAME"

echo "⚙️ 正在提取并配置文件..."
# 将 AppImage 安装到 /opt
sudo install -Dm755 "$APPIMAGE_NAME" "/opt/ocs-desktop/OCS-Desktop.AppImage"

# 提取内部资源 (图标和内置 Chrome)
./"$APPIMAGE_NAME" --appimage-extract >/dev/null

# 配置内置 Chrome
sudo mkdir -p /opt/ocs-desktop/resources/bin/chrome/chrome
sudo bsdtar -xf "./squashfs-root/resources/bin/chrome/chrome.zip" \
  --strip-components=2 \
  -C "/opt/ocs-desktop/resources/bin/chrome/chrome"
sudo chmod -R +x /opt/ocs-desktop/resources/bin/chrome/chrome

# 安装图标
sudo install -Dm644 "./squashfs-root/usr/share/icons/hicolor/0x0/apps/ocs desktop.png" \
  "/usr/share/icons/hicolor/256x256/apps/ocs-desktop.png"

# 清理临时提取文件夹和安装包
rm -rf ./squashfs-root
rm "$APPIMAGE_NAME"

echo "🚀 创建启动命令和桌面快捷方式..."
# 创建 /usr/bin 启动脚本
cat <<'EOF' | sudo tee /usr/bin/ocs-desktop >/dev/null
#!/bin/bash
exec /opt/ocs-desktop/OCS-Desktop.AppImage --no-sandbox "$@"
EOF
sudo chmod 755 /usr/bin/ocs-desktop

# 创建桌面快捷方式
cat <<'EOF' | sudo tee "/usr/share/applications/OCS Desktop.desktop" >/dev/null
[Desktop Entry]
Name=OCS Desktop
Exec=ocs-desktop
Icon=ocs-desktop
Terminal=false
Type=Application
Categories=Utility;
Comment=OCS 浏览器自动化神器，一键浏览器多开，用户脚本环境一键配置.
StartupWMClass=OCS Desktop
EOF

# 更新桌面数据库
sudo update-desktop-database /usr/share/applications

echo
echo "=================================================================="
echo "✅ OCS Desktop 安装成功！"
echo "⚠️ OCS Desktop 需要的 Chrome 将被安装在："
echo "   /opt/ocs-desktop/resources/bin/chrome/chrome/chrome"
echo "👉 请在 OCS Desktop 软件内使用该路径进行浏览器配置。"
echo "=================================================================="
echo "你可以通过在终端输入 ocs-desktop 或在系统的应用菜单中搜索 OCS Desktop 来启动它。"
echo
