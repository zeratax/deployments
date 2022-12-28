{config, pkgs, lib, ...}:
let
    dataDir = "/var/lib/satisfactory";
    gameDir = "${dataDir}/SatisfactoryDedicatedServer";
    settingsDir = "${gameDir}/FactoryGame/Saved/Config/LinuxServer";
    binary = "${gameDir}/Engine/Binaries/Linux/UE4Server-Linux-Shipping";

    experimental = true;
    maxPlayers = 8;

    gameINI = pkgs.writeText "Game.ini" ''
      [/Script/Engine.GameNetworkManager]
      TotalNetBandwidth=500000
      MaxDynamicBandwidth=120000
      MinDynamicBandwidth=100000

      [/Script/Engine.GameSession]
      MaxPlayers=${toString maxPlayers}
    '';
in {
  users.users.satisfactory = {
    home = dataDir;
    createHome = true;
    isSystemUser = true;
    group = "satisfactory";
  };
  users.groups.satisfactory = {};

  nixpkgs.config.allowUnfree = true;

  networking = {
    firewall = {
      allowedUDPPorts = [ 15777 15000 7777 ];
    };
  };

  systemd.services.satisfactory = {
    wantedBy = [ "multi-user.target" ];
    preStart = ''
      mkdir -p ${settingsDir}
      ln -sf ${gameINI} "${settingsDir}/Game.ini"

      ${pkgs.steamcmd}/bin/steamcmd \
        +force_install_dir ${dataDir}/SatisfactoryDedicatedServer \
        +login anonymous \
        +app_update 1690800 \
            -beta ${if experimental then "experimental" else "public"} \
            validate \
        +quit
      ${pkgs.patchelf}/bin/patchelf \
        --set-interpreter ${pkgs.glibc}/lib/ld-linux-x86-64.so.2 \
        ${binary}
    '';
    script = ''
      ${binary} FactoryGame
    '';
    serviceConfig = {
      Nice = "-5";
      Restart = "always";
      User = "satisfactory";
      WorkingDirectory = dataDir;
    };
    environment = {
      LD_LIBRARY_PATH="SatisfactoryDedicatedServer/linux64:SatisfactoryDedicatedServer/Engine/Binaries/Linux:SatisfactoryDedicatedServer/Engine/Binaries/ThirdParty/PhysX3/Linux/x86_64-unknown-linux-gnu/";
    };
  };
}