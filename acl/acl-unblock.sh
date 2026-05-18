#!/bin/bash
# ============================================================
# ACL UNBLOCK - PROJECT PESBUK
# File: acl/acl-unblock.sh
#
# Fungsi: Hapus blokir IP tertentu dari iptables
# Cara pakai: sudo bash acl/acl-unblock.sh <IP_ADDRESS>
# Contoh    : sudo bash acl/acl-unblock.sh 172.19.0.3
# ============================================================

BRIDGE="pesbuk-br"
IP=$1

if [ -z "$IP" ]; then
    echo "Usage: sudo bash acl-unblock.sh <IP_ADDRESS>"
    echo "Contoh: sudo bash acl-unblock.sh 172.19.0.3"
    exit 1
fi

# Cek apakah IP memang diblokir
if ! iptables -L FORWARD -n 2>/dev/null | grep -q "$IP"; then
    echo "[INFO] IP $IP tidak ada dalam daftar blokir."
    exit 0
fi

# Hapus rule iptables
iptables -D FORWARD -i "$BRIDGE" -s "$IP" -j DROP

TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
echo "[$TIMESTAMP] [UNBLOCKED] $IP tidak lagi diblokir."
