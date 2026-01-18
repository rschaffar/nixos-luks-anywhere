#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 1 ]]; then
  echo "Usage: $0 \"ssh-ed25519 AAAA... user@host\"" >&2
  exit 1
fi

SSH_KEY="$1"
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CONFIG="${ROOT_DIR}/hetzner/configuration.nix"

if [[ ! -f "$CONFIG" ]]; then
  echo "Error: $CONFIG not found" >&2
  exit 1
fi

# Escape special characters for sed
ESCAPED_KEY=$(printf '%s\n' "$SSH_KEY" | sed 's/[&/\]/\\&/g')

sed -i "s|ssh-ed25519 AAAA\.\.\. your-public-key-here|${ESCAPED_KEY}|g" "$CONFIG"

echo "SSH key configured in $CONFIG"
