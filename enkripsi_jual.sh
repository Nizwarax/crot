#!/bin/bash

#================================#
#    POWERFUL SCRIPT PROTECTOR     #
#================================#

# Warna & Simbol
N='\033[0m'; W='\033[1;37m'; R='\033[1;31m';
G='\033[1;32m'; Y='\033[1;33m'; C='\033[1;36m';
ask="${G}[${W}?${G}]${N}"
sukses="${G}[${W}√${G}]${N}"
eror="${R}[${W}!${R}]${N}"
info="${C}[${W}i${C}]${N}"

# Cek dependensi
if ! command -v openssl &>/dev/null; then
    echo -e "$eror 'openssl' tidak ditemukan. Silakan install terlebih dahulu."
    exit 1
fi

clear
echo -e "${Y}--- Powerful Script Protector ---${N}"
echo -e "Melindungi script Anda dengan enkripsi, obfuscation, dan anti-debugging."
echo ""

# 1. Minta file input
read -rp "$(echo -e "${ask} Nama script yang mau dilindungi ${G}> ${W}")" infile
if [ ! -f "$infile" ]; then
    echo -e "$eror File '${W}$infile${R}' tidak ditemukan!"
    exit 1
fi

# 2. Minta file output
output="${infile%.sh}_protected.sh"
read -rp "$(echo -e "${ask} Nama file output [${G}$output${W}] ${G}> ${W}")" new_output
[[ -n "$new_output" ]] && output="$new_output"

# 3. Proses Enkripsi
echo -e "$info Melakukan enkripsi dan obfuscation..."

# Buat kunci acak
key=$(openssl rand -hex 32)
# Enkripsi konten dan encode ke base64
encrypted_content=$(openssl enc -aes-256-cbc -salt -pbkdf2 -pass pass:"$key" -in "$infile" | base64 -w 0)
# Obfuscate kunci
obfuscated_key=$(echo -n "$key" | base64 -w 0)

# 4. Buat script loader (template yang akan dikirim ke pembeli)
# Kode ini sengaja dibuat sulit dibaca
cat > "$output" << EOL
#!/bin/bash
# Protected Script - Do Not Modify

# Anti-debugging check
if [[ \$(ps -o args= -p \$\$) == *"bash -x"* || \$(ps -o args= -p \$\$) == *"sh -x"* ]]; then
    echo "Debugging is not allowed."
    exit 1
fi

# Obfuscated variables
__part1="\$encrypted_content"
__key_part="\$obfuscated_key"

# Obfuscated execution function
__run() {
    local cmd_b64="YmFzZTY0IC1k"
    local cmd_openssl="b3BlbnNzbCBlbmMgLWQgLWFlcy0yNTYtY2JjIC1wYmtkZjIgLXBhc3M="
    local cmd_bash="YmFzaA=="

    local p1=\$(echo "\$cmd_b64" | base64 -d)
    local p2=\$(echo "\$cmd_openssl" | base64 -d)
    local p3=\$(echo "\$cmd_bash" | base64 -d)

    local secret_key=\$(echo "\$__key_part" | \$p1)

    eval "echo \"\$__part1\" | \$p1 | \$p2 pass:\"\$secret_key\" | \$p3"
}

# Hide errors and run
exec 2>/dev/null
__run
EOL

# 5. Selesai
if [ $? -eq 0 ] && [ -f "$output" ]; then
    chmod +x "$output"
    echo ""
    echo -e "$sukses Script berhasil dilindungi!"
    echo -e " -> File output Anda adalah: ${W}$output${N}"
    echo -e " -> File inilah yang aman untuk Anda kirim ke pembeli."
else
    echo -e "$eror Gagal membuat script terenkripsi!"
fi
