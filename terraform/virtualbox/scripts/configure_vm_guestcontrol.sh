#!/usr/bin/env bash
set -euo pipefail

VM_NAME="$1"
SSH_USER="$2"
SSH_PASSWORD="$3"
VM_HOSTNAME="$4"
VM_IP="$5"
PUBKEY_B64="$6"

TMP_SCRIPT="$(mktemp)"

cat > "$TMP_SCRIPT" <<EOF
set -euo pipefail

cat > /tmp/01-netcfg.yaml <<NET
network:
  version: 2
  ethernets:
    enp0s3:
      dhcp4: true
    enp0s8:
      dhcp4: false
      addresses:
        - ${VM_IP}/24
      nameservers:
        addresses: [8.8.8.8, 8.8.4.4]
NET

sudo mv /tmp/01-netcfg.yaml /etc/netplan/01-netcfg.yaml
sudo netplan apply || true

mkdir -p ~/.ssh
chmod 700 ~/.ssh
printf '%s' '${PUBKEY_B64}' | base64 -d > /tmp/infra_key.pub
grep -qxF "\$(cat /tmp/infra_key.pub)" ~/.ssh/authorized_keys 2>/dev/null || cat /tmp/infra_key.pub >> ~/.ssh/authorized_keys
chmod 600 ~/.ssh/authorized_keys
rm -f /tmp/infra_key.pub

sudo hostnamectl set-hostname ${VM_HOSTNAME}
grep -qxF '127.0.0.1 ${VM_HOSTNAME}' /etc/hosts || echo '${SSH_PASSWORD}' | sudo -S bash -c "echo '127.0.0.1 ${VM_HOSTNAME}' >> /etc/hosts"
EOF

SCRIPT_B64="$(base64 -w 0 "$TMP_SCRIPT")"

VBoxManage guestcontrol "$VM_NAME" run \
  --exe /bin/bash \
  --username "$SSH_USER" \
  --password "$SSH_PASSWORD" \
  --wait-stdout \
  --wait-stderr \
  -- -lc "echo '$SCRIPT_B64' | base64 -d > /tmp/tf-configure.sh && /bin/bash /tmp/tf-configure.sh"

rm -f "$TMP_SCRIPT"

echo "$VM_NAME configured via guestcontrol"
