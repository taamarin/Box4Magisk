#!/system/bin/sh

scripts=$(realpath $0)
scripts_dir=$(dirname ${scripts})
source /data/adb/box/settings.ini

restart_clash() {
  ${scripts_dir}/box.service start
  sleep 0.5
  ${scripts_dir}/box.iptables enable
  if [ "$?" == "0" ] ; then
    log info "$(date) ${bin_name} restart"
  else
    log error "${bin_name} failed to restart."
  fi
}

update_file() {
  file="$1"
  file_bak="${file}.bak"
  update_url="$2"
  if [ -f ${file} ] ; then
    mv -f ${file} ${file_bak}
  fi
  echo "curl -k --insecure -L -A 'clash' ${update_url} -o ${file}"
  curl -k --insecure -L -A 'clash' ${update_url} -o ${file} 2>&1
  sleep 0.5
  if [ -f "${file}" ] ; then
    echo ""
  else
    if [ -f "${file_bak}" ] ; then
    mv ${file_bak} ${file}
    fi
  fi
}

update_subgeo() {
  case "${bin_name}" in
    clash)
      geoip_file="${data_dir}/clash/Country.mmdb"
      geoip_url="https://github.com/Loyalsoldier/geoip/raw/release/Country-only-cn-private.mmdb"
      # geoip_url="https://github.com/v2fly/geoip/raw/release/geoip-only-cn-private.dat"
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

  if [ "${auto_updategeox}" == "true" ] ; then
    if update_file ${geoip_file} ${geoip_url} && update_file ${geosite_file} ${geosite_url} ; then
      flag=false
    fi
  fi
  if [ ${auto_updatesubcript} == "true" ] ; then
    if update_file ${clash_config} ${subcript_url} ; then
      flag=true
    fi
  fi
  if [ -f "${pid_file}" ] && [ ${flag} == true ] ; then
    restart_clash
  fi
}

port_detection() {
  logs() {
    export TZ=Asia/Jakarta
    now=$(date +"[%H:%M %z]")
    case $1 in
    info)
      [ -t 1 ] && echo -n "\033[1;33m${now} [info]: $2\033[0m" || echo -n "${now} [info]: $2" | tee -a ${logs_file}
      ;;
    *)
      [ -t 1 ] && echo -n "\033[1;30m${now} [$1]: $2\033[0m" || echo -n "${now} [$1]: $2" | tee -a ${logs_file}
      ;;
    esac
  }
  match_count=0
  if (ss -h > /dev/null 2>&1) ; then
    port=$(ss -antup | grep "${bin_name}" | ${busybox_path} awk '$7~/'pid=$(pidof ${bix_bin_name})*'/{print $5}' | ${busybox_path} awk -F ':' '{print $2}' | sort -u)
  else
    log info "skip!!! port detected"
    exit 0
  fi
  logs info "port detected: "
  for sub_port in ${port[@]} ; do
    sleep 0.5
    echo -n "${sub_port} " >> ${logs_file}
  done
  echo "" >> ${logs_file}
}

update_kernel() {
  arch="arm64"
  platform="android"
  file_kernel="clash.${arch}"
  tag="Prerelease-Alpha"
  tag_name="alpha-[0-9,a-z]+"
  url_meta="https://github.com/MetaCubeX/Clash.Meta/releases"

  tag_meta=$(curl -fsSL ${url_meta}/expanded_assets/${tag} | grep -oE "${tag_name}" | head -1)
  filename="Clash.Meta-${platform}-${arch}-${tag_meta}"
  if update_file ${data_dir}/${file_kernel}.gz ${url_meta}/download/${tag}/${filename}.gz; then
    flag="true"
  fi

  if [ "${flag}" == "true" ] ; then
    if (gunzip --help > /dev/null 2>&1) ; then
      if ! (gunzip ${data_dir}/${file_kernel}.gz) ; then
        if ! (rm -rf ${data_dir}/${file_kernel}.gz.bak) ; then
          rm -rf ${data_dir}/${file_kernel}.gz
        fi
        log warn "gunzip ${file_kernel}.gz failed" 
      else
        mv -f ${data_dir}/${file_kernel} ${data_dir}/kernel/clash && flag="true"
        if [ -f "${pid_file}" ] && [ "${flag}" == "true" ] ; then
          restart_clash
        else
          log warn "${bin_name} tidak dimulai ulang"
        fi
      fi
    else
      log error "gunzip not found" 
    fi
  else
    log warn "download ${file_kernel}.gz failed" 
  fi
}

cgroup_limit() {
  if [ "${cgroup_memory_limit}" == "" ] ; then
    return
  fi
  if [ "${cgroup_memory_path}" == "" ] ; then
    cgroup_memory_path=$(mount | grep cgroup | ${busybox_path} awk '/memory/{print $3}' | head -1)
  fi

  mkdir -p "${cgroup_memory_path}/${bin_name}"
  echo $(cat ${pid_file}) > "${cgroup_memory_path}/${bin_name}/cgroup.procs" \
  && log info "${cgroup_memory_path}/${bin_name}/cgroup.procs"  
  echo "${cgroup_memory_limit}" > "${cgroup_memory_path}/${bin_name}/memory.limit_in_bytes" \
  && log info "${cgroup_memory_path}/${bin_name}/memory.limit_in_bytes"
}

update_dashboard() {
  file_dasboard="${data_dir}/dashboard.zip"
  rm -rf ${data_dir}/dashboard/dist
  curl -L -A 'clash' "https://github.com/taamarin/yacd/archive/refs/heads/gh-pages.zip" -o ${file_dasboard} 2>&1
  unzip -o  "${file_dasboard}" "yacd-gh-pages/*" -d ${data_dir}/dashboard >&2
  mv -f ${data_dir}/dashboard/yacd-gh-pages ${data_dir}/dashboard/dist 
  rm -rf ${file_dasboard}
}

case "$1" in
  subgeo)
    update_subgeo
    rm -rf ${data_dir}/${bin_name}/*.bak && exit 1
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
  *)
    echo "$0:  usage:  $0 {upyacd|upcore|cgroup|port|subgeo}"
    ;;
esac