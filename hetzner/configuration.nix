# NixOS configuration for Hetzner Cloud with LUKS + initrd SSH unlock
{ lib, pkgs, config, ... }:
let
  metadataIpv6Script = builtins.readFile ./hetzner-metadata-ipv6.sh;
in
{

  # ==========================================================================
  # Boot configuration
  # ==========================================================================
  boot.loader.grub = {
    efiSupport = true;
    efiInstallAsRemovable = true;
    # disko will automatically add devices with EF02 partition
  };

  # ==========================================================================
  # initrd SSH for remote LUKS unlock
  # ==========================================================================
  boot.initrd.systemd.enable = true;

  boot.initrd.network = {
    enable = true;
    ssh = {
      enable = true;
      port = 2222;
      # Generated and deployed by scripts/deploy.sh
      hostKeys = [ "/etc/secrets/initrd/ssh_host_ed25519_key" ];
      authorizedKeys = [
        "ssh-ed25519 AAAA... your-public-key-here"
      ];
    };
  };

  # Auto-prompt for LUKS passphrase on SSH login
  boot.initrd.systemd.users.root.shell = "/bin/systemd-tty-ask-password-agent";

  # Use DHCP in initrd for network (Hetzner provides DHCP)
  boot.kernelParams = [ "ip=dhcp" ];

  boot.initrd.systemd.storePaths = with pkgs; [ curl gawk iproute2 coreutils ];

  # IPv6 configuration from Hetzner metadata (initrd)
  boot.initrd.systemd.services.hetzner-metadata-ipv6 = {
    description = "Configure IPv6 from Hetzner metadata";
    wantedBy = [ "sysinit.target" ];
    after = [ "systemd-networkd.service" ];
    unitConfig.DefaultDependencies = false;
    serviceConfig.Type = "oneshot";
    path = with pkgs; [ curl gawk iproute2 coreutils ];  # coreutils for sleep
    script = metadataIpv6Script;
  };

  # ==========================================================================
  # Networking
  # ==========================================================================
  networking.hostName = "hetzner";
  networking.useDHCP = true;
  networking.enableIPv6 = true;
  networking.nameservers = [
    "185.12.64.1"        # Hetzner DNS (IPv4)
    "2a01:4ff:ff00::add:2"  # Hetzner DNS (IPv6)
  ];

  # IPv6 configuration from Hetzner metadata (runtime)
  systemd.services.hetzner-metadata-ipv6 = {
    description = "Configure IPv6 from Hetzner metadata";
    wantedBy = [ "multi-user.target" ];
    wants = [ "network-online.target" ];
    after = [ "network-online.target" ];
    serviceConfig.Type = "oneshot";
    path = with pkgs; [ curl gawk iproute2 ];
    script = metadataIpv6Script;
  };

  # ==========================================================================
  # SSH
  # ==========================================================================
  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = "prohibit-password";
      PasswordAuthentication = false;
    };
  };

  users.users.root.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAA... your-public-key-here"
  ];

  # ==========================================================================
  # Basic system
  # ==========================================================================
  time.timeZone = "UTC";

  nix.settings = {
    experimental-features = [ "nix-command" "flakes" ];
    trusted-users = [ "root" ];
  };

  environment.systemPackages = with pkgs; [
    curl
    git
    btop
    neovim
    rsync
  ];

  system.stateVersion = "25.11";
}
