#!/bin/bash

#============================#
#    TELEGRAM ENCRYPTION BOT   #
#============================#

# --- WARNA & SIMBOL (untuk logging) ---
N='\033[0m'; W='\033[1;37m'; R='\033[1;31m';
G='\033[1;32m'; Y='\033[1;33m'; C='\033[1;36m';
sukses="${G}[${W}√${G}]${N}"
eror="${R}[${W}!${R}]${N}"
info="${C}[${W}i${C}]${N}"

# --- KONFIGURASI ---
SCRIPT_DIR=$(dirname "$(realpath "$0")")
CONFIG_FILE="$SCRIPT_DIR/bot.conf"
PROTECTOR_SCRIPT="$SCRIPT_DIR/protector.sh"

if [ ! -f "$CONFIG_FILE" ]; then
    echo -e "$eror File konfigurasi '$CONFIG_FILE' tidak ditemukan. Jalankan 'encssl' untuk mengonfigurasi."
    exit 1
fi
source "$CONFIG_FILE"

# --- VARIABEL API & STATUS ---
API_URL="https://api.telegram.org/bot$BOT_TOKEN"
LAST_UPDATE_ID=0
# Gunakan file untuk menyimpan status pengguna, karena variabel bash tidak akan bertahan di antara pemanggilan
USER_STATE_FILE="$SCRIPT_DIR/user_state.tmp"

# --- FUNGSI BOT ---

# Mendapatkan dan mengatur status pengguna (apa yang sedang dilakukan pengguna)
get_user_state() {
    local chat_id="$1"
    grep "^$chat_id:" "$USER_STATE_FILE" | cut -d':' -f2
}

set_user_state() {
    local chat_id="$1"
    local state="$2"
    # Hapus status lama dan tambahkan yang baru
    sed -i "/^$chat_id:/d" "$USER_STATE_FILE"
    echo "$chat_id:$state" >> "$USER_STATE_FILE"
}

# Fungsi untuk mengirim pesan dengan keyboard kustom
send_keyboard() {
    local chat_id="$1"
    local text="$2"
    local keyboard="$3"
    curl -s -X POST "$API_URL/sendMessage" -d "chat_id=$chat_id" -d "text=$text" -d "reply_markup=$keyboard" > /dev/null
}

# Fungsi untuk mengirim pesan teks biasa
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

    # Dekripsi file ke file sementara jika perlu
    if [[ "$file_name" == decrypted_* ]]; then
        local original_name="${file_name#decrypted_}"
        mv "$file_path" "$original_name"
        file_path="$original_name"
        file_name="$original_name"
    fi

    curl -s -F "chat_id=$chat_id" -F "document=@$file_path;filename=$file_name" "$API_URL/sendDocument" > /dev/null
}

# Fungsi untuk mengunduh file
download_file() {
    local file_id="$1"
    local file_name="$2"
    local download_dir="$SCRIPT_DIR/downloads"
    mkdir -p "$download_dir"
    local local_path="$download_dir/$file_name"

    local file_path_json=$(curl -s "$API_URL/getFile?file_id=$file_id")
    local file_path=$(echo "$file_path_json" | grep -o '"file_path":"[^"]*' | cut -d'"' -f4)

    if [ -z "$file_path" ]; then return 1; fi

    local download_url="https://api.telegram.org/file/bot$BOT_TOKEN/$file_path"
    curl -s -o "$local_path" "$download_url"
    echo "$local_path"
}

# --- HANDLER ---

handle_start_command() {
    local chat_id="$1"
    local text="Hai! Saya bisa mengenkripsi dan mendekripsi file Anda. Pilih aksi:"
    local keyboard='{"keyboard":[["Enkripsi (Kompresi) ke File"],["Dekripsi (Dekompresi) File"],["Batal"]],"resize_keyboard":true,"one_time_keyboard":true}'
    send_keyboard "$chat_id" "$text" "$keyboard"
    set_user_state "$chat_id" "idle"
}

handle_button_press() {
    local chat_id="$1"
    local button_text="$2"

    case "$button_text" in
        "Enkripsi (Kompresi) ke File")
            local text="Anda memilih untuk mengenkripsi (kompresi) ke file. Sekarang, kirimkan file yang ingin Anda proses. Nama file output akan tetap sama dengan aslinya."
            send_message "$chat_id" "$text"
            set_user_state "$chat_id" "awaiting_encryption_file"
            ;;
        "Dekripsi (Dekompresi) File")
            local text="Anda memilih untuk mendekripsi (dekompresi) file. Sekarang, kirimkan file yang ingin Anda proses."
            send_message "$chat_id" "$text"
            set_user_state "$chat_id" "awaiting_decryption_file"
            ;;
        "Batal")
            send_message "$chat_id" "Operasi dibatalkan."
            handle_start_command "$chat_id" # Tampilkan menu utama lagi
            ;;
    esac
}

