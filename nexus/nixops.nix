{ apiToken ? "changeme"
, location ? "nbg1" }:
{
   network = {
    description = "Nexus Proxy Server";
    enableRollback = true;
    storage.legacy = {
      databasefile = "~/.nixops/deployments.nixops";
    };
  };

  nexus =
    { config, pkgs, ... }:
    {
      deployment.targetEnv = "hetznercloud";
      deployment.hetznerCloud = {
        inherit apiToken location;
        serverType = "cx11";
      };

      imports = [
        ../common/ssh.nix
        ../common/lets-encrypt.nix
         ./nexus.nix
      ];

      networking = {
        hostName = "nexus";
        domain = "dmnd.sh";
      };
    };
}