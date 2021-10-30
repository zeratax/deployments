{
  network.description = "Matrix Server";
  cloud =
    { config, pkgs, ... }:
    { 
        deployment.targetHost = "staging.dmnd.sh";

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
          domain = config.deployment.targetHost;
        };
    };
}
