#!/bin/bash

#=====================#
#    ENCSSL INSTALLER   #
#=====================#

# --- KONFIGURASI ---
# PENTING: Ganti URL_RAW_ANDA dengan URL mentah ke file di repositori Anda.
REPO_URL="<URL_RAW_ANDA>"
INSTALL_DIR="$HOME/.encssl"
CMD_NAME="encssl"
CMD_PATH="/usr/local/bin/$CMD_NAME"

# --- WARNA & SIMBOL ---
N='\033[0m'; W='\033[1;37m'; R='\033[1;31m';
G='\033[1;32m'; Y='\033[1;33m'; C='\033[1;36m';
sukses="${G}[${W}√${G}]${N}"
eror="${R}[${W}!${R}]${N}"
info="${C}[${W}i${C}]${N}"

echo -e "$info Memulai instalasi ENCSSL..."

# --- LANGKAH 1: BUAT DIREKTORI INSTALASI ---
echo -e "$info Membuat direktori instalasi di: ${W}$INSTALL_DIR${N}"
mkdir -p "$INSTALL_DIR"
if [ $? -ne 0 ]; then
    echo -e "$eror Gagal membuat direktori. Keluar."
    exit 1
fi

# --- LANGKAH 2: UNDUH SKRIP ---
echo -e "$info Mengunduh skrip yang diperlukan..."
curl -L -s -o "$INSTALL_DIR/protector.sh" "$REPO_URL/protector.sh"
if [ $? -ne 0 ]; then
    echo -e "$eror Gagal mengunduh protector.sh. Periksa URL Anda."
    exit 1
fi

curl -L -s -o "$INSTALL_DIR/telegram_bot.sh" "$REPO_URL/telegram_bot.sh"
if [ $? -ne 0 ]; then
    echo -e "$eror Gagal mengunduh telegram_bot.sh. Periksa URL Anda."
    exit 1
fi

echo -e "$sukses Skrip berhasil diunduh."

# --- LANGKAH 3: BUAT SKRIP DAPAT DIEKSEKUSI ---
echo -e "$info Membuat skrip dapat dieksekusi..."
chmod +x "$INSTALL_DIR/protector.sh"
chmod +x "$INSTALL_DIR/telegram_bot.sh"
echo -e "$sukses Izin berhasil diatur."

# --- LANGKAH 4: BUAT PERINTAH GLOBAL ---
echo -e "$info Membuat perintah global '${W}$CMD_NAME${N}'..."
echo -e "Ini memerlukan hak akses superuser (sudo) untuk membuat symlink di ${W}$CMD_PATH${N}."
if [ -L "$CMD_PATH" ]; then
    echo -e "$info Menghapus symlink lama..."
    sudo rm "$CMD_PATH"
fi

sudo ln -s "$INSTALL_DIR/protector.sh" "$CMD_PATH"
if [ $? -eq 0 ]; then
    echo -e "$sukses Perintah '${W}$CMD_NAME${N}' berhasil dibuat."
else
    echo -e "$eror Gagal membuat symlink. Coba jalankan skrip ini dengan 'sudo bash install.sh'."
    exit 1
fi

# --- SELESAI ---
echo -e "\n${Y}Instalasi Selesai!${N}"
echo -e "Anda sekarang dapat menjalankan menu dari mana saja dengan mengetik:"
echo -e "  ${G}$CMD_NAME${N}"
echo -e "Untuk mengonfigurasi bot Anda, jalankan '${G}$CMD_NAME${N}' dan pilih 'Pengaturan Bot Telegram'."
