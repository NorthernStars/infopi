#!/bin/bash
set -euo pipefail

APP_NAME="infopi"

# --- Detect target user (prefer sudo caller if present) ---
APP_USER="${SUDO_USER:-${USER}}"

# Resolve home directory reliably
HOME_DIR="$(getent passwd "${APP_USER}" | cut -d: -f6)"
if [[ -z "${HOME_DIR}" || ! -d "${HOME_DIR}" ]]; then
  echo "Error: Could not determine home directory for user '${APP_USER}'."
  exit 1
fi

APP_DIR="${HOME_DIR}/infopi"
PYTHON_BIN="$(command -v python3 || true)"
PIP_BIN="$(command -v pip3 || true)"
SERVICE_FILE="/etc/systemd/system/${APP_NAME}.service"

if [[ -z "${PYTHON_BIN}" ]]; then
  echo "Error: python3 not found. Please install it: sudo apt-get install -y python3"
  exit 1
fi

if [[ -z "${PIP_BIN}" ]]; then
  echo "Error: pip3 not found. Please install it: sudo apt-get install -y python3-pip"
  exit 1
fi

echo "[1/7] Checking app directory: ${APP_DIR}"
if [[ ! -d "${APP_DIR}" ]]; then
  echo "    Creating ${APP_DIR} (owned by ${APP_USER})"
  mkdir -p "${APP_DIR}"
  chown -R "${APP_USER}:${APP_USER}" "${APP_DIR}"
else
  echo "    OK (already exists)"
fi

echo "[2/7] Installing Python requirements (if requirements.txt exists)"
if [[ -f "${APP_DIR}/requirements.txt" ]]; then
  sudo -u "${APP_USER}" "${PIP_BIN}" install --user -r "${APP_DIR}/requirements.txt"
else
  echo "    No requirements.txt found in ${APP_DIR}, skipping."
fi

echo "[3/7] Writing systemd service to ${SERVICE_FILE}"
cat > "${SERVICE_FILE}" <<EOF
[Unit]
Description=InfoPi (Python app on tty1)
After=multi-user.target
# Ensure exclusive use of tty1:
Conflicts=getty@tty1.service

[Service]
Type=simple
User=${APP_USER}
WorkingDirectory=${APP_DIR}
Environment=PYTHONUNBUFFERED=1

# Direct output to main console:
TTYPath=/dev/tty1
StandardInput=tty
StandardOutput=tty
StandardError=tty

# Run without virtual environment:
ExecStart=${PYTHON_BIN} ${APP_DIR}/main.py

Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

echo "[4/7] Disabling login prompt on tty1 (getty@tty1) to avoid conflicts"
systemctl stop getty@tty1.service || true
systemctl disable getty@tty1.service || true
systemctl mask getty@tty1.service || true

echo "[5/7] Ensuring proper ownership for ${APP_USER}"
chown -R "${APP_USER}:${APP_USER}" "${APP_DIR}"

echo "[6/7] Enabling and starting the service"
systemctl daemon-reload
systemctl enable --now "${APP_NAME}.service"

echo "[7/7] Installation finished"
echo
echo "=== Done ✅ ==="
echo "Check service status:   sudo systemctl status ${APP_NAME}.service"
echo "View live logs:         sudo journalctl -u ${APP_NAME}.service -f"
echo
echo "Notes:"
echo "- The script runs as user '${APP_USER}', inside '${APP_DIR}',"
echo "  and writes directly to /dev/tty1 (the Pi's main screen)."
echo "- The login prompt on tty1 has been disabled (getty@tty1 is masked)."
echo "  To restore it later, run:"
echo "    sudo systemctl unmask getty@tty1.service"
echo "    sudo systemctl enable --now getty@tty1.service"

