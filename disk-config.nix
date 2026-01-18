# Disk configuration with LUKS encryption
# Compatible with both BIOS and EFI boot (Hetzner Cloud)
{ lib, ... }:
{
  disko.devices = {
    disk.main = {
      device = lib.mkDefault "/dev/sda";
      type = "disk";
      content = {
        type = "gpt";
        partitions = {
          # BIOS boot partition (for legacy boot compatibility)
          boot = {
            size = "1M";
            type = "EF02";
          };
          # EFI System Partition
          esp = {
            size = "512M";
            type = "EF00";
            content = {
              type = "filesystem";
              format = "vfat";
              mountpoint = "/boot";
              mountOptions = [ "umask=0077" ];
            };
          };
          # LUKS encrypted root partition
          luks = {
            size = "100%";
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
    };
  };
}
