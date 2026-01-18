# NixOS on Hetzner Cloud with LUKS Encryption

Deploy encrypted NixOS to Hetzner Cloud using [nixos-anywhere](https://github.com/nix-community/nixos-anywhere) and [disko](https://github.com/nix-community/disko).

## Features

- Full disk encryption with LUKS
- Remote LUKS unlock via SSH (initrd)
- BIOS + EFI hybrid boot support
- Works on x86_64 and aarch64

## Prerequisites

1. A Hetzner Cloud server (any Linux, will be wiped)
2. SSH access as root
3. Nix installed on your local machine

## Setup

### 1. Add your SSH key

Edit `configuration.nix` and replace the placeholder SSH keys in TWO places:
- `boot.initrd.network.ssh.authorizedKeys`
- `users.users.root.openssh.authorizedKeys.keys`

```nix
"ssh-ed25519 AAAAC3... your-actual-key"
```

### 2. Create LUKS password file

```bash
echo "your-secure-passphrase" > /tmp/disk-password
chmod 600 /tmp/disk-password
```

### 3. Deploy

```bash
nix run github:nix-community/nixos-anywhere -- \
  --flake .#hetzner \
  --target-host root@YOUR_SERVER_IP \
  --disk-encryption-keys /tmp/disk-password /tmp/disk-password
```

For ARM servers:
```bash
nix run github:nix-community/nixos-anywhere -- \
  --flake .#hetzner-arm \
  --target-host root@YOUR_SERVER_IP \
  --disk-encryption-keys /tmp/disk-password /tmp/disk-password
```

### 4. Clean up password file

```bash
rm /tmp/disk-password
```

## After Deployment

### Unlock LUKS on boot

After the server reboots, it waits for LUKS unlock. Connect via SSH on port 2222:

```bash
ssh -p 2222 root@YOUR_SERVER_IP
```

You'll be prompted to enter the LUKS passphrase. After unlocking, the system boots normally.

### Normal SSH access

Once unlocked, connect normally:

```bash
ssh root@YOUR_SERVER_IP
```

## Updating the system

After initial deployment, use `nixos-rebuild`:

```bash
# From local machine
nixos-rebuild switch --flake .#hetzner --target-host root@YOUR_SERVER_IP

# Or SSH in and rebuild locally
ssh root@YOUR_SERVER_IP
cd /etc/nixos  # or wherever you put your config
nixos-rebuild switch --flake .#hetzner
```

## Customization

- **Disk device**: Edit `disk-config.nix` if your disk isn't `/dev/sda`
- **Hostname**: Edit `networking.hostName` in `configuration.nix`
- **Timezone**: Edit `time.timeZone` in `configuration.nix`
- **Packages**: Add to `environment.systemPackages` in `configuration.nix`

## Troubleshooting

**Can't connect to port 2222 for unlock:**
- Wait a bit longer, initrd network takes time
- Check Hetzner console for boot messages
- Verify your SSH key is correct

**Host key changed warning:**
- The initrd and main system use the same host key, but if you reinstall:
  ```bash
  ssh-keygen -R YOUR_SERVER_IP
  ssh-keygen -R "[YOUR_SERVER_IP]:2222"
  ```

**Disk device wrong:**
- Hetzner Cloud typically uses `/dev/sda`
- Check with `lsblk` in rescue mode if unsure
