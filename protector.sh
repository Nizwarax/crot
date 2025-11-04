#!/bin/bash

#================================#
#    ADVANCED SCRIPT PROTECTOR     #
#================================#

# --- KONFIGURASI ---
# Skrip akan dijalankan dari symlink, jadi kita perlu mencari tahu di mana file sebenarnya berada.
SCRIPT_DIR=$(dirname "$(realpath "$0")")
BACKUP_DIR="$SCRIPT_DIR/protector_backups"

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

    # Buat direktori backup utama jika belum ada
    if [ ! -d "$BACKUP_DIR" ]; then
        echo -e "$info Membuat direktori backup utama: ${W}$BACKUP_DIR/${N}"
        mkdir -p "$BACKUP_DIR"
        if [ $? -ne 0 ]; then
            echo -e "$eror Gagal membuat direktori backup utama di ${W}$BACKUP_DIR${N}."
            echo -e "$eror Periksa izin tulis Anda. Enkripsi dibatalkan."
            exit 1
        fi
    fi

    # Buat subdirektori timestamp yang unik (tambahkan nanodetik untuk keunikan)
    local timestamp=$(date +"%Y-%m-%d_%H-%M-%S-%N")
    local backup_path="$BACKUP_DIR/$timestamp"
    mkdir "$backup_path"
    if [ $? -ne 0 ]; then
        echo -e "$eror Gagal membuat direktori backup timestamp di ${W}$backup_path${N}."
        echo -e "$eror Periksa izin tulis Anda. Enkripsi dibatalkan."
        exit 1
    fi

    # Salin file asli ke direktori backup
    cp "$file_to_backup" "$backup_path/"
    if [ $? -ne 0 ]; then
        echo -e "$eror Gagal menyalin file asli ke ${W}$backup_path/${N}."
        echo -e "$eror Enkripsi dibatalkan."
        exit 1
    fi

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
    echo -e " ${R}[${W}0${R}]${W} Keluar${N}"
    echo "----------------------------------------------------"

    read -rp "$(echo -e "${W}Pilih Opsi ${G}> ${N}")" choice

    case "$choice" in
        1) menu_single_sh; read -r ;;
        2) menu_mass_sh; read -r ;;
        3) menu_decrypt_file; read -r ;;
        0) echo -e "\n${Y}Terima kasih!${N}"; exit 0 ;;
        *) echo -e "$eror Pilihan tidak valid!"; sleep 2 ;;
    esac
done
