#!/usr/bin/env bash
set -euo pipefail

VM_NAME="$1"
VM_IMAGE="$2"
VM_CPUS="$3"
VM_MEMORY="$4"
HOSTONLY_IFACE="$5"
SSH_FWD_PORT="$6"

run_vboxmanage() {
  local attempts=20
  local output

  while [ $attempts -gt 0 ]; do
    if output="$(VBoxManage "$@" 2>&1)"; then
      [ -n "$output" ] && echo "$output"
      return 0
    fi

    if echo "$output" | grep -qi "already locked for a session"; then
      attempts=$((attempts - 1))
      sleep 2
      continue
    fi

    echo "$output" >&2
    return 1
  done

  echo "$output" >&2
  return 1
}

if ! VBoxManage showvminfo "$VM_NAME" >/dev/null 2>&1; then
  if [[ "$VM_IMAGE" == *.box ]]; then
    TMP_DIR="$(mktemp -d)"
    tar -xf "$VM_IMAGE" -C "$TMP_DIR"
    OVF_PATH="$(find "$TMP_DIR" -maxdepth 2 -type f -name '*.ovf' | head -n 1)"
    if [[ -z "$OVF_PATH" ]]; then
      echo "ERROR: No OVF found inside box archive: $VM_IMAGE"
      rm -rf "$TMP_DIR"
      exit 1
    fi
    run_vboxmanage import "$OVF_PATH" --vsys 0 --vmname "$VM_NAME" --cpus "$VM_CPUS" --memory "$VM_MEMORY"
    rm -rf "$TMP_DIR"
  else
    run_vboxmanage import "$VM_IMAGE" --vsys 0 --vmname "$VM_NAME" --cpus "$VM_CPUS" --memory "$VM_MEMORY"
  fi
fi

if VBoxManage list runningvms | grep -q "\"$VM_NAME\""; then
  VBoxManage controlvm "$VM_NAME" poweroff >/dev/null 2>&1 || true
  sleep 2
fi

run_vboxmanage modifyvm "$VM_NAME" --cpus "$VM_CPUS" --memory "$VM_MEMORY"
run_vboxmanage modifyvm "$VM_NAME" --nic1 nat --nictype1 82540EM --cableconnected1 on
run_vboxmanage modifyvm "$VM_NAME" --nic2 hostonly --hostonlyadapter2 "$HOSTONLY_IFACE" --nictype2 82540EM --cableconnected2 on
run_vboxmanage modifyvm "$VM_NAME" --audio none --usb off || true

run_vboxmanage modifyvm "$VM_NAME" --natpf1 delete tfssh >/dev/null 2>&1 || true
run_vboxmanage modifyvm "$VM_NAME" --natpf1 "tfssh,tcp,127.0.0.1,$SSH_FWD_PORT,,22"

if ! VBoxManage list runningvms | grep -q "\"$VM_NAME\""; then
  run_vboxmanage startvm "$VM_NAME" --type headless
fi
