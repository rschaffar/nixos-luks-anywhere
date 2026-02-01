# Bootstrap entrypoint for nixos-anywhere (Hetzner Dedicated)
# BIOS boot with RAID1 for both /boot and /
{ lib, ... }:
{
  imports = [
    ./hetzner/configuration.nix
    ./hetzner/hardware-configuration-dedicated.nix
  ];

  # Override hostname
  networking.hostName = lib.mkForce "hetzner-dedicated";

  # ==========================================================================
  # GRUB boot loader (BIOS mode)
  # ==========================================================================
  # Disko automatically adds devices with EF02 partitions to GRUB
  # /boot is on RAID1, so no sync needed - mdadm handles mirroring
  boot.loader.grub = {
    efiSupport = lib.mkForce false; # BIOS only, no EFI
    efiInstallAsRemovable = lib.mkForce false;
  };

  # ==========================================================================
  # Network interface names for dedicated servers
  # ==========================================================================
  # Dedicated servers often have different interface names
  # Common patterns: enp41s0, enp0s31f6, enp4s0, eno1, etc.
  systemd.network.networks."10-wan" = lib.mkForce {
    # Match any ethernet interface
    matchConfig.Type = "ether";
    networkConfig = {
      DHCP = "ipv4";
      IPv6AcceptRA = false;
    };
    dhcpV4Config = {
      UseDNS = false;
    };
  };
}
