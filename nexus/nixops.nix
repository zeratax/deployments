{ ... }:
{
   network = {
    description = "Nexus Proxy Server";
    enableRollback = true;
    storage.legacy = {};
  };

  nexus =
    { config, pkgs, ... }:
    {
      deployment.targetHost = "nexus.dmnd.sh";

      imports = [
        ../providers/hetzner.nix
        ../common/ssh.nix
        ../common/lets-encrypt.nix
         ./nexus.nix
         ./network.nix
      ];

      networking.useNetworkd = true;

      networking.useDHCP = false;

      modules.hetzner.wan = {
        enable = true;
        macAddress = "96:00:02:3e:e9:56";
        ipAddresses = [
          "49.12.209.173/32"
          "2a01:4f8::1/64"
        ];
      };

      networking = {
        hostName = "nexus";
        domain = "dmnd.sh";
      };
    };
}