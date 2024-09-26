{
  network = {
    description = "Minecraft Server";
    enableRollback = true;
    storage.legacy = {};
  };
  minecraft = {config, ...}: {
    deployment.targetHost = "mc.dmnd.sh";
    nixpkgs.hostPlatform = "aarch64-linux";

    imports = [
      ../providers/hetzner.nix
      ../common/ssh.nix
      ../common/lets-encrypt.nix
      ./networking.nix
      ./backup.nix
      ./minecraft.nix
    ];

    networking = {
      hostName = "minecraft";
      domain = config.deployment.targetHost;
    };
  };
}
