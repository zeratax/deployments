{ pkgs, config, lib, ... }:
with lib;
let
  nur-no-pkgs = import (builtins.fetchTarball "https://github.com/nix-community/NUR/archive/master.tar.gz") {
    repoOverrides = {
      zeratax = import /home/kaine/git/nur-packages { };
    };
  };
in
{
  nixpkgs.config.packageOverrides = pkgs: rec {
    nur-pkgs = import (builtins.fetchTarball "https://github.com/nix-community/NUR/archive/master.tar.gz") {
      inherit pkgs;
      repoOverrides = {
        zeratax = import /home/kaine/git/nur-packages { };
      };
    };
    matrix-registration = nur-pkgs.repos.zeratax.matrix-registration.overrideAttrs (old: {
      src = builtins.path { path = /home/kaine/git/matrix-registration; name = "matrix-registration"; };
    });
  };
  imports = [
    nur-no-pkgs.repos.zeratax.modules.matrix-registration
  ];

  services.matrix-registration = {
    enable = true;
    settings = {
	db = "postgresql://mreguser:mregpass@localhost/mregdb";
    };
    credentialsFile = ./secrets;
  };

  services.postgresql = {
    enable = true;
    package = pkgs.postgresql_10;
    enableTCPIP = true;
    authentication = pkgs.lib.mkOverride 10 ''
      local all all trust
      host all all ::1/128 trust
    '';
    initialScript = pkgs.writeText "backend-initScript" ''
      CREATE ROLE mreguser WITH LOGIN PASSWORD 'mregpass' CREATEDB;
      CREATE DATABASE mregdb;
      GRANT ALL PRIVILEGES ON DATABASE mregdb TO mreguser;
    '';
  };


  services.matrix-synapse = {
    enable = true;

    database_type = "sqlite3";
    registration_shared_secret = "67b1c8a8-d5f3-11eb-877d-8320956c1295";

    listeners = [
      {
        port = 8008;
        bind_address = "";
        type = "http";
        tls = false;
        x_forwarded = true;
        resources = [
          {
            names = [ "client" "federation" ];
            compress = false;
          }
        ];
      }
    ];
  };
}
