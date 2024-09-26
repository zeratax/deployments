{
  pkgs,
  config,
  lib,
  ...
}: let
  nur-pkgs = import (builtins.fetchTarball
    "https://github.com/nix-community/NUR/archive/master.tar.gz") {
    inherit pkgs;
    repoOverrides =
      {}
      // lib.optionalAttrs (builtins.pathExists ~/git/nur-packages) {
        zeratax = import ~/git/nur-packages {};
      };
  };

  # plugins = config.services.bukkit-plugins.plugins;
  # dynmap-defaults = import ./plugin-settings/dynmap.nix { };
  # discordsrv-defaults = import ./plugin-settings/discordsrv.nix { };
  paper-defaults = import ./plugin-settings/paper.nix {};
  paper-tweaks-defaults = import ./plugin-settings/paper-tweaks.nix {};

  newpapermc = pkgs.papermc.overrideAttrs (old: rec {
    version = "1.21.1.99";
    src = let
      mcVersion = lib.versions.pad 3 version;
      buildNum = builtins.elemAt (lib.splitVersion version) 3;
    in
      pkgs.fetchurl {
        url = "https://api.papermc.io/v2/projects/paper/versions/${mcVersion}/builds/${buildNum}/downloads/paper-${mcVersion}-${buildNum}.jar";
        sha256 = "0z73v368ya4m9avh7jgvvxvicl278fmirs6q1wkwzc9aisk963x0";
      };
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

    # https://docs.papermc.io/paper/aikars-flags#if-you-are-using-an-xmx-value-greater-than-12g
    jvmOpts = lib.strings.concatStringsSep " " [
      "-Xms13G"
      "-Xmx13G"
      "-XX:+UseG1GC"
      "-XX:+ParallelRefProcEnabled"
      "-XX:MaxGCPauseMillis=200"
      "-XX:+UnlockExperimentalVMOptions"
      "-XX:+DisableExplicitGC"
      "-XX:+AlwaysPreTouch"
      "-XX:G1NewSizePercent=40"
      "-XX:G1MaxNewSizePercent=50"
      "-XX:G1HeapRegionSize=16M"
      "-XX:G1ReservePercent=15"
      "-XX:G1HeapWastePercent=5"
      "-XX:G1MixedGCCountTarget=4"
      "-XX:InitiatingHeapOccupancyPercent=20"
      "-XX:G1MixedGCLiveThresholdPercent=90"
      "-XX:G1RSetUpdatingPauseTimePercent=5"
      "-XX:SurvivorRatio=32"
      "-XX:+PerfDisableSharedMem"
      "-XX:MaxTenuringThreshold=1"
      "-Dusing.aikars.flags=https://mcflags.emc.gs"
      "-Daikars.new.flags=true"
    ];

    server-icon = ./server-icon.png;

    serverProperties = {
      server-name = "DIAMONDS";
      level-name = "longlegs";
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
      "rcon.password" =
        lib.removeSuffix "\n" (builtins.readFile ./rcon-password.key);
      broadcast-rcon-to-ops = true;
      broadcast-console-to-ops = true;
      op-permission-level = 4;

      view-distance = 30;
      entity-broadcast-range-percentage = 200;
      max-players = 20;
      online-mode = true;

      # resource-pack = "https://cloud.dmnd.sh/s/q3P9FwKew3QRkbJ/download?path=%2F&files=John%20Smith%20Legacy%20JSC%201.20.2%20v6.zip";
      # resource-pack-sha1 = "B04757FF80268FC144996EE16EC214FB330AE276";
      resource-pack = "https://cloud.dmnd.sh/s/q3P9FwKew3QRkbJ/download?path=%2F&files=dmnd-v1.0.zip";
      resource-pack-sha1 = "60E6E7B821BD580BA09A50C9700DA4893143E232";
      require-resource-pack = true;
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
      bluemap = {
        package = nur-pkgs.repos.zeratax.bukkitPlugins.bluemap;
        settings = {};
      };
      bluemap-marker-manager = {
        package = nur-pkgs.repos.zeratax.bukkitPlugins.bluemap-marker-manager;
        settings = {};
      };
      bluemap-offline-player-markers = {
        package =
          nur-pkgs.repos.zeratax.bukkitPlugins.bluemap-offline-player-markers;
        settings = {};
      };
      paper-tweaks = {
        package = nur-pkgs.repos.zeratax.bukkitPlugins.paper-tweaks;
        settings = {};
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
      # dynmap = {
      #   package = newdynmap; #nur-pkgs.repos.zeratax.bukkitPlugins.dynmap;
      #   settings = lib.recursiveUpdate dynmap-defaults {
      #     # overwrite defaults here
      #   };
      # };
      simple-voice-chat = {
        package = nur-pkgs.repos.zeratax.bukkitPlugins.simple-voice-chat;
        settings = {};
      };
    };
  };

  # open ports to host e.g. a dynmap
  networking.firewall = {
    allowedTCPPorts = [80 443];
    allowedUDPPorts = [
      24454
    ]; # for simple voice chat https://modrepo.de/minecraft/voicechat/wiki/server_setup_self_hosted
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
        # proxyPass = "http://localhost:${builtins.toString plugins.dynmap.settings."dynmap/configuration.txt".webserver-port}";
        proxyPass = "http://localhost:8100/";
      };
    };
  };
}
