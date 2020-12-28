{ ... }:
{
  imports = [ <nixpkgs/nixos/modules/profiles/qemu-guest.nix> ];
  boot.loader.grub.device = "/dev/vda";
  boot.cleanTmpDir = true;
  fileSystems."/" = { device = "/dev/vda1"; fsType = "ext4"; };
}
