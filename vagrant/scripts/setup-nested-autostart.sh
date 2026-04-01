#!/bin/bash
# =============================================================================
# Configure nested VirtualBox VM autostart on control-node boot
# =============================================================================

set -euo pipefail

echo "============================================"
echo "Configuring Nested VM Autostart"
echo "============================================"

cat > /usr/local/bin/start-nested-vms.sh <<'EOF'
#!/bin/bash
set -euo pipefail

if ! command -v VBoxManage >/dev/null 2>&1; then
  exit 0
fi

for vm in vm-haproxy vm-microservices; do
  if VBoxManage showvminfo "$vm" >/dev/null 2>&1; then
    if VBoxManage list runningvms | grep -q "\"$vm\""; then
      echo "$vm already running"
    else
      VBoxManage startvm "$vm" --type headless || true
    fi
  fi
done
EOF

chmod +x /usr/local/bin/start-nested-vms.sh

cat > /etc/systemd/system/nested-vms-autostart.service <<'EOF'
[Unit]
Description=Auto-start nested VirtualBox VMs
After=network-online.target
Wants=network-online.target

[Service]
Type=oneshot
User=vagrant
Group=vagrant
Environment=HOME=/home/vagrant
ExecStart=/usr/local/bin/start-nested-vms.sh
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable nested-vms-autostart.service
systemctl start nested-vms-autostart.service || true

echo "============================================"
echo "Nested VM Autostart Configured"
echo "============================================"
