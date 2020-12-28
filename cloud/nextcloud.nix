{ pkgs, config, lib, ...}:

let

in {
    deployment.keys.storage-box-webdav-pass.text = builtins.readFile ./storage-box-webdav-pass.key;
    environment.etc."davfs2/secrets".source = config.deployment.keys.storage-box-webdav-pass.path;

    services.davfs2.enable = true;
    
    fileSystems."/var/lib/nextcloud/data" = {
        device = lib.head (builtins.split " " config.deployment.keys.storage-box-webdav-pass.text);
        fsType = "davfs";
        options = [
            "gid=998" # id -g nextcloud
            "uid=1000" # id -u nextcloud
            "dir_mode=0770"
            "_netdev" # device requires network 
        ];
    };

    deployment.keys.nextcloud-db-pass.text = builtins.readFile ./nextcloud-db-pass.key;
    deployment.keys.nextcloud-db-pass.user = "nextcloud";
    deployment.keys.nextcloud-db-pass.group = "nextcloud";
    deployment.keys.nextcloud-admin-pass.text = builtins.readFile ./nextcloud-admin-pass.key;
    deployment.keys.nextcloud-admin-pass.user = "nextcloud";
    deployment.keys.nextcloud-admin-pass.group = "nextcloud";
    users.users.nextcloud.extraGroups = [ config.users.groups.keys.name ];


    networking.firewall = {
        allowedTCPPorts = [ 80 443 ];
        allowPing = true;
    };

    services.nextcloud = {
        enable = true;
        hostName = config.networking.domain;

        # Use HTTPS for links
        https = true;

        # home = "/var/lib/nextcloud";
        
        # Auto-update Nextcloud Apps
        autoUpdateApps.enable = true;
        # Set what time makes sense for you
        autoUpdateApps.startAt = "05:00:00";

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
        };
    };

    services.nginx.virtualHosts."${config.networking.domain}" = {
        forceSSL = true;
        enableACME = true;
    };

    services.postgresql = {
        enable = true;

        # Ensure the database, user, and permissions always exist
        ensureDatabases = [ "nextcloud" ];
        ensureUsers = [
            { 
                name = "nextcloud";
                ensurePermissions."DATABASE nextcloud" = "ALL PRIVILEGES";
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
