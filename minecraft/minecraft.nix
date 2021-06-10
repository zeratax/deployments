{ pkgs, config, lib, stdenv, ... }:
with lib;
let
  nur-pkgs = import (builtins.fetchTarball "https://github.com/nix-community/NUR/archive/master.tar.gz") {
    inherit pkgs;
    repoOverrides = if builtins.pathExists ~/git/nur-packages then {
      zeratax = import ~/git/nur-packages { inherit pkgs; } ;
    } else { };
  };

  plugins = config.services.bukkit-plugins.plugins;
  dynmap-defaults = import ./plugin-settings/dynmap.nix { };
  discordsrv-defaults = import ./plugin-settings/discordsrv.nix { };
  harbor-defaults = import ./plugin-settings/harbor.nix { };
  paper-defaults = import ./plugin-settings/paper.nix { };

  # this seems dumb
  mcVersion = "1.16.5";
  buildNum = "771";
  jar = pkgs.fetchurl {
    url = "https://papermc.io/api/v1/paper/${mcVersion}/${buildNum}/download";
    sha256 = "1lmlfhigbzbkgzfq6knglka0ccf4i32ch25gkny0c5fllmsnm08l";
  };
  newpapermc = pkgs.papermc.overrideAttrs (old: {
    version = "${mcVersion}r${buildNum}";
    installPhase = ''
      install -Dm444 ${jar} $out/share/papermc/papermc.jar
      install -Dm555 -t $out/bin minecraft-server
    '';
  });
in
{
  imports = [
    nur-pkgs.repos.zeratax.modules.bukkit-plugins
    nur-pkgs.repos.zeratax.modules.bukkit-server
  ];

  # open ports to host e.g. a dynmap
  networking.firewall = {
    allowedTCPPorts = [ 80 443 ];
    allowPing = true;
  };

  services.bukkit-server = {
    enable = true;
    declarative = true;
    eula = true;
    openFirewall = true;
    package = newpapermc; # unstable uses a too recent version of java

    serverProperties = {
      server-name = "DIAMONDS";
      level-name = "antarcticite";
      level-type = "default";
      motd = "a weak diamond is no diamond at all";

      gamemode = "survival";
      difficulty = "hard";
      spawn-monsters = true;
      pvp = true;
      hardcore = false;

      spawn-protection = 0;
      max-tick-time = 60000;

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
    };

    additionalSettingsFiles = {
      "paper.yml" = recursiveUpdate paper-defaults {
        settings.unsupported-settings = {
          allow-permanent-block-break-exploits = true;
          allow-piston-duplication = true;
        };
      };
    };
  };

  services.bukkit-plugins = {
    enable = true;
    plugins = {
      harbor = {
        package = nur-pkgs.repos.zeratax.bukkitPlugins.harbor;
        settings = recursiveUpdate harbor-defaults {
          # overwrite defaults here
        };
      };
      dynmap = {
        package = nur-pkgs.repos.zeratax.bukkitPlugins.dynmap;
        settings = recursiveUpdate dynmap-defaults {
          # overwrite defaults here
        };
      };
      discordsrv = {
        package = nur-pkgs.repos.zeratax.bukkitPlugins.discordsrv;
        settings = recursiveUpdate discordsrv-defaults {
          "DiscordSRV/config.yml" = {
            BotToken = builtins.readFile ./bot-token.key;
            AvatarUrl = "https://crafatar.com/renders/head/{uuid-nodashes}.png?size={size}&overlay#{texture}";
            Channels = {
              global = "189775065116573696";
            };
            DiscordCannedResponses = {
              "!ip" = "mc.dmnd.sh";
              "!site" = "http://dmnd.sh";
            };
            Experiment_WebhookChatMessageDelivery = true;
            UseModernPaperChatEvent = true;
            DiscordChatChannelRolesAllowedToUseColorCodesInChat = [
              "Gems"
            ];
            ChannelTopicUpdaterChannelTopicsAtShutdownEnabled = false;
          };
        };
      };
    };
  };

  # create a group minecraft, so that nginx can read files
  users.groups.minecraft = {
    members = [
      config.users.users.minecraft.name
      config.services.nginx.user
    ];
  };

  systemd.services.bukkit-server = {
    serviceConfig = {
      Group = config.users.groups.minecraft.name;
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

      locations."~ ^/(tiles|css|images|js)/" = {
        root = "${config.services.bukkit-plugins.pluginsDir}/dynmap/web";

        extraConfig = ''
          expires     0;
          add_header  Cache-Control private;
        '';
      };

      locations."/" = {
        proxyPass = "http://localhost:${builtins.toString plugins.dynmap.settings."dynmap/configuration.txt".webserver-port}";
      };
    };
  };
}
