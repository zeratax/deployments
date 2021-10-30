{
  network.description = "Cloud Storage";
  cloud =
    { config, pkgs, ... }:
    { 
        deployment.targetHost = "cloud.dmnd.sh";

        imports = [
            ../providers/hetzner.nix
            ../common/ssh.nix
            ../common/lets-encrypt.nix
            # ./networking.nix
            ./backup.nix
            ./nextcloud.nix
        ];

        networking = {
            hostName = "cloud";
            domain = config.deployment.targetHost;
        };
    };
}
