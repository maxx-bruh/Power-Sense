#!/usr/bin/env bash
set -euo pipefail

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${BLUE}==>${NC} Uninstalling DMS Charging Clock Patch..."

DMS_DIR="${HOME}/repos/dux-shell"
OVERRIDE_CONF="${HOME}/.config/systemd/user/dms.service.d/override.conf"

if [ -d "${DMS_DIR}" ]; then
    echo -e "${BLUE}==>${NC} Restoring ClockContent.qml to original upstream state..."
    git -C "${DMS_DIR}" checkout quickshell/Widgets/ClockContent.qml 2>/dev/null || true
fi

if [ -f "${OVERRIDE_CONF}" ]; then
    echo -e "${BLUE}==>${NC} Removing DMS_SHELL_DIR environment variable from systemd override..."
    sed -i '/DMS_SHELL_DIR/d' "${OVERRIDE_CONF}"
    if [ ! -s "${OVERRIDE_CONF}" ] || [ "$(grep -v '^\s*$' "${OVERRIDE_CONF}" | grep -v '^\s*\[Service\]\s*$' | wc -l)" -eq 0 ]; then
        rm -f "${OVERRIDE_CONF}"
    fi
fi

systemctl --user daemon-reload
if systemctl --user is-active --quiet dms.service; then
    systemctl --user restart dms.service
fi

echo -e "${GREEN}✔ Reverted back to stock DMS clock successfully!${NC}"

