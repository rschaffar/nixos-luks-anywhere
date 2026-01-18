# Repository Guidelines

## Project Structure

```
flake.nix                 # Flake entry (hetzner, hetzner-arm outputs)
disk-config.nix           # Disko LUKS disk layout
bootstrap.nix             # nixos-anywhere entry point
scripts/deploy.sh         # Deployment wrapper
scripts/set-ssh-key.sh    # Configure SSH key in config
secrets/initrd/           # Initrd SSH host key (generated, gitignored)

hetzner/                  # Downstream-copyable files
  configuration.nix       # Main NixOS config
  hardware-configuration.nix  # Hetzner VM hardware profile
  hetzner-metadata-ipv6.sh    # IPv6 config from Hetzner metadata
```

## Commands

```bash
# Configure SSH key
./scripts/set-ssh-key.sh "ssh-ed25519 AAAA... user@host"

# Deploy new server
./scripts/deploy.sh --target root@HOST

# Update existing server
nixos-rebuild switch --flake .#hetzner --target-host root@HOST
```

## Key Design Decisions

- **IPv6**: Auto-configured from Hetzner metadata service (169.254.169.254) at boot
- **Initrd SSH**: Port 2222, separate host key from main system
- **LUKS**: Passphrase passed via FIFO during deploy (never written to disk)
- **Downstream use**: Copy `hetzner/` directory to your flake after bootstrap

## Coding Style

- 2-space indentation
- Group config by section (boot, networking, SSH, packages)
- Use `with pkgs;` for package lists

## Security

- Don't commit secrets or LUKS passphrases
- Initrd host key is in `secrets/initrd/` (gitignored)
- SSH keys in config are authorized keys, not private keys
