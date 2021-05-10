{
  network.description = "Minecraft Server";
  minecraft =
    { config, pkgs, ... }:
    { 
        deployment.targetHost = "65.21.110.116";

        imports = [
            ../providers/hetzner.nix
            ../common/ssh.nix
            ../common/lets-encrypt.nix
            # ./networking.nix
            ./minecraft.nix
        ];

        networking = {
          hostName = "minecraft";
          domain = "mc.dmnd.sh";
        };
    };
}
