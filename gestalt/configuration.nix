{ config, pkgs, lib, ... }:
let
  nixos-unstable = import <nixos-unstable> { };
in
{
  imports =
    [
      ./hardware-configuration.nix
      ./custom-hardware.nix
      ./boot.nix
      ./k3s.nix
      # ./pci-passthrough.nix
    ] ++ lib.optionals (builtins.pathExists /etc/nixos/cachix) [ ./cachix.nix ];


  ################### Nix Configuration ###################
  nix = {
    settings = {
      auto-optimise-store = true;
    };
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 30d";
    };
    # free up 1GiB when less than 100MiB left
    extraOptions = ''
      min-free = ${toString (100 * 1024 * 1024)}
      max-free = ${toString (1024 * 1024 * 1024)}
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

  ################### l10n ###################
  console = {
    font = "Lat2-Terminus16";
    keyMap = "us";
  };

  fonts.fonts = with pkgs; [
    noto-fonts
    noto-fonts-cjk
    noto-fonts-emoji
    noto-fonts-extra
  ];

  # Set your time zone.
  time.timeZone = "Europe/Berlin";

  # Select internationalisation properties.
  i18n = {
    defaultLocale = "en_GB.UTF-8";
    extraLocaleSettings = {
      LC_ADDRESS = "de_DE.UTF-8";
      LC_IDENTIFICATION = "de_DE.UTF-8";
      LC_MEASUREMENT = "de_DE.UTF-8";
      LC_MONETARY = "de_DE.UTF-8";
      LC_NAME = "de_DE.UTF-8";
      LC_NUMERIC = "de_DE.UTF-8";
      LC_PAPER = "de_DE.UTF-8";
      LC_TELEPHONE = "de_DE.UTF-8";
      LC_TIME = "de_DE.UTF-8";
    };
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
  environment.systemPackages = with pkgs; [
    vim # Do not forget to add an editor to edit configuration.nix! The Nano editor is also installed by default.
    wget
    firefox
  ];

  # fix home-manager install, see https://github.com/NixOS/nix/issues/2033#issuecomment-1366974053
  # environment.shellInit = ''export  NIXPATH="nixpkgs=/nix/var/nix/profiles/per-user/root/channels/nixos:nixos-config=/etc/nixos/configuration.nix:/nix/var/nix/profiles/per-user/$USER/channels:/nix/var/nix/profiles/per-user/root/channels"'';

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  programs.gnupg.agent = {
    enable = true;
    enableSSHSupport = true;
  };

  ################### SERVICES ###################

  ################### X Server ###################
  # Enable the X11 windowing system.
  services.xserver.enable = true;

  # Enable the KDE Plasma Desktop Environment.
  services.xserver.displayManager.sddm.enable = true;
  services.xserver.desktopManager.plasma5.enable = true;

  # Configure keymap in X11
  services.xserver = {
    layout = "us";
    xkbVariant = "altgr-intl";
  };

  # Enable CUPS to print documents.
  services.printing.enable = true;

  # Enable sound with pipewire.
  sound.enable = true;
  hardware.pulseaudio.enable = false;
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

  services.udev.packages = [
    pkgs.yubikey-personalization
    pkgs.libu2f-host
  ];
  services.mullvad-vpn.enable = true;
  networking.firewall.checkReversePath = "loose"; # https://github.com/NixOS/nixpkgs/issues/113589

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
  virtualisation.libvirtd.enable = true;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "22.11"; # Did you read the comment?
}
