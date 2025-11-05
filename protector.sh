#!/bin/bash

#================================#
#    ADVANCED SCRIPT PROTECTOR     #
#================================#

# --- KONFIGURASI ---
SCRIPT_DIR=$(dirname "$(realpath "$0")")
BACKUP_DIR="$SCRIPT_DIR/protector_backups"
SELF_NAME=$(basename "$0")

# --- WARNA & SIMBOL ---
N='\033[0m'; W='\033[1;37m'; R='\033[1;31m';
G='\033[1;32m'; Y='\033[1;33m'; C='\033[1;36m';
ask="${G}[${W}?${G}]${N}"
sukses="${G}[${W}√${G}]${N}"
eror="${R}[${W}!${R}]${N}"
info="${C}[${W}i${C}]${N}"

# --- FUNGSI BANTUAN ---
show_help() {
    cat << EOF
Advanced Script Protector — Melindungi script .sh dengan enkripsi AES-256.

Penggunaan:
  $SELF_NAME <file.sh>                Enkripsi satu file (mode non-interaktif)
  $SELF_NAME --decrypt <file.sh>      Dekripsi ke stdout
  $SELF_NAME                          Buka menu interaktif
  $SELF_NAME --help                   Tampilkan bantuan ini

Fitur:
  - Enkripsi AES-256 dengan kunci acak
  - Backup otomatis sebelum enkripsi
  - Perlindungan anti-debug dasar
EOF
}

# --- PENGECEKAN DEPENDENSI ---
check_deps() {
    if ! command -v openssl &>/dev/null; then
        echo -e "$eror 'openssl' tidak ditemukan. Silakan install."
        exit 1
    fi
    if ! command -v base64 &>/dev/null; then
        echo -e "$eror 'base64' tidak ditemukan."
        exit 1
    fi
}

# --- PEMBUATAN BACKUP (DENGAN ERROR HANDLING LENGKAP) ---
create_backup() {
    local file_to_backup="$1"

    if [ ! -f "$file_to_backup" ]; then
        echo -e "$eror File backup tidak valid: $file_to_backup"
        exit 1
    fi

    # Buat direktori utama jika belum ada
    if [ ! -d "$BACKUP_DIR" ]; then
        if ! mkdir -p "$BACKUP_DIR" 2>/dev/null; then
            echo -e "$eror Gagal membuat direktori backup: ${W}$BACKUP_DIR${N}"
            echo -e "$eror Periksa izin penulisan. Operasi dibatalkan."
            exit 1
        fi
        echo -e "$info Direktori backup dibuat: ${W}$BACKUP_DIR/${N}"
    fi

    # Buat subdirektori unik (dengan nanodetik + fallback)
    local timestamp
    if command -v date >/dev/null && date +"%N" &>/dev/null; then
        timestamp=$(date +"%Y-%m-%d_%H-%M-%S-%N")
    else
        timestamp=$(date +"%Y-%m-%d_%H-%M-%S")
        timestamp="${timestamp}_$(shuf -i 1000-9999 -n 1)"
    fi

    local backup_path="$BACKUP_DIR/$timestamp"
    if ! mkdir "$backup_path" 2>/dev/null; then
        echo -e "$eror Gagal membuat folder backup timestamp."
        exit 1
    fi

    if ! cp "$file_to_backup" "$backup_path/" 2>/dev/null; then
        echo -e "$eror Gagal menyalin file ke backup."
        exit 1
    fi

    echo -e "$sukses Backup file asli disimpan di: ${W}$backup_path/${N}"
}

# --- ENKRIPSI FILE .SH ---
protect_sh_file() {
    local infile="$1"

    if [ "$infile" = "$SELF_NAME" ]; then
        echo -e "$eror Tidak dapat melindungi diri sendiri ($SELF_NAME)."
        exit 1
    fi

    local temp_output=$(mktemp) || { echo -e "$eror Gagal membuat file sementara."; exit 1; }
    trap 'rm -f "$temp_output"' EXIT

    local key=$(openssl rand -hex 32)
    local encrypted_content=$(openssl enc -aes-256-cbc -salt -pbkdf2 -pass pass:"$key" -in "$infile" | base64 -w 0)
    local obfuscated_key=$(echo -n "$key" | base64 -w 0)

    cat > "$temp_output" << EOL
#!/bin/bash

# --- LOADER ---
if [[ \$(ps -o args= -p \$\$) == *"bash -x"* || \$(ps -o args= -p \$\$) == *"sh -x"* ]]; then
    echo "Debugging is not allowed." >&2
    exit 1
fi

__run_protected() {
    local encrypted_content='$encrypted_content'
    local obfuscated_key='$obfuscated_key'

    local decoded_key=\$(echo "\$obfuscated_key" | base64 -d)
    if [ -z "\$decoded_key" ]; then
        echo "Error: Failed to decode key." >&2
        return 1
    fi

    local decrypted_content=\$(echo "\$encrypted_content" | base64 -d | openssl enc -d -aes-256-cbc -pbkdf2 -pass pass:"\$decoded_key" 2>/dev/null)
    if [ -z "\$decrypted_content" ]; then
        echo "Error: Decryption failed." >&2
        return 1
    fi

    # Bersihkan jejak sebelum eksekusi
    unset encrypted_content obfuscated_key decoded_key

    eval "\$decrypted_content"
}

__run_protected
EOL

    if ! mv "$temp_output" "$infile" 2>/dev/null; then
        echo -e "$eror Gagal menimpa file asli: $infile"
        exit 1
    fi
    chmod +x "$infile"
}

