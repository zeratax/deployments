{ pkgs, config, lib, ...}:

let
  ssh-fingerprint = builtins.readFile ./id_ed25519.pub;
  postgres-user = config.users.users.postgres.name;
in {
  deployment.keys.aws-secrets.text = builtins.readFile ./aws-secrets.key;
  deployment.keys.ssh-key = {
    text = builtins.readFile ./id_ed25519.key;
    # user = postgres-user;
    # group = postgres-group;
    # permissions = "0644";
  };

  systemd.services.dbBackup = {
    serviceConfig = {
      EnvironmentFile = config.deployment.keys.aws-secrets.path;
      User = postgres-user;
      Type = "oneshot";
    };
    script = ''
    today=$(date +"%Y%m%d")
    expire=$(date -d "02:30 today + 90 days" --utc +'%Y-%m-%dT%H:%M:%SZ')
    ${config.services.postgresql.package}/bin/pg_dump \
      -U postgres \
      -Fc nextcloud | \
    ${pkgs.age}/bin/age \
      -r "${ssh-fingerprint}" | \
    ${pkgs.awscli}/bin/aws s3 cp \
      - \
      "s3://$AWS_BACKUP_BUCKET/cloud-backup.$today.dump"
    '';
  };

  systemd.timers.dbBackup = {
    wantedBy = [ "timers.target" ];
    partOf = [ "dbBackup.service" ];
    timerConfig.OnCalendar = "*-*-* 2:30:00";
    timerConfig.Persistent = true;
  };

  systemd.services."restoreDbBackup@" = {
    environment = {
      BACKUP_DATE = "%i";
    };
    serviceConfig = {
      EnvironmentFile = config.deployment.keys.aws-secrets.path;
      User = "root"; # i assume i did this because of permission issues, but should be investigated more
      Type = "oneshot";
    };
    script = ''
      ${pkgs.awscli}/bin/aws s3 cp \
        "s3://$AWS_BACKUP_BUCKET/cloud-backup.$BACKUP_DATE.dump" \
        - | \
      ${pkgs.age}/bin/age \
        --decrypt \
        -i "${config.deployment.keys.ssh-key.path}" | \
      ${config.services.postgresql.package}/bin/pg_restore \
        -U postgres \
        --clean \
        --dbname nextcloud
    '';
  };
}
