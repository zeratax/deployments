{
  pkgs,
  config,
  lib,
  ...
}: {
  deployment.keys.smtp-pass = {
    text = builtins.readFile ./smtp-pass.key;
    group = config.users.groups.nextcloud.name;
    user = config.users.users.nextcloud.name;
  };
  deployment.keys.storage-box-webdav-pass = {
    text = builtins.readFile ./storage-box-webdav-pass.key;
    group = "root";
    user = "root";
  };
  environment.etc."davfs2/secrets".source = config.deployment.keys.storage-box-webdav-pass.path;

  services.davfs2 = {
    enable = true;
    settings = {
      globalSection = {
        cache_size = 16384;
      };
    };
  };

  # manually setting these, so we can use them below. otherwise these are autoallocated...
  users.users.nextcloud.group = "nextcloud";
  users.users.nextcloud.uid = 399; # id -u nextcloud
  users.groups.nextcloud.gid = 399; # id -g nextcloud
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
  users.users.nextcloud.extraGroups = [config.users.groups.keys.name];

  networking.firewall = {
    allowedTCPPorts = [80 443];
    allowPing = true;
  };

  services.nextcloud = {
    enable = true;
    hostName = config.networking.domain;
    https = true;

    extraApps = with config.services.nextcloud.package.packages.apps; {
      inherit
        calendar
        contacts
        # files_markdown
        previewgenerator
        # maps
        music
        news
        tasks
        twofactor_webauthn
        # unsplash
        ;
      # generate with https://github.com/NixOS/nixpkgs/tree/master/pkgs/servers/nextcloud/packages
      # checksum = pkgs.fetchNextcloudApp {
      # broken in 28, see https://github.com/westberliner/checksum/issues/86
      #   url = "https://github.com/westberliner/checksum/releases/download/v1.2.2/checksum.tar.gz";
      #   sha256 = "sha256-BOKvJEjF1dLChd9LcpfXC0enrmuL1CJW1OIGOzH2AzQ=";
      #   license = "gpl3Plus";
      # };
    };
    extraAppsEnable = true;

    package = pkgs.nextcloud31;

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

    phpOptions."opcache.interned_strings_buffer" = "23";

    poolSettings = {
      "pm" = "dynamic";
      "pm.max_children" = "64";
      "pm.start_servers" = "7";
      "pm.min_spare_servers" = "7";
      "pm.max_spare_servers" = "14";
      "pm.max_requests" = "500";
    };
  };

  programs.msmtp = {
    enable = true;
    accounts.default = {
      host = "smtp.zoho.com";
      from = "contact@dmnd.sh";
      user = "admin@misaki.moe";
      port = 587;
      tls = true;
      auth = true;
      passwordeval = "cat ${config.deployment.keys.smtp-pass.path}";
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
    ensureDatabases = ["nextcloud"];
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
