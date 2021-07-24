{
  network.description = "Matrix Server";
  cloud =
    { config, pkgs, ... }:
    { 
        deployment.targetHost = "162.55.209.118";

        imports = [
            ../providers/hetzner.nix
            ../common/ssh.nix
            ../common/lets-encrypt.nix
            ./synapse.nix 
            ./dokuwiki.nix
        ];

        networking = {
          firewall.allowedTCPPorts = [ 80 443 ];
          hostName = "matrix";
          domain = "staging.dmnd.sh";
        };
    };
}
