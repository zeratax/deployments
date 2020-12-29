{
  network.description = "Cloud Storage";
  cloud =
    { config, pkgs, ... }:
    { 
        deployment.targetHost = "49.12.106.164";

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
            domain = "cloud.dmnd.sh";
        };
    };
}
