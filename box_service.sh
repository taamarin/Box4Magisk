#!/system/bin/sh

(
until [ $(getprop init.svc.bootanim) = "stopped" ] ; do
    sleep 3
done

chmod 755 /data/adb/box/scripts/start.sh
/data/adb/box/scripts/start.sh
)&