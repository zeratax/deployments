{ pkgs, config, lib, ... }:
let nexus = config.services.nexus;
in
{
  services.nexus.enable = true;

  services.nginx = {
    enable = true;
    recommendedProxySettings = true;
    virtualHosts."${config.networking.fqdn}" = {
      enableACME = true;
      forceSSL = true;
      locations."/" = {
        proxyPass = "http://${nexus.listenAddress}:${toString nexus.listenPort}";
        recommendedProxySettings = true;
        extraConfig = ''
          proxy_pass_header Authorization;
        '';
      };

      locations."/v2" = {
        proxyPass = "http://${nexus.listenAddress}:8013";
        recommendedProxySettings = true;
        extraConfig = ''
          proxy_pass_header Authorization;
        '';
      };
    };
  };

  environment.systemPackages = with pkgs; [
   speedtest-cli
  ];

  networking.firewall = {
    enable = true;
    allowedTCPPorts = [
      config.services.nginx.defaultSSLListenPort
      config.services.nginx.defaultHTTPListenPort
    ];
  };
}
