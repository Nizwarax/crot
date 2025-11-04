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
    local original_file="$1"
    local protected_file="$2"

    if [ ! -d "$BACKUP_DIR" ]; then
        mkdir "$BACKUP_DIR"
        echo -e "$info Membuat direktori backup: ${W}$BACKUP_DIR/${N}"
    fi

    local timestamp=$(date +"%Y-%m-%d_%H-%M-%S")
    local backup_path="$BACKUP_DIR/$timestamp"
    mkdir "$backup_path"

    cp "$original_file" "$backup_path/"
    cp "$protected_file" "$backup_path/"

    echo -e "$sukses Backup file asli dan file terproteksi disimpan di: ${W}$backup_path/${N}"
}

# CORE: Fungsi enkripsi untuk file .sh
protect_sh_file() {
    local infile="$1"
    local output="$2"

    # Buat kunci acak & enkripsi konten
    local key=$(openssl rand -hex 32)
    local encrypted_content=$(openssl enc -aes-256-cbc -salt -pbkdf2 -pass pass:"$key" -in "$infile" | base64 -w 0)
    local obfuscated_key=$(echo -n "$key" | base64 -w 0)

    # Buat script loader
    cat > "$output" << EOL
#!/bin/bash
if [[ \$(ps -o args= -p \$\$) == *"bash -x"* || \$(ps -o args= -p \$\$) == *"sh -x"* ]]; then echo "Debugging not allowed."; exit 1; fi
__p1="$encrypted_content"; __k_p="$obfuscated_key"; __run() { local c_b64="YmFzZTY0IC1k"; local c_ossl="b3BlbnNzbCBlbmMgLWQgLWFlcy0yNTYtY2JjIC1wYmtkZjIgLXBhc3M="; local c_sh="YmFzaA=="; local p1=\$(echo "\$c_b64"|base64 -d); local p2=\$(echo "\$c_ossl"|base64 -d); local p3=\$(echo "\$c_sh"|base64 -d); local sk=\$(echo "\$__k_p"|\$p1); eval "echo \\"\$__p1\\" | \$p1 | \$p2 pass:\\"\$sk\\" | \$p3"; }; exec 2>/dev/null; __run
EOL
    chmod +x "$output"
}

# CORE: Fungsi enkripsi untuk file ZIP/Biner
protect_binary_file() {
    local infile="$1"
    local output="$2"

    # Buat kunci acak & enkripsi konten
    local key=$(openssl rand -hex 32)
    local encrypted_content=$(openssl enc -aes-256-cbc -salt -pbkdf2 -pass pass:"$key" -in "$infile" | base64 -w 0)
    local obfuscated_key=$(echo -n "$key" | base64 -w 0)

    # Buat script loader
    cat > "$output" << EOL
#!/bin/bash
echo "File extractor initializing..."
read -rp "Enter the name for the output file (e.g., archive.zip): " user_output
if [ -z "\$user_output" ]; then echo "Error: Output file name cannot be empty."; exit 1; fi
__p1="$encrypted_content"; __k_p="$obfuscated_key"; __extract() { local c_b64="YmFzZTY0IC1k"; local c_ossl="b3BlbnNzbCBlbmMgLWQgLWFlcy0yNTYtY2JjIC1wYmtkZjIgLXBhc3M="; local p1=\$(echo "\$c_b64"|base64 -d); local p2=\$(echo "\$c_ossl"|base64 -d); local sk=\$(echo "\$__k_p"|\$p1); echo "Extracting to '\$user_output'..."; echo "\$__p1" | \$p1 | \$p2 pass:"\$sk" > "\$user_output"; }; __extract
if [ \$? -eq 0 ]; then echo "File extracted successfully: \$user_output"; else echo "Extraction failed. Invalid password or corrupted data."; fi
EOL
    chmod +x "$output"
}


# --- MENU ---

# Menu 1: Enkripsi satu file .sh
menu_single_sh() {
    echo -e "\n${C}--- Lindungi Satu Script .sh ---${N}"
    read -rp "$(echo -e "${ask} Nama file script .sh ${G}> ${W}")" infile
    if [ ! -f "$infile" ]; then echo -e "$eror File tidak ditemukan!"; return; fi

    local output="${infile%.sh}_protected.sh"
    read -rp "$(echo -e "${ask} Nama file output [${G}$output${W}] ${G}> ${W}")" new_output
    [[ -n "$new_output" ]] && output="$new_output"

    echo -e "$info Memproses file: ${W}$infile${N}"
    protect_sh_file "$infile" "$output"
    create_backup "$infile" "$output"
}

# Menu 2: Enkripsi massal .sh
menu_mass_sh() {
    echo -e "\n${C}--- Lindungi Semua Script .sh di Direktori Ini ---${N}"
    read -rp "$(echo -e "${ask} Apakah Anda yakin? (y/n) ${G}> ${W}")" confirm
    if [[ "$confirm" != "y" ]]; then echo -e "$eror Operasi dibatalkan."; return; fi

    local count=0
    for infile in *.sh; do
        if [ -f "$infile" ] && [ "$infile" != "protector.sh" ]; then
            local output="${infile%.sh}_protected.sh"
            echo -e "$info Memproses file: ${W}$infile${N}"
            protect_sh_file "$infile" "$output"
            create_backup "$infile" "$output"
            ((count++))
        fi
    done
    echo -e "\n$sukses Selesai! Total ${W}$count${N} file script berhasil dilindungi."
}

# Menu 3: Enkripsi file ZIP atau lainnya
menu_zip_file() {
    echo -e "\n${C}--- Lindungi File ZIP / Biner ---${N}"
    read -rp "$(echo -e "${ask} Nama file (misal: data.zip) ${G}> ${W}")" infile
    if [ ! -f "$infile" ]; then echo -e "$eror File tidak ditemukan!"; return; fi

    local output="extract_${infile%.*}"
    read -rp "$(echo -e "${ask} Nama file extractor .sh [${G}$output${W}] ${G}> ${W}")" new_output
    [[ -n "$new_output" ]] && output="$new_output"

    echo -e "$info Memproses file: ${W}$infile${N}"
    protect_binary_file "$infile" "$output"
    create_backup "$infile" "$output"
}

# --- SCRIPT UTAMA ---
check_deps
while true; do
    clear
    echo -e "${Y}--- Advanced Script & File Protector ---${N}"
    echo -e "Melindungi script .sh dan file lainnya dengan enkripsi & backup."
    echo -e "----------------------------------------------------"
    echo -e " ${G}[${W}1${G}]${W} Lindungi SATU script .sh${N}"
    echo -e " ${G}[${W}2${G}]${W} Lindungi SEMUA script .sh di folder ini${N}"
    echo -e " ${G}[${W}3${G}]${W} Lindungi file ZIP / Biner / Lainnya${N}"
    echo -e " ${R}[${W}0${R}]${W} Keluar${N}"
    echo "----------------------------------------------------"

    read -rp "$(echo -e "${W}Pilih Opsi ${G}> ${N}")" choice

    case "$choice" in
        1) menu_single_sh ;;
        2) menu_mass_sh ;;
        3) menu_zip_file ;;
        0) echo -e "\n${Y}Terima kasih!${N}"; exit 0 ;;
        *) echo -e "$eror Pilihan tidak valid!" ;;
    esac

    echo -e "\n${ask} Tekan [${W}Enter${N}] untuk kembali ke menu..."
    read -r
done
