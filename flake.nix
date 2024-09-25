{
  inputs = {
    nixpkgs.url = "nixpkgs/nixos-24.05";
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
