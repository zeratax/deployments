{ pkgs, config, lib, stdenv, ... }:
let
  # this seems dumb
  mcVersion = "1.16.5";
  buildNum = "488";
  jar = pkgs.fetchurl {
    url = "https://papermc.io/api/v1/paper/${mcVersion}/${buildNum}/download";
    sha256 = "07zgq6pfgwd9a9daqv1dab0q8cwgidsn6sszn7bpr37y457a4ka8";
  };
  newpapermc = pkgs.papermc.overrideAttrs (old: {
    inherit mcVersion jar buildNum;
    version = "${mcVersion}r${buildNum}";
    installPhase = ''
      install -Dm444 ${jar} $out/share/papermc/papermc.jar
      install -Dm555 -t $out/bin minecraft-server
    '';
  });
in {
  # open ports to host e.g. a dynmap
  networking.firewall = {
    allowedTCPPorts = [ 80 443 ];
    allowPing = true;
  };

  services.minecraft-server = {
    enable = true;
    declarative = true;
    eula = true;
    openFirewall = true;
    package = newpapermc; # unstable uses a too recent version of java

    serverProperties = {
      spawn-protection = 0;
      max-tick-time = 60000;
      server-name = "DIAMONDS";
      gamemode = "survival";
      broadcast-console-to-ops = true;
      difficulty = "hard";
      spawn-monsters = true;
      broadcast-rcon-to-ops = true;
      op-permission-level = 4;
      pvp = true;
      level-type = "default";
      hardcore = false;
      max-players = 20;
      level-name = "antarcticite";
      view-distance = 7;
      online-mode = true;
      motd = "a weak diamond is no diamond at all";
      enable-query = true;
    };
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
    };
  };
}

