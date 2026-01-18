#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage: deploy.sh --target root@HOST [--flake hetzner|hetzner-arm]
  --target, -t   Target host (required), e.g. root@1.2.3.4
  --flake, -f    Flake output to deploy (default: hetzner)
  --arm          Shortcut for --flake hetzner-arm
  --help, -h     Show this help
EOF
}

FLAKE="hetzner"
TARGET=""
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
INITRD_KEY="${ROOT_DIR}/secrets/initrd/ssh_host_ed25519_key"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --target|-t)
      TARGET="${2:-}"
      shift 2
      ;;
    --flake|-f)
      FLAKE="${2:-}"
      shift 2
      ;;
    --arm)
      FLAKE="hetzner-arm"
      shift
      ;;
    --help|-h)
      usage
      exit 0
      ;;
    *)
      echo "Unknown argument: $1" >&2
      usage
      exit 2
      ;;
  esac
done

if [[ -z "$TARGET" ]]; then
  echo "Missing required --target" >&2
  usage
  exit 2
fi

if [[ ! -s "$INITRD_KEY" ]]; then
  mkdir -p "$(dirname "$INITRD_KEY")"
  umask 077
  ssh-keygen -t ed25519 -N "" -f "$INITRD_KEY" >/dev/null
fi

STAGING_DIR="$(mktemp -d)"
trap 'rm -rf "$STAGING_DIR"; unset LUKS_PASSPHRASE' EXIT
mkdir -p "${STAGING_DIR}/etc/secrets/initrd"
cp -f "$INITRD_KEY" "${STAGING_DIR}/etc/secrets/initrd/ssh_host_ed25519_key"
chmod 600 "${STAGING_DIR}/etc/secrets/initrd/ssh_host_ed25519_key"

read -r -s -p "LUKS passphrase: " LUKS_PASSPHRASE
echo

nix run github:nix-community/nixos-anywhere -- \
  --flake "${ROOT_DIR}#${FLAKE}" \
  --target-host "$TARGET" \
  --extra-files "$STAGING_DIR" \
  --disk-encryption-keys /tmp/disk-password <(printf %s "$LUKS_PASSPHRASE")
