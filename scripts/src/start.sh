#!/system/bin/sh

moddir="/data/adb/modules/box_for_magisk"
if [ -n "$(magisk -v | grep lite)" ] ; then
  moddir=/data/adb/lite_modules/box_for_magisk
fi

scripts_dir="/data/adb/box/scripts"

refresh_box() {
  if [ -f /data/adb/box/run/box.pid ] ; then
    ${scripts_dir}/box.service stop && ${scripts_dir}/box.iptables disable
  fi
}

start_service() {
  if [ ! -f /data/adb/box/manual ] ; then
    if [ ! -f ${moddir}/disable ] ; then
      ${scripts_dir}/box.service start
      if [ -f /data/adb/box/run/box.pid ] ; then
        ${scripts_dir}/box.iptables enable
      fi
    fi
    inotifyd ${scripts_dir}/box.inotify ${moddir} &>> /dev/null &
  fi
}

refresh_box
start_service