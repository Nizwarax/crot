# Advanced Script Protector & Telegram Bot

Skrip ini memungkinkan Anda untuk melindungi skrip shell (`.sh`) dengan mengenkripsinya. Skrip yang dilindungi dapat dieksekusi secara normal tetapi kode sumbernya akan tersembunyi.

Selain itu, alat ini terintegrasi dengan Telegram Bot untuk mengotomatiskan proses enkripsi.

## Fitur

-   **Enkripsi Kuat**: Menggunakan `openssl` dengan AES-256 untuk mengenkripsi file.
-   **Anti-Debugging**: Skrip yang dilindungi memiliki mekanisme anti-debugging sederhana.
-   **Menu Interaktif**: Antarmuka menu yang mudah digunakan untuk mengenkripsi dan mendekripsi file.
-   **Integrasi Bot Telegram**: Otomatiskan enkripsi dengan mengirim file ke bot Telegram pribadi Anda.
-   **Pencadangan Otomatis**: Secara otomatis membuat cadangan file asli sebelum enkripsi.

## Perintah Sekali Jalan (Instalasi Cepat)

Perintah ini akan membuat semua skrip yang diperlukan dapat dieksekusi. Jalankan perintah ini sekali di terminal Anda:

```bash
chmod +x protector.sh telegram_bot.sh
```

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

### Langkah 2: Konfigurasi Bot

1.  Jalankan skrip utama:
    ```bash
    ./protector.sh
    ```
2.  Dari menu utama, pilih opsi **[4] Pengaturan Bot Telegram**.
3.  Masukkan **Token Bot** dan **User ID** yang Anda dapatkan dari Langkah 1.
4.  Pengaturan Anda akan disimpan di file `bot.conf`.

### Langkah 3: Jalankan Bot

1.  Jalankan kembali skrip utama jika Anda keluar:
    ```bash
    ./protector.sh
    ```
2.  Dari menu utama, pilih opsi **[5] Jalankan Bot Telegram**.
3.  Bot sekarang aktif dan akan mendengarkan file yang Anda kirim. Biarkan terminal ini tetap berjalan.

### Langkah 4: Gunakan Bot Anda

1.  Buka percakapan dengan bot Anda di Telegram.
2.  Kirim file skrip `.sh` apa pun yang ingin Anda enkripsi.
3.  Bot akan secara otomatis mengenkripsi file tersebut dan mengirimkannya kembali kepada Anda dengan **nama file yang sama persis**.

Untuk menghentikan bot, kembali ke terminal tempat bot berjalan dan tekan `CTRL + C`.
