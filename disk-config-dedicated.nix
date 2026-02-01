# Disk configuration for Hetzner Dedicated servers (BIOS boot)
# RAID1 across two NVMe drives with LUKS encryption
#
# Layout:
#   nvme0n1                              nvme1n1
#   ├─ p1: BIOS boot (1M)                ├─ p1: BIOS boot (1M)
#   ├─ p2: boot RAID member (1G)         ├─ p2: boot RAID member (1G)
#   │          └── md/boot (ext4 /boot, RAID1)
#   └─ p3: root RAID member              └─ p3: root RAID member
#              └── md/root (RAID1) → LUKS → ext4 /
{ lib, ... }:
{
  disko.devices = {
    disk = {
      # First NVMe drive
      nvme0 = {
        device = lib.mkDefault "/dev/nvme0n1";
        type = "disk";
        content = {
          type = "gpt";
          partitions = {
            # BIOS boot partition (GRUB core.img)
            boot = {
              size = "1M";
              type = "EF02";
            };
            # Boot partition (RAID1 member)
            boot-raid = {
              size = "1G";
              content = {
                type = "mdraid";
                name = "boot";
              };
            };
            # Root partition (RAID1 member)
            root-raid = {
              size = "100%";
              content = {
                type = "mdraid";
                name = "root";
              };
            };
          };
        };
      };

      # Second NVMe drive
      nvme1 = {
        device = lib.mkDefault "/dev/nvme1n1";
        type = "disk";
        content = {
          type = "gpt";
          partitions = {
            # BIOS boot partition (GRUB core.img)
            boot = {
              size = "1M";
              type = "EF02";
            };
            # Boot partition (RAID1 member)
            boot-raid = {
              size = "1G";
              content = {
                type = "mdraid";
                name = "boot";
              };
            };
            # Root partition (RAID1 member)
            root-raid = {
              size = "100%";
              content = {
                type = "mdraid";
                name = "root";
              };
            };
          };
        };
      };
    };

    # RAID arrays
    mdadm = {
      # Boot RAID1 (unencrypted, contains kernels and initrd)
      boot = {
        type = "mdadm";
        level = 1;
        # Use metadata 1.0 (at end of device) for better GRUB compatibility
        metadata = "1.0";
        content = {
          type = "filesystem";
          format = "ext4";
          mountpoint = "/boot";
          mountOptions = [ "noatime" ];
        };
      };

      # Root RAID1 (LUKS encrypted)
      root = {
        type = "mdadm";
        level = 1;
        content = {
          type = "luks";
          name = "cryptroot";
          # nixos-anywhere will prompt for password or use --disk-encryption-keys
          passwordFile = "/tmp/disk-password";
          settings = {
            allowDiscards = true;
            bypassWorkqueues = true;
          };
          # What's inside the LUKS container
          content = {
            type = "filesystem";
            format = "ext4";
            mountpoint = "/";
            mountOptions = [ "noatime" ];
          };
        };
      };
    };
  };
}
