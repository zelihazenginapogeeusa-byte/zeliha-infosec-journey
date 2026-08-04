#!/usr/bin/env bash
#
# install-splunk-enterprise.sh
# Sample script that automates installing Splunk Enterprise on Ubuntu Server.
#
# Usage:
#   1. Download the Splunk Enterprise .deb package from
#      https://www.splunk.com/en_us/download/splunk-enterprise.html
#      (the free lab/educational tier is fine) and place it next to this script.
#   2. chmod +x install-splunk-enterprise.sh
#   3. sudo ./install-splunk-enterprise.sh <splunk-package-file.deb>
#
set -euo pipefail

if [ "$EUID" -ne 0 ]; then
  echo "This script must be run as root/sudo." >&2
  exit 1
fi

DEB_FILE="${1:-}"

if [ -z "$DEB_FILE" ] || [ ! -f "$DEB_FILE" ]; then
  echo "Usage: sudo ./install-splunk-enterprise.sh <splunk-package-file.deb>" >&2
  exit 1
fi

echo "[1/5] Updating system packages..."
apt-get update -y

echo "[2/5] Installing Splunk Enterprise: $DEB_FILE"
dpkg -i "$DEB_FILE"

echo "[3/5] Starting Splunk and accepting the license..."
/opt/splunk/bin/splunk start --accept-license --answer-yes --no-prompt

echo "[4/5] Enabling Splunk boot-start..."
/opt/splunk/bin/splunk enable boot-start

echo "[5/5] Installation complete."
echo ""
echo "Splunk Web UI: http://<this-server-ip>:8000"
echo "You'll be prompted to change the default admin password on first login."
