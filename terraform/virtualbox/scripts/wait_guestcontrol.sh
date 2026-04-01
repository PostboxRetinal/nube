#!/usr/bin/env bash
set -euo pipefail

VM_NAME="$1"
SSH_USER="$2"
SSH_PASSWORD="$3"

echo "Waiting for guestcontrol on $VM_NAME..."

max_attempts=90
attempt=0

while [ $attempt -lt $max_attempts ]; do
  attempt=$((attempt + 1))

  if VBoxManage guestcontrol "$VM_NAME" run \
      --exe /usr/bin/id \
      --username "$SSH_USER" \
      --password "$SSH_PASSWORD" \
      --wait-stdout >/dev/null 2>&1; then
    echo "$VM_NAME guestcontrol is ready"
    exit 0
  fi

  sleep 4
done

echo "ERROR: Timeout waiting for guestcontrol on $VM_NAME"
exit 1
