{
  network.description = "Matrix Server";
  cloud =
    { config, pkgs, ... }:
    { 
        deployment.targetHost = "165.227.167.178";

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
