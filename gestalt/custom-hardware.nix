{ config, lib, ... }:
# let
#   nixos-unstable = import <nixos-unstable> { };
# in
{
  imports = [
    <nixos-hardware/common/pc/ssd>
    # <nixos-hardware/common/cpu/intel> # enables igpu
    # <nixos-unstable/nixos/modules/hardware/video/nvidia.nix>
  ];

  # disabledModules = [
  #   "hardware/video/nvidia.nix"
  # ];

  nixpkgs.overlays = [
#     (self: super:
#     {
#       linuxPackages_latest = super.linuxPackages_latest.extend (linuxSelf: linuxSuper:
#       let
#         generic = args: linuxSelf.callPackage (import <nixos-unstable/pkgs/os-specific/linux/nvidia-x11/generic.nix> args) { };
#       in
#       {
#         nvidiaPackages.stable = generic {
#           version = "470.63.01";
#           sha256_64bit = "sha256:057dsc0j3136r5gc08id3rwz9c0x7i01xkcwfk77vqic9b6486kg";
#           settingsSha256 = "sha256:0lizp4hn49yvca2yd76yh3awld98pkaa35a067lpcld35vb5brgv";
#           persistencedSha256 = "sha256:1f3gdpa23ipjy2xwf7qnxmw7w8xxhqy25rmcz34xkngjf4fn4pbs";
#         };
#       });
#     })
  ];

  services.xserver.videoDrivers = [ "nvidia" ];

  hardware.nvidia = {
    # package = config.boot.kernelPackages.nvidiaPackages.latest;
    package = config.boot.kernelPackages.nvidiaPackages.mkDriver {
      version = "555.58.02";
      sha256_64bit = "sha256-xctt4TPRlOJ6r5S54h5W6PT6/3Zy2R4ASNFPu8TSHKM=";
      sha256_aarch64 = "sha256-xctt4TPRlOJ6r5S54h5W6PT6/3Zy2R4ASNFPu8TSHKM=";
      openSha256 = "sha256-ZpuVZybW6CFN/gz9rx+UJvQ715FZnAOYfHn5jt5Z2C8=";
      settingsSha256 = "sha256-ZpuVZybW6CFN/gz9rx+UJvQ715FZnAOYfHn5jt5Z2C8=";
      persistencedSha256 = lib.fakeSha256;
    };
    powerManagement.enable = false;
    powerManagement.finegrained = false;
    open = false;
    nvidiaSettings = true;
    modesetting.enable = true;
  };

  hardware.steam-hardware.enable = true;

  hardware = {
    opengl = {
      enable = true;
      driSupport = true;
      driSupport32Bit = true;
    };
  };
}
