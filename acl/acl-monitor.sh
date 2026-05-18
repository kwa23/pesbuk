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

ALERT_LOG="$(cd "$(dirname "$0")" && pwd)/../snort/logs/alert.log"
BLOCKED_LOG="$(cd "$(dirname "$0")" && pwd)/blocked.log"
BRIDGE="pesbuk-br"

# Keyword yang dianggap serangan berbahaya
ATTACK_KEYWORDS="SQLi OR 1=1|SQLi ENCODED|NMAP SYN SCAN|NMAP NULL SCAN|NMAP XMAS SCAN|NMAP FIN SCAN|POSSIBLE BRUTE FORCE"

echo "=============================================="
echo " ACL Monitor - Pesbuk Security System"
echo " Memantau: $ALERT_LOG"
echo " Bridge  : $BRIDGE"
echo " Log     : $BLOCKED_LOG"
echo "=============================================="

# ------------------------------------------------------------
# PENTING: Hapus semua rule lama untuk pesbuk-br
# IP container bisa berubah setiap docker compose up/down
# Rule lama bisa memblokir container yang SALAH
# ------------------------------------------------------------
echo "[$(date '+%Y-%m-%d %H:%M:%S')] Membersihkan rule iptables lama untuk $BRIDGE..."

# Hapus dari chain FORWARD
iptables-save | grep -- "-A FORWARD" | grep "$BRIDGE" | grep "DROP" | \
    sed 's/-A FORWARD/-D FORWARD/' | while read -r rule; do
    eval iptables "$rule" 2>/dev/null && echo "  [FLUSH FORWARD] $rule"
done

# Hapus dari chain INPUT
iptables-save | grep -- "-A INPUT" | grep "$BRIDGE" | grep "DROP" | \
    sed 's/-A INPUT/-D INPUT/' | while read -r rule; do
    eval iptables "$rule" 2>/dev/null && echo "  [FLUSH INPUT] $rule"
done

echo "[$(date '+%Y-%m-%d %H:%M:%S')] Rules lama dibersihkan. ACL Monitor aktif..."
echo ""

# Pastikan file alert ada
if [ ! -f "$ALERT_LOG" ]; then
    echo "[ERROR] File alert tidak ditemukan: $ALERT_LOG"
    echo "        Pastikan container Snort sudah berjalan."
    exit 1
fi

# ------------------------------------------------------------
# Pantau alert log secara real-time
# ------------------------------------------------------------
tail -n 0 -f "$ALERT_LOG" | while read -r line; do

    # Cek apakah baris mengandung keyword serangan
    if echo "$line" | grep -qE "$ATTACK_KEYWORDS"; then

        # Ekstrak IP sumber dari format: {TCP} 172.x.x.x:PORT -> ...
        SRC_IP=$(echo "$line" | grep -oP '(?<=\{TCP\} )\d+\.\d+\.\d+\.\d+')

        if [ -z "$SRC_IP" ]; then
            continue
        fi

        # Cek apakah IP sudah diblokir di FORWARD
        ALREADY_BLOCKED=$(iptables -L FORWARD -n 2>/dev/null | grep "$SRC_IP" | grep -c "DROP")

        if [ "$ALREADY_BLOCKED" -gt 0 ]; then
            echo "[$(date '+%Y-%m-%d %H:%M:%S')] [SKIP] $SRC_IP sudah diblokir sebelumnya."
            continue
        fi

        # Blokir di FORWARD (traffic antar container)
        iptables -I FORWARD -i "$BRIDGE" -s "$SRC_IP" -j DROP

        # Blokir di INPUT (traffic dari container ke host/172.x.x.1)
        iptables -I INPUT -i "$BRIDGE" -s "$SRC_IP" -j DROP

        TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
        ALERT_MSG=$(echo "$line" | grep -oP '\[\*\*\] \[.*?\] .+? \[\*\*\]' | head -1)

        echo "[$TIMESTAMP] [BLOCKED] $SRC_IP | $ALERT_MSG"
        echo "[$TIMESTAMP] BLOCKED $SRC_IP | $ALERT_MSG" >> "$BLOCKED_LOG"
    fi
done
