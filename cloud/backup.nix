{ pkgs, config, lib, ...}:

let
  ssh-fingerprint = "ssh-rsa AAAAB3NzaC1yc2EAAAABJQAAAQEA5K62E/ZFLEOIQmzKClxVAP5GmR+6ir+hWxPxK9XfvMZtTtCcnhXBnXNfQlSrX301INy9DiVfN+bRYHS3LU7TUfEcd6E5iwCOH6o9nRVZS7IkJDN/cw0m3co7cFeoayNZylIeACVfM7DwBjzzOXMV3T4hN5LbHkpv63CNTTTQqBaak+CZBQFmzMgIYGiEAi5a3yzZFpVh46JkaasDO2C9SfTNBIuCfaUIAbMbXb09B6FsirBdhndEI2fpT+1jYM0PUeqnxDbYuv5UDwDgKADo/HBAid1X4srJZzMjcnFjtwrazk3/DzyICnZM4R6xuw4cOYiDgfbfYsLYaT70YqFPUw== kaine@gestalt";
in {
  deployment.keys.aws-secrets.text = builtins.readFile ./aws-secrets.key;

  systemd.services.dbBackup = {
    serviceConfig = {
      EnvironmentFile = config.deployment.keys.aws-secrets.path;
      User = "postgres";
      Type = "oneshot";
    };
    script = ''
    today=$(date +"%Y%m%d")
    expire=$(date -d "06:45 today + 30 days" --utc +'%Y-%m-%dT%H:%M:%SZ')
    ${pkgs.postgresql_11}/bin/pg_dump \
      --format=c \
      -U postgres \
      -Fc nextcloud | \
    ${pkgs.age}/bin/age \
      -r "${ssh-fingerprint}" | \
    ${pkgs.awscli}/bin/aws s3 cp \
      - \
      "s3://$AWS_BACKUP_BUCKET/cloud-backup.$today.dump" \
      --expires $expire
    '';
  };

  systemd.timers.dbBackup = {
    wantedBy = [ "timers.target" ];
    partOf = [ "dbBackup.service" ];
    timerConfig.OnCalendar = "*-*-* 2:30:00";
    timerConfig.Persistent = true;
  };
}