handle_file() {
    local chat_id="$1"
    local file_id="$2"
    local file_name="$3"
    local user_state=$(get_user_state "$chat_id")

    if [[ "$user_state" == "awaiting_encryption_file" ]]; then
        send_message "$chat_id" "File '$file_name' diterima, sedang diproses untuk enkripsi..."
        local downloaded_file=$(download_file "$file_id" "$file_name")
        if [ $? -ne 0 ] || [ ! -f "$downloaded_file" ]; then
            send_message "$chat_id" "Maaf, gagal mengunduh file."
            return
        fi

        "$PROTECTOR_SCRIPT" "$downloaded_file"
        if [ $? -ne 0 ]; then
            send_message "$chat_id" "Maaf, gagal mengenkripsi file."
        else
            send_message "$chat_id" "Enkripsi berhasil. Mengirim kembali file..."
            send_file "$chat_id" "$downloaded_file"
        fi
        rm -f "$downloaded_file"
        set_user_state "$chat_id" "idle"
        handle_start_command "$chat_id"

    elif [[ "$user_state" == "awaiting_decryption_file" ]]; then
        send_message "$chat_id" "File '$file_name' diterima, sedang diproses untuk dekripsi..."
        local downloaded_file=$(download_file "$file_id" "$file_name")
        local decrypted_file_path="$SCRIPT_DIR/downloads/decrypted_$file_name"

        if [ $? -ne 0 ] || [ ! -f "$downloaded_file" ]; then
            send_message "$chat_id" "Maaf, gagal mengunduh file."
            return
        fi

        # Panggil dekripsi dan arahkan output ke file baru
        "$PROTECTOR_SCRIPT" --decrypt "$downloaded_file" > "$decrypted_file_path"
        if [ $? -ne 0 ] || ! [ -s "$decrypted_file_path" ]; then
            send_message "$chat_id" "Maaf, gagal mendekripsi file. Pastikan file ini adalah file yang valid."
        else
            send_message "$chat_id" "Dekripsi berhasil. Mengirim kembali file..."
            send_file "$chat_id" "$decrypted_file_path" "$file_name"
        fi
        rm -f "$downloaded_file" "$decrypted_file_path"
        set_user_state "$chat_id" "idle"
        handle_start_command "$chat_id"

    else
        send_message "$chat_id" "Saya tidak yakin apa yang harus dilakukan dengan file ini. Silakan pilih aksi terlebih dahulu."
        handle_start_command "$chat_id"
    fi
}


# --- LOOP UTAMA ---
echo -e "${G}Bot enkripsi interaktif Telegram dimulai... Tekan [CTRL+C] untuk berhenti.${N}"
# Pastikan file status ada
touch "$USER_STATE_FILE"

while true; do
    response_file=$(mktemp)
    # Unduh pembaruan ke file sementara
    curl -s -o "$response_file" "$API_URL/getUpdates?offset=$((LAST_UPDATE_ID + 1))&timeout=30"

    # Proses respons langsung dari file, jangan memuatnya ke dalam variabel
    if grep -q '"ok":true' "$response_file"; then
        update_ids=$(grep -o '"update_id":[0-9]*' "$response_file" | cut -d':' -f2 | sort -un)
        for update_id in $update_ids; do
            if (( update_id > LAST_UPDATE_ID )); then
                LAST_UPDATE_ID=$update_id

                # Ekstrak blok pesan untuk update_id ini dari file
                message=$(grep -A 20 "\"update_id\":$update_id" "$response_file")

                # Parsing JSON yang lebih kuat untuk ID, ambil hanya baris pertama
                chat_id=$(echo "$message" | grep -o '"chat":{"id":[0-9]*' | sed 's/"chat":{"id"://' | head -1)
                from_id=$(echo "$message" | grep -o '"from":{"id":[0-9]*' | sed 's/"from":{"id"://' | head -1)

                # Jika chat_id kosong, lewati iterasi ini karena ini adalah pembaruan yang tidak valid
                if [ -z "$chat_id" ]; then
                    continue
                fi

                # Otorisasi
                if [ "$from_id" != "$USER_ID" ]; then
                    echo -e "$eror Pengguna tidak diizinkan: $from_id"
                    send_message "$chat_id" "Anda tidak diizinkan menggunakan bot ini."
                    continue
                fi

                # Logika perutean, ambil hanya baris pertama
                text=$(echo "$message" | grep -o '"text":"[^"]*' | cut -d'"' -f3 | head -1)
                file_id=$(echo "$message" | grep -o '"document":{"file_id":"[^"]*' | cut -d'"' -f4 | head -1)
                file_name=$(echo "$message" | grep -o '"file_name":"[^"]*' | cut -d'"' -f3 | head -1)

                if [[ "$text" == "/start" ]]; then
                    handle_start_command "$chat_id"
                elif [[ -n "$text" ]]; then
                    handle_button_press "$chat_id" "$text"
                elif [[ -n "$file_id" ]]; then
                    handle_file "$chat_id" "$file_id" "$file_name"
                fi
            fi
        done
    fi
    # Hapus file sementara setelah digunakan
    rm -f "$response_file"
    sleep 1
done
