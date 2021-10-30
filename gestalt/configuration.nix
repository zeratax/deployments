{ config, pkgs, lib, ... }:
let
  nixos-unstable = import <nixos-unstable> { };
in
{
  imports =
    [
      ./hardware-configuration.nix
      # ./pci-passthrough.nix
      <nixos-hardware/common/pc/ssd>
      <nixos-hardware/common/cpu/intel>
      <nixos-unstable/nixos/modules/hardware/video/nvidia.nix>
    ] ++ lib.optionals (builtins.pathExists ./cachix.nix) [ ./cachix.nix ];

  disabledModules = [
    "hardware/video/nvidia.nix"
  ];

  ################### Nix Configuration ###################
  nix = {
    autoOptimiseStore = true;
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
  nixpkgs.overlays = [
    (self: super:
    {
      linuxPackages_latest = super.linuxPackages_latest.extend (linuxSelf: linuxSuper:
      let
        generic = args: linuxSelf.callPackage (import <nixos-unstable/pkgs/os-specific/linux/nvidia-x11/generic.nix> args) { };
      in
      {
        nvidiaPackages.stable = generic {
          version = "470.63.01";
          sha256_64bit = "sha256:057dsc0j3136r5gc08id3rwz9c0x7i01xkcwfk77vqic9b6486kg";
          settingsSha256 = "sha256:0lizp4hn49yvca2yd76yh3awld98pkaa35a067lpcld35vb5brgv";
          persistencedSha256 = "sha256:1f3gdpa23ipjy2xwf7qnxmw7w8xxhqy25rmcz34xkngjf4fn4pbs";
        };
      });
    })
  ];

  nixpkgs.config.allowUnfree = true;

  nixpkgs.config.packageOverrides = pkgs: {
    # amdvlk = nixos-unstable.amdvlk;
    mullvad-vpn = nixos-unstable.mullvad-vpn;
  };


  ################### Hardware Stuff ###################
  # pci-passthrough
  # pciPassthrough = {
  #   enable = true;
  #   pciIDs = "";
  #   libvirtUsers = [ config.users.users.kaine.name ];
  # };
  hardware.enableRedistributableFirmware = true;

  # Enable sound.
  sound.enable = true;
  hardware.pulseaudio.enable = true;
  hardware.bluetooth.enable = true;

  hardware.steam-hardware.enable = true;

  hardware = {
    opengl = {
      driSupport = true;
      driSupport32Bit = true;
    };
  };

  ################### Boot Loader ###################
  boot = {
    # kernelParams = [ "intel_idle.max_cstate=1" ]; # https://gist.github.com/Brainiarc7/8dfd6bb189b8e6769bb5817421aec6d1
    loader = {
      systemd-boot.enable = true;
      efi = {
        canTouchEfiVariables = false;
        # efiSysMountPoint = "/boot";
      };
      # grub = {
      #   devices = [ "nodev" ];
      #   enable = true;
      #   efiInstallAsRemovable = true;
      #   efiSupport = true;
      #   version = 2;
      #   useOSProber = true;
      # };
    };
  };

  ################### Networking ###################
  networking.hostName = "gestalt";
  networking.networkmanager.enable = true;

  networking.useDHCP = false;
  networking.interfaces.eno1.useDHCP = true;

  ################### l10n ###################
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

  # Set your time zone.
  time.timeZone = "Europe/Berlin";

  ################### User Enviroment ###################
  environment.systemPackages = with pkgs; [
    curl
    git
    ntfs3g
    vim
    wget
  ] ++ lib.lists.optionals config.services.xserver.desktopManager.plasma5.enable [
    libsForQt5.akonadi-search
    ark
  ];

  programs.gnupg.agent = {
    enable = true;
    enableSSHSupport = true;
  };

  virtualisation.docker.enable = true;

  # List services that you want to enable:
  services.udev.packages = [
    pkgs.yubikey-personalization
    pkgs.libu2f-host
  ];
  services.mullvad-vpn.enable = true;
  networking.firewall.checkReversePath = "loose"; # https://github.com/NixOS/nixpkgs/issues/113589

  # Enable the OpenSSH daemon.
  services.openssh.enable = true;

  # Enable CUPS to print documents.
  services.printing.enable = true;

  # Enable keyring cos stuff like vscode uses it
  services.gnome.gnome-keyring.enable = true;

  # Enable the X11 windowing system.
  services.xserver.videoDrivers = [ "nvidia" "modesetting" ];

  services.xserver.enable = true;
  services.xserver.layout = "us";
  services.xserver.xkbVariant = "intl";
  services.xserver.xkbOptions = "eurosign:e";

  ################### X Server Stuff ###################
  # Enable the KDE Desktop Environment.
  services.xserver.displayManager.sddm.enable = true;
  services.xserver.desktopManager.plasma5.enable = true;
  services.xserver.desktopManager.gnome.enable = true;
  # https://github.com/NixOS/nixpkgs/issues/75867#issuecomment-591648489
  programs.ssh.askPassword = pkgs.lib.mkForce "${pkgs.ksshaskpass.out}/bin/ksshaskpass";
  services.xserver.windowManager.i3.enable = true;
  services.xserver.displayManager.defaultSession = "plasma5";

  # Enable color calibration
  services.colord.enable = lib.mkIf config.services.xserver.enable true;
  services.pcscd.enable = lib.mkIf config.services.xserver.enable true;

  users.users.kaine = {
    isNormalUser = true;
    extraGroups = [ "wheel" "networkmanager" "docker" ];
    openssh.authorizedKeys.keys = [
      "ssh-rsa AAAAB3NzaC1yc2EAAAABJQAAAQEA5K62E/ZFLEOIQmzKClxVAP5GmR+6ir+hWxPxK9XfvMZtTtCcnhXBnXNfQlSrX301INy9DiVfN+bRYHS3LU7TUfEcd6E5iwCOH6o9nRVZS7IkJDN/cw0m3co7cFeoayNZylIeACVfM7DwBjzzOXMV3T4hN5LbHkpv63CNTTTQqBaak+CZBQFmzMgIYGiEAi5a3yzZFpVh46JkaasDO2C9SfTNBIuCfaUIAbMbXb09B6FsirBdhndEI2fpT+1jYM0PUeqnxDbYuv5UDwDgKADo/HBAid1X4srJZzMjcnFjtwrazk3/DzyICnZM4R6xuw4cOYiDgfbfYsLYaT70YqFPUw=="
    ];
  };
  system.stateVersion = "21.05";
}
