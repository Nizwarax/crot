#!/bin/bash

#================================#
#    ADVANCED SCRIPT PROTECTOR     #
#================================#

# --- KONFIGURASI ---
BACKUP_DIR="protector_backups"

# --- WARNA & SIMBOL ---
N='\033[0m'; W='\033[1;37m'; R='\033[1;31m';
G='\033[1;32m'; Y='\033[1;33m'; C='\033[1;36m';
ask="${G}[${W}?${G}]${N}"
sukses="${G}[${W}√${G}]${N}"
eror="${R}[${W}!${R}]${N}"
info="${C}[${W}i${C}]${N}"

# --- FUNGSI UTAMA ---

# Cek dependensi
check_deps() {
    if ! command -v openssl &>/dev/null; then
        echo -e "$eror 'openssl' tidak ditemukan. Silakan install."
        exit 1
    fi
}

# Membuat backup
create_backup() {
    local file_to_backup="$1"

    if [ ! -d "$BACKUP_DIR" ]; then
        mkdir "$BACKUP_DIR"
        echo -e "$info Membuat direktori backup: ${W}$BACKUP_DIR/${N}"
    fi

    local timestamp=$(date +"%Y-%m-%d_%H-%M-%S")
    local backup_path="$BACKUP_DIR/$timestamp"
    mkdir "$backup_path"

    cp "$file_to_backup" "$backup_path/"

    echo -e "$sukses Backup file asli disimpan di: ${W}$backup_path/${N}"
}

# CORE: Fungsi enkripsi untuk file .sh
protect_sh_file() {
    local infile="$1"
    local temp_output=$(mktemp)

    # Buat kunci acak & enkripsi konten
    local key=$(openssl rand -hex 32)
    local encrypted_content=$(openssl enc -aes-256-cbc -salt -pbkdf2 -pass pass:"$key" -in "$infile" | base64 -w 0)
    local obfuscated_key=$(echo -n "$key" | base64 -w 0)

    # Buat script loader
    cat > "$temp_output" << EOL
#!/bin/bash

# --- LOADER ---
# Anti-debug sederhana
if [[ \$(ps -o args= -p \$\$) == *"bash -x"* || \$(ps -o args= -p \$\$) == *"sh -x"* ]]; then
    echo "Debugging is not allowed."
    exit 1
fi

# Fungsi untuk dekripsi dan eksekusi
__run_protected() {
    local encrypted_content='$encrypted_content'
    local obfuscated_key='$obfuscated_key'

    # Dekode kunci
    local decoded_key=\$(echo "\$obfuscated_key" | base64 -d)
    if [ -z "\$decoded_key" ]; then
        echo "Error: Failed to decode the key."
        return 1
    fi

    # Dekripsi konten
    local decrypted_content=\$(echo "\$encrypted_content" | base64 -d | openssl enc -d -aes-256-cbc -pbkdf2 -pass pass:"\$decoded_key" 2>/dev/null)
    if [ -z "\$decrypted_content" ]; then
        echo "Error: Decryption failed. The key is incorrect or the data is corrupt."
        return 1
    fi

    # Eksekusi konten yang sudah didekripsi
    eval "\$decrypted_content"
}

# Panggil fungsi utama
__run_protected
EOL

    # Timpa file asli dengan versi yang dilindungi
    mv "$temp_output" "$infile"
    chmod +x "$infile"
}


# --- MENU ---

# Menu 1: Enkripsi satu file .sh
menu_single_sh() {
    echo -e "\n${C}--- Lindungi Satu Script .sh ---${N}"
    read -rp "$(echo -e "${ask} Nama file script .sh ${G}> ${W}")" infile
    if [ ! -f "$infile" ]; then echo -e "$eror File tidak ditemukan!"; return; fi

    echo -e "$info Memproses file: ${W}$infile${N}"
    create_backup "$infile"
    protect_sh_file "$infile"
    echo -e "$sukses File ${W}$infile${N} berhasil dilindungi (file asli ditimpa)."
}

# Menu 2: Enkripsi massal .sh
menu_mass_sh() {
    echo -e "\n${C}--- Lindungi Semua Script .sh di Direktori Ini (File Asli Ditimpa) ---${N}"
    read -rp "$(echo -e "${ask} Apakah Anda yakin? (y/n) ${G}> ${W}")" confirm
    if [[ "$confirm" != "y" ]]; then echo -e "$eror Operasi dibatalkan."; return; fi

    local count=0
    for infile in *.sh; do
        if [ -f "$infile" ] && [ "$infile" != "protector.sh" ] && [ "$infile" != "telegram_bot.sh" ]; then
            echo -e "$info Memproses file: ${W}$infile${N}"
            create_backup "$infile"
            protect_sh_file "$infile"
            ((count++))
        fi
    done
    echo -e "\n$sukses Selesai! Total ${W}$count${N} file script berhasil dilindungi."
}

