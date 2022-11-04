#!/system/bin/sh

moddir="/data/adb/modules/box_for_magisk"
if [ -n "$(magisk -v | grep lite)" ]
then
  moddir=/data/adb/lite_modules/box_for_magisk
fi

scripts_dir="/data/adb/box/scripts"
busybox_path="/data/adb/magisk/busybox"

refresh_box() {
  if [ -f ${box_pid_file} ]; then
    ${scripts_dir}/box.service stop && ${scripts_dir}/box.iptables disable
  fi
}

start_service() {
  if [ ! -f /data/adb/box/manual ]; then
    if [ ! -f ${moddir}/disable ]; then
      ${scripts_dir}/box.service start
      if [ -f /data/adb/box/run/*.pid ]; then
        ${scripts_dir}/box.iptables enable
      fi
    fi

    if [ "$?" = 0 ]; then
       ulimit -SHn 1000000
       inotifyd ${scripts_dir}/box.inotify ${moddir} &>> /dev/null &
    fi
  fi
}

refresh_box
start_service