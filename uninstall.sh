#!/bin/bash
set -euo pipefail

APP_NAME="infopi"
SERVICE_FILE="/etc/systemd/system/${APP_NAME}.service"
PURGE="${1:-}"

echo "[1/6] Checking for service file: ${SERVICE_FILE}"
if [[ ! -f "${SERVICE_FILE}" ]]; then
  echo "    Service file not found. Continuing with tty1 restore and cleanup."
fi

# Try to discover the app user and app dir from the service file (if present)
APP_USER=""
APP_DIR=""
if [[ -f "${SERVICE_FILE}" ]]; then
  APP_USER="$(awk -F= '/^User=/{print $2}' "${SERVICE_FILE}" || true)"
  if [[ -z "${APP_USER}" ]]; then
    APP_USER="${SUDO_USER:-${USER}}"
  fi
  HOME_DIR="$(getent passwd "${APP_USER}" | cut -d: -f6)"
  if [[ -n "${HOME_DIR}" ]]; then
    # Try to read WorkingDirectory from service; fall back to ~/infopi
    WD_LINE="$(awk -F= '/^WorkingDirectory=/{print $2}' "${SERVICE_FILE}" || true)"
    if [[ -n "${WD_LINE}" ]]; then
      APP_DIR="${WD_LINE}"
    else
      APP_DIR="${HOME_DIR}/infopi"
    fi
  fi
else
  APP_USER="${SUDO_USER:-${USER}}"
  HOME_DIR="$(getent passwd "${APP_USER}" | cut -d: -f6)"
  APP_DIR="${HOME_DIR}/infopi"
fi

echo "[2/6] Stopping and disabling systemd service (if present)"
if systemctl list-unit-files | grep -q "^${APP_NAME}.service"; then
  systemctl stop "${APP_NAME}.service" || true
  systemctl disable "${APP_NAME}.service" || true
else
  echo "    ${APP_NAME}.service not registered (skipping stop/disable)."
fi

echo "[3/6] Restoring login prompt on tty1"
# Unmask, enable and start getty@tty1 again
systemctl unmask getty@tty1.service || true
systemctl enable --now getty@tty1.service || true

echo "[4/6] Removing service file (if present)"
if [[ -f "${SERVICE_FILE}" ]]; then
  rm -f "${SERVICE_FILE}"
  echo "    Removed ${SERVICE_FILE}"
else
  echo "    Service file already absent."
fi

echo "[5/6] Reloading systemd daemon"
systemctl daemon-reload

echo "[6/6] Optional purge of app directory"
if [[ "${PURGE}" == "--purge" ]]; then
  if [[ -n "${APP_DIR}" && -d "${APP_DIR}" ]]; then
    echo "    Deleting app directory: ${APP_DIR}"
    rm -rf "${APP_DIR}"
  else
    echo "    App directory not found; nothing to delete."
  fi
else
  echo "    Keeping app files. To remove them as well, rerun with --purge"
fi

echo
echo "=== Uninstall complete ✅ ==="
echo "- Service removed:        ${APP_NAME}.service"
echo "- tty1 login restored:    getty@tty1.service enabled"
echo "- App directory:          ${APP_DIR:-unknown} ($( [[ "${PURGE}" == "--purge" ]] && echo "deleted" || echo "kept" ))"
echo
echo "Tip: You can clean journal logs if desired (optional):"
echo "  sudo journalctl --vacuum-time=7d"

