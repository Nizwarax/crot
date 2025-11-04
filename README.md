# Advanced Script Protector

## Instalasi

Cukup unduh dan jalankan skrip instalasi. Salin dan tempel perintah berikut ke terminal Anda:

```bash
curl -L -o install.sh https://raw.githubusercontent.com/Nizwarax/crot/main/install.sh && bash install.sh
```

Skrip instalasi akan secara otomatis:
1.  Mengunduh file yang diperlukan (`protector.sh`) ke direktori `~/.encssl`.
2.  Membuatnya dapat dieksekusi.
3.  Membuat perintah global `encssl` sehingga Anda dapat menjalankannya dari mana saja.

Setelah instalasi selesai, Anda dapat menjalankan alat ini kapan saja dengan mengetik:
```bash
encssl
```

---

Skrip ini memungkinkan Anda untuk melindungi skrip shell (`.sh`) dengan mengenkripsinya. Skrip yang dilindungi dapat dieksekusi secara normal tetapi kode sumbernya akan tersembunyi.

## Fitur

-   **Enkripsi Kuat**: Menggunakan `openssl` dengan AES-256 untuk mengenkripsi file.
-   **Anti-Debugging**: Skrip yang dilindungi memiliki mekanisme anti-debugging sederhana.
-   **Menu Interaktif**: Antarmuka menu yang mudah digunakan untuk mengenkripsi dan mendekripsi file.
-   **Pencadangan Otomatis**: Secara otomatis membuat cadangan file asli sebelum enkripsi.

---

## Pemecahan Masalah

**Masalah**: Anda melihat `command not found` atau `syntax error` saat menjalankan menu `encssl`.

**Penyebab**: Ini paling sering terjadi ketika file skrip tidak diunduh dengan benar selama instalasi. GitHub terkadang dapat membatasi permintaan, yang menyebabkan installer mengunduh halaman kesalahan HTML alih-alih file skrip Bash yang sebenarnya.

**Solusi**:
1.  **Jalankan Ulang Installer**: Cukup jalankan kembali perintah instalasi. Skrip ini dirancang agar aman untuk dijalankan kembali. Ini akan menimpa file yang rusak dan mencoba mengunduh ulang.
    ```bash
    curl -L -o install.sh https://raw.githubusercontent.com/Nizwarax/crot/main/install.sh && bash install.sh
    ```
2.  **Periksa Koneksi Anda**: Pastikan Anda memiliki koneksi internet yang stabil.
