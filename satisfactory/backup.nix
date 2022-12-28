{ pkgs, config, lib, ...}:

let
  saveDir = "${config.users.users.satisfactory.home}/.config/Epic/FactoryGame/Saved";
in {
  deployment.keys.aws-secrets.text = builtins.readFile ./aws-secrets.key;

  systemd.services.saveGamesBackup = {
    serviceConfig = {
      EnvironmentFile = config.deployment.keys.aws-secrets.path;
      User = "satisfactory";
      Type = "oneshot";
      WorkingDirectory = saveDir;
    };
    script = ''
      today=$(date +"%Y%m%d")
      expire=$(date -d "02:30 today + 30 days" --utc +'%Y-%m-%dT%H:%M:%SZ')

      ${pkgs.awscli}/bin/aws s3 cp --recursive \
        SaveGames/ \
        "s3://$AWS_BACKUP_BUCKET/satisfactory-savegames.$today"
    '';
  };

  systemd.timers.saveGamesBackup = {
    wantedBy = [ "timers.target" ];
    partOf = [ "saveGamesBackup.service" ];
    timerConfig.OnCalendar = "*-*-* 2:30:00";
    timerConfig.Persistent = true;
  };

  systemd.services."restoreSaveGamesBackup@" = {
    conflicts = [ "satisfactory.service" ];
    environment = {
      BACKUP_DATE = "%i";
    };
    serviceConfig = {
      EnvironmentFile = config.deployment.keys.aws-secrets.path;
      User = "satisfactory";
      Type = "oneshot";
      WorkingDirectory = saveDir;
    };
    script = ''
      ${pkgs.awscli}/bin/aws s3 cp --recursive \
        "s3://$AWS_BACKUP_BUCKET/satisfactory-savegames.$BACKUP_DATE" \
        SaveGames/ \
    '';
  };
}