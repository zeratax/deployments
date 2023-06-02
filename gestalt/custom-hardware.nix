{ config, lib, pkgs, ... }:
let
  nixos-unstable = import <nixos-unstable> { };
in
{
  imports = [
    <nixos-hardware/common/pc/ssd>
    <nixos-hardware/common/cpu/intel>
    <nixos-unstable/nixos/modules/hardware/video/nvidia.nix>
  ];

  disabledModules = [
    "hardware/video/nvidia.nix"
  ];

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
  hardware.nvidia.package = config.boot.kernelPackages.nvidiaPackages.beta;

  hardware.steam-hardware.enable = true;

  hardware = {
    opengl = {
      enable = true;
      driSupport = true;
      driSupport32Bit = true;
    };
  };
}
