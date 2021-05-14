{ ... }:
{
  # probably should just use the do plugin:
  # https://releases.nixos.org/nixops/nixops-1.7/manual/manual.html#sec-deploying-to-digital-ocean
  imports = [ <nixpkgs/nixos/modules/profiles/qemu-guest.nix> ];
  boot.loader.grub.device = "/dev/vda";
  boot.cleanTmpDir = true;
  fileSystems."/" = { device = "/dev/vda1"; fsType = "ext4"; };
}
