{
  network = {
    description = "Nexus Proxy Server";
    enableRollback = true;
    storage.legacy = {};
  };

  nexus = {...}: {
    deployment.targetHost = "nexus.dmnd.sh";
    imports = [
      ../providers/hetzner.nix
      ../common/ssh.nix
      ../common/lets-encrypt.nix
      ./networking.nix
      ./nexus.nix
    ];
    networking = {
      hostName = "nexus";
      domain = "dmnd.sh";
    };
  };
}
