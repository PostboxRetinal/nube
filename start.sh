#!/bin/bash
# Script para crear los disrectorios requeridos y reforzar los perms de la carpeta secrets
set -e

mkdir -p ./data/consul ./data/consul_secrets ./data/ftp_users
chmod 700 ./data/consul_secrets
echo "Created required dirs"
