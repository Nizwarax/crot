#!/bin/bash

#============================#
#    TELEGRAM ENCRYPTION BOT   #
#============================#

# --- WARNA & SIMBOL ---
N='\033[0m'; W='\033[1;37m'; R='\033[1;31m';
G='\033[1;32m'; Y='\033[1;33m'; C='\033[1;36m';
sukses="${G}[${W}√${G}]${N}"
eror="${R}[${W}!${R}]${N}"
info="${C}[${W}i${C}]${N}"

# --- KONFIGURASI ---
CONFIG_FILE="bot.conf"
if [ ! -f "$CONFIG_FILE" ]; then
    echo -e "$eror File konfigurasi '$CONFIG_FILE' tidak ditemukan. Jalankan dari menu 'Pengaturan Bot' di protector.sh."
    exit 1
fi
source "$CONFIG_FILE"

# --- VARIABEL API ---
API_URL="https://api.telegram.org/bot$BOT_TOKEN"
LAST_UPDATE_ID=0

# --- FUNGSI BOT ---

# Fungsi untuk mengirim pesan teks
send_message() {
    local chat_id="$1"
    local text="$2"
    curl -s -X POST "$API_URL/sendMessage" -d "chat_id=$chat_id" -d "text=$text" > /dev/null
}

# Fungsi untuk mengirim file
send_file() {
    local chat_id="$1"
    local file_path="$2"
    local file_name=$(basename "$file_path")

    curl -s -F "chat_id=$chat_id" -F "document=@$file_path;filename=$file_name" "$API_URL/sendDocument" > /dev/null
}

# Fungsi untuk mengunduh file
download_file() {
    local file_id="$1"
    local file_name="$2"

    # Dapatkan path file dari Telegram
    local file_path_json=$(curl -s "$API_URL/getFile?file_id=$file_id")
    local file_path=$(echo "$file_path_json" | grep -o '"file_path":"[^"]*' | cut -d'"' -f4)

    if [ -z "$file_path" ]; then
        echo -e "$eror Gagal mendapatkan path file."
        return 1
    fi

    # Unduh file
    local download_url="https://api.telegram.org/file/bot$BOT_TOKEN/$file_path"
    curl -s -o "$file_name" "$download_url"
    echo "$file_name"
}

# Fungsi utama untuk memproses pembaruan
process_updates() {
    local response=$(curl -s "$API_URL/getUpdates?offset=$((LAST_UPDATE_ID + 1))&timeout=30")
    local updates=$(echo "$response" | grep -o '{"update_id":[0-9]*,"message":{"message_id":[0-9]*,"from":{"id":[0-9]*,"is_bot":false,"first_name":"[^"]*","username":"[^"]*"},"chat":{"id":[0-9]*,"first_name":"[^"]*","username":"[^"]*","type":"private"},"date":[0-9]*,"document":{"file_name":"[^"]*","mime_type":"[^"]*","file_id":"[^"]*","file_unique_id":"[^"]*","file_size":[0-9]*}}}')

    if [ -z "$updates" ]; then
        return
    fi

    echo "$updates" | while read -r update; do
        # Ekstrak informasi penting
        local update_id=$(echo "$update" | grep -o '"update_id":[0-9]*' | cut -d':' -f2)
        local chat_id=$(echo "$update" | grep -o '"chat":{"id":[0-9]*' | cut -d':' -f2 | cut -d',' -f1)
        local from_id=$(echo "$update" | grep -o '"from":{"id":[0-9]*' | cut -d':' -f2 | cut -d',' -f1)
        local file_id=$(echo "$update" | grep -o '"file_id":"[^"]*' | cut -d'"' -f3)
        local file_name=$(echo "$update" | grep -o '"file_name":"[^"]*' | cut -d'"' -f3)

        # Update ID terakhir
        LAST_UPDATE_ID=$update_id

        # Periksa apakah pengguna diizinkan
        if [ "$from_id" != "$USER_ID" ]; then
            echo -e "$eror Pengguna tidak diizinkan: $from_id"
            send_message "$chat_id" "Anda tidak diizinkan menggunakan bot ini."
            continue
        fi

        echo -e "$info Menerima file: ${W}$file_name${N} dari user: ${W}$from_id${N}"
        send_message "$chat_id" "File '$file_name' diterima, sedang diproses..."

        # Unduh file
        local downloaded_file=$(download_file "$file_id" "$file_name")
        if [ $? -ne 0 ] || [ ! -f "$downloaded_file" ]; then
            echo -e "$eror Gagal mengunduh file."
            send_message "$chat_id" "Maaf, terjadi kesalahan saat mengunduh file."
            continue
        fi

        # Enkripsi file menggunakan protector.sh
        ./protector.sh "$downloaded_file"
        if [ $? -ne 0 ]; then
            echo -e "$eror Gagal mengenkripsi file."
            send_message "$chat_id" "Maaf, terjadi kesalahan saat mengenkripsi file."
            rm -f "$downloaded_file"
            continue
        fi

        echo -e "$sukses File ${W}$downloaded_file${N} berhasil dienkripsi."
        send_message "$chat_id" "File Anda berhasil dienkripsi. Mengirim kembali..."

        # Kirim file yang sudah dienkripsi
        send_file "$chat_id" "$downloaded_file"

        # Hapus file lokal
        rm -f "$downloaded_file"
        echo -e "$info File lokal ${W}$downloaded_file${N} dihapus."
    done
}


# --- LOOP UTAMA ---
echo -e "${G}Bot enkripsi Telegram dimulai... Tekan [CTRL+C] untuk berhenti.${N}"
while true; do
    process_updates
    sleep 1
done
