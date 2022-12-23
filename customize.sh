
SKIPUNZIP=1
ASH_STANDALONE=1

status=""
architecture=""
latest=$(date +%Y%m%d%H%M)

if $BOOTMODE; then
  ui_print "- Installing from Magisk app"
else
  ui_print "*********************************************************"
  ui_print "! Install from recovery is NOT supported"
  ui_print "! Some recovery has broken implementations, install with such recovery will finally cause BFM modules not working"
  ui_print "! Please install from Magisk app"
  abort "*********************************************************"
fi

# check Magisk
ui_print "- Magisk version: $MAGISK_VER ($MAGISK_VER_CODE)"

# check android
if [ "$API" -lt 23 ]; then
  ui_print "! Unsupported sdk: $API"
  abort "! Minimal supported sdk is 23 (Android 6.0)"
else
  ui_print "- Device sdk: $API"
fi

# check architecture
if [ "$ARCH" != "arm" ] && [ "$ARCH" != "arm64" ] && [ "$ARCH" != "x86" ] && [ "$ARCH" != "x64" ]; then
  abort "! Unsupported platform: $ARCH"
else
  ui_print "- Device platform: $ARCH"
fi

ui_print "- Installing Box for Magisk"

if [ -d "/data/adb/box" ] ; then
    ui_print "- Backup box"
    mkdir -p /data/adb/box/${latest}
    mv /data/adb/box/* /data/adb/box/${latest}/
fi

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

ui_print "- Mkdir BFM folder"
mkdir -p ${MODPATH}/system/bin
mkdir -p ${MODPATH}/system/etc/security/cacerts
mkdir -p /data/adb/box
mkdir -p /data/adb/box/bin
mkdir -p /data/adb/box/dashboard
mkdir -p /data/adb/box/run
mkdir -p /data/adb/box/scripts
mkdir -p /data/adb/box/xray
mkdir -p /data/adb/box/v2fly
mkdir -p /data/adb/box/sing-box
mkdir -p /data/adb/box/clash

ui_print "- Extracting BFM files"
unzip -o "${ZIPFILE}" -x 'META-INF/*' -d $MODPATH >&2
unzip -j -o "${ZIPFILE}" 'uninstall.sh' -d ${MODPATH} >&2
unzip -j -o "${ZIPFILE}" 'box_service.sh' -d /data/adb/service.d >&2
tar -xjf ${MODPATH}/binary/${ARCH}.tar.bz2 -C ${MODPATH}/system/bin >&2

ui_print "- Create resolv.conf"
if [ ! -f "/system/etc/resolv.conf" ] ; then
  touch ${MODPATH}/system/etc/resolv.conf
  echo nameserver 8.8.8.8 > ${MODPATH}/system/etc/resolv.conf
  echo nameserver 9.9.9.9 >> ${MODPATH}/system/etc/resolv.conf
  echo nameserver 1.1.1.1 >> ${MODPATH}/system/etc/resolv.conf
  echo nameserver 149.112.112.112 >> ${MODPATH}/system/etc/resolv.conf
fi

ui_print "- Move BFM files"
mv ${MODPATH}/scripts/cacert.pem ${MODPATH}/system/etc/security/cacerts
mv ${MODPATH}/scripts/src/* /data/adb/box/scripts/
mv ${MODPATH}/scripts/clash/* /data/adb/box/clash/
mv ${MODPATH}/scripts/settings.ini /data/adb/box/
mv ${MODPATH}/scripts/template.ini /data/adb/box/
mv ${MODPATH}/scripts/xray /data/adb/box/
mv ${MODPATH}/scripts/v2fly /data/adb/box/
mv ${MODPATH}/scripts/sing-box /data/adb/box/

ui_print "- Delete leftover files"
rm -rf ${MODPATH}/scripts
rm -rf ${MODPATH}/binary
rm -rf ${MODPATH}/box_service.sh
sleep 1
ui_print "- Setting permissions"
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
