  { pkgs, config, lib, ... }:
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
  users.users.nextcloud.group = "nextcloud";
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
      inherit calendar contacts maps previewgenerator tasks twofactor_nextcloud_notification twofactor_webauthn;
      # generate with https://github.com/NixOS/nixpkgs/tree/master/pkgs/servers/nextcloud/packages
      # checksum = pkgs.fetchNextcloudApp {
      # broken in 28, see https://github.com/westberliner/checksum/issues/86
      #   url = "https://github.com/westberliner/checksum/releases/download/v1.2.2/checksum.tar.gz";
      #   sha256 = "sha256-BOKvJEjF1dLChd9LcpfXC0enrmuL1CJW1OIGOzH2AzQ=";
      #   license = "gpl3Plus";
      # };
      # files_markdown = pkgs.fetchNextcloudApp {
      # broken in 28, https://github.com/icewind1991/files_markdown/issues/218
      #   url = "https://github.com/icewind1991/files_markdown/releases/download/v2.4.1/files_markdown-v2.4.1.tar.gz";
      #   sha256 = "0p97ha6x3czzbflavmjn4jmz3z706h5f84spg4j7dwq3nc9bqrf7";
      #   license = "agpl3Plus";
      # };
      # maps = pkgs.fetchNextcloudApp {
      #   url = "https://github.com/nextcloud/maps/releases/download/v1.1.0-2a-nightly/maps-1.1.0-2a-nightly.tar.gz";
      #   sha256 = "0517kakkk7lr7ays6rrnl276709kcm5yvkp8g6cwjnfih7pmnkn9";
      #   license = "agpl3Plus";
      # };
      # music = pkgs.fetchNextcloudApp {
      # broken in 28, see https://github.com/owncloud/music/issues/1112
      #   url = "https://github.com/owncloud/music/releases/download/v1.9.1/music_1.9.1_for_nextcloud.tar.gz";
      #   sha256 = "06w82v34csx4scl5n4k4fpdxiivrzjb3yvj3hh4bc15gdz68cis9";
      #   license = "agpl3Plus";
      # };
      news = pkgs.fetchNextcloudApp {
        url = "https://github.com/nextcloud/news/releases/download/25.0.0-alpha3/news.tar.gz";
        sha256 = "sha256-AENBJH/bEob5JQvw4WEi864mdLYJ5Mqe78HJH6ceCpI=";
        license = "agpl3Plus";
      };
      # previewgenerator = pkgs.fetchNextcloudApp {
      #   url = "https://github.com/nextcloud-releases/previewgenerator/releases/download/v5.3.0/previewgenerator-v5.3.0.tar.gz";
      #   sha256 = "0ziyl7kqgivk9xvkd12byps6bb3fvcvdgprfa9ffy1zrgpl9syhk";
      #   license = "agpl3Plus";
      # };
      twofactor_totp = pkgs.fetchNextcloudApp {
        # not available for 28 so we have to define it ourselves
        url = "https://github.com/nextcloud-releases/twofactor_totp/releases/download/v6.4.1/twofactor_totp-v6.4.1.tar.gz";
        sha256 = "189cwq78dqanqxhsl69dahdkh230zhz2r285lvf0b7pg0sxcs0yc";
        license = "agpl3Plus";
      };
      # unsplash = pkgs.fetchNextcloudApp {
      # broken in 28, see https://github.com/nextcloud/unsplash/issues/131
      #   url = "https://github.com/nextcloud/unsplash/releases/download/v2.2.1/unsplash.tar.gz";
      #   sha256 = "1ya1h4nb9cyj1hdgb5l5isx7a43a7ri92cm0h8nwih20hi6a9wzx";
      #   license = "agpl3Plus";
      # };
    };
    extraAppsEnable = true;

    package = pkgs.nextcloud28;

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
    enableJIT = true;

    package = pkgs.postgresql_16;

    # Ensure the database, user, and permissions always exist
    ensureDatabases = [ "nextcloud" ];
    ensureUsers = [
      {
        name = "nextcloud";
        ensureDBOwnership = true;
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
