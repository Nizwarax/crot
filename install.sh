#!/bin/bash

#=====================#
#    ENCSSL INSTALLER   #
#=====================#

# --- KONFIGURASI ---
REPO_URL="https://raw.githubusercontent.com/Nizwarax/crot/main"
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

# --- LANGKAH 1: PERIKSA DEPENDENSI ---
echo -e "$info Memeriksa dependensi yang diperlukan..."
if ! command -v curl &>/dev/null; then
    echo -e "$eror 'curl' tidak ditemukan. Ini diperlukan untuk mengunduh skrip."
    echo -e "$info Silakan install 'curl' menggunakan manajer paket Anda."
    exit 1
fi
echo -e "$sukses Semua dependensi terpenuhi."

# --- LANGKAH 2: BUAT DIREKTORI INSTALASI ---
echo -e "$info Membuat direktori instalasi di: ${W}$INSTALL_DIR${N}"
mkdir -p "$INSTALL_DIR"
if [ $? -ne 0 ]; then
    echo -e "$eror Gagal membuat direktori. Keluar."
    exit 1
fi

# --- LANGKAH 3: UNDUH & VERIFIKASI SKRIP ---

# Fungsi untuk mengunduh file dan memverifikasi itu bukan halaman kesalahan HTML
download_and_verify() {
    local url="$1"
    local dest="$2"
    local filename=$(basename "$dest")

    echo -e "$info Mengunduh ${W}$filename${N}..."
    # Gunakan -f untuk gagal pada kesalahan server, -L untuk mengikuti pengalihan
    curl -fL -s -o "$dest" "$url"

    if [ $? -ne 0 ]; then
        echo -e "$eror Gagal mengunduh ${W}$filename${N}."
        echo -e "$eror Periksa koneksi internet Anda atau URL repositori: ${C}$url${N}"
        exit 1
    fi

    # Verifikasi file bukan halaman HTML (kesalahan umum dengan URL GitHub mentah)
    if grep -q "<!DOCTYPE html>" "$dest"; then
        echo -e "$eror File yang diunduh ${W}$filename${N} tampaknya adalah halaman kesalahan HTML."
        echo -e "$eror Ini mungkin karena URL repositori salah atau GitHub membatasi permintaan."
        rm -f "$dest" # Hapus file yang rusak
        exit 1
    fi
}

echo -e "$info Mengunduh skrip yang diperlukan..."
download_and_verify "$REPO_URL/protector.sh" "$INSTALL_DIR/protector.sh"

echo -e "$sukses Skrip berhasil diunduh dan diverifikasi."

# --- LANGKAH 3: BUAT SKRIP DAPAT DIEKSEKUSI ---
echo -e "$info Membuat skrip dapat dieksekusi..."
chmod +x "$INSTALL_DIR/protector.sh"
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
