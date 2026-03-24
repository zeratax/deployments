{
  inputs = {
    nixpkgs.url = "nixpkgs/nixos-24.11";
    flake-utils.url = "github:numtide/flake-utils";
    nixops.url = "github:NixOS/nixops";
    nixops.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = {
    nixpkgs,
    flake-utils,
    nixops,
    ...
  }:
    flake-utils.lib.eachDefaultSystem (system: let
      pkgs = import nixpkgs {
        inherit system;
        config = {
          # permittedInsecurePackages = [
          #   "python3.10-requests-2.28.2"
          #   "python3.10-cryptography-40.0.1"
          # ];
        };
      };
      nixops_unstable_minimal = pkgs.nixops_unstable_minimal.overrideAttrs (finalAttrs: previousAttrs: {
        src = nixops;
      });
      nixops_with_plugins =
        nixops_unstable_minimal.withPlugins
        (ps: []);
      strongbox = pkgs.stdenv.mkDerivation rec {
        pname = "strongbox";
        version = "2.1.0";
        src = pkgs.fetchurl {
          url = "https://github.com/uw-labs/strongbox/releases/download/v${version}/strongbox_${version}_linux_amd64";
          sha256 = "13g54jlpi134lsvx8lvznx2cpbprxip1wxcwmdans6ifsd9v0zgs";
        };
        dontUnpack = true;
        installPhase = ''
          mkdir -p $out/bin
          cp $src $out/bin/strongbox
          chmod +x $out/bin/strongbox
        '';
      };
    in {
      devShell = pkgs.mkShell {
        buildInputs = [
          nixops_with_plugins
          strongbox
          pkgs.age
        ];
        NIXOPS_STATE = "./statefile/deployments.nixops";
        shellHook = ''
          strongbox -git-config
        '';
      };

      formatter = nixpkgs.legacyPackages.${system}.alejandra;
    });
}
