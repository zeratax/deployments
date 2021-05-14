{ config, lib,  pkgs, modulesPath, ... }:

{
    imports = [ (modulesPath + "/profiles/qemu-guest.nix") ];

    boot.initrd.availableKernelModules = [ "ata_piix" "virtio_pci" "xhci_pci" "sd_mod" "sr_mod" ];
    boot.initrd.kernelModules = [ ];
    boot.kernelModules = [ ];
    boot.extraModulePackages = [ ];

    boot.cleanTmpDir = true;
    boot.loader.grub.enable = true;
    boot.loader.grub.version = 2;
    boot.loader.grub.devices = [ "/dev/sda" ];

    fileSystems."/" =
    { device = "/dev/sda1";
      fsType = "ext4";
    };

    swapDevices = [ ];

    networking.useDHCP = false;
    networking.interfaces.ens10.useDHCP = true;
    networking.interfaces.ens3.useDHCP = true;
}
