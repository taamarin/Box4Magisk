#!/system/bin/sh

scripts=$(realpath $0)
scripts_dir=$(dirname ${scripts})
source /data/adb/box/settings.ini

restart_box() {
  probe_bin_alive() {
     [ -f ${pid_file} ] && cmd_file="/proc/$(pidof ${bin_name})/cmdline" || return 1
     [ -f ${cmd_file} ] && grep -q ${bin_name} ${cmd_file} && return 0 || return 1
  }
  ${scripts_dir}/box.service stop
  ${scripts_dir}/box.service start
  if probe_bin_alive ; then
    ${scripts_dir}/box.iptables enable
    log info "$(date) ${bin_name} restart"
  else
    log error "${bin_name} failed to restart."
  fi
}

update_file() {
  file="$1"
  file_bak="${file}.bak"
  update_url="$2"
  [ -f ${file} ] \
  && mv -f ${file} ${file_bak}
  echo "/data/adb/magisk/busybox wget --no-check-certificate ${update_url} -O ${file}"
  /data/adb/magisk/busybox wget --no-check-certificate ${update_url} -O ${file} 2>&1
  sleep 0.5
  if [ -f "${file}" ] ; then
    echo ""
  else
    [ -f "${file_bak}" ] \
    && mv ${file_bak} ${file}
  fi
}

update_subgeo() {
  case "${bin_name}" in
    clash)
      if [ "${meta}" = "false" ] ; then
        geoip_file="${data_dir}/clash/Country.mmdb"
        geoip_url="https://github.com/Loyalsoldier/geoip/raw/release/Country-only-cn-private.mmdb"
      else
        geoip_file="${data_dir}/clash/GeoIP.dat"
        geoip_url="https://github.com/v2fly/geoip/raw/release/geoip-only-cn-private.dat"
      fi
      geosite_file="${data_dir}/clash/GeoSite.dat"
      geosite_url="https://github.com/CHIZI-0618/v2ray-rules-dat/raw/release/geosite.dat"
    ;;
    sing-box)
      geoip_file="${data_dir}/sing-box/geoip.db"
      geoip_url="https://github.com/SagerNet/sing-geoip/releases/download/20221012/geoip-cn.db"
      geosite_file="${data_dir}/sing-box/geosite.db"
      geosite_url="https://github.com/CHIZI-0618/v2ray-rules-dat/raw/release/geosite.db"
    ;;
    *)
      geoip_file="${data_dir}/${bin_name}/geoip.dat"
      geoip_url="https://github.com/v2fly/geoip/raw/release/geoip-only-cn-private.dat"
      geosite_file="${data_dir}/${bin_name}/geosite.dat"
      geosite_url="https://github.com/CHIZI-0618/v2ray-rules-dat/raw/release/geosite.dat"
    ;;
  esac

  if [ "${auto_updategeox}" = "true" ] ; then
    if update_file ${geoip_file} ${geoip_url} && update_file ${geosite_file} ${geosite_url} ; then
      log warn "Update geo $(date +"%Y-%m-%d %I.%M %p")"
      flag=false
    fi
  fi
  if [ ${auto_updatesubcript} = "true" ] ; then
    if update_file ${clash_config} ${subcript_url} ; then
      flag=true
    fi
  fi
  if [ -f "${pid_file}" ] && [ ${flag} = true ] ; then
    restart_box
  fi
}

port_detection() {
  logs() {
    export TZ=Asia/Jakarta
    now=$(date +"%I.%M %p")
    case $1 in
    info)
      [ -t 1 ] && echo -n "\033[1;34m${now} [info]: $2\033[0m" || echo -n "${now} [info]: $2" | tee -a ${logs_file} >> /dev/null 2>&1
      ;;
    port)
      [ -t 1 ] && echo -n "\033[1;33m$2 \033[0m" || echo -n "$2 " | tee -a ${logs_file} >> /dev/null 2>&1
      ;;
    *)
      [ -t 1 ] && echo -n "\033[1;30m${now} [$1]: $2\033[0m" || echo -n "${now} [$1]: $2" | tee -a ${logs_file} >> /dev/null 2>&1
      ;;
    esac
  }
  match_count=0
  if (ss -h > /dev/null 2>&1) ; then
    port=$(ss -antup | grep "${bin_name}" | ${busybox_path} awk '$7~/'pid=$(pidof ${bin_name})*'/{print $5}' | ${busybox_path} awk -F ':' '{print $2}' | sort -u)
  else
    log info "skip!!! port detected"
    exit 0
  fi
  logs info "${bin_name} port detected: "
  for sub_port in ${port[*]} ; do
    sleep 0.5
    logs port "${sub_port}"
  done
  echo "" >> ${logs_file}
}

