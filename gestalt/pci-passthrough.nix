# https://gist.github.com/WhittlesJr/a6de35b995e8c14b9093c55ba41b697c
{config, pkgs, lib, ... }:

with lib;
let
  cfg = config.pciPassthrough;
in
{
  ###### interface
  options.pciPassthrough = {
    enable = mkEnableOption "PCI Passthrough";

    pciIDs = mkOption {
      description = "Comma-separated list of PCI IDs to pass-through";
      type = types.str;
    };

    libvirtUsers = mkOption {
      description = "Extra users to add to libvirtd (root is already included)";
      type = types.listOf types.str;
      default = [];
    };
  };

  ###### implementation
  config = (mkIf cfg.enable {

    boot.kernelParams = [ 
      "intel_iommu=on"
      "i915.enable_gvt=1"
      "i915.enable_guc=0"
    ];

    # These modules are required for PCI passthrough, and must come before early modesetting stuff
    boot.kernelModules = [ 
      "kvmgt"
      "mdev"
      "vfio" 
      "vfio_iommu_type1" 
      "vfio_pci" 
      "vfio_virqfd" 
    ];

    boot.extraModprobeConfig ="options vfio-pci ids=${cfg.pciIDs}";

    environment.systemPackages = with pkgs; [
      virtmanager
      qemu
      OVMF
      pciutils
    ];

    virtualisation.libvirtd.enable = true;
    virtualisation.libvirtd.qemuPackage = pkgs.qemu_kvm;

    users.groups.libvirtd.members = [ "root" ] ++ cfg.libvirtUsers;

    virtualisation.libvirtd.qemuVerbatimConfig = ''
      nvram = [
      "${pkgs.OVMF}/FV/OVMF.fd:${pkgs.OVMF}/FV/OVMF_VARS.fd"
      ]
    '';
  });
}
