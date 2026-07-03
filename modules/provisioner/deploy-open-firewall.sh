#!/bin/sh
# Disable host ufw/iptables; OCI NSG handles filtering (OpenSSH local-exec; Unix).

set -e

PRIVATE_KEY_PATH="${PRIVATE_KEY_PATH:-}"
USER="${USER:-}"
INSTANCE_IP="${INSTANCE_IP:-}"

if [ -z "$PRIVATE_KEY_PATH" ] || [ -z "$USER" ] || [ -z "$INSTANCE_IP" ]; then
  echo "Error: Required environment variables not set (PRIVATE_KEY_PATH, USER, INSTANCE_IP)"
  exit 1
fi

if ! command -v ssh >/dev/null 2>&1; then
  echo "Error: ssh not found"
  exit 1
fi

SSH_OPTS="-i $PRIVATE_KEY_PATH -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null"
TARGET="$USER@$INSTANCE_IP"

ssh $SSH_OPTS "$TARGET" "
set -e
if command -v ufw >/dev/null 2>&1 || [ -x /usr/sbin/ufw ]; then
  sudo /usr/sbin/ufw disable 2>/dev/null || true
  echo 'ufw disabled'
fi
sudo iptables -P INPUT ACCEPT 2>/dev/null || true
sudo iptables -P FORWARD ACCEPT 2>/dev/null || true
sudo iptables -F INPUT 2>/dev/null || true
sudo iptables -F FORWARD 2>/dev/null || true
echo 'Host firewall off; OCI NSG only'
"
