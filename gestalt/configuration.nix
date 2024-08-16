{ config, pkgs, lib, ... }:
let
  nixos-unstable = import <nixos-unstable> { };
in
{
  imports = [
    ./modules/k3s.nix

    # order is important. vfio must come before other gpu related kernel modules
    ./hardware-configuration.nix
    ./custom-hardware.nix
    ./boot.nix
  ] ++ lib.optionals (builtins.pathExists /etc/nixos/cachix) [ ./cachix.nix ];

  ################### Nix Configuration ###################
  nix = {
    package = pkgs.nixFlakes;
    settings = { auto-optimise-store = true; };
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 30d";
    };
    # free up 5GiB when less than 1GiB left
    # also enable flakes
    extraOptions = ''
      min-free = ${toString (1 * 1024 * 1024 * 1024)}
      max-free = ${toString (5 * 1024 * 1024 * 1024)}
      experimental-features = nix-command flakes
    '';
  };

  ################### Nixpkgs Overwrites ###################
  nixpkgs.config.allowUnfree = true;

  nixpkgs.config.packageOverrides = pkgs: {
    mullvad-vpn = nixos-unstable.mullvad-vpn;
  };

  ################### Networking ###################
  networking.hostName = "gestalt";
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  networking.enableIPv6 = true;

  # Enable networking
  networking.networkmanager.enable = true;

  # Add fritz box selfsigned cert
  security.pki.certificates = [ (builtins.readFile ./certs/myFRITZBox.crt) ];

  ################### l10n ###################
  console = {
    font = "Lat2-Terminus16";
    keyMap = "us";
  };

  fonts = {
    enableDefaultPackages = true;

    packages = with pkgs; [
      noto-fonts
      noto-fonts-cjk
      noto-fonts-color-emoji
      noto-fonts-extra
    ];
  };

  # Set your time zone.
  time.timeZone = "Europe/Berlin";

  # Select internationalisation properties.
  i18n = {
    defaultLocale = "en_GB.UTF-8";
    # extraLocaleSettings = {
    #   LC_ADDRESS = "de_DE.UTF-8";
    #   LC_IDENTIFICATION = "de_DE.UTF-8";
    #   LC_MEASUREMENT = "de_DE.UTF-8";
    #   LC_MONETARY = "de_DE.UTF-8";
    #   LC_NAME = "de_DE.UTF-8";
    #   LC_NUMERIC = "de_DE.UTF-8";
    #   LC_PAPER = "de_DE.UTF-8";
    #   LC_TELEPHONE = "de_DE.UTF-8";
    #   LC_TIME = "de_DE.UTF-8";
    # };
    # # This enables "fcitx" as your IME.  This is an easy-to-use IME.  It supports many different input methods.
    # inputMethod.enabled = "fcitx";

    # # This enables "mozc" as an input method in "fcitx".  This has a relatively
    # # complete dictionary.  I recommend it for Japanese input.
    # inputMethod.fcitx.engines = with pkgs.fcitx-engines; [ mozc ];
  };

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.jonaa = {
    isNormalUser = true;
    description = "Jona Abdinghoff";
    extraGroups = [ "networkmanager" "wheel" "docker" "libvirtd" ];
    openssh.authorizedKeys.keys = [
      "ssh-rsa AAAAB3NzaC1yc2EAAAABJQAAAQEA5K62E/ZFLEOIQmzKClxVAP5GmR+6ir+hWxPxK9XfvMZtTtCcnhXBnXNfQlSrX301INy9DiVfN+bRYHS3LU7TUfEcd6E5iwCOH6o9nRVZS7IkJDN/cw0m3co7cFeoayNZylIeACVfM7DwBjzzOXMV3T4hN5LbHkpv63CNTTTQqBaak+CZBQFmzMgIYGiEAi5a3yzZFpVh46JkaasDO2C9SfTNBIuCfaUIAbMbXb09B6FsirBdhndEI2fpT+1jYM0PUeqnxDbYuv5UDwDgKADo/HBAid1X4srJZzMjcnFjtwrazk3/DzyICnZM4R6xuw4cOYiDgfbfYsLYaT70YqFPUw=="
    ];
  };

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs;
    [
      vim # Do not forget to add an editor to edit configuration.nix! The Nano editor is also installed by default.
    ];

  programs.gnupg.agent = {
    enable = true;
    enableSSHSupport = true;
  };

  ################### SERVICES ###################

  ################### Display Manager ###################
  services.displayManager = {
    defaultSession = "plasma";
    sddm = {
      enable = true;
      wayland.enable = true;
    };
  };
  services.desktopManager.plasma6.enable = true;

  # # Enable X11 server
  # services.xserver = {
  #   enable = true;
  #
  #   # Configure keymap in X11
  #   xkb = {
  #     layout = "us";
  #     variant = "altgr-intl";
  #   };
  # };

  # Enable CUPS to print documents.
  services.printing.enable = true;

  # Enable fwupd to update firmware
  services.fwupd.enable = true;

  # Enable sound with pipewire.
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    # If you want to use JACK applications, uncomment this
    #jack.enable = true;

    # use the example session manager (no others are packaged yet so this is enabled by default,
    # no need to redefine it in your config for now)
    #media-session.enable = true;
  };

  # Enable touchpad support (enabled default in most desktopManager).
  # services.xserver.libinput.enable = true;

  # See https://nixos.wiki/wiki/Yubikey
  services.udev.packages = [ pkgs.yubikey-personalization ];

  services.mullvad-vpn.enable = true;
  networking.firewall.checkReversePath =
    "loose"; # https://github.com/NixOS/nixpkgs/issues/113589

  services.tailscale = { enable = true; };

  services.transmission = {
    enable = false;
    package = nixos-unstable.pkgs.transmission_4;
    settings = {
      incomplete-dir-enabled = false;
      rpc-enabled = true;
      rpc-whitelist = "127.0.0.1,192.168.*.*,100.*.*.*";
      rpc-host-whitelist = "${config.networking.hostName}";
      rpc-bind-address = "0.0.0.0";
    };
    openPeerPorts = true;
    openRPCPort = true;
  };

  # Enable the OpenSSH daemon.
  services.openssh.enable = true;

  # Enable color calibration
  services.colord.enable = lib.mkIf config.services.xserver.enable true;
  services.pcscd.enable = lib.mkIf config.services.xserver.enable true;

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  virtualisation.docker.enable = true;

  simulatedK3SCluster = {
    enable = true;
    kubeMasterIP = "192.168.188.89";
    kubeMasterGateway = "192.168.188.1";
    kubeMasterHostname = "gestalt.local";

    kubeAgents = 6;

    tokenFile = ./k3s-server-token.key;
    certPath = ./certs/selfsigned.crt;
    certKeyPath = ./certs/selfsigned.key;

    nexusProxyRepo.enable = true;
  };

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "22.11"; # Did you read the comment?
}
