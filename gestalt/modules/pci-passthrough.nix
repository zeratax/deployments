# edited from: https://gist.github.com/WhittlesJr/a6de35b995e8c14b9093c55ba41b697c
{ config, pkgs, lib, ... }:

with lib;
let cfg = config.pciPassthrough;
in {
  ###### interface
  options.pciPassthrough = {
    enable = mkEnableOption "PCI Passthrough";

    pciIDs = mkOption {
      description = "list of PCI IDs to pass-through";
      type = types.listOf types.str;
      default = [ ];
    };

    user = mkOption {
      description =
        "Extra user to add to libvirtd (root is already included)";
      type = types.str;
      default = "";
    };
  };

  ###### implementation
  config = (mkIf cfg.enable {

    boot.kernelParams =
      [ "intel_iommu=on" "i915.enable_gvt=1" "i915.enable_guc=0" ];

    # These modules are required for PCI passthrough, and must come before other gpu modules
    boot.kernelModules =
      [ "kvmgt" "mdev" "vfio" "vfio_iommu_type1" "vfio_pci" "vfio_virqfd" ];

    boot.extraModprobeConfig = lib.optionalString (cfg.pciIDs != [ ])
      "options vfio-pci ids=${lib.concatStringsSep "," cfg.pciIDs}";

    environment.systemPackages = with pkgs; [ qemu OVMF pciutils ];

    programs.virt-manager.enable = true;

    users.groups.libvirtd.members = [ "root" ]
      ++ lib.optional (cfg.user != "") cfg.user;
    # users.groups.vfio.members = [ "root" ]
    #   ++ lib.optional (cfg.user != "") cfg.user;

    systemd.tmpfiles.rules = lib.optionals (cfg.user != "") [
      # issue in systemd v254 https://github.com/systemd/systemd/issues/28588
      "z /dev/vfio/vfio 0666 - - -"

      "f /dev/shm/scream 0660 ${cfg.user} ${config.users.groups.qemu-libvirtd.name} -"
      "f /dev/shm/looking-glass 0660 ${cfg.user} ${config.users.groups.qemu-libvirtd.name} -"
    ];

    virtualisation = {
      spiceUSBRedirection.enable = true;
      libvirtd = {
        enable = true;
        qemu = {
          package = pkgs.qemu_kvm;
          verbatimConfig = ''
            nvram = [
            "${pkgs.OVMF}/FV/OVMF.fd:${pkgs.OVMF}/FV/OVMF_VARS.fd"
            ]
          '';
        };
      };
    };
  });
}
