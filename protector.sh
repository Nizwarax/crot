#!/bin/bash

#================================#
#    ADVANCED SCRIPT PROTECTOR     #
#================================#

# --- KONFIGURASI ---
# Skrip akan dijalankan dari symlink, jadi kita perlu mencari tahu di mana file sebenarnya berada.
SCRIPT_DIR=$(dirname "$(realpath "$0")")
BACKUP_DIR="$SCRIPT_DIR/protector_backups"
CONFIG_FILE="$SCRIPT_DIR/bot.conf"
BOT_SCRIPT_PATH="$SCRIPT_DIR/telegram_bot.sh"

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
    if ! command -v jq &>/dev/null; then
        echo -e "$eror 'jq' tidak ditemukan. Ini diperlukan agar bot dapat berfungsi."
        echo -e "$info Silakan install 'jq' (misalnya, ${C}sudo apt-get install jq${N})."
        # Jangan keluar, karena menu utama masih bisa digunakan.
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

# CORE: Fungsi dekripsi
decrypt_file() {
    local infile="$1"
    local outfile="$2"

    local encrypted_content=$(grep "local encrypted_content=" "$infile" | head -1 | cut -d"'" -f2)
    local obfuscated_key=$(grep "local obfuscated_key=" "$infile" | head -1 | cut -d"'" -f2)

    if [ -z "$encrypted_content" ] || [ -z "$obfuscated_key" ]; then
        return 1 # Bukan file yang valid
    fi

    local decoded_key=$(echo "$obfuscated_key" | base64 -d)
    if [ -z "$decoded_key" ]; then
        return 1 # Gagal mendekode kunci
    fi

    # Dekripsi konten
    echo "$encrypted_content" | base64 -d | openssl enc -d -aes-256-cbc -pbkdf2 -pass pass:"$decoded_key" > "$outfile" 2>/dev/null
    if [ $? -eq 0 ] && [ -s "$outfile" ]; then
        return 0 # Berhasil
    else
        rm -f "$outfile" # Bersihkan upaya yang gagal
        return 1 # Gagal dekripsi
    fi
}

# Menu 4: Dekripsi file
menu_decrypt_file() {
    echo -e "\n${C}--- Dekripsi File yang Dilindungi ---${N}"
    read -rp "$(echo -e "${ask} Nama file yang akan didekripsi ${G}> ${W}")" infile
    if [ ! -f "$infile" ]; then echo -e "$eror File tidak ditemukan!"; return; fi

    local default_output="decrypted_$(basename "$infile")"
    read -rp "$(echo -e "${ask} Nama file output [${G}$default_output${W}] ${G}> ${W}")" outfile
    [[ -z "$outfile" ]] && outfile="$default_output"

    echo -e "$info Mendekripsi file ke: ${W}$outfile${N}"
    if decrypt_file "$infile" "$outfile"; then
        echo -e "$sukses File berhasil didekripsi: ${W}$outfile${N}"
    else
        echo -e "$eror Gagal mendekripsi file. Kunci salah atau data rusak."
    fi
}


# Fungsi terpisah untuk konfigurasi bot
menu_configure_bot() {
    echo -e "\n${C}--- Konfigurasi Bot Telegram ---${N}"

    local current_token=""
    local current_user_id=""

    # Periksa apakah konfigurasi sudah ada
    if [ -f "$CONFIG_FILE" ]; then
        source "$CONFIG_FILE" # Muat variabel saat ini
        current_token="$BOT_TOKEN"
        current_user_id="$USER_ID"
        echo -e "$info Konfigurasi bot saat ini ditemukan:"
        echo -e "  - Token: ${W}...${current_token: -4}${N}"
        echo -e "  - User ID: ${W}$current_user_id${N}"
        read -rp "$(echo -e "${ask} Apakah Anda ingin mengubah pengaturan ini? (y/n) [${G}n${W}] ${G}> ${W}")" change_settings

        if [[ "$change_settings" != "y" ]]; then
            echo -e "$info Pengaturan tidak diubah."
            return
        fi
    fi

    # Minta input baru
    read -rp "$(echo -e "${ask} Masukkan Token Bot Anda ${G}> ${W}")" bot_token
    read -rp "$(echo -e "${ask} Masukkan User ID atau Group ID Anda ${G}> ${W}")" user_id

    # Gunakan nilai yang ada jika input kosong
    [[ -z "$bot_token" ]] && bot_token="$current_token"
    [[ -z "$user_id" ]] && user_id="$current_user_id"

    # Tulis file konfigurasi baru
    echo "BOT_TOKEN='$bot_token'" > "$CONFIG_FILE"
    echo "USER_ID='$user_id'" >> "$CONFIG_FILE"

    echo -e "$sukses Pengaturan bot disimpan di ${W}$CONFIG_FILE${N}"
}

