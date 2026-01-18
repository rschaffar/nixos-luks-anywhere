# Bootstrap entrypoint for nixos-anywhere
{ ... }:
{
  imports = [
    ./hetzner/configuration.nix
    ./hetzner/hardware-configuration.nix
  ];
}
