{...}: {
  imports = [
    ./modules/satisfactory.nix
  ];

  services.satisfactory = {
    enable = true;
    address = "0.0.0.0";
    maxPlayers = 10;
    autoPause = true;
  };
}
