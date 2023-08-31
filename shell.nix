{ pkgs ? import <nixpkgs> {} }:
let
  nixos-old = import <nixos-21.11> { };
in pkgs.mkShell {
  nativeBuildInputs = with pkgs; [ nixos-old.nixops ];
}