# Menu 4: Dekripsi file
menu_decrypt_file() {
    echo -e "\n${C}--- Dekripsi File yang Dilindungi ---${N}"
    read -rp "$(echo -e "${ask} Nama file yang akan didekripsi ${G}> ${W}")" infile
    if [ ! -f "$infile" ]; then echo -e "$eror File tidak ditemukan!"; return; fi

    # Ekstrak konten dan kunci dari file
    local encrypted_content=$(grep "local encrypted_content=" "$infile" | head -1 | cut -d"'" -f2)
    local obfuscated_key=$(grep "local obfuscated_key=" "$infile" | head -1 | cut -d"'" -f2)

    if [ -z "$encrypted_content" ] || [ -z "$obfuscated_key" ]; then
        echo -e "$eror File ini sepertinya bukan file yang dilindungi dengan benar."
        return 1
    fi

    # Dekode kunci
    local decoded_key=$(echo "$obfuscated_key" | base64 -d)
    if [ -z "$decoded_key" ]; then
        echo -e "$eror Gagal mendekode kunci."
        return 1
    fi

    # Tentukan nama file output
    local default_output="decrypted_$(basename "$infile")"
    read -rp "$(echo -e "${ask} Nama file output [${G}$default_output${W}] ${G}> ${W}")" outfile
    [[ -z "$outfile" ]] && outfile="$default_output"

    # Dekripsi konten
    echo -e "$info Mendekripsi file ke: ${W}$outfile${N}"
    echo "$encrypted_content" | base64 -d | openssl enc -d -aes-256-cbc -pbkdf2 -pass pass:"$decoded_key" > "$outfile" 2>/dev/null

    if [ $? -eq 0 ] && [ -s "$outfile" ]; then
        echo -e "$sukses File berhasil didekripsi: ${W}$outfile${N}"
    else
        echo -e "$eror Gagal mendekripsi file. Kunci salah atau data rusak."
        rm -f "$outfile" # Hapus file yang gagal
    fi
}


# Menu 5: Pengaturan Bot
menu_bot_settings() {
    echo -e "\n${C}--- Pengaturan Bot Telegram ---${N}"
    read -rp "$(echo -e "${ask} Masukkan Token Bot Anda ${G}> ${W}")" bot_token
    read -rp "$(echo -e "${ask} Masukkan User ID atau Group ID Anda ${G}> ${W}")" user_id

    # Simpan ke file konfigurasi
    echo "BOT_TOKEN='$bot_token'" > bot.conf
    echo "USER_ID='$user_id'" >> bot.conf

    echo -e "$sukses Pengaturan bot disimpan di ${W}bot.conf${N}"
}

# Menu 6: Jalankan Bot
menu_run_bot() {
    if [ ! -f "bot.conf" ]; then
        echo -e "$eror File konfigurasi 'bot.conf' tidak ditemukan."
        echo -e "$info Silakan atur token dan ID Anda melalui menu Pengaturan Bot terlebih dahulu."
        return 1
    fi
    if [ ! -f "telegram_bot.sh" ]; then
        echo -e "$eror File bot 'telegram_bot.sh' tidak ditemukan."
        return 1
    fi

    echo -e "$info Menjalankan bot Telegram..."
    ./telegram_bot.sh
}


# --- SCRIPT UTAMA ---
check_deps

# Mode non-interaktif untuk bot
if [ -n "$1" ]; then
    if [ -f "$1" ]; then
        # Hanya enkripsi, tanpa backup di mode ini (bot yang akan menangani)
        protect_sh_file "$1"
        exit 0
    else
        echo "Error: File '$1' not found."
        exit 1
    fi
fi

while true; do
    clear
    echo -e "${Y}--- Advanced Script & File Protector ---${N}"
    echo -e "Melindungi script .sh dan file lainnya dengan enkripsi & backup."
    echo -e "----------------------------------------------------"
    echo -e " ${G}[${W}1${G}]${W} Lindungi SATU script .sh${N}"
    echo -e " ${G}[${W}2${G}]${W} Lindungi SEMUA script .sh di folder ini${N}"
    echo -e " ${C}[${W}3${C}]${W} Dekripsi File yang Dilindungi${N}"
    echo -e "----------------------------------------------------"
    echo -e " ${Y}[${W}4${Y}]${W} Pengaturan Bot Telegram${N}"
    echo -e " ${Y}[${W}5${Y}]${W} Jalankan Bot Telegram${N}"
    echo -e "----------------------------------------------------"
    echo -e " ${R}[${W}0${R}]${W} Keluar${N}"
    echo "----------------------------------------------------"

    read -rp "$(echo -e "${W}Pilih Opsi ${G}> ${N}")" choice

    case "$choice" in
        1) menu_single_sh ;;
        2) menu_mass_sh ;;
        3) menu_decrypt_file ;;
        4) menu_bot_settings ;;
        5) menu_run_bot ;;
        0) echo -e "\n${Y}Terima kasih!${N}"; exit 0 ;;
        *) echo -e "$eror Pilihan tidak valid!" ;;
    esac

    echo -e "\n${ask} Tekan [${W}Enter${N}] untuk kembali ke menu..."
    read -r
done
