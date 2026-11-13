#!/usr/bin/env bash
set -euo pipefail

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${BLUE}==>${NC} Installing DMS Charging Clock Pill..."

# Check prerequisites
if ! command -v git &>/dev/null; then
    echo -e "${RED}Error: git is required but not installed.${NC}"
    exit 1
fi

if ! command -v systemctl &>/dev/null; then
    echo -e "${RED}Error: systemd (systemctl) is required.${NC}"
    exit 1
fi

REPOS_DIR="${HOME}/repos"
DMS_DIR="${REPOS_DIR}/dux-shell"
SYSTEMD_OVERRIDE_DIR="${HOME}/.config/systemd/user/dms.service.d"
OVERRIDE_CONF="${SYSTEMD_OVERRIDE_DIR}/override.conf"

# Determine script source directory if cloned, or prepare for curl
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" 2>/dev/null && pwd || echo "")"
PATCH_FILE="${SCRIPT_DIR}/charging-battery.patch"

# 1. Clone or update dux-shell repository
mkdir -p "${REPOS_DIR}"
if [ ! -d "${DMS_DIR}/.git" ]; then
    echo -e "${BLUE}==>${NC} Cloning dux-shell repository into ${DMS_DIR}..."
    git clone --recurse-submodules https://github.com/duxlabs-dev/dux-shell.git "${DMS_DIR}"
else
    echo -e "${BLUE}==>${NC} Found existing dux-shell repository at ${DMS_DIR}."
fi

# 2. Get patch content
TARGET_FILE="${DMS_DIR}/quickshell/Widgets/ClockContent.qml"
if [ ! -f "${TARGET_FILE}" ]; then
    echo -e "${RED}Error: Target file ${TARGET_FILE} not found.${NC}"
    exit 1
fi

echo -e "${BLUE}==>${NC} Applying charging indicator patch to ClockContent.qml..."

# Check if patch is already applied
if grep -q "phoneBattery" "${TARGET_FILE}"; then
    echo -e "${YELLOW}Notice: Patch is already applied to ClockContent.qml. Skipping patch.${NC}"
else
    if [ -f "${PATCH_FILE}" ]; then
        git -C "${DMS_DIR}" apply "${PATCH_FILE}" || git -C "${DMS_DIR}" apply --reject "${PATCH_FILE}"
    else
        # Fallback to downloading patch directly from repository if executed via curl | bash
        RAW_PATCH_URL="${RAW_PATCH_URL:-https://raw.githubusercontent.com/meet-afk/Power-up/main/charging-battery.patch}"
        curl -sSL "${RAW_PATCH_URL}" | git -C "${DMS_DIR}" apply -
    fi
    echo -e "${GREEN}==>${NC} Patch applied successfully!"
fi

# 3. Setup systemd user service override
echo -e "${BLUE}==>${NC} Configuring systemd user service override..."
mkdir -p "${SYSTEMD_OVERRIDE_DIR}"

if [ -f "${OVERRIDE_CONF}" ] && grep -q "DMS_SHELL_DIR" "${OVERRIDE_CONF}"; then
    echo -e "${YELLOW}Notice: DMS_SHELL_DIR already configured in ${OVERRIDE_CONF}.${NC}"
else
    cat <<EOF >> "${OVERRIDE_CONF}"
[Service]
Environment="DMS_SHELL_DIR=${DMS_DIR}/quickshell"
EOF
    echo -e "${GREEN}==>${NC} Added DMS_SHELL_DIR override to systemd service."
fi

# 4. Reload systemd daemon and restart DMS
echo -e "${BLUE}==>${NC} Reloading and restarting dms.service..."
systemctl --user daemon-reload
if systemctl --user is-active --quiet dms.service; then
    systemctl --user restart dms.service
    echo -e "${GREEN}==>${NC} DMS restarted successfully!"
else
    echo -e "${YELLOW}Notice: dms.service is not currently running. It will use the new patch when started.${NC}"
fi

echo ""
echo -e "${GREEN}✔ Installation completed!${NC}"
echo "Plug in your laptop to see the phone-style charging pill in action."

