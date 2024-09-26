# see https://nixos.wiki/wiki/Install_NixOS_on_Hetzner_Cloud#Network_configuration
{...}: {
  systemd.network.enable = true;
  systemd.network.networks."10-wan" = {
    matchConfig.Name = "eth0";
    networkConfig.DHCP = "ipv4";
    address = [
      "2a01:4f8:1c1c:a1f5::/64"
    ];
    routes = [
      {routeConfig.Gateway = "fe80::1";}
    ];
  };
}
