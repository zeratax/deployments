{
  network.description = "Matrix Server";
  cloud =
    { config, pkgs, ... }:
    { 
        deployment.targetHost = "49.12.106.164";

        imports = [
            ../providers/digitalocean.nix
            ../common/ssh.nix
            ../common/lets-encrypt.nix
            ./networking.nix # generated at runtime by nixos-infect
            ./synapse.nix 
        ];

        networking = {
          hostName = "matrix";
          domain = "staging.dmnd.sh";
        };
    };
}
