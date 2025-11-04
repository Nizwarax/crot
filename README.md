# Advanced Script Protector & Telegram Bot

## Instalasi

Cukup unduh dan jalankan skrip instalasi. Salin dan tempel perintah berikut ke terminal Anda:

**PENTING**: Ganti `<URL_RAW_ANDA>` dengan URL ke file mentah `install.sh` di repositori Anda.

```bash
curl -L -o install.sh https://raw.githubusercontent.com/Nizwarax/crot/main/install.sh && bash install.sh
```

Skrip instalasi akan secara otomatis:
1.  Mengunduh file yang diperlukan (`protector.sh` dan `telegram_bot.sh`) ke direktori `~/.encssl`.
2.  Membuatnya dapat dieksekusi.
3.  Membuat perintah global `encssl` sehingga Anda dapat menjalankannya dari mana saja.

Setelah instalasi selesai, Anda dapat menjalankan alat ini kapan saja dengan mengetik:
```bash
encssl
```

---

Skrip ini memungkinkan Anda untuk melindungi skrip shell (`.sh`) dengan mengenkripsinya. Skrip yang dilindungi dapat dieksekusi secara normal tetapi kode sumbernya akan tersembunyi.

Selain itu, alat ini terintegrasi dengan Telegram Bot untuk mengotomatiskan proses enkripsi.

## Fitur

-   **Enkripsi Kuat**: Menggunakan `openssl` dengan AES-256 untuk mengenkripsi file.
-   **Anti-Debugging**: Skrip yang dilindungi memiliki mekanisme anti-debugging sederhana.
-   **Menu Interaktif**: Antarmuka menu yang mudah digunakan untuk mengenkripsi dan mendekripsi file.
-   **Integrasi Bot Telegram**: Otomatiskan enkripsi dengan mengirim file ke bot Telegram pribadi Anda.
-   **Pencadangan Otomatis**: Secara otomatis membuat cadangan file asli sebelum enkripsi.

## Cara Menjalankan Bot Telegram

Berikut adalah cara menyiapkan dan menjalankan bot enkripsi Telegram dari awal hingga akhir.

### Langkah 1: Dapatkan Kredensial Bot Anda

1.  **Dapatkan Token Bot**:
    *   Buka Telegram dan cari **@BotFather**.
    *   Mulai percakapan dengannya dan kirim perintah `/newbot`.
    *   Ikuti petunjuknya untuk membuat bot baru.
    *   BotFather akan memberi Anda **Token API**. Salin token ini.

2.  **Dapatkan ID Pengguna Anda**:
    *   Cari **@userinfobot** di Telegram.
    *   Mulai percakapan dengannya dan bot akan memberi Anda **User ID** Anda. Salin ID ini.

### Langkah 2: Konfigurasi & Jalankan Bot

1.  Jalankan perintah `encssl` di terminal Anda:
    ```bash
    encssl
    ```
2.  Dari menu utama, pilih opsi **[4] Konfigurasi & Jalankan Bot Telegram**.
3.  **Jika ini adalah pertama kalinya**, Anda akan diminta untuk memasukkan **Token Bot** dan **User ID** Anda. Masukkan kredensial yang Anda dapatkan dari Langkah 1.
4.  Setelah konfigurasi disimpan, bot akan **berjalan secara otomatis**. Biarkan terminal ini tetap berjalan agar bot tetap aktif.

### Langkah 3: Gunakan Bot Anda

1.  Buka percakapan dengan bot Anda di Telegram (atau ketik `/start` jika sudah terbuka).
2.  Bot akan menyapa Anda dengan tombol **"Enkripsi"** dan **"Dekripsi"**.
3.  Tekan salah satu tombol, lalu kirim file yang ingin Anda proses.
4.  Bot akan secara otomatis memproses file Anda dan mengirimkannya kembali.

Untuk menghentikan bot, kembali ke terminal tempat bot berjalan dan tekan `CTRL + C`.
