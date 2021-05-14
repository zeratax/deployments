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
          { address="49.12.106.164"; prefixLength=16; }
        ];
        ipv6.addresses = [
          { address="2a01:4f8:c17:d8db::2"; prefixLength=64; }
        ];
      };
      ens10.useDHCP = true;
    };
  };
}