update_kernel() {
  arc=$(uname -m)
  if [ "${arc}" = "aarch64" ] ; then
    arch="arm64"
    platform="android"
  else
    arch="armv7"
    platform="linux"
  fi
  file_kernel="${bin_name}-${arch}"
  case "${bin_name}" in
    sing-box)
      download_link="https://github.com/SagerNet/sing-box/releases"
      github_api="https://api.github.com/repos/SagerNet/sing-box/releases"

      latest_version_tag=$(/data/adb/magisk/busybox wget --no-check-certificate -qO- ${github_api} | grep -m 1 "tag_name" | grep -o "v[0-9.]*" | head -1)
      latest_version=$(/data/adb/magisk/busybox wget --no-check-certificate -qO- ${github_api} | grep -m 1 "tag_name" | grep -o "[0-9.]*" | head -1)

      download_file="sing-box-${latest_version}-${platform}-${arch}"
      update_file "${data_dir}/${file_kernel}.tar.gz" "${download_link}/download/${latest_version_tag}/${download_file}.tar.gz"

      tar -xvf "${data_dir}/${file_kernel}.tar.gz" -C ${data_dir} >&2
      mv -f "${data_dir}/${download_file}/sing-box" "${bin_kernel}/sing-box" \
      && rm -rf "${data_dir}/${download_file}"
      if [ $(pidof ${bin_name}) ] && [ -f ${pid_file} ] ; then
        restart_box && exit 0
      else
        exit 0
      fi
      ;;
    clash)
      if [ "${meta}" = "true" ] ; then
        tag="Prerelease-Alpha"
        tag_name="alpha-[0-9,a-z]+"
        download_link="https://github.com/taamarin/Clash.Meta/releases"
        latest_version=$(/data/adb/magisk/busybox wget --no-check-certificate -qO- "${download_link}/expanded_assets/${tag}" | grep -oE "${tag_name}" | head -1)
        filename="clash.meta-${platform}-${arch}-${latest_version}"
        update_file "${data_dir}/${file_kernel}.gz" "${download_link}/download/${tag}/${filename}.gz"
      else
        if [ "${dev}" != "false" ] ; then
          download_link="https://release.dreamacro.workers.dev/latest"
          update_file "${data_dir}/${file_kernel}.gz" "${download_link}/clash-linux-${arch}-latest.gz"
        else
          download_link="https://github.com/Dreamacro/clash/releases"
          filename=$(/data/adb/magisk/busybox wget --no-check-certificate -qO- "${download_link}/expanded_assets/premium" | grep -oE "clash-linux-${arch}-[0-9]+.[0-9]+.[0-9]+" | head -1)
          update_file "${data_dir}/${file_kernel}.gz" "${download_link}/download/premium/${filename}.gz"
        fi
      fi
      ;;
    xray)
      download_link="https://github.com/XTLS/Xray-core/releases"
      github_api="https://api.github.com/repos/XTLS/Xray-core/releases"
      latest_version=$(/data/adb/magisk/busybox wget --no-check-certificate -qO- ${github_api} | grep "tag_name" | grep -o "v[0-9.]*" | head -1)
      if [ "${arc}" != "aarch64" ] ; then
        download_file="Xray-linux-arm32-v7a.zip"
      else
        download_file="Xray-android-arm64-v8a.zip"
      fi
      update_file "${data_dir}/${file_kernel}.zip" "${download_link}/download/${latest_version}/${download_file}"
      unzip -o "${data_dir}/${file_kernel}.zip" "xray" -d ${bin_kernel} >&2
      if [ $(pidof ${bin_name}) ] && [ -f ${pid_file} ] ; then
        restart_box && exit 0
      else
        exit 0
      fi
    ;;
    v2fly)
      download_link="https://github.com/v2fly/v2ray-core/releases"
      github_api="https://api.github.com/repos/v2fly/v2ray-core/releases"
      latest_version=$(/data/adb/magisk/busybox wget --no-check-certificate -qO- ${github_api} | grep "tag_name" | grep -o "v[0-9.]*" | head -1)
      if [ "${arc}" != "aarch64" ] ; then
        download_file="v2ray-linux-arm32-v7a.zip"
      else
        download_file="v2ray-android-arm64-v8a.zip"
      fi
      update_file "${data_dir}/${file_kernel}.zip" "${download_link}/download/${latest_version}/${download_file}"
      unzip -j -o "${data_dir}/${file_kernel}.zip" "v2ray" -d ${bin_kernel} >&2 \
      && mv "${bin_kernel}/v2ray" "${bin_kernel}/v2fly" || log error "failed replace"
      if [ $(pidof ${bin_name}) ] && [ -f ${pid_file} ] ; then
        restart_box && exit 0
      else
        exit 0
      fi
      ;;
    *)
      log error "kernel error." && exit 1
      ;;
  esac
  if (gunzip --help > /dev/null 2>&1) ; then
    if ! (gunzip "${data_dir}/${file_kernel}.gz") ; then
      if ! (rm -rf "${data_dir}/${file_kernel}.gz.bak") ; then
        rm -rf "${data_dir}/${file_kernel}.gz"
      fi
      log warn "gunzip ${file_kernel}.gz failed" 
    else
      mv -f "${data_dir}/${file_kernel}" "${bin_kernel}/${bin_name}" && flag="true"
      if [ -f "${pid_file}" ] && [ "${flag}" = "true" ] ; then
        restart_box
      else
        log warn "${bin_name} tidak dimulai ulang"
      fi
    fi
  else
    log error "gunzip not found" 
  fi
}