# Fungsi untuk memulai bot
start_bot() {
    echo -e "$info Memulai bot di latar belakang..."

    # Periksa apakah file konfigurasi ada
    if [ ! -f "$CONFIG_FILE" ]; then
        echo -e "$eror File konfigurasi bot tidak ditemukan."
        echo -e "$eror Silakan pilih 'Ubah Konfigurasi Bot' terlebih dahulu."
        return 1
    fi

    # Periksa apakah skrip bot ada
    if [ ! -f "$BOT_SCRIPT_PATH" ]; then
        echo -e "$eror File skrip bot '$BOT_SCRIPT_PATH' tidak ditemukan. Instalasi mungkin rusak."
        return 1
    fi

    local pid_file="$SCRIPT_DIR/bot.pid"
    local log_file="$SCRIPT_DIR/bot.log"

    # Jalankan bot di latar belakang dengan nohup, alihkan output ke file log
    nohup "$BOT_SCRIPT_PATH" > "$log_file" 2>&1 &

    # Simpan PID dari proses yang baru saja dimulai
    local bot_pid=$!
    echo "$bot_pid" > "$pid_file"

    # Beri waktu sejenak untuk memeriksa apakah proses tersebut langsung keluar
    sleep 1
    if ! ps -p "$bot_pid" > /dev/null; then
        echo -e "$eror Bot gagal dimulai. Periksa log untuk detail:"
        echo -e "  ${W}tail -n 20 $log_file${N}"
        rm -f "$pid_file"
    else
        echo -e "$sukses Bot berhasil dimulai dengan PID: ${W}$bot_pid${N}."
        echo -e "$info Log bot ditulis ke: ${W}$log_file${N}"
    fi
}

# Fungsi untuk menghentikan bot
stop_bot() {
    local pid_file="$SCRIPT_DIR/bot.pid"

    if [ ! -f "$pid_file" ]; then
        echo -e "$eror File PID tidak ditemukan. Bot mungkin tidak berjalan."
        return 1
    fi

    local pid=$(cat "$pid_file")
    echo -e "$info Mencoba menghentikan bot dengan PID: ${W}$pid${N}..."

    # Coba hentikan dengan baik terlebih dahulu
    if kill "$pid" > /dev/null 2>&1; then
        # Tunggu hingga 5 detik agar proses berhenti
        local count=0
        while ps -p "$pid" > /dev/null; do
            sleep 1
            ((count++))
            if [ "$count" -ge 5 ]; then
                break # Lanjutkan ke kill paksa
            fi
        done
    fi

    # Jika masih berjalan, paksa hentikan
    if ps -p "$pid" > /dev/null; then
        echo -e "$info Bot tidak berhenti dengan baik, mencoba menghentikan secara paksa..."
        kill -9 "$pid" > /dev/null 2>&1
    fi

    # Verifikasi penghentian
    if ! ps -p "$pid" > /dev/null; then
        echo -e "$sukses Bot berhasil dihentikan."
        rm -f "$pid_file"
    else
        echo -e "$eror Gagal menghentikan bot. Anda mungkin perlu melakukannya secara manual: ${W}kill -9 $pid${N}"
    fi
}

# Fungsi untuk melihat log bot
view_bot_log() {
    local log_file="$SCRIPT_DIR/bot.log"
    if [ ! -f "$log_file" ]; then
        echo -e "$eror File log tidak ditemukan. Mulai bot setidaknya sekali untuk membuatnya."
        sleep 2
        return
    fi

    clear
    echo -e "$info Menampilkan log dari: ${W}$log_file${N}"
    echo -e "$info Tekan ${Y}[CTRL+C]${N} untuk berhenti melihat dan kembali ke menu."

    # Beri jeda agar pengguna dapat membaca pesan di atas
    sleep 2

    # Ikuti log. Perangkap CTRL+C untuk keluar dengan bersih.
    trap 'echo -e "\n\n$info Kembali ke menu..."; sleep 1; trap - INT' INT
    tail -f "$log_file"
}

