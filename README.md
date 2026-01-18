# NixOS on Hetzner Cloud with LUKS Encryption

Deploy encrypted NixOS to Hetzner Cloud with remote LUKS unlock via SSH.

## Features

- Full disk encryption (LUKS)
- Remote unlock via SSH (port 2222 in initrd)
- IPv6 auto-configured from Hetzner metadata
- Works on x86_64 and aarch64

## Quick Start

```bash
./scripts/set-ssh-key.sh "ssh-ed25519 AAAA... user@host"
./scripts/deploy.sh --target root@YOUR_SERVER_IP
```

For ARM servers add `--arm`.

## Files

| File                                 | Purpose                            |
|--------------------------------------|------------------------------------|
| `flake.nix`                          | Flake entry (hetzner, hetzner-arm) |
| `disk-config.nix`                    | Disko LUKS layout                  |
| `bootstrap.nix`                      | nixos-anywhere entry               |
| `scripts/set-ssh-key.sh`             | Configure your SSH key             |
| `scripts/deploy.sh`                  | Deployment wrapper                 |
| **`hetzner/`**                       | **Files to copy to your flake**    |
| `hetzner/configuration.nix`          | Main NixOS config                  |
| `hetzner/hardware-configuration.nix` | Hetzner VM hardware                |
| `hetzner/hetzner-metadata-ipv6.sh`   | IPv6 config script                 |

## Setup

### 1. Add your SSH key

```bash
./scripts/set-ssh-key.sh "ssh-ed25519 AAAA... user@host"
```

### 2. Deploy

```bash
./scripts/deploy.sh --target root@YOUR_SERVER_IP
```

The script:
- Generates initrd SSH host key (if missing)
- Prompts for LUKS passphrase
- Deploys via nixos-anywhere

### 3. Unlock on boot

After reboot, SSH to port 2222 to unlock:

```bash
ssh -p 2222 root@YOUR_SERVER_IP
# Enter LUKS passphrase when prompted
```

Then connect normally on port 22.

## Updating

```bash
nixos-rebuild switch --flake .#hetzner --target-host root@YOUR_SERVER_IP
```

## IPv6

IPv6 is auto-configured from Hetzner metadata at boot (both initrd and runtime). No manual IPv6 config needed.

## Using as a Template

### Option 1: Fork this repo

1. Fork/clone this repository
2. Run `./scripts/set-ssh-key.sh "your-ssh-public-key"`
3. Deploy with `./scripts/deploy.sh`

### Option 2: Bootstrap, then integrate

Use this repo to bootstrap your server, then copy the `hetzner/` directory to your own flake:

```bash
# 1. Bootstrap with this repo
./scripts/set-ssh-key.sh "your-ssh-public-key"
./scripts/deploy.sh --target root@SERVER

# 2. Copy to your flake
cp -r hetzner/ /path/to/your/flake/

# 3. Import in your flake.nix
#    ./hetzner/configuration.nix
#    ./hetzner/hardware-configuration.nix
```

The `hetzner/` directory is self-contained - just import both `.nix` files.

## Troubleshooting

**Can't connect to port 2222:**
- Check Hetzner firewall allows port 2222 (both IPv4 and IPv6)
- Verify SSH key is correct

**Host key warning:**
```bash
ssh-keygen -R "[YOUR_SERVER_IP]:2222"
```

## Credits

This project is built on top of [nixos-anywhere](https://github.com/nix-community/nixos-anywhere) by the 
[nix-community](https://github.com/nix-community), which makes it possible to install NixOS on any machine via SSH. 
Disk partitioning is handled by [disko](https://github.com/nix-community/disko).
