#!/bin/bash
# ============================================================
# ACL MONITOR - PROJECT PESBUK
# File: acl/acl-monitor.sh
#
# Fungsi: Baca alert Snort secara real-time, lalu otomatis
#         blokir IP penyerang menggunakan iptables di bridge pesbuk-br
#
# Cara pakai: sudo bash acl/acl-monitor.sh
# ============================================================

ALERT_LOG="$(dirname "$0")/../snort/logs/alert.log"
BLOCKED_LOG="$(dirname "$0")/blocked.log"
BRIDGE="pesbuk-br"

# Keyword yang dianggap serangan berbahaya
ATTACK_KEYWORDS="SQLi OR 1=1|SQLi ENCODED|NMAP SYN SCAN|NMAP NULL SCAN|NMAP XMAS SCAN|NMAP FIN SCAN|POSSIBLE BRUTE FORCE"

echo "=============================================="
echo " ACL Monitor - Pesbuk Security System"
echo " Memantau: $ALERT_LOG"
echo " Bridge  : $BRIDGE"
echo " Log     : $BLOCKED_LOG"
echo "=============================================="
echo "[$(date '+%Y-%m-%d %H:%M:%S')] ACL Monitor aktif..."
echo ""

# Pastikan file log ada
if [ ! -f "$ALERT_LOG" ]; then
    echo "[ERROR] File alert tidak ditemukan: $ALERT_LOG"
    echo "        Pastikan container Snort sudah berjalan."
    exit 1
fi

# Pantau alert log secara real-time
tail -n 0 -f "$ALERT_LOG" | while read -r line; do

    # Cek apakah baris mengandung keyword serangan
    if echo "$line" | grep -qE "$ATTACK_KEYWORDS"; then

        # Ekstrak IP sumber dari format: {TCP} 172.x.x.x:PORT -> ...
        SRC_IP=$(echo "$line" | grep -oP '(?<=\{TCP\} )\d+\.\d+\.\d+\.\d+')

        if [ -z "$SRC_IP" ]; then
            continue
        fi

        # Cek apakah IP sudah diblokir sebelumnya
        if iptables -L FORWARD -n 2>/dev/null | grep -q "$SRC_IP"; then
            echo "[$(date '+%Y-%m-%d %H:%M:%S')] [SKIP] $SRC_IP sudah diblokir sebelumnya."
            continue
        fi

        # Tambahkan iptables rule untuk memblokir IP di bridge pesbuk-br
        iptables -I FORWARD -i "$BRIDGE" -s "$SRC_IP" -j DROP

        TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
        ALERT_MSG=$(echo "$line" | grep -oP '\[\*\*\] \[.*?\] .+? \[\*\*\]' | head -1)

        echo "[$TIMESTAMP] [BLOCKED] $SRC_IP | $ALERT_MSG"

        # Simpan ke log pemblokiran
        echo "[$TIMESTAMP] BLOCKED $SRC_IP | $ALERT_MSG" >> "$BLOCKED_LOG"
    fi
done
