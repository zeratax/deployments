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
  # paper-tweaks-defaults = import ./plugin-settings/paper-tweaks.nix {};
  paper-defaults = import ./plugin-settings/paper.nix {};

  newpapermc = pkgs.papermc.overrideAttrs (old: rec {
    version = "1.21.11.69";
    src = let
      mcVersion = lib.versions.pad 3 version;
      buildNum = builtins.elemAt (lib.splitVersion version) 3;
    in
      pkgs.fetchurl {
        url = "https://api.papermc.io/v2/projects/paper/versions/${mcVersion}/builds/${buildNum}/downloads/paper-${mcVersion}-${buildNum}.jar";
        sha256 = "1blgrg16yg5iwfain4vlqn8v1g3s59r7pws3ag3zq7fpz4m4ydyg";
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

    whitelist = {
      CatsCrossing = "1db3a01f-edb1-4760-b221-ce64d2645c69";
      LorgeBee = "bf552ef4-b24b-47dc-b410-7d14e60a5454";
      Cadsnaper2002 = "9d00dedf-ddff-40b3-aa5d-0a56f93bfdb3";
      zeratax = "d93bfa80-ca4d-430e-ba93-d42a48e1e124";
      PJLobsterman = "49e4dd2f-b793-49a4-b4cc-b0f18dde6c14";
      _thomas123 = "ea040fb0-bc45-4608-bd36-83c78c5dfde7";
      GRANGLES = "28a56111-c236-40f2-968a-52a49c8e06e3";
      LargestBee = "b483b602-95e3-4701-b15a-5c603da0a172";
    };

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
      # when changing this remember to also update ./backup.nix
      level-name = "La Macha";
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
      enable-status = true;
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
      # resource-pack = "https://cloud.dmnd.sh/s/q3P9FwKew3QRkbJ/download?path=%2F&files=dmnd-v1.0.zip";
      # resource-pack-sha1 = "60E6E7B821BD580BA09A50C9700DA4893143E232";
      resource-pack = "https://github.com/LunarEclipseStudios/From-The-Fog/releases/download/v1.11.2-1.21.10/From-The-Fog-Data-Resource-Pack-1.21.9-1.21.10-v1.11.2.zip";
      resource-pack-sha1 = "9p139kc2wjkzlpq3z2s3g23557314alw";
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
      voicechat-interactions-paper = {
        package = nur-pkgs.repos.zeratax.bukkitPlugins.voicechat-interactions-paper;
        settings = {};
      };
      packet-events = {
        package = nur-pkgs.repos.zeratax.bukkitPlugins.packet-events;
        settings = {};
      };
      custom-discs = {
        package = nur-pkgs.repos.zeratax.bukkitPlugins.custom-discs;
        settings = {};
      };
      simple-voice-chat = {
        package = nur-pkgs.repos.zeratax.bukkitPlugins.simple-voice-chat;
        settings = {};
      };
      vivecraft = {
        package = nur-pkgs.repos.zeratax.bukkitPlugins.vivecraft;
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