# --- DEKRIPSI FILE ---
decrypt_file() {
    local infile="$1"
    local outfile="$2"

    if [ ! -f "$infile" ]; then
        echo -e "$eror File input tidak ditemukan." >&2
        return 1
    fi

    local encrypted_content=$(grep "local encrypted_content=" "$infile" | head -1 | cut -d"'" -f2)
    local obfuscated_key=$(grep "local obfuscated_key=" "$infile" | head -1 | cut -d"'" -f2)

    if [ -z "$encrypted_content" ] || [ -z "$obfuscated_key" ]; then
        echo -e "$eror File tidak dikenali sebagai file terlindungi." >&2
        return 1
    fi

    local decoded_key=$(echo "$obfuscated_key" | base64 -d)
    if [ -z "$decoded_key" ]; then
        echo -e "$eror Gagal mendekode kunci." >&2
        return 1
    fi

    if ! echo "$encrypted_content" | base64 -d | openssl enc -d -aes-256-cbc -pbkdf2 -pass pass:"$decoded_key" > "$outfile" 2>/dev/null; then
        rm -f "$outfile" 2>/dev/null
        echo -e "$eror Dekripsi gagal (kunci salah atau data rusak)." >&2
        return 1
    fi

    return 0
}

# --- MENU INTERAKTIF ---
menu_single_sh() {
    echo -e "\n${C}--- Lindungi Satu Script .sh ---${N}"
    read -rp "$(echo -e "${ask} Nama file script .sh ${G}> ${W}")" infile
    if [ ! -f "$infile" ]; then echo -e "$eror File tidak ditemukan!"; return; fi
    if [ "$infile" = "$SELF_NAME" ]; then echo -e "$eror Tidak bisa melindungi diri sendiri!"; return; fi

    echo -e "$info Memproses: ${W}$infile${N}"
    create_backup "$infile"
    protect_sh_file "$infile"
    echo -e "$sukses File ${W}$infile${N} berhasil dilindungi."
}

menu_mass_sh() {
    echo -e "\n${C}--- Lindungi Semua Script .sh di Direktori Ini ---${N}"
    read -rp "$(echo -e "${ask} Yakin? File asli akan ditimpa. (y/n) ${G}> ${W}")" confirm
    if [[ "$confirm" != "y" ]]; then echo -e "$eror Dibatalkan."; return; fi

    local count=0
    for infile in *.sh; do
        if [ -f "$infile" ] && [ "$infile" != "$SELF_NAME" ]; then
            echo -e "$info Memproses: ${W}$infile${N}"
            create_backup "$infile"
            protect_sh_file "$infile"
            ((count++))
        fi
    done
    echo -e "\n$sukses Selesai! Total ${W}$count${N} file dilindungi."
}

menu_decrypt_file() {
    echo -e "\n${C}--- Dekripsi File Terlindungi ---${N}"
    read -rp "$(echo -e "${ask} File input ${G}> ${W}")" infile
    [ ! -f "$infile" ] && { echo -e "$eror File tidak ditemukan!"; return; }

    local default_out="decrypted_$(basename "$infile")"
    read -rp "$(echo -e "${ask} File output [${G}$default_out${W}] ${G}> ${W}")" outfile
    [[ -z "$outfile" ]] && outfile="$default_out"

    echo -e "$info Menyimpan ke: ${W}$outfile${N}"
    if decrypt_file "$infile" "$outfile"; then
        echo -e "$sukses Dekripsi berhasil: ${W}$outfile${N}"
    else
        echo -e "$eror Gagal mendekripsi file."
    fi
}

# --- MODE NON-INTERAKTIF ---
if [ "$1" == "--help" ] || [ "$1" == "-h" ]; then
    show_help
    exit 0
elif [ "$1" == "--decrypt" ]; then
    if [ -f "$2" ]; then
        decrypt_file "$2" "/dev/stdout"
        exit $?
    else
        echo -e "$eror File tidak ditemukan: $2" >&2
        exit 1
    fi
elif [ -n "$1" ]; then
    if [ -f "$1" ]; then
        protect_sh_file "$1"
        echo -e "$sukses $1 berhasil dilindungi."
        exit 0
    else
        echo -e "$eror File tidak ditemukan: $1" >&2
        exit 1
    fi
fi

# --- MENU UTAMA (INTERAKTIF) ---
check_deps

while true; do
    clear
    echo -e "${Y}--- Advanced Script & File Protector ---${N}"
    echo -e "Melindungi script .sh dengan enkripsi AES-256 dan backup otomatis."
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
