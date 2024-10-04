{
  network = {
    description = "Satisfactory Server";
    enableRollback = true;
    storage.legacy = {};
  };

  satisfactory = {config, ...}: {
    deployment.targetHost = "satisfactory.dmnd.sh";

    imports = [
      ../common/ssh.nix
      ../providers/hetzner.nix
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
      hostName = "satisfactory";
      domain = config.deployment.targetHost;
    };

    # see https://nixos.wiki/wiki/Install_NixOS_on_Hetzner_Cloud#Network_configuration
    systemd.network.enable = true;
    systemd.network.networks."10-wan" = {
      matchConfig.Name = "enp1s0";
      networkConfig.DHCP = "ipv4";
      address = [
        "2a01:4f8:1c1b:7e00::/64"
      ];
      routes = [
        {routeConfig.Gateway = "fe80::1";}
      ];
    };
  };
}
