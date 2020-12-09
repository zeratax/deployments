{ lib, ... }: {
  # This file was populated at runtime with the networking
  # details gathered from the active system.
  networking = {
    nameservers = [ "8.8.8.8" ];
    defaultGateway = "165.227.160.1";
    defaultGateway6 = "2a03:b0c0:3:d0::1";
    dhcpcd.enable = false;
    usePredictableInterfaceNames = lib.mkForce true;
    interfaces = {
      eth0 = {
        ipv4.addresses = [
          { address="165.227.167.178"; prefixLength=20; }
{ address="10.19.0.5"; prefixLength=16; }
        ];
        ipv6.addresses = [
          { address="2a03:b0c0:3:d0::e5c:f001"; prefixLength=64; }
{ address="fe80::2036:31ff:fe63:becf"; prefixLength=64; }
        ];
        ipv4.routes = [ { address = "165.227.160.1"; prefixLength = 32; } ];
        ipv6.routes = [ { address = "2a03:b0c0:3:d0::1"; prefixLength = 32; } ];
      };
      
    };
  };
  services.udev.extraRules = ''
    ATTR{address}=="22:36:31:63:be:cf", NAME="eth0"
    ATTR{address}=="4a:8f:56:f5:c9:41", NAME="eth1"
  '';
}
