#!/bin/bash
# ============================================================
# ACL UNBLOCK - PROJECT PESBUK
# File: acl/acl-unblock.sh
#
# Fungsi: Hapus blokir IP tertentu dari iptables (FORWARD + INPUT)
# Cara pakai: sudo bash acl/acl-unblock.sh <IP_ADDRESS>
# Cara hapus semua: sudo bash acl/acl-unblock.sh ALL
# ============================================================

BRIDGE="pesbuk-br"
IP=$1

if [ -z "$IP" ]; then
    echo "Usage: sudo bash acl-unblock.sh <IP_ADDRESS>"
    echo "       sudo bash acl-unblock.sh ALL   (hapus semua rule)"
    exit 1
fi

# Opsi: hapus SEMUA rule ACL untuk pesbuk-br
if [ "$IP" = "ALL" ]; then
    echo "Menghapus semua ACL rule untuk $BRIDGE..."

    iptables-save | grep -- "-A FORWARD" | grep "$BRIDGE" | grep "DROP" | \
        sed 's/-A FORWARD/-D FORWARD/' | while read -r rule; do
        eval iptables "$rule" 2>/dev/null && echo "  [REMOVED FORWARD] $rule"
    done

    iptables-save | grep -- "-A INPUT" | grep "$BRIDGE" | grep "DROP" | \
        sed 's/-A INPUT/-D INPUT/' | while read -r rule; do
        eval iptables "$rule" 2>/dev/null && echo "  [REMOVED INPUT] $rule"
    done

    echo "[$(date '+%Y-%m-%d %H:%M:%S')] Semua ACL rule dihapus."
    exit 0
fi

# Hapus IP spesifik dari FORWARD
if iptables -L FORWARD -n 2>/dev/null | grep -q "$IP"; then
    iptables -D FORWARD -i "$BRIDGE" -s "$IP" -j DROP
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [UNBLOCKED FORWARD] $IP"
else
    echo "[INFO] $IP tidak ada di FORWARD chain."
fi

# Hapus IP spesifik dari INPUT
if iptables -L INPUT -n 2>/dev/null | grep -q "$IP"; then
    iptables -D INPUT -i "$BRIDGE" -s "$IP" -j DROP
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [UNBLOCKED INPUT] $IP"
else
    echo "[INFO] $IP tidak ada di INPUT chain."
fi
