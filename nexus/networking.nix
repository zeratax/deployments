# see https://nixos.wiki/wiki/Install_NixOS_on_Hetzner_Cloud#Network_configuration
{...}: {
  systemd.network.enable = true;
  systemd.network.networks."10-wan" = {
    matchConfig.Name = "ens3"; # either ens3 or enp1s0 depending on system, check 'ip addr'
    networkConfig.DHCP = "ipv4";
    address = [
      # replace this address with the one assigned to your instance
      "2a01:4f8:aaaa:bbbb::1/64"
    ];
    routes = [
      {routeConfig.Gateway = "fe80::1";}
    ];
  };
}
