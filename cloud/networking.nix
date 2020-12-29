{ lib, ... }: {
  networking = {
    nameservers = [ "1.1.1.1" ];
    defaultGateway = "172.31.1.1";
    defaultGateway6 = "fe80::1";
    dhcpcd.enable = false;
    usePredictableInterfaceNames = lib.mkForce true;
    interfaces = {
      ens3 = {
        ipv4.addresses = [
          { address="49.12.106.164"; prefixLength=20; }
          { address="10.0.0.2"; prefixLength=16; }
        ];
        ipv6.addresses = [
          { address="2a01:4f8:c17:d8db::2"; prefixLength=64; }
        ];
        # ipv4.routes = [ { address = "172.31.1.1"; prefixLength = 32; } ];
        # ipv6.routes = [ { address = "fe80::1"; prefixLength = 32; } ];
      };      
    };
  };
}
