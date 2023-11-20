{
  inputs = {
    nixpkgs.url = "nixpkgs/nixos-23.05";
    flake-utils.url = "github:numtide/flake-utils";
    nixops.url = "github:talyz/nixops/mapping-types";
  };

  outputs = { self, nixpkgs, flake-utils, nixops }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = (import nixpkgs {
          inherit system;
          config = {
            permittedInsecurePackages = [
              "python3.10-requests-2.28.2"
              "python3.10-cryptography-40.0.1"
            ];
          };
        });
        nixops_unstable = pkgs.nixops_unstable.overrideAttrs (finalAttrs: previousAttrs: {
          src = nixops;
        });
      in
      {
        devShell = pkgs.mkShell {
          buildInputs = [
            nixops_unstable
          ];
        };

        formatter = nixpkgs.legacyPackages.${system}.nixpkgs-fmt;
      });
}