cgroup_limit() {
  [ "${cgroup_memory_limit}" = "" ] && return
  [ "${cgroup_memory_path}" = "" ] \
  && cgroup_memory_path=$(mount | grep cgroup | ${busybox_path} awk '/memory/{print $3}' | head -1)

  mkdir -p "${cgroup_memory_path}/${bin_name}"
  echo $(cat ${pid_file}) > "${cgroup_memory_path}/${bin_name}/cgroup.procs" \
  && log info "${cgroup_memory_path}/${bin_name}/cgroup.procs"  
  echo "${cgroup_memory_limit}" > "${cgroup_memory_path}/${bin_name}/memory.limit_in_bytes" \
  && log info "${cgroup_memory_path}/${bin_name}/memory.limit_in_bytes"
}

update_dashboard() {
  file_dasboard="${data_dir}/dashboard.zip"
  rm -rf ${data_dir}/dashboard/dist
  /data/adb/magisk/busybox wget --no-check-certificate "https://github.com/haishanh/yacd/archive/refs/heads/gh-pages.zip" -O ${file_dasboard} 2>&1
  unzip -o  "${file_dasboard}" "yacd-gh-pages/*" -d ${data_dir}/dashboard >&2
  mv -f ${data_dir}/dashboard/yacd-gh-pages ${data_dir}/dashboard/dist
  rm -rf ${file_dasboard}
}

dnstt() {
  if [ -f "${bin_kernel}/dnstt" ] ; then
    chmod 0700 ${bin_kernel}/dnstt && chown 0:3005 ${bin_kernel}/dnstt
    if [ ${ns} != "" ] && [ ${key} != "" ] ; then
      nohup ${busybox_path} setuidgid 0:3005 ${bin_kernel}/dnstt -udp ${dns_for_dnstt}:53 -pubkey ${key} ${ns} 127.0.0.1:9553 > /dev/null 2>&1 &
      echo -n $! > ${data_dir}/run/dnstt.pid
      sleep 0.1
      [ $(pidof dnstt) ] \
      && log info "dnstt is enable." || log error "v2ray-dns The configuration is incorrect, the startup fails, and the following is the error"
    else
      log warn "v2ray-dns tidak aktif, (ns & (key) kosong" 
    fi
  else
    log error "kernel dnstt no found" 
  fi
}

run_base64() {
  if [ "$(cat ${data_dir}/sing-box/acc.txt 2>&1)" != "" ] ; then
    log info "$(cat ${data_dir}/sing-box/acc.txt 2>&1)"
    base64 ${data_dir}/sing-box/acc.txt > ${data_dir}/dashboard/dist/proxy.txt
    log info "ceks ${data_dir}/dashboard/dist/proxy.txt"
    log info "done"
  else
    log warn "${data_dir}/sing-box/acc.txt kosong"
    exit 1
  fi
}

case "$1" in
  subgeo)
    update_subgeo
    rm -rf "${data_dir}/${bin_name}/*.bak" && exit 1
    ;;
  port)
    port_detection
    ;;
  cgroup)
    cgroup_limit
    ;;
  upcore)
    update_kernel
    ;;
  upyacd)
    update_dashboard
    ;;
  v2raydns)
    dnstt
    ;;
  rbase64)
    run_base64
    ;;
  *)
    echo "$0:  usage:  $0 {rbase64|upyacd|v2raydns|upcore|cgroup|port|subgeo}"
    ;;
esac