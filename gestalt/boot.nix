{
  config,
  ...
}: {
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
    {
      domain = "*";
      type = "-";
      item = "memlock";
      value = "infinity";
    }
    # {domain = "${config.users.users.jonaa.name}";type = "-";item = "memlock";value = "infinity";}
  ];

  boot = {
    # fixes broken audio, see https://github.com/NixOS/nixpkgs/issues/330685#issuecomment-2259307241
    kernelPatches = [
      {
        name = "fix-1";
        patch = builtins.fetchurl {
          url = "https://git.kernel.org/pub/scm/linux/kernel/git/stable/linux.git/patch/sound/soc/soc-topology.c?id=e0e7bc2cbee93778c4ad7d9a792d425ffb5af6f7";
          sha256 = "sha256:1y5nv1vgk73aa9hkjjd94wyd4akf07jv2znhw8jw29rj25dbab0q";
        };
      }
      {
        name = "fix-2";
        patch = builtins.fetchurl {
          url = "https://git.kernel.org/pub/scm/linux/kernel/git/stable/linux.git/patch/sound/soc/soc-topology.c?id=0298f51652be47b79780833e0b63194e1231fa34";
          sha256 = "sha256:14xb6nmsyxap899mg9ck65zlbkvhyi8xkq7h8bfrv4052vi414yb";
        };
      }
    ];
    # kernelPackages = pkgs.linuxPackages_6_9;
    loader = {
      systemd-boot.enable = true;
      efi = {
        canTouchEfiVariables = true;
        efiSysMountPoint = "/boot";
      };
    };
    extraModprobeConfig = "options kvm_intel nested=1"; # allow nested virtualization
    supportedFilesystems = ["ntfs"];
  };
}
