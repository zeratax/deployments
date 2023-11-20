{ apiToken ? "changeme"
, location ? "nbg1"
}:
{
  network = {
    description = "Minecraft Server";
    enableRollback = true;
    storage.legacy = {
      databasefile = "~/.nixops/deployments.nixops";
    };
  };
  minecraft =
    { config, pkgs, ... }:
    {
      deployment.targetEnv = "hetznercloud";
      deployment.hetznerCloud = {
        inherit apiToken location;
        serverType = "cx21";
      };

      imports = [
        ../common/ssh.nix
        ../common/lets-encrypt.nix
        ./backup.nix
        ./minecraft.nix
      ];

      networking = {
        hostName = "minecraft";
        domain = "mc.dmnd.sh";
      };
    };
}
