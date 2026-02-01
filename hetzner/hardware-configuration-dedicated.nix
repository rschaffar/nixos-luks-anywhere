# Hardware configuration for Hetzner Dedicated servers
# Bare metal with NVMe drives and software RAID
{ modulesPath, ... }:
{
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
  ];

  # Kernel modules for NVMe and RAID
  boot.initrd.availableKernelModules = [
    # NVMe support
    "nvme"
    # SATA/AHCI (some dedicated servers have SATA drives too)
    "ahci"
    "sd_mod"
    # USB (for rescue/recovery)
    "xhci_pci"
    "usbhid"
    "usb_storage"
    # Network drivers for initrd SSH unlock
    "igb" # Intel I350/I210/I211 Gigabit (common on Hetzner dedicated)
    "e1000e" # Intel PRO/1000 PCIe
    "ixgbe" # Intel 10 Gigabit
    "i40e" # Intel Ethernet Controller X710/XL710
  ];

  # Software RAID support
  boot.swraid = {
    enable = true;
    mdadmConf = ''
      MAILADDR root
    '';
  };
}
