box_data_dir="data/adb/box"

rm_data() {
    rm -rf ${box_data_dir}
    rm -rf /data/adb/service.d/box_service.sh
}

rm_data