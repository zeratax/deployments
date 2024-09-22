{
  apiToken ? "changeme",
  location ? "nbg1",
}: {
  network = {
    description = "Satisfactory Server";
    enableRollback = true;
    storage.legacy = {
      databasefile = "~/.nixops/deployments.nixops";
    };
  };

  satisfactory = {config, ...}: {
    deployment.targetEnv = "hetznercloud";
    deployment.hetznerCloud = {
      inherit apiToken location;
      serverType = "ccx12";
    };

    imports = [
      ../common/ssh.nix
      ./satisfactory.nix
      ./backup.nix
    ];

    swapDevices = [
      {
        device = "/var/lib/swapfile";
        size = 1024 * 4;
      }
    ];

    networking = {
      hostName = "sf";
      domain = config.deployment.targetHost;
    };
  };
}
