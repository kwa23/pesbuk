#!/bin/bash
# ============================================================
# SWITCH RULES - PROJECT PESBUK
# File: snort/switch-rules.sh
#
# Fungsi: Ganti mode Snort antara LOCAL rules dan COMMUNITY rules
# Cara pakai:
#   sudo bash ~/pesbuk/snort/switch-rules.sh local       → pakai local.rules (default)
#   sudo bash ~/pesbuk/snort/switch-rules.sh community   → pakai community.rules
# ============================================================

MODE=$1
SNORT_CONF="$(cd "$(dirname "$0")" && pwd)/snort.conf"

if [ -z "$MODE" ]; then
    echo "Usage: sudo bash switch-rules.sh [local|community]"
    echo ""
    echo "  local      → Gunakan rule buatan sendiri (local.rules)"
    echo "  community  → Gunakan community rules dari Sourcefire"
    exit 1
fi

if [ ! -f "$SNORT_CONF" ]; then
    echo "[ERROR] File tidak ditemukan: $SNORT_CONF"
    exit 1
fi

case "$MODE" in
    local)
        # Aktifkan local.rules, nonaktifkan community.rules
        sed -i \
            -e 's|^# include /etc/snort/rules/local\.rules|include /etc/snort/rules/local.rules|' \
            -e 's|^include /etc/snort/rules/community\.rules|# include /etc/snort/rules/community.rules|' \
            "$SNORT_CONF"
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] MODE: LOCAL RULES"
        echo "  ✓ local.rules AKTIF"
        echo "  ✗ community.rules nonaktif"
        ;;
    community)
        # Aktifkan community.rules, nonaktifkan local.rules
        sed -i \
            -e 's|^include /etc/snort/rules/local\.rules|# include /etc/snort/rules/local.rules|' \
            -e 's|^# include /etc/snort/rules/community\.rules|include /etc/snort/rules/community.rules|' \
            "$SNORT_CONF"
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] MODE: COMMUNITY RULES"
        echo "  ✗ local.rules nonaktif"
        echo "  ✓ community.rules AKTIF"
        ;;
    *)
        echo "[ERROR] Mode tidak dikenal: $MODE"
        echo "Gunakan: local atau community"
        exit 1
        ;;
esac

echo ""
echo "Restart container Snort agar perubahan berlaku:"
echo "  sudo docker compose restart snort"
echo "  sudo docker logs pesbuk-snort_101032330051"
