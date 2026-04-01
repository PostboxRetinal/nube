#!/usr/bin/env bash
set -euo pipefail

VM_NAME="$1"

VBoxManage controlvm "$VM_NAME" poweroff >/dev/null 2>&1 || true
VBoxManage unregistervm "$VM_NAME" --delete >/dev/null 2>&1 || true
sleep 2
