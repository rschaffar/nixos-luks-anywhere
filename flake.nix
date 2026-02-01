{
  description = "NixOS on Hetzner Cloud with LUKS encryption";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    { nixpkgs, disko, ... }:
    {
      nixosConfigurations = {
        # x86_64 Hetzner Cloud
        hetzner = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          modules = [
            disko.nixosModules.disko
            ./disk-config.nix
            ./bootstrap.nix
          ];
        };

        # aarch64 Hetzner Cloud (ARM)
        hetzner-arm = nixpkgs.lib.nixosSystem {
          system = "aarch64-linux";
          modules = [
            disko.nixosModules.disko
            ./disk-config.nix
            ./bootstrap.nix
          ];
        };

        # x86_64 Hetzner Dedicated (bare metal with RAID1)
        hetzner-dedicated = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          modules = [
            disko.nixosModules.disko
            ./disk-config-dedicated.nix
            ./bootstrap-dedicated.nix
          ];
        };
      };
    };
}
