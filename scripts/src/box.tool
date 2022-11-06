#!/system/bin/sh

scripts=$(realpath $0)
scripts_dir=$(dirname ${scripts})

source /data/adb/box/settings.ini

logs() {
  export TZ=Asia/Jakarta
  echo -n "$(date '+%H:%M %z') $*" | tee -a ${logs_file} > /dev/null 2>&1
}

restart_clash() {
  ${scripts_dir}/box.service start
  sleep 0.75
  ${scripts_dir}/box.iptables enable
  if [ "$?" == "0" ]; then
    log "[info]: `date` ${bin_name} restart" >>${logs_file}
  else
    log "[error]: ${bin_name} failed to restart." >>${logs_file}
  fi
}

update_file() {
  file="$1"
  file_bak="${file}.bak"
  update_url="$2"
  if [ -f ${file} ]; then
    mv -f ${file} ${file_bak}
  fi
  echo "curl -k --insecure -L -A 'clash' ${update_url} -o ${file}"
  curl -k --insecure -L -A 'clash' ${update_url} -o ${file} 2>&1
  sleep 0.5
  if [ -f "${file}" ]; then
    echo ""
  else
    if [ -f "${file_bak}" ]; then
    mv ${file_bak} ${file}
    fi
  fi
}

auto_update() {
  if [ "${auto_updategeox}" == "true" ]; then
   update_file ${geoip_file} ${geoip_url}
   if [ "$?" = "0" ]; then
    flag=false
   fi
  fi

  if [ "${auto_updategeox}" == "true" ]; then
   update_file ${geosite_file} ${geosite_url}
   if [ "$?" = "0" ]; then
    flag=false
   fi
  fi

  if [ ${auto_updatesubcript} == "true" ]; then
   update_file ${config_file} ${subcript_url}
   if [ "$?" = "0" ]; then
    flag=true
   fi
  fi

  if [ -f "${pid_file}" ] && [ ${flag} == true ]; then
  restart_clash
  fi
}

port_detection() {
  match_count=0
  if (ss -h > /dev/null 2>&1); then
    port=$(ss -antup | grep "$bin_name" | ${busybox_path} awk '$7~/'pid=$(pidof ${bix_bin_name})*'/{print $5}' | ${busybox_path} awk -F ':' '{print $2}' | sort -u)
  else
    log "[info]: skip port detected"
    exit 0
  fi
  logs "[info]: port detected: "
  for sub_port in ${port[@]} ; do
    sleep 0.5
    echo -n "${sub_port} / " >> ${logs_file}
  done
  echo "" >> ${logs_file}
}

update_kernel() {
  arch="arm64"
  platform="android"
  file_kernel="clash.${arch}"
  tag="Prerelease-alpha-next"
  tag_name="alpha-next-[0-9,a-z]+"
  url_meta="https://github.com/taamarin/Clash.Meta/releases"

  tag_meta=$(curl -fsSL ${url_meta}/expanded_assets/${tag} | grep -oE "${tag_name}" | head -1)
  filename="Clash.Meta-${platform}-${arch}-${tag_meta}"
  update_file ${data_dir}/${file_kernel}.gz ${url_meta}/download/${tag}/${filename}.gz
  if [ "$?" = "0" ]; then
    flag=false
  fi
  if [ ${flag} == false ]; then
    if (gunzip --help > /dev/null 2>&1); then
        if ! (gunzip ${data_dir}/"${file_kernel}".gz); then
          if ! (rm -rf ${data_dir}/"${file_kernel}".gz.bak); then
            rm -rf ${data_dir}/"${file_kernel}".gz
          fi
          log "[warning]: gunzip ${file_kernel}.gz failed" 
        fi
    else
      log "[error]: gunzip not found" 
    fi
  else
    log "[warning]: download ${file_kernel}.gz failed" 
  fi

  mv -f ${data_dir}/"${file_kernel}" ${data_dir}/kernel/clash
  if [ "$?" = "0" ]; then
    flag=true
  fi
  if [ -f "${pid_file}" ] && [ ${flag} == true ]; then
    restart_clash
  else
    log "[warning]: ${bin_name} tidak dimulai ulang"
  fi
}

cgroup_limit() {
  if [ "${cgroup_memory_limit}" == "" ]; then
    return
  fi
  if [ "${cgroup_memory_path}" == "" ]; then
    cgroup_memory_path=$(mount | grep cgroup | ${busybox_path} awk '/memory/{print $3}' | head -1)
  fi

  mkdir -p "${cgroup_memory_path}/${bin_name}"
  echo $(cat ${pid_file}) > "${cgroup_memory_path}/${bin_name}/cgroup.procs" \
  && log "[info]: ${cgroup_memory_path}/${bin_name}/cgroup.procs"  
  echo "${cgroup_memory_limit}" > "${cgroup_memory_path}/${bin_name}/memory.limit_in_bytes" \
  && log "[info]: ${cgroup_memory_path}/${bin_name}/memory.limit_in_bytes"
}

up_dashboard() {
  url_dashboard="https://github.com/taamarin/yacd/archive/refs/heads/gh-pages.zip"
  file_dasboard="${data_dir}/dashboard.zip"
  rm -rf ${data_dir}/dashboard/dist
  curl -L -A 'clash' ${url_dashboard} -o ${file_dasboard} 2>&1
  unzip -o  "${file_dasboard}" "yacd-gh-pages/*" -d ${data_dir}/dashboard >&2
  mv -f ${data_dir}/dashboard/yacd-gh-pages ${data_dir}/dashboard/dist 
  rm -rf ${file_dasboard}
}

case "$1" in
  subgeo)
    auto_update
    rm -rf ${data_dir}/${bin_name}/*.bak
    exit 1
    ;;
  detec)
    port_detection
    ;;
  cgroup)
    cgroup_limit
    ;;
  upcore)
    update_kernel
    ;;
  upyacd)
    up_dashboard
    ;;
  *)
    echo "$0:  usage:  $0 {upyacd|upcore|cgroup|detec|subgeo}"
    ;;
esac