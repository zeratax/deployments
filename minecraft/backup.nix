{
  pkgs,
  config,
  ...
}: let
  # nixos-unstable = import <nixos-unstable> {};
  mc-server = config.services.bukkit-server;
  mc-settings = mc-server.serverProperties;
  mc-dir = mc-server.dataDir;
  rcon = ''
    systemctl is-active --quiet bukkit-server && \
    ${pkgs.rcon}/bin/rcon --minecraft \
      -H localhost \
      -p ${builtins.toString mc-settings."rcon.port"} \
      -P ${mc-settings."rcon.password"}'';

  mcWorlds = [
    {
      name = "Miliarium";
      isDefaultLevelType = false;
    }
    {
      name = "alexandrite";
      isDefaultLevelType = true;
    }
    {
      name = "cairngorm";
      isDefaultLevelType = true;
    }
    {
      name = "cinnabar";
      isDefaultLevelType = true;
    }
    {
      name = "phosphophyllite";
      isDefaultLevelType = true;
    }
    {
      name = "redstone_logic_world";
      isDefaultLevelType = false;
    }
    {
      name = "skyrim";
      isDefaultLevelType = true;
    }
    {
      name = "longlegs";
      isDefaultLevelType = true;
    }
  ];

  makePaths = world: let
    base = ["${mc-dir}/${world.name}/"];
    extraPaths =
      if world.isDefaultLevelType
      then [
        "${mc-dir}/${world.name}_nether/"
        "${mc-dir}/${world.name}_the_end/"
      ]
      else [];
  in
    base ++ extraPaths;

  worldPaths = builtins.concatLists (builtins.map makePaths mcWorlds);
in {
  deployment.keys.aws-secrets.text = builtins.readFile ./aws-secrets.key;
  deployment.keys.restic-password.text =
    builtins.readFile ./restic-password.key;

  systemd.services.worldBackupFailure = {
    serviceConfig = {
      User = "minecraft";
      Type = "oneshot";
    };
    script = ''
      ${rcon} <<EOS
        save-on
        say ...backup failed!
      EOS
    '';
  };

  # restic seems to be broken with s3 in 23.05
  # nixpkgs.config.packageOverrides = pkgs: { restic = nixos-unstable.restic; };

  services.restic.backups = {
    mc-worlds = {
      paths =
        worldPaths
        ++ [
          "${mc-dir}/bluemap/web/assets/*.png"
          "${mc-dir}/ops.json"
          "${mc-dir}/plugins/BlueMap/"
          "${mc-dir}/plugins/PaperTweaks/sqlite.db"
          "${mc-dir}/plugins/PaperTweaks/mv.db"
        ];

      timerConfig = {
        OnCalendar = "*-*-* 3:30:00";
        Persistent = true;
      };

      repository = "s3:https://s3.amazonaws.com/dmnd-backup/mc-worlds";
      environmentFile = config.deployment.keys.aws-secrets.path;
      passwordFile = config.deployment.keys.restic-password.path;

      initialize = true;
    };
  };

  systemd.services.restic-backups-mc-worlds = {
    onFailure = ["worldBackupFailure.service"];
    preStart = ''
      ${rcon} <<EOS
        say Creating backup...
        save-all
        save-off
      EOS
    '';
    postStart = ''
      ${rcon} <<EOS
        save-on
        say ...finished backup!
      EOS
    '';
  };

  systemd.services."restoreBackup@" = {
    description = "Restore to a specific Restic Snapshot";
    conflicts = ["bukkit-server.service"];
    environment = {
      SNAPSHOT_ID = "%i";
      RESTIC_REPOSITORY = config.services.restic.backups.mc-worlds.repository;
    };
    serviceConfig = {
      EnvironmentFile = config.deployment.keys.aws-secrets.path;
      User = "minecraft";
      Type = "oneshot";
    };
    script = ''
      ${pkgs.restic}/bin/restic restore $SNAPSHOT_ID --target /
      # ${pkgs.systemd}/bin/systemctl restart bukkit-server.service
    '';
  };

  systemd.services."listBackups" = {
    description = "List all Restic Snapshots";
    environment = {
      RESTIC_REPOSITORY = config.services.restic.backups.mc-worlds.repository;
    };
    serviceConfig = {
      EnvironmentFile = config.deployment.keys.aws-secrets.path;
      User = "minecraft";
      Type = "oneshot";
    };
    script = ''
      ${pkgs.restic}/bin/restic snapshots
    '';
  };
}
