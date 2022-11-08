{
  network = {
    description = "Minecraft Server";
    enableRollback = true;
    storage.legacy = {};
  };
  minecraft =
    { config, pkgs, ... }:
    { 
        deployment.targetHost = "mc.dmnd.sh";

        imports = [
            ../providers/hetzner.nix
            ../common/ssh.nix
            ../common/lets-encrypt.nix
            # ./networking.nix
            ./backup.nix
            ./minecraft.nix
        ];

        networking = {
          hostName = "minecraft";
          domain = config.deployment.targetHost;
        };
    };
}
