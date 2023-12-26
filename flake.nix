{
  inputs = {
    nixpkgs.url = "nixpkgs/nixos-23.11";
    flake-utils.url = "github:numtide/flake-utils";
    nixops.url = "github:NixOS/nixops";
    nixops.inputs.nixpkgs.follows = "nixpkgs";
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
          NIXOPS_STATE = "./statefile/deployments.nixops";
        };

        formatter = nixpkgs.legacyPackages.${system}.nixpkgs-fmt;
      });
}
