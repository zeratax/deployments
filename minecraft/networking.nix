{ lib, ... }: {
  networking = {
    nameservers = [ "1.1.1.1" ];
    defaultGateway = "172.31.1.1";
    defaultGateway6 = "fe80::1";
    dhcpcd.enable = false;
    interfaces = {
      ens3 = {
        ipv4.addresses = [
          { address = "65.21.110.116"; prefixLength = 16; }
        ];
        ipv6.addresses = [
          { address = "2a01:4f9:c010:a60d::2"; prefixLength = 64; }
        ];
      };
    };
  };
}
