
SKIPUNZIP=1
ASH_STANDALONE=1

status=""
architecture=""
latest=$(date +%Y%m%d%H%M)

if [ $BOOTMODE ! = true ] ; then
	ui_print "- Installing through TWRP Not supported"
	ui_print "- Intsall this module via Magisk Manager"
	abort "- ! Aborting installation !"
fi

ui_print "- Installing Box for Magisk"

if [ -d "/data/adb/box" ] ; then
    ui_print "- backup box"
    mkdir -p /data/adb/box/${latest}
    mv /data/adb/box/* /data/adb/box/${latest}/
fi

mkdir -p ${MODPATH}/system/bin
mkdir -p ${MODPATH}/system/etc/security/cacerts
mkdir -p /data/adb/box
mkdir -p /data/adb/box/kernel
mkdir -p /data/adb/box/dashboard
mkdir -p /data/adb/box/run
mkdir -p /data/adb/box/scripts
mkdir -p /data/adb/box/xray/confs
mkdir -p /data/adb/box/v2fly/confs
mkdir -p /data/adb/box/sing-box
mkdir -p /data/adb/box/clash

case "${ARCH}" in
    arm)
        architecture="armv7"
        ;;
    arm64)
        architecture="armv8"
        ;;
    x86)
        architecture="386"
        ;;
    x64)
        architecture="amd64"
        ;;
esac

unzip -o "${ZIPFILE}" -x 'META-INF/*' -d $MODPATH >&2
unzip -j -o "${ZIPFILE}" 'uninstall.sh' -d ${MODPATH} >&2
unzip -j -o "${ZIPFILE}" 'box_service.sh' -d /data/adb/service.d >&2
tar -xjf ${MODPATH}/binary/${ARCH}.tar.bz2 -C ${MODPATH}/system/bin >&2

if [ ! -f "/system/etc/resolv.conf" ] ; then
  touch ${MODPATH}/system/etc/resolv.conf
  echo nameserver 8.8.8.8 > ${MODPATH}/system/etc/resolv.conf
  echo nameserver 9.9.9.9 >> ${MODPATH}/system/etc/resolv.conf
  echo nameserver 1.1.1.1 >> ${MODPATH}/system/etc/resolv.conf
  echo nameserver 149.112.112.112 >> ${MODPATH}/system/etc/resolv.conf
fi

mv ${MODPATH}/scripts/cacert.pem ${MODPATH}/system/etc/security/cacerts
mv ${MODPATH}/scripts/src/* /data/adb/box/scripts/
mv ${MODPATH}/scripts/clash/* /data/adb/box/clash/
mv ${MODPATH}/scripts/settings.ini /data/adb/box/
mv ${MODPATH}/scripts/template /data/adb/box/
mv ${MODPATH}/scripts/xray/confs /data/adb/box/xray/
mv ${MODPATH}/scripts/v2fly/confs /data/adb/box/v2fly/
mv ${MODPATH}/scripts/sing-box /data/adb/box/

rm -rf ${MODPATH}/scripts
rm -rf ${MODPATH}/binary
rm -rf ${MODPATH}/box_service.sh
sleep 1
set_perm_recursive ${MODPATH} 0 0 0755 0644
set_perm_recursive /data/adb/box/ 0 3005 0755 0644
set_perm_recursive /data/adb/box/scripts/ 0 3005 0755 0700
set_perm_recursive /data/adb/box/dashboard/ 0 3005 0755 0700
set_perm  /data/adb/service.d/box_service.sh  0  0  0755
set_perm  ${MODPATH}/service.sh  0  0  0755
set_perm  ${MODPATH}/uninstall.sh  0  0  0755
set_perm  ${MODPATH}/system/etc/security/cacerts/cacert.pem 0 0 0644
chmod ugo+x ${MODPATH}/system/bin/*
chmod ugo+x /data/adb/box/scripts/*
ui_print "- Installation is complete, reboot your device"
