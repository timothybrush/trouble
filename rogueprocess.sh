#!/bin/bash
#
# install-tmp-permissions-timer.sh
#
# Installs a systemd timer that runs every minute and sets permissions on all
# files and directories in /tmp to 777.
#
# WARNING:
# This is insecure and should only be used for demonstration purposes.
# It will remove the sticky-bit protection behavior that /tmp normally relies on.

set -euo pipefail

if [[ $EUID -ne 0 ]]; then
    echo "Run this script as root."
    exit 1
fi

SCRIPT_PATH="/usr/local/bin/tmp-permissions.sh"
SERVICE_PATH="/etc/systemd/system/tmp-permissions.service"
TIMER_PATH="/etc/systemd/system/tmp-permissions.timer"

echo "Creating $SCRIPT_PATH ..."
cat > "$SCRIPT_PATH" <<'EOF'
#!/bin/bash
# WARNING: insecure, for demo purposes only

# Set permissions of all files and directories under /tmp to 777
find /tmp -mindepth 1 -exec chmod 777 {} \;
EOF

chmod 755 "$SCRIPT_PATH"

echo "Creating $SERVICE_PATH ..."
cat > "$SERVICE_PATH" <<'EOF'
[Unit]
Description=Set permissions of all files in /tmp to 777 (demo)

[Service]
Type=oneshot
ExecStart=/usr/local/bin/tmp-permissions.sh
EOF

echo "Creating $TIMER_PATH ..."
cat > "$TIMER_PATH" <<'EOF'
[Unit]
Description=Run tmp-permissions.service every minute

[Timer]
OnBootSec=1min
OnUnitActiveSec=1min
Unit=tmp-permissions.service

[Install]
WantedBy=timers.target
EOF

echo "Reloading systemd ..."
systemctl daemon-reload

echo "Enabling and starting timer ..."
systemctl enable --now tmp-permissions.timer

echo
echo "Installation complete."
echo
echo "Check status with:"
echo "  systemctl status tmp-permissions.timer"
echo "  systemctl list-timers | grep tmp-permissions"
echo
echo "To remove it later:"
echo "  systemctl disable --now tmp-permissions.timer"
echo "  rm -f $SCRIPT_PATH $SERVICE_PATH $TIMER_PATH"
echo "  systemctl daemon-reload"
