{ pkgs, lib, config, ... }:
let
  kubeMasterIP = "192.168.188.89";
  kubeMasterGateway = "192.168.188.1";
  kubeMasterHostname = "gestalt.local";
  kubeMasterAPIServerPort = 6443;

  nspawn-config-text = ''
    [Exec]
    SystemCallFilter=add_key keyctl bpf
  '';

  mkNode = { ip, port ? 6443 }: {
    autoStart = true;
    macvlans = [ "eno1" ];
    timeoutStartSec = "10min";

    # enable nested containers https://wiki.archlinux.org/title/systemd-nspawn#Run_docker_in_systemd-nspawn
    enableTun = true;
    extraFlags = [ "--private-users-ownership=chown" ];
    additionalCapabilities = [
      ''all" --system-call-filter="add_key keyctl bpf" --capability="all''
    ];

    allowedDevices = [
      { node = "/dev/fuse"; modifier = "rwm"; }
      { node = "/dev/mapper/control"; modifier = "rwm"; }
      { node = "/dev/console"; modifier = "rwm"; }
    ];

    bindMounts = {
      fuse = {
        hostPath = "/dev/fuse";
        mountPoint = "/dev/fuse";
        isReadOnly = false;
      };
    };
    config = { config, pkgs, ... }: {

      # resolve host
      networking = {
        extraHosts = ''
          ${kubeMasterIP} ${kubeMasterHostname}
        '';
        defaultGateway = kubeMasterGateway;
        interfaces = {
          mv-eno1.ipv4.addresses = [{ address = ip; prefixLength = 24; }];
        };
      };

      services.kubernetes = {
        roles = [ "node" ];
        masterAddress = kubeMasterHostname;

        # point kubelet and other services to kube-apiserver
        kubelet.kubeconfig.server = "https://${kubeMasterHostname}:${toString kubeMasterAPIServerPort}";
        apiserverAddress = "https://${kubeMasterHostname}:${toString kubeMasterAPIServerPort}";

        kubelet = {
          extraOpts = "--fail-swap-on=false";
        };
      };

      networking.firewall = {
        enable = true;
        allowedTCPPorts = [
          config.services.kubernetes.kubelet.port
          config.services.kubernetes.kubelet.healthz.port
        ];
        allowedTCPPortRanges = [
          { from = 30000; to = 32767; }
        ];
      };

      services.avahi = {
        enable = true;
        publish = {
          enable = true;
          addresses = true;
          workstation = true;
        };
      };

      system.stateVersion = "22.05";

      # Manually configure nameserver. Using resolved inside the container seems to fail
      # currently
      environment.etc."resolv.conf".text = "nameserver 1.1.1.1";
    };
  };
in
{
  networking = {
    defaultGateway = kubeMasterGateway;
    # create macvlan for containers
    macvlans.mv-eno1-host = {
      interface = "eno1";
      mode = "bridge";
    };
    interfaces = {
      eno1.ipv4.addresses = lib.mkForce [ ];
      mv-eno1-host.ipv4.addresses = [{ address = kubeMasterIP; prefixLength = 24; }];
    };

    extraHosts = ''
      ${kubeMasterIP} ${kubeMasterHostname}
    '';
    firewall = {
      enable = true;
      allowedTCPPorts = [
        config.services.postgresql.port
        config.services.kubernetes.apiserver.securePort
        config.services.kubernetes.controllerManager.securePort
        config.services.kubernetes.scheduler.port
        config.services.cfssl.port
      ];
      allowedTCPPortRanges = [
        { from = 2379; to = 2380; }
      ];
    };
  };

  services.avahi = {
    enable = true;
    publish = {
      enable = true;
      addresses = true;
      workstation = true;
    };
  };

  # packages for administration tasks
  environment.systemPackages = with pkgs; [
    kompose
    kubectl
    kubernetes
  ];

  services.kubernetes = {
    roles = [ "master" ];
    masterAddress = kubeMasterHostname;
    apiserverAddress = "https://${kubeMasterHostname}:${toString kubeMasterAPIServerPort}";
    apiserver = {
      securePort = kubeMasterAPIServerPort;
      advertiseAddress = kubeMasterIP;
    };
    kubelet.extraOpts = "--fail-swap-on=false";
  };

  containers.kubenode1 = mkNode { ip = "192.168.188.101"; };
  containers.kubenode2 = mkNode { ip = "192.168.188.102"; };
  containers.kubenode3 = mkNode { ip = "192.168.188.103"; };

  services.postgresql = {
    enable = true;
    package = pkgs.postgresql_15;
    enableTCPIP = true;
    authentication = pkgs.lib.mkOverride 10 ''
      local all all trust
      host all all 127.0.0.1/32 trust
      host all all ::1/128 trust
      host all all ${kubeMasterGateway}/24 trust
    '';
    initialScript = pkgs.writeText "backend-initScript" ''
      CREATE DATABASE slotdb;
    '';
  };
}
