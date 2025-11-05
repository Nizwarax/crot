#!/bin/bash

#=====================#
#    ENCSSL INSTALLER   #
#=====================#

# --- KONFIGURASI ---
REPO_URL="https://raw.githubusercontent.com/Nizwarax/crot/main"  # ← TANPA SPASI DI AKHIR!
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
if ! mkdir -p "$INSTALL_DIR"; then
    echo -e "$eror Gagal membuat direktori instalasi. Periksa izin $HOME Anda."
    exit 1
fi

# --- LANGKAH 3: UNDUH & VERIFIKASI SKRIP ---

download_and_verify() {
    local url="$1"
    local dest="$2"
    local filename=$(basename "$dest")

    echo -e "$info Mengunduh ${W}$filename${N}..."
    if ! curl -fL -s -o "$dest" "$url"; then
        echo -e "$eror Gagal mengunduh ${W}$filename${N}."
        echo -e "$eror Periksa koneksi internet atau URL: ${C}$url${N}"
        exit 1
    fi

    if [ ! -s "$dest" ]; then
        echo -e "$eror File ${W}$filename${N} kosong. Unduhan gagal."
        rm -f "$dest"
        exit 1
    fi

    if grep -q "<!DOCTYPE html>" "$dest" 2>/dev/null; then
        echo -e "$eror File ${W}$filename${N} adalah halaman HTML (mungkin 404)."
        echo -e "$eror Pastikan file 'protector.sh' ada di repositori GitHub Anda."
        rm -f "$dest"
        exit 1
    fi
}

echo -e "$info Mengunduh skrip utama..."
download_and_verify "$REPO_URL/protector.sh" "$INSTALL_DIR/protector.sh"

echo -e "$sukses Skrip berhasil diunduh dan diverifikasi."

# --- LANGKAH 4: BUAT SKRIP DAPAT DIEKSEKUSI ---
echo -e "$info Mengatur izin eksekusi..."
if ! chmod +x "$INSTALL_DIR/protector.sh"; then
    echo -e "$eror Gagal memberi izin eksekusi pada skrip."
    exit 1
fi
echo -e "$sukses Izin eksekusi berhasil diatur."

# --- LANGKAH 5: BUAT PERINTAH GLOBAL (SYMLINK) ---
echo -e "$info Membuat perintah global '${W}$CMD_NAME${N}' di ${W}$CMD_PATH${N}..."

# ✅ Pastikan file target benar-benar ada sebelum membuat symlink
if [ ! -f "$INSTALL_DIR/protector.sh" ]; then
    echo -e "$eror Fatal: File target tidak ditemukan setelah unduhan."
    echo -e "$eror Ini seharusnya tidak terjadi — periksa log sebelumnya."
    exit 1
fi

# Hapus symlink lama jika ada
if [ -L "$CMD_PATH" ]; then
    echo -e "$info Menghapus symlink lama..."
    sudo rm -f "$CMD_PATH"
elif [ -e "$CMD_PATH" ]; then
    echo -e "$eror File atau direktori lain sudah ada di ${W}$CMD_PATH${N}."
    echo -e "$eror Harap hapus manual atau pindahkan dulu, lalu jalankan ulang installer."
    exit 1
fi

# Buat symlink baru
echo -e "$info Membuat symlink (memerlukan sudo)..."
if sudo ln -sf "$INSTALL_DIR/protector.sh" "$CMD_PATH"; then
    echo -e "$sukses Perintah '${W}$CMD_NAME${N}' berhasil dibuat."
else
    echo -e "$eror Gagal membuat symlink di ${W}$CMD_PATH${N}."
    echo -e "$eror Pastikan:"
    echo -e "  - Anda memiliki akses sudo"
    echo -e "  - Direktori /usr/local/bin ada dan dapat ditulis"
    echo -e "  - Tidak ada konflik izin atau kebijakan keamanan (SELinux, dsb)"
    exit 1
fi

# --- SELESAI ---
echo -e "\n${Y}✅ Instalasi ENCSSL Selesai!${N}"
echo -e "Anda sekarang dapat menjalankan tool ini dari mana saja dengan perintah:"
echo -e "  ${G}$CMD_NAME${N}"
echo -e "\n${C}Tips:${N} Untuk memperbarui di masa depan, jalankan installer ini lagi."
