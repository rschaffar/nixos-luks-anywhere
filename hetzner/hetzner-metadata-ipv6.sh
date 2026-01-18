#!/usr/bin/env bash
set -eu

log() { echo "hetzner-metadata-ipv6: $*" >&2; }

# Fetch metadata (retry until network is ready)
for i in 1 2 3 4 5; do
  meta="$(curl -fsS --connect-timeout 2 --max-time 5 http://169.254.169.254/hetzner/v1/metadata 2>/dev/null || true)"
  [ -n "$meta" ] && break
  sleep 1
done
if [ -z "$meta" ]; then
  log "metadata unavailable"
  exit 0
fi

# Parse IPv6 config
ipv6_cidr="$(echo "$meta" | awk '/^[[:space:]]+address: /{if ($2 ~ /:/) {print $2; exit}}')"
gw="$(echo "$meta" | awk '/^[[:space:]]+gateway: /{if ($2 ~ /:/) {print $2; exit}}')"

if [ -z "$ipv6_cidr" ] || [ -z "$gw" ]; then
  log "no IPv6 config in metadata"
  exit 0
fi

# Use first non-loopback interface
iface="$(ip -br link | awk '$1 != "lo" {print $1; exit}')"
if [ -z "$iface" ]; then
  log "no interface found"
  exit 0
fi

# Configure IPv6
log "configuring $ipv6_cidr on $iface via $gw"
ip -6 addr replace "$ipv6_cidr" dev "$iface" nodad 2>/dev/null || true
ip -6 route replace default via "$gw" dev "$iface" 2>/dev/null || true
