# Box for Magisk

[STEP install](install.md)

[![ANDROID](https://img.shields.io/badge/Android-3DDC84?style=for-the-badge&logo=android&logoColor=white)]()

A fork of [CHIZI-0618/box4magisk](https://github.com/CHIZI-0618/box4magisk)

Proyek ini adalah modul [Magisk](https://github.com/topjohnwu/Magisk) dari clash, sing-box, v2ray, xray. Mendukung REDIRECT (khusus TCP), proxy transparan TPROXY (TCP + UDP), mendukung proxy mode campuran TUN (TCP + UDP), dan REDIRECT (TCP) + TUN (UDP).

## penafian

Proyek ini tidak bertanggung jawab atas: perangkat rusak, kartu SD rusak, atau SoC terbakar.

**Pastikan file konfigurasi Anda tidak menyebabkan traffic loopback, jika tidak maka dapat menyebabkan ponsel Anda restart tanpa batas.**

Jika Anda benar-benar tidak tahu cara mengonfigurasi modul ini, Anda mungkin memerlukan aplikasi seperti ClashForAndroid, v2rayNG, papan selancar, SagerNet, AnXray, dll.


## install

- Download paket zip modul dari [RELEASE](https://github.com/taamarin/Box4Magisk/releases) dan install melalui [MAGISK](https://github.com/topjohnwu/Magisk)

- Mendukung pembaruan modul online berikutnya di Magisk Manager (memperbarui modul akan berlaku tanpa memulai ulang)

### Notes
modul tidak berisi [clash](https://github.com/Dreamacro/clash)、[clash.meta](https://github.com/MetaCubeX/Clash.Meta)、[sing-box](https://github.com/SagerNet/sing-box)、[v2ray-core](https://github.com/v2fly/v2ray-core)、[Xray-core](https://github.com/XTLS/Xray-core) dan file binery lainnya.
  
Setelah modul terinstall, unduh file inti dari arsitektur perangkat Anda yang sesuai dan letakkan di direktori `/data/adb/box/bin/`, atau executed

```shell
su -c /data/adb/box/scripts/box.tool upcore
```


## konfigurasi

- Setiap inti bekerja di direktori `/data/adb/box/bin/${bin_name}`, nama inti ditentukan oleh `bin_name` di file `/data/adb/box/settings.ini` [line 11](https://github.com/taamarin/Box4Magisk/blob/master/scripts/settings.ini#L11), `clash`, `xray`, `v2ray`, `sing-box`, `bin_name` **menentukan inti yang diaktifkan oleh modul**

- Setiap file konfigurasi inti perlu disesuaikan oleh pengguna, dan skrip akan memeriksa validitas konfigurasi, dan hasil pemeriksaan akan disimpan dalam file `/data/adb/box/run/runs.log`

- Tip: `clash` dan `sing-box` hadir dengan konfigurasi default yang siap bekerja dengan skrip proxy transparan. Untuk konfigurasi lebih lanjut, lihat dokumentasi resmi terkait. Alamat: [dokumen clash](https://github.com/Dreamacro/clash/wiki/configuration), [dokumen sing-box](https://sing-box.sagernet.org/configuration/outbound/)


## Instruksi

### Metode konvensional (metode standar & yang disarankan)

#### Memulai dan menghentikan layanan manajemen

**Layanan inti berikut secara kolektif disebut sebagai Kotak**
- Layanan Box akan berjalan secara otomatis setelah boot sistem secara default
- Anda dapat mengaktifkan atau menonaktifkan modul melalui aplikasi Magisk Manager **secara real time** memulai atau menghentikan layanan `box`, **tidak perlu memulai ulang perangkat**. Memulai layanan mungkin memerlukan waktu beberapa detik, menghentikan layanan dapat langsung berlaku

#### Pilih aplikasi (APP) yang membutuhkan proxy

- Box default untuk memproksi semua aplikasi (APP) untuk semua pengguna Android
- Jika Anda ingin `box` mem-proxy semua aplikasi (APP), kecuali beberapa aplikasi tertentu, silakan buka file `/data/adb/box/settings.ini` [line 21-22](https://github.com/taamarin/Box4Magisk/blob/master/scripts/settings.ini#L21-L22) dan ubah nilai `proxy_mode` menjadi `blacklist` (default), tambahkan package ke `packages_list` [line 26-27](https://github.com/taamarin/Box4Magisk/blob/master/scripts/settings.ini#26-27), contoh: `packages_list=("com.termux" "org.telegram.messenger")`

- Ketika nilai `proxy_mode` [line 21](https://github.com/taamarin/Box4Magisk/blob/master/scripts/settings.ini#L21) adalah `core`, proxy transparan tidak akan berfungsi, hanya kernel yang sesuai yang akan dimulai, yang dapat digunakan untuk mendukung TUN

### penggunaan tingkat lanjut

#### mengubah mode proxy

- Box menggunakan TPROXY untuk mem-proxy TCP + UDP secara transparan secara default. Jika mendeteksi bahwa perangkat tidak mendukung TPROXY, Box akan secara otomatis menggunakan REDIRECT ke hanya proxy TCP

- Buka file `/data/adb/box/settings.ini`, ubah nilai `network_mode` [line 19](https://github.com/taamarin/Box4Magisk/blob/master/scripts/settings.ini#L19) menjadi `REDIRECT` atau `MIXED` untuk menggunakan REDIRECT proxy TCP, yang tidak diaktifkan di kernel Box (hanya `sing-box` dan `clash` mendukung TUN) dan UDP akan di proxy TUN

#### Lewati proxy transparan saat menghubungkan ke Wi-Fi atau hotspot

- Box secara transparan memproksi `localhost` dan `hotspot` (termasuk tethering USB) secara default

- Buka file `/data/adb/box/settings.ini`, ubah `ignore_out_list` dan tambahkan elemen `wlan+`, kemudian proxy transparan mem-bypass WLAN, dan hotspot tidak terhubung dengan proxy

- Buka file `/data/adb/box/settings.ini`, ubah `ap_list` dan hapus elemen `wlan+` box akan memproxy hotspot (model MediaTek mungkin `ap+` alih-alih `wlan+`)

#### masuk ke mode manual

Jika Anda ingin mengontrol Box sepenuhnya dengan menjalankan perintah, buat saja file baru `/data/adb/box/manual`. Dalam hal ini, layanan Box tidak akan **mulai otomatis** saat perangkat Anda dinyalakan, Anda juga tidak dapat mengatur mulai atau berhentinya layanan melalui aplikasi Magisk Manager.

##### Memulai dan menghentikan layanan manajemen

- Skrip layanan Box adalah `/data/adb/box/scripts/box.service`

- Misalnya, dalam lingkungan pengujian (versi Magisk: 25200)

  - Mulai Box:

    `/data/adb/box/scripts/box.service start`

  - Stop Box:

    `/data/adb/box/scripts/box.service stop`

    Terminal akan mencetak log dan mengeluarkannya ke file log secara bersamaan

##### Kelola apakah proxy transparan diaktifkan

- Skrip proxy transparan adalah `/data/adb/box/scripts/box.tproxy`

- Misalnya, dalam lingkungan pengujian (versi Magisk: 25200)

  - Aktifkan proxy transparan:

    `/data/adb/box/scripts/box.tproxy enable`

  - Nonaktifkan proxy transparan:

    `/data/adb/box/scripts/box.tproxy disable`

## instruksi lainnya

- Saat memodifikasi setiap file konfigurasi inti, harap pastikan bahwa konfigurasi yang terkait dengan `tprxoy` konsisten dengan definisi di file `/data/adb/box/settings.ini`

- Jika mesin memiliki alamat **IP publik**, tambahkan IP ke larik `intranet` di file `/data/adb/box/settings.ini` untuk mencegah traffic loop

- Log untuk layanan Box ada di direktori `/data/adb/box/run`


## uninstall

- Menghapus installan modul ini dari aplikasi Magisk Manager akan menghapus `/data/adb/service.d/box4magisk_service.sh` dan menyimpan direktori data Box `/data/adb/box`
- Anda dapat menggunakan perintah untuk menghapus data Box: `rm -rf /data/adb/box`

## memperbarui log

[CHANGELOG](CHANGELOG.md)
