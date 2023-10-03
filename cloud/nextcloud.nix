{ pkgs, config, lib, ... }:
let
  davfs_config_path = builtins.path { path = "davfs2/davfs2.conf"; name = "davfs_config_path"; };

in
{
  deployment.keys.storage-box-webdav-pass = {
    text = builtins.readFile ./storage-box-webdav-pass.key;
    group = "root";
    user = "root";
  };
  environment.etc."davfs2/secrets".source = config.deployment.keys.storage-box-webdav-pass.path;

  services.davfs2 = {
    enable = true;
    extraConfig = ''
      cache_size 8192
    '';
  };

  # manually setting these, so we can use them below. otherwise these are autoallocated...
  users.users.nextcloud.uid = 994; # id -u nextcloud
  users.groups.nextcloud.gid = 998; # id -g nextcloud
  fileSystems."/var/lib/nextcloud/data" = {
    device = lib.head (builtins.split " " config.deployment.keys.storage-box-webdav-pass.text);
    fsType = "davfs";
    options = [
      "gid=${toString config.users.users.nextcloud.uid}"
      "uid=${toString config.users.groups.nextcloud.gid}"
      "nofail" # if i can't boot i can't fix stuff
      "dir_mode=0770"
      "_netdev" # device requires network 
    ];
  };

  deployment.keys.nextcloud-db-pass = {
    text = builtins.readFile ./nextcloud-db-pass.key;
    user = config.users.users.nextcloud.name;
    group = config.users.groups.nextcloud.name;
  };
  deployment.keys.nextcloud-admin-pass = {
    text = builtins.readFile ./nextcloud-admin-pass.key;
    user = config.users.users.nextcloud.name;
    group = config.users.groups.nextcloud.name;
  };
  users.users.nextcloud.extraGroups = [ config.users.groups.keys.name ];

  networking.firewall = {
    allowedTCPPorts = [ 80 443 ];
    allowPing = true;
  };

  services.nextcloud = {
    enable = true;
    hostName = config.networking.domain;
    https = true;

    extraApps = with config.services.nextcloud.package.packages.apps; {
      inherit calendar files_markdown news tasks twofactor_nextcloud_notification twofactor_webauthn unsplash;
      # generate with https://github.com/NixOS/nixpkgs/tree/master/pkgs/servers/nextcloud/packages
      twofactor_totp = pkgs.fetchNextcloudApp {
        # not available for 27 so we have to define it ourselves
        url = "https://github.com/nextcloud-releases/twofactor_totp/releases/download/v6.4.1/twofactor_totp-v6.4.1.tar.gz";
        sha256 = "189cwq78dqanqxhsl69dahdkh230zhz2r285lvf0b7pg0sxcs0yc";
      };
      music = pkgs.fetchNextcloudApp {
        url = "https://github.com/owncloud/music/releases/download/v1.8.4/music_1.8.4_for_nextcloud.tar.gz";
        sha256 = "0cvmj5cnk0wfgraj11rs12g3947fi3cc92kgvf8wam939aaxg6vh";
      };
      checksum = pkgs.fetchNextcloudApp {
        url = "https://github.com/nextcloud-releases/contacts/releases/download/v5.4.0-beta2/contacts-v5.4.0-beta2.tar.gz";
        sha256 = "0ya1jr3prw7xh9s9zkhki26gbzrh5nir46g2x96vi3nqi2jwascx";
      };
      previewgenerator = pkgs.fetchNextcloudApp {
        url = "https://github.com/nextcloud-releases/previewgenerator/releases/download/v5.3.0/previewgenerator-v5.3.0.tar.gz";
        sha256 = "0ziyl7kqgivk9xvkd12byps6bb3fvcvdgprfa9ffy1zrgpl9syhk";
      };
      maps = pkgs.fetchNextcloudApp {
        url = "https://github.com/nextcloud/maps/releases/download/v1.1.0-2a-nightly/maps-1.1.0-2a-nightly.tar.gz";
        sha256 = "0517kakkk7lr7ays6rrnl276709kcm5yvkp8g6cwjnfih7pmnkn9";
      };
    };
    extraAppsEnable = true;

    package = pkgs.nextcloud27;

    maxUploadSize = "10G";

    configureRedis = true;
    config = {
      # Further forces Nextcloud to use HTTPS
      overwriteProtocol = "https";

      # Nextcloud PostegreSQL database configuration, recommended over using SQLite
      dbtype = "pgsql";
      dbuser = "nextcloud";
      dbhost = "/run/postgresql"; # nextcloud will add /.s.PGSQL.5432 by itself
      dbname = "nextcloud";
      dbpassFile = config.deployment.keys.nextcloud-db-pass.path;

      adminpassFile = config.deployment.keys.nextcloud-admin-pass.path;
      adminuser = "admin";

      defaultPhoneRegion = "DE";

    };

    poolSettings = {
      "pm" = "dynamic";
      "pm.max_children" = "64";
      "pm.start_servers" = "7";
      "pm.min_spare_servers" = "7";
      "pm.max_spare_servers" = "14";
      "pm.max_requests" = "500";
    };
  };

  services.nginx.virtualHosts."${config.networking.domain}" = {
    forceSSL = true;
    enableACME = true;
  };

  services.postgresql = {
    enable = true;

    package = pkgs.postgresql_15;

    # Ensure the database, user, and permissions always exist
    ensureDatabases = [ "nextcloud" ];
    ensureUsers = [
      {
        name = "nextcloud";
        ensurePermissions = {
          "DATABASE nextcloud" = "ALL PRIVILEGES";
          "ALL TABLES IN SCHEMA public" = "ALL PRIVILEGES";
          "SCHEMA public" = "CREATE";
        };
      }
    ];
  };

  systemd.services."nextcloud-setup" = {
    requires = [
      "postgresql.service"
      "var-lib-nextcloud-data.mount"
      "nextcloud-db-pass-key.service"
      "nextcloud-admin-pass-key.service"
    ];
    after = [
      "postgresql.service"
      "var-lib-nextcloud-data.mount"
      "nextcloud-db-pass-key.service"
      "nextcloud-admin-pass-key.service"
    ];
  };
}
