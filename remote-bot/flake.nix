{
  inputs = {
    nixpkgs.url = "nixpkgs/nixos-24.05";
    flake-utils.url = "github:numtide/flake-utils";
    nixops = {
      url = "github:NixOS/nixops";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    remote-bot = {
      url = "github:zeratax/remote-bot";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = {
    nixpkgs,
    flake-utils,
    nixops,
    remote-bot,
    ...
  }:
    {
      nixopsConfigurations.default = {
        inherit nixpkgs;

        network = {
          description = "Remote Bot Server";
          enableRollback = true;
          storage.legacy = {};
        };

        remote-bot = {config, ...}: {
          nixpkgs.hostPlatform = "aarch64-linux";
          deployment.targetHost = "remote-bot.dmnd.sh";

          imports = [
            ./ssh.nix
            ./lets-encrypt.nix
            ./hetzner.nix
            ./remote-bot.nix
            remote-bot.nixosModules.default
          ];

          systemd.network.enable = true;
          systemd.network.networks."10-wan" = {
            matchConfig.Name = "eth0";
            networkConfig.DHCP = "ipv4";
            address = [
              "2a01:4f8:c0c:e5d0::/64"
            ];
            routes = [
              {routeConfig.Gateway = "fe80::1";}
            ];
          };

          networking = {
            hostName = "remote-bot";
            domain = config.deployment.targetHost;
          };
        };
      };
    }
    // flake-utils.lib.eachDefaultSystem (system: let
      pkgs = import nixpkgs {
        inherit system;
        config = {};
      };
      nixops_unstable_minimal = pkgs.nixops_unstable_minimal.overrideAttrs (finalAttrs: previousAttrs: {
        src = nixops;
      });
      nixops_with_plugins =
        nixops_unstable_minimal.withPlugins
        (ps: []);
    in {
      devShell = pkgs.mkShell {
        buildInputs = [
          nixops_with_plugins
        ];
        NIXOPS_STATE = "./statefile/deployments.nixops";
      };

      formatter = nixpkgs.legacyPackages.${system}.alejandra;
    });
}
