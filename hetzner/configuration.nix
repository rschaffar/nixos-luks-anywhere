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
      # Generated on first boot via system.activationScripts.generateInitrdHostKey
      hostKeys = [ "/etc/secrets/initrd/ssh_host_ed25519_key" ];
      authorizedKeys = [
        "ssh-ed25519 AAAA... your-public-key-here"
      ];
    };
  };

  # Auto-prompt for LUKS passphrase on SSH login
  boot.initrd.systemd.users.root.shell = "/bin/systemd-tty-ask-password-agent";

  # Generate initrd SSH host key on first boot (ends up in unencrypted /boot anyway)
  system.activationScripts.generateInitrdHostKey = ''
    if [[ ! -f /etc/secrets/initrd/ssh_host_ed25519_key ]]; then
      mkdir -p /etc/secrets/initrd
      ${pkgs.openssh}/bin/ssh-keygen -t ed25519 -N "" -f /etc/secrets/initrd/ssh_host_ed25519_key -q
    fi
  '';

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
  # Networking (systemd-networkd + IPv6 metadata)
  # ==========================================================================
  # Use systemd-networkd consistently (same as initrd uses for ip=dhcp).
  # This avoids route conflicts between initrd's systemd-networkd and dhcpcd.
  #
  # References:
  # - https://wiki.nixos.org/wiki/Install_NixOS_on_Hetzner_Cloud#Network_configuration
  # - https://wiki.nixos.org/wiki/Systemd/networkd
  networking.hostName = "hetzner";
  networking.useDHCP = false; # Disable dhcpcd
  networking.useNetworkd = true; # Use systemd-networkd
  networking.enableIPv6 = true;

  systemd.network = {
    enable = true;
    networks."10-wan" = {
      matchConfig.Name = "enp1s0 eth0"; # Handle both names (udev rename)
      networkConfig = {
        DHCP = "ipv4"; # IPv4 via DHCP, IPv6 via metadata script
        IPv6AcceptRA = false; # Hetzner doesn't provide RA, we use metadata
      };
      dhcpV4Config = {
        UseDNS = false; # We set DNS manually
      };
    };
  };

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
