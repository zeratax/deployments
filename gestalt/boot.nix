{ config, pkgs, ... }:

{
  imports = [
    ./modules/pci-passthrough.nix
    ./modules/virtualisation.nix
  ];

  pciPassthrough = {
    enable = false;
    # pciIDs = [
    #   "10de:1c07"
    #   "10de:2204"
    #   "10de:1aef"
    # ];
    user = config.users.users.jonaa.name;
  };

  virtualisation = {
    hugepages = {
      enable = true;
      defaultPageSize = "2M";
      pageSize = "2M";
      numPages = 1024;
    };
  };

  security.pam.loginLimits = [
      {domain = "*";type = "-";item = "memlock";value = "infinity";}
      # {domain = "${config.users.users.jonaa.name}";type = "-";item = "memlock";value = "infinity";}
  ];

  boot = {
    # kernelPackages = pkgs.linuxPackages_6_9;
    loader = {
      systemd-boot.enable = true;
      efi = {
        canTouchEfiVariables = true;
        efiSysMountPoint = "/boot";
      };
    };
    extraModprobeConfig =
      "options kvm_intel nested=1"; # allow nested virtualization
    supportedFilesystems = [ "ntfs" ];
  };
}