# --- SUBMENU MANAJEMEN BOT ---
menu_telegram_bot() {
    local pid_file="$SCRIPT_DIR/bot.pid"
    local log_file="$SCRIPT_DIR/bot.log"

    # Fungsi untuk memeriksa apakah bot sedang berjalan
    is_bot_running() {
        if [ -f "$pid_file" ]; then
            local pid=$(cat "$pid_file")
            # Periksa apakah proses dengan PID tersebut ada
            if ps -p "$pid" > /dev/null; then
                return 0 # Berjalan
            fi
        fi
        return 1 # Tidak berjalan
    }

    while true; do
        clear
        echo -e "${Y}--- Menu Manajemen Bot Telegram ---${N}"
        echo -e "Kelola bot enkripsi/dekripsi Anda."
        echo -e "----------------------------------------------------"

        if is_bot_running; then
            echo -e " ${G}Status: Berjalan (PID: $(cat "$pid_file"))${N}"
            echo -e " ${R}[${W}1${R}]${W} Hentikan Bot${N}"
            echo -e " ${C}[${W}2${C}]${W} Lihat Log Bot (Live)${N}"
        else
            echo -e " ${R}Status: Tidak Berjalan${N}"
            echo -e " ${G}[${W}1${G}]${W} Mulai Bot di Latar Belakang${N}"
        fi

        echo -e " ${Y}[${W}3${Y}]${W} Ubah Konfigurasi Bot${N}"
        echo -e "----------------------------------------------------"
        echo -e " ${W}[${W}0${W}]${W} Kembali ke Menu Utama${N}"
        echo "----------------------------------------------------"

        read -rp "$(echo -e "${W}Pilih Opsi ${G}> ${N}")" bot_choice

        case "$bot_choice" in
            1)
                if is_bot_running; then
                    stop_bot
                else
                    start_bot
                fi
                sleep 2
                ;;
            2)
                if is_bot_running; then
                    view_bot_log
                else
                    echo -e "$eror Pilihan tidak valid!"
                    sleep 2
                fi
                ;;
            3)
                menu_configure_bot
                echo -e "\n${ask} Tekan [${W}Enter${N}] untuk kembali..."
                read -r
                ;;
            0) return ;;
            *) echo -e "$eror Pilihan tidak valid!"; sleep 2 ;;
        esac
    done
}


# --- SCRIPT UTAMA ---
check_deps

# Mode non-interaktif untuk bot
if [ "$1" == "--decrypt" ]; then
    if [ -f "$2" ]; then
        # Dekripsi file. Output ke stdout untuk bot.
        decrypt_file "$2" "/dev/stdout"
        exit $?
    else
        exit 1 # File tidak ditemukan
    fi
elif [ -n "$1" ]; then
    if [ -f "$1" ]; then
        # Enkripsi file seperti biasa (menimpa file).
        protect_sh_file "$1"
        exit 0
    else
        exit 1 # File tidak ditemukan
    fi
fi

# --- MENU UTAMA ---
while true; do
    clear
    echo -e "${Y}--- Advanced Script & File Protector ---${N}"
    echo -e "Melindungi script .sh dan file lainnya dengan enkripsi & backup."
    echo -e "----------------------------------------------------"
    echo -e " ${G}[${W}1${G}]${W} Lindungi SATU script .sh${N}"
    echo -e " ${G}[${W}2${G}]${W} Lindungi SEMUA script .sh di folder ini${N}"
    echo -e " ${C}[${W}3${C}]${W} Dekripsi File yang Dilindungi${N}"
    echo -e "----------------------------------------------------"
    echo -e " ${Y}[${W}4${Y}]${W} Menu Manajemen Bot Telegram${N}"
    echo -e "----------------------------------------------------"
    echo -e " ${R}[${W}0${R}]${W} Keluar${N}"
    echo "----------------------------------------------------"

    read -rp "$(echo -e "${W}Pilih Opsi ${G}> ${N}")" choice

    case "$choice" in
        1) menu_single_sh; read -r ;;
        2) menu_mass_sh; read -r ;;
        3) menu_decrypt_file; read -r ;;
        4) menu_telegram_bot ;; # Panggil submenu baru
        0) echo -e "\n${Y}Terima kasih!${N}"; exit 0 ;;
        *) echo -e "$eror Pilihan tidak valid!"; sleep 2 ;;
    esac
done
