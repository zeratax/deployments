{config, ...}: {
  deployment.keys.envFile.text = builtins.readFile ./environment.key;

  services.remote-bot = {
    enable = true;
    environmentFile = config.deployment.keys.envFile.path;
    settings = {
      recipient_email = "mail@zera.tax";
      sender_domain = "dmnd.sh";
      timezone = "+02:00";
    };
  };

  networking.firewall = {
    allowedTCPPorts = [80 443];
    allowPing = true;
  };

  services.nginx = {
    enable = true;
    recommendedTlsSettings = true;
    recommendedOptimisation = true;
    recommendedGzipSettings = true;
    recommendedProxySettings = true;

    virtualHosts."${config.networking.domain}" = {
      forceSSL = true;
      enableACME = true;

      locations."/" = {
        proxyPass = "http://localhost:8000/";
      };
    };
  };
}
