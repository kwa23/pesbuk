#!/bin/bash
# ============================================================
# ACL BLOCK - PROJECT PESBUK
# File: acl/acl-block.sh
#
# Fungsi: Blokir IP tertentu secara manual di bridge pesbuk-br
# Cara pakai: sudo bash acl/acl-block.sh <IP_ADDRESS>
# Contoh    : sudo bash acl/acl-block.sh 172.19.0.3
# ============================================================

BLOCKED_LOG="$(cd "$(dirname "$0")" && pwd)/blocked.log"
BRIDGE="pesbuk-br"
IP=$1

if [ -z "$IP" ]; then
    echo "Usage: sudo bash acl-block.sh <IP_ADDRESS>"
    echo "Contoh: sudo bash acl-block.sh 172.19.0.3"
    exit 1
fi

# Validasi format IP
if ! echo "$IP" | grep -qP '^\d+\.\d+\.\d+\.\d+$'; then
    echo "[ERROR] Format IP tidak valid: $IP"
    exit 1
fi

# Cek apakah sudah diblokir
if iptables -L FORWARD -n 2>/dev/null | grep -q "$IP"; then
    echo "[INFO] IP $IP sudah diblokir di FORWARD."
else
    iptables -I FORWARD -i "$BRIDGE" -s "$IP" -j DROP
    echo "[OK] FORWARD rule ditambahkan untuk $IP"
fi

if iptables -L INPUT -n 2>/dev/null | grep -q "$IP"; then
    echo "[INFO] IP $IP sudah diblokir di INPUT."
else
    iptables -I INPUT -i "$BRIDGE" -s "$IP" -j DROP
    echo "[OK] INPUT rule ditambahkan untuk $IP"
fi

TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
echo "[$TIMESTAMP] [MANUAL BLOCK] $IP diblokir (FORWARD + INPUT)."
echo "[$TIMESTAMP] MANUAL BLOCK $IP" >> "$BLOCKED_LOG"
