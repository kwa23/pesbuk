#!/bin/bash
# ============================================================
# ACL BLOCK - PROJECT PESBUK
# File: acl/acl-block.sh
#
# Fungsi: Blokir IP tertentu secara manual di bridge pesbuk-br
# Cara pakai: sudo bash acl/acl-block.sh <IP_ADDRESS>
# Contoh    : sudo bash acl/acl-block.sh 172.19.0.3
# ============================================================

BLOCKED_LOG="$(dirname "$0")/blocked.log"
BRIDGE="pesbuk-br"
IP=$1

if [ -z "$IP" ]; then
    echo "Usage: sudo bash acl-block.sh <IP_ADDRESS>"
    echo "Contoh: sudo bash acl-block.sh 172.19.0.3"
    exit 1
fi

# Validasi format IP sederhana
if ! echo "$IP" | grep -qP '^\d+\.\d+\.\d+\.\d+$'; then
    echo "[ERROR] Format IP tidak valid: $IP"
    exit 1
fi

# Cek apakah sudah diblokir
if iptables -L FORWARD -n 2>/dev/null | grep -q "$IP"; then
    echo "[INFO] IP $IP sudah diblokir sebelumnya."
    exit 0
fi

# Blokir IP
iptables -I FORWARD -i "$BRIDGE" -s "$IP" -j DROP

TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
echo "[$TIMESTAMP] [MANUAL BLOCK] $IP diblokir."
echo "[$TIMESTAMP] MANUAL BLOCK $IP" >> "$BLOCKED_LOG"
