{ pkgs, config, lib, ... }:
with lib;
let
  nur-pkgs = import (builtins.fetchTarball "https://github.com/nix-community/NUR/archive/master.tar.gz") {
    inherit pkgs;
    repoOverrides = {} // optionalAttrs (builtins.pathExists ~/git/nur-packages) {
      zeratax = import ~/git/nur-packages {};
    };
  };
  pkgsUnstable = import <nixos-unstable> { };

  plugins = config.services.bukkit-plugins.plugins;
  dynmap-defaults = import ./plugin-settings/dynmap.nix { };
  discordsrv-defaults = import ./plugin-settings/discordsrv.nix { };
  harbor-defaults = import ./plugin-settings/harbor.nix { };
  paper-defaults = import ./plugin-settings/paper.nix { };

  # this seems dumb
  mcVersion = "1.18";
  buildNum = "57";
  papermcjar = pkgs.fetchurl {
    url = "https://papermc.io/api/v2/projects/paper/versions/${mcVersion}/builds/${buildNum}/downloads/paper-${mcVersion}-${buildNum}.jar";
    sha256 = "00c71fb787603ddd6244758f1be44e789baaa5bd56a9dc51dca97917f5aa164f";
  };
  newpapermc = pkgs.papermc.overrideAttrs (old: {
    version = "${mcVersion}r${buildNum}";
    installPhase = ''
      install -Dm444 ${papermcjar} $out/share/papermc/papermc.jar
      install -Dm555 -t $out/bin minecraft-server
    '';
  });
  
  dynmapjar = pkgs.fetchurl {
    url = "https://dynmap.us/builds/dynmap/Dynmap-3.3-SNAPSHOT-spigot.jar";
    sha256 = "07sj77srvlhvaag8rdnfp5hir97abssgy0xhn12sgbvw7p1lrza3";
  };
  newdynmap = nur-pkgs.repos.zeratax.bukkitPlugins.dynmap.overrideAttrs (old: rec {
    version = "3.3-beta-1";
    installPhase = ''
      mkdir -p $out
      cp ${dynmapjar} $out/dynmap.jar
    '';
  });
  discordsrvjar = pkgs.fetchurl {
    url = "https://nexus.scarsz.me/service/local/repositories/snapshots/content/com/discordsrv/discordsrv/1.24.1-SNAPSHOT/discordsrv-1.24.1-20211224.003647-46.jar";
    sha256 = "1668rly7nf8v3kfggr31hk8rfp6vf2pxq3vxcy84jzr6gqs7nsxv";
  };
  newdiscordsrv = nur-pkgs.repos.zeratax.bukkitPlugins.discordsrv.overrideAttrs (old: rec {
    version = "1.24.1-SNAPSHOT";
    installPhase = ''
      mkdir -p $out
      cp ${discordsrvjar} $out/discordsrv.jar
    '';
  });

in
{
  imports = [
    nur-pkgs.repos.zeratax.modules.bukkit-plugins
    nur-pkgs.repos.zeratax.modules.bukkit-server
    nur-pkgs.repos.zeratax.modules.dmnd-bot
  ];

  nixpkgs.config.packageOverrides = pkgs: {
    dmnd-bot = nur-pkgs.repos.zeratax.dmnd-bot.overrideAttrs (old: rec {
      preCheck = ''
        echo "creating test certs..."
        pushd spec/test_certs/
        bash create_certs.sh
        popd
        echo "done!"
      '';
    });
  };

  # open ports to host e.g. a dynmap
  networking.firewall = {
    allowedTCPPorts = [ 80 443 ];
    allowPing = true;
  };

  services.dmnd-bot = {
    enable = true;

    settings = {
      discord = {
        id = lib.toInt (builtins.readFile ./discord_id.key);
        token = lib.removeSuffix "\n" (builtins.readFile ./discord_token.key);
      };
      saucenao = {
        enabled = true;
        token = lib.removeSuffix "\n" (builtins.readFile ./saucenao.key);
      };
    };
  };

  services.bukkit-server = {
    enable = true;
    declarative = true;
    eula = true;
    openFirewall = true;
    package = newpapermc; 

    serverProperties = {
      server-name = "DIAMONDS";
      level-name = "alexandrite";
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
          "Harbor/config.yml" = {
            messages.actionbar.enabled = false;
          };
        };
      };
      dynmap = {
        package = newdynmap; #nur-pkgs.repos.zeratax.bukkitPlugins.dynmap;
        settings = recursiveUpdate dynmap-defaults {
          # overwrite defaults here
        };
      };
      discordsrv = {
        package = newdiscordsrv; #nur-pkgs.repos.zeratax.bukkitPlugins.discordsrv;
        settings = recursiveUpdate discordsrv-defaults {
          "DiscordSRV/config.yml" = {
            BotToken = builtins.readFile ./bot-token.key;
            AvatarUrl = "https://crafatar.com/renders/head/{uuid-nodashes}.png?size={size}&overlay#{texture}";
            Channels = {
              global = "901949237162541107";
            };
            DiscordCannedResponses = {
              "!ip" = config.networking.domain;
              "!site" = "http://dmnd.sh";
            };
            Experiment_WebhookChatMessageDelivery = true;
            UseModernPaperChatEvent = true;
            DiscordChatChannelRolesAllowedToUseColorCodesInChat = [
              "Gems"
            ];
            ChannelTopicUpdaterChannelTopicsAtShutdownEnabled = false;
            DiscordInviteLink = "https://discord.gg/MVYe49X";
            EnablePresenceInformation = true;
          };
        };
      };
    };
  };

  # ~~create a group minecraft, so that nginx can read files~~
  # somehow nginx can't access these files no matter what i try ;-;

  # users = {
  #   users.nginx = {
  #     extraGroups = [ config.users.groups.minecraft.name ];
  #   };
  #   groups.minecraft = {
  #     members = [
  #       config.users.users.minecraft.name
  #       config.services.nginx.user
  #     ];
  #   };
  # };

  # systemd.services.bukkit-server = {
  #   serviceConfig = {
  #     Group = config.users.groups.minecraft.name;
  #   };
  # };

  # systemd.services.nginx.serviceConfig.ReadWritePaths = [ "/var/lib/minecraft/plugins/dynmap/" ];

  services.nginx = {
    enable = true;
    recommendedTlsSettings = true;
    recommendedOptimisation = true;
    recommendedGzipSettings = true;
    recommendedProxySettings = true;

    virtualHosts."${config.networking.domain}" = {
      forceSSL = true;
      enableACME = true;

      # locations."~ ^/(tiles|css|images|js)/" = {
      #   root = "${config.services.bukkit-plugins.pluginsDir}/dynmap/web";

      #   extraConfig = ''
      #     expires     0;
      #     add_header  Cache-Control private;
      #   '';
      # };

      locations."/" = {
        proxyPass = "http://localhost:${builtins.toString plugins.dynmap.settings."dynmap/configuration.txt".webserver-port}";
      };
    };
  };
}
