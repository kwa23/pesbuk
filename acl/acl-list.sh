#!/bin/bash
# ============================================================
# ACL LIST - PROJECT PESBUK
# File: acl/acl-list.sh
#
# Fungsi: Tampilkan semua IP yang sedang diblokir di bridge pesbuk-br
# Cara pakai: sudo bash acl/acl-list.sh
# ============================================================

BLOCKED_LOG="$(dirname "$0")/blocked.log"
BRIDGE="pesbuk-br"

echo "=============================================="
echo " ACL Status - Pesbuk Security System"
echo "=============================================="
echo ""

echo "--- IP yang sedang DIBLOKIR (iptables aktif) ---"
RULES=$(iptables -L FORWARD -n --line-numbers 2>/dev/null | grep "$BRIDGE" | grep "DROP")

if [ -z "$RULES" ]; then
    echo "  (tidak ada IP yang diblokir saat ini)"
else
    echo "$RULES"
fi

echo ""
echo "--- Riwayat Pemblokiran (blocked.log) ---"
if [ -f "$BLOCKED_LOG" ]; then
    cat "$BLOCKED_LOG"
else
    echo "  (belum ada riwayat)"
fi
echo ""
echo "=============================================="
