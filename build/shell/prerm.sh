#! /bin/sh
# deb 卸载前脚本（electron-builder deb.afterRemove）
# 作用：清理各用户桌面上的快捷方式

app=myapp

rootDesktop=/root/Desktop

if [ -f $rootDesktop/$app.desktop ]; then
  rm -f $rootDesktop/$app.desktop
fi

users=`users`

for u in $users
  do
  dir=/home/$u/Desktop
  if [ -f $dir/$app.desktop ]; then
    rm -f $dir/$app.desktop
  fi
done

exit 0
