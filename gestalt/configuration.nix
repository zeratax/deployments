# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, ... }:


let

  # get the last working revision with nvidia driver
  # nixos-unstable-pinned = import (builtins.fetchTarball {
  #   name = "nixos-unstable_nvidia-410-66_2018-11-03";
  #   url = https://github.com/nixos/nixpkgs/archive/04e9c9b0a3539104ccea18e9647961f70e96810b.tar.gz;
  #   sha256 = "0vcn4idnq0j4671lsi6lgsw8724hwpgy5jk7cysv4dvh09h025i6";
  # }) { };
  nixos-unstable = import <nixos-unstable> { };

in

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
    ];

  nixpkgs.overlays = [
    # https://github.com/NixOS/nixpkgs/issues/94315#issuecomment-719892849
    # (self: super:
    #   let
    #     nixpkgs-mesa = builtins.fetchTarball
    #       "https://github.com/nixos/nixpkgs/archive/bdac777becdbb8780c35be4f552c9d4518fe0bdb.tar.gz";
    #   in { mesa_drivers = (import nixpkgs-mesa { }).mesa_drivers; })
  ];

  nixpkgs.config.allowUnfree = true;

  nixpkgs.config.packageOverrides = pkgs: {
    # amdvlk = nixos-unstable.amdvlk;
    mullvad-vpn = nixos-unstable.mullvad-vpn;
  };

  hardware.cpu.intel.updateMicrocode = true;

  # Enable sound.
  sound.enable = true;
  hardware.pulseaudio.enable = true;

  hardware.opengl.driSupport = true;
  hardware.opengl.extraPackages = with pkgs; [ 
    # amdvlk 
    mesa_drivers
    linuxPackages.nvidia_x11 
  ];

  # 32-bit support
  hardware.opengl.driSupport32Bit = true;
  hardware.opengl.extraPackages32 = with pkgs.pkgsi686Linux; [
    # nixos-unstable.pkgs.pkgsi686Linux.amdvlk
    libva
  ];
  hardware.pulseaudio.support32Bit = true;

  hardware.steam-hardware.enable = true;

  # boot.loader.systemd-boot.enable = true;
  boot.loader = {
    efi = {
      canTouchEfiVariables = false;
      efiSysMountPoint = "/boot";
    };
    grub = {
       devices = [ "nodev" ];
       enable = true;
       efiInstallAsRemovable = true;
       efiSupport = true;
       version = 2;
       useOSProber = true; 
    };
  };


  networking.hostName = "gestalt"; # Define your hostname.
  networking.networkmanager.enable = true;
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  # The global useDHCP flag is deprecated, therefore explicitly set to false here.
  # Per-interface useDHCP will be mandatory in the future, so this generated config
  # replicates the default behaviour.
  networking.useDHCP = false;
  networking.interfaces.eno1.useDHCP = true;

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Select internationalisation properties.
  console = {
    font = "Lat2-Terminus16";
    keyMap = "us";
  };

  # i18n = {
  #   defaultLocale = "en_US.UTF-8";
  #   # This enables "fcitx" as your IME.  This is an easy-to-use IME.  It supports many different input methods.
  #   inputMethod.enabled = "fcitx";

  #   # This enables "mozc" as an input method in "fcitx".  This has a relatively
  #   # complete dictionary.  I recommend it for Japanese input.
  #   inputMethod.fcitx.engines = with pkgs.fcitx-engines; [ mozc ];
  # };

  fonts.fonts = with pkgs; [
    noto-fonts
    noto-fonts-cjk
    noto-fonts-emoji
    noto-fonts-extra
  ];

  fonts.fontconfig.defaultFonts = {
    monospace = [
      "DejaVu Sans Mono"
      "IPAGothic"
    ];
    sansSerif = [
      "DejaVu Sans"
      "IPAPGothic"
    ];
    serif = [
      "DejaVu Serif"
      "IPAPMincho"
    ];
  };

  # https://github.com/bohoomil/fontconfig-ultimate/issues/171
  # fonts.fontconfig.ultimate.enable = true;

  # Set your time zone.
  time.timeZone = "Europe/Berlin";

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    curl
    git
    ntfs3g
    python3
    unzip
    vim
    wget
  ] ++ lib.lists.optionals config.services.xserver.desktopManager.plasma5.enable [
    kdeApplications.akonadi-search
    ark
  ] ++ lib.lists.optionals config.services.xserver.enable [
    alacritty
    firefox
  ];

  # use amdvlk by default:
  # environment.variables.VK_ICD_FILENAMES = "/run/opengl-driver/share/vulkan/icd.d/amd_icd64.json:/run/opengl-driver-32/share/vulkan/icd.d/amd_icd32.json";

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  programs.gnupg.agent = {
    enable = true;
    enableSSHSupport = true;
  };

  # List services that you want to enable:
  services.colord.enable = true;
  services.pcscd.enable = true;
  services.udev.packages = [
    pkgs.yubikey-personalization
    pkgs.libu2f-host
  ];
  services.mullvad-vpn.enable = true;

  # Enable the OpenSSH daemon.
  services.openssh.enable = true;

  # Enable CUPS to print documents.
  services.printing.enable = true;


  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  # Enable the X11 windowing system.
  services.xserver.enable = true;
  services.xserver.layout = "us";
  services.xserver.xkbVariant = "intl";
  services.xserver.xkbOptions = "eurosign:e";

  services.xserver.videoDrivers = [
    # "amdvlk"
    "modesetting"
    "nvidiaBeta"
  ];

  # services.xserver.xrandrHeads = [
  #    { monitorConfig = ''Option "Rotate" "normal"''; output = "DisplayPort-2"; primary = true; }
  #    { monitorConfig = ''Option "Rotate" "left"''; output = "HDMI-A-0"; }
  # ];

  # Enable touchpad support.
  # services.xserver.libinput.enable = true;

  # Enable the KDE Desktop Environment.
  services.xserver.displayManager.sddm.enable = true;
  services.xserver.desktopManager.plasma5.enable = true;
  # services.xserver.desktopManager.gnome3.enable = true;
  # https://github.com/NixOS/nixpkgs/issues/75867#issuecomment-591648489
  programs.ssh.askPassword = pkgs.lib.mkForce "${pkgs.plasma5.ksshaskpass.out}/bin/ksshaskpass";
  services.xserver.windowManager.i3.enable = true;
  services.xserver.displayManager.defaultSession = "plasma";

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.kaine = {
    isNormalUser = true;
    extraGroups = [ "wheel" "networkmanager" ]; # Enable ‘sudo’ for the user.
    openssh.authorizedKeys.keys = [
      "ssh-rsa AAAAB3NzaC1yc2EAAAABJQAAAQEA5K62E/ZFLEOIQmzKClxVAP5GmR+6ir+hWxPxK9XfvMZtTtCcnhXBnXNfQlSrX301INy9DiVfN+bRYHS3LU7TUfEcd6E5iwCOH6o9nRVZS7IkJDN/cw0m3co7cFeoayNZylIeACVfM7DwBjzzOXMV3T4hN5LbHkpv63CNTTTQqBaak+CZBQFmzMgIYGiEAi5a3yzZFpVh46JkaasDO2C9SfTNBIuCfaUIAbMbXb09B6FsirBdhndEI2fpT+1jYM0PUeqnxDbYuv5UDwDgKADo/HBAid1X4srJZzMjcnFjtwrazk3/DzyICnZM4R6xuw4cOYiDgfbfYsLYaT70YqFPUw=="
    ];
  };

  # This value determines the NixOS release with which your system is to be
  # compatible, in order to avoid breaking some software such as database
  # servers. You should change this only after NixOS release notes say you
  # should.
  system.stateVersion = "20.03"; # Did you read the comment?
}
