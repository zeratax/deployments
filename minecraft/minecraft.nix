{ pkgs, config, lib, stdenv, ... }:
with lib;
let
  nur-pkgs = import (builtins.fetchTarball "https://github.com/nix-community/NUR/archive/master.tar.gz") {
    inherit pkgs;
    repoOverrides = {
      zeratax = import /home/kaine/git/nur-packages { inherit pkgs; };
    };
  };

  plugins = config.services.bukkit-plugins.plugins;

  # this seems dumb
  mcVersion = "1.16.5";
  buildNum = "488";
  jar = pkgs.fetchurl {
    url = "https://papermc.io/api/v1/paper/${mcVersion}/${buildNum}/download";
    sha256 = "07zgq6pfgwd9a9daqv1dab0q8cwgidsn6sszn7bpr37y457a4ka8";
  };
  newpapermc = pkgs.papermc.overrideAttrs (old:  {
  
    version = "${mcVersion}r${buildNum}";
    installPhase = ''
      install -Dm444 ${jar} $out/share/papermc/papermc.jar
      install -Dm555 -t $out/bin minecraft-server
    '';
  });
in {
  imports = [ nur-pkgs.repos.zeratax.modules.bukkit-plugins ];

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

  services.bukkit-plugins = {
    enable = true;
    plugins = {
      harbor = {
        package = nur-pkgs.repos.zeratax.bukkitPlugins.harbor;
        settings = {
          "Harbor/config.yml" = {
            night-skip = {
              enabled = true;
              percentage = 50;
              time-rate = 70;
              daytime-ticks = 1200;
              instant-skip = false;
              proportional-acceleration = false;
              clear-rain = true;
              clear-thunder = true;
              reset-phantom-statistic = true;
            };
            exclusions = {
              ignored-permission = true;
              exclude-adventure = true;
              exclude-creative = true;
              exclude-spectator = true;
              exclude-vanished = true;
            };
            afk-detection = {
              enabled = true;
              timeout = 15;
            };
            blacklisted-worlds = [
              "world_nether"
              "world_the_end"
            ];
            whitelist-mode = false;

            messages = {
              chat = {
                enabled = true;
                message-cooldown = 5;
                player-sleeping = "&e[player] is now sleeping ([sleeping]/[needed], [more] more needed to skip).";
                player-left-bed = "&e[player] got out of bed ([sleeping]/[needed], [more] more needed to skip).";
                night-skipping = [
                  "&eAccelerating the night."
                  "&eRapidly approaching daytime."
                ];
                night-skipped = [
                  "&eThe night has been skipped."
                  "&eAhhh, finally morning."
                  "&eArghh, it's so bright outside."
                  "&eRise and shine."
                ];
              };
              actionbar = {
                enabled = true;
                players-sleeping = "&e[sleeping] out of [needed] players are sleeping ([more] more needed to skip)";
                night-skipping = "&eEveryone is sleeping- sweet dreams!";
              };
              bossbar = {
                enabled = true;
                players-sleeping = {
                  message = "&f&l[sleeping] out of [needed] are sleeping &7&l([more] more needed)";
                  color = "BLUE";
                };
                night-skipping = {
                  message = "&f&lEveryone is sleeping. Sweet dreams!";
                  color = "GREEN";
                };
              };
              miscellaneous = {
                chat-prefix = "&8&l(&6&lHarbor&8&l)&f ";
                unrecognized-command = "Unrecognized command.";
              };
            };
            interval = 1;
            metrics = true;
            debug = false;
            version = concatStringsSep "." (
              sublist 0 2 (
                splitString "." plugins.harbor.package.version));
          };
        };
      };
      # dynmap = {
      #   package = nur-pkgs.repos.zeratax.bukkitPlugins.dynmap;
      #   settings = { };
      # };
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

