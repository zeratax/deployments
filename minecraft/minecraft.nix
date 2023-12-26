{ pkgs, config, lib, ... }:
let
  nur-pkgs = import (builtins.fetchTarball "https://github.com/nix-community/NUR/archive/master.tar.gz") {
    inherit pkgs;
    repoOverrides = { } // lib.optionalAttrs (builtins.pathExists ~/git/nur-packages) {
      zeratax = import ~/git/nur-packages { };
    };
  };

  plugins = config.services.bukkit-plugins.plugins;
  dynmap-defaults = import ./plugin-settings/dynmap.nix { };
  # discordsrv-defaults = import ./plugin-settings/discordsrv.nix { };
  paper-defaults = import ./plugin-settings/paper.nix { };

  # this seems dumb
  mcVersion = "1.20.2";
  buildNum = "297";
  papermcjar = pkgs.fetchurl {
    url = "https://papermc.io/api/v2/projects/paper/versions/${mcVersion}/builds/${buildNum}/downloads/paper-${mcVersion}-${buildNum}.jar";
    sha256 = "sha256-2umWiyZmhwGeoitl0Y4IqjClDGNop5cGlcy+x+C7VBI=";
  };
  newpapermc = pkgs.papermc.overrideAttrs (old: {
    version = "${mcVersion}r${buildNum}";
    installPhase = ''
      install -Dm444 ${papermcjar} $out/share/papermc/papermc.jar
      install -Dm555 -t $out/bin minecraft-server
    '';
  });

  dynmapjar = pkgs.fetchurl {
    url = "https://cdn.modrinth.com/data/fRQREgAc/versions/UXqPUg7D/Dynmap-3.7-beta-2-spigot.jar";
    sha256 = "0n5cqyqryx1dak9fdd45rpdjxsgzxvndi3p17ngb0x4x0ib19vjp";
  };
  newdynmap = nur-pkgs.repos.zeratax.bukkitPlugins.dynmap.overrideAttrs (old: {
    version = "3.7-beta-2";
    installPhase = ''
      mkdir -p $out
      cp ${dynmapjar} $out/dynmap.jar
    '';
  });
in {
  imports = [
    nur-pkgs.repos.zeratax.modules.bukkit-plugins
    nur-pkgs.repos.zeratax.modules.bukkit-server
  ];
  services.bukkit-server = {
    enable = true;
    declarative = true;
    eula = true;
    openFirewall = true;
    package = newpapermc;

    server-icon = ./server-icon.png;

    serverProperties = {
      server-name = "DIAMONDS";
      level-name = "skyrim";
      level-type = "default";
      motd = "a weak diamond is no diamond at all";

      gamemode = "survival";
      difficulty = "hard";
      spawn-monsters = true;
      pvp = true;
      hardcore = false;

      spawn-protection = 0;
      max-tick-time = 60000;

      enable-command-block = true;

      enable-query = true;
      enable-rcon = true;
      "rcon.port" = 25575;
      "rcon.password" = builtins.readFile ./rcon-password.key;
      broadcast-rcon-to-ops = true;
      broadcast-console-to-ops = true;
      op-permission-level = 4;

      view-distance = 16;
      max-players = 20;
      online-mode = true;

      resource-pack = "https://cloud.dmnd.sh/s/q3P9FwKew3QRkbJ/download?path=%2F&files=John%20Smith%20Legacy%20JSC%201.20.2%20v6.zip";
      resource-pack-sha1 = "B04757FF80268FC144996EE16EC214FB330AE276";
    };

    additionalSettingsFiles = {
      "config/paper-global.yml" = lib.recursiveUpdate paper-defaults {
        unsupported-settings = {
          allow-permanent-block-break-exploits = true;
          allow-piston-duplication = true;
        };
      };
    };
  };

  services.bukkit-plugins = {
    enable = true;
    plugins = {
      dynmap = {
        package = newdynmap; #nur-pkgs.repos.zeratax.bukkitPlugins.dynmap;
        settings = lib.recursiveUpdate dynmap-defaults {
          # overwrite defaults here
        };
      };
      simple-voice-chat = {
        package = nur-pkgs.repos.zeratax.bukkitPlugins.simple-voice-chat;
        settings = { };
      };
      # discordsrv = {
      #   package = newdiscordsrv; #nur-pkgs.repos.zeratax.bukkitPlugins.discordsrv;
      #   settings = lib.recursiveUpdate discordsrv-defaults {
      #     "DiscordSRV/config.yml" = {
      #       BotToken = builtins.readFile ./bot-token.key;
      #       AvatarUrl = "https://crafatar.com/renders/head/{uuid-nodashes}.png?size={size}&overlay#{texture}";
      #       Channels = {
      #         global = "901949237162541107";
      #       };
      #       DiscordCannedResponses = {
      #         "!ip" = config.networking.domain;
      #         "!site" = "http://dmnd.sh";
      #       };
      #       Experiment_WebhookChatMessageDelivery = true;
      #       UseModernPaperChatEvent = true;
      #       DiscordChatChannelRolesAllowedToUseColorCodesInChat = [
      #         "Gems"
      #       ];
      #       ChannelTopicUpdaterChannelTopicsAtShutdownEnabled = false;
      #       DiscordInviteLink = "https://discord.gg/MVYe49X";
      #       EnablePresenceInformation = true;
      #     };
      #   };
      # };
    };
  };

  # open ports to host e.g. a dynmap
  networking.firewall = {
    allowedTCPPorts = [ 80 443 ];
    allowedUDPPorts = [ 24454 ]; # for simple voice chat https://modrepo.de/minecraft/voicechat/wiki/server_setup_self_hosted
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
        proxyPass = "http://localhost:${builtins.toString plugins.dynmap.settings."dynmap/configuration.txt".webserver-port}";
      };
    };
  };
}
