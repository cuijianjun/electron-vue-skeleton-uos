#! /bin/sh
# deb 安装后脚本（electron-builder deb.afterInstall）
# 作用：把桌面快捷方式复制到各用户桌面，并刷新桌面

desktopPath=/opt/myapp/build/shell/myapp.desktop

rootDesktop=/root/Desktop

if [ -d $rootDesktop ]; then
  cp $desktopPath $rootDesktop
fi

users=`users`

for u in $users
  do
  dir=/home/$u/Desktop
  if [ -d $dir ]; then
    cp $desktopPath $dir
    chmod 755 $dir/myapp.desktop
    chown $u:$u $dir/myapp.desktop 2>/dev/null || true
  fi
done

# 刷新桌面图标缓存
update-desktop-database /usr/share/applications 2>/dev/null || true

exit 0
