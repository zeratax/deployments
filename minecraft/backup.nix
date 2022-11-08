{ pkgs, config, lib, ... }:
with lib;
let
  nur-pkgs = import (builtins.fetchTarball "https://github.com/nix-community/NUR/archive/master.tar.gz") {
    inherit pkgs;
    repoOverrides = {} // lib.optionalAttrs (builtins.pathExists ~/git/nur-packages) {
      zeratax = import ~/git/nur-packages {};
    };
  };

  mc-server = config.services.bukkit-server;
  mc-settings = mc-server.serverProperties;
  mc-dir = mc-server.dataDir;
  rcon = ''
    systemctl is-active --quiet bukkit-server && \
    ${pkgs.rcon}/bin/rcon --minecraft \
      -H localhost \
      -p ${builtins.toString mc-settings."rcon.port"} \
      -P ${mc-settings."rcon.password"}'';
in
{
  deployment.keys.aws-secrets.text = builtins.readFile ./aws-secrets.key;
  deployment.keys.restic-password.text = builtins.readFile ./restic-password.key;

  systemd.services.worldBackupFailure = {
    serviceConfig = {
      User = "minecraft";
      Type = "oneshot";
    };
    script = ''
      ${rcon} <<EOS
        save-on
        say ...backup restore failed!
      EOS
    '';
  };

  services.restic.backups = {
    mc-worlds = {
      paths = [
        "${mc-dir}/${mc-settings.level-name}/"
        "${mc-dir}/${mc-settings.level-name}_nether"
        "${mc-dir}/${mc-settings.level-name}_the_end"
        "${mc-dir}/phosphophyllite/"
        "${mc-dir}/phosphophyllite_nether/"
        "${mc-dir}/phosphophyllite_the_end/"
        "${mc-dir}/cinnabar/"
        "${mc-dir}/cinnabar_nether/"
        "${mc-dir}/cinnabar_the_end/"
        "${mc-dir}/redstone_logic_world/"
        "${mc-dir}/Miliarium/"
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
    onFailure = [ "worldBackupFailure.service" ];
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
    onFailure = [ "worldBackupFailure.service" ];
    conflicts = [ "bukkit-server.service" ];
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
      ${pkgs.systemd}/bin/systemctl restart bukkit-server.service
    '';

  };
}
