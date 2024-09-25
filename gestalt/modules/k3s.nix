{
  pkgs,
  lib,
  config,
  ...
}: let
  cfg = config.simulatedK3SCluster;

  # since we need this file to be visible at evaluation for host
  # as well as all containers we need an absolute path
  # that is the same on the all systems
  tokenFile = builtins.toPath cfg.tokenFile;
  certfile = builtins.readFile cfg.certPath;

  subnet =
    builtins.head (builtins.match "([0-9]+\\.[0-9]+\\.[0-9]+)\\.[0-9]+"
      cfg.kubeMasterGateway);

  kubeMasterMacVlanInterface = "mv-${cfg.kubeMasterInterface}";
  kubeMasterMacVlanHostInterface = "${kubeMasterMacVlanInterface}-host";

  kubeContainers = map (idx: let
    ipEnding = 100 + idx;
  in
    lib.attrsets.nameValuePair "kube${toString idx}"
    (mkNode {ip = "${subnet}.${toString ipEnding}";}))
  (lib.lists.range 1 cfg.kubeAgents);

  mkNode = {ip}: {
    # use macvlan
    autoStart = true;
    macvlans = [cfg.kubeMasterInterface];
    timeoutStartSec = "10min";

    # enable nested containers https://wiki.archlinux.org/title/systemd-nspawn#Run_docker_in_systemd-nspawn
    enableTun = true;
    extraFlags = ["--private-users-ownership=chown"];
    additionalCapabilities = [''all" --system-call-filter="add_key keyctl bpf" --capability="all''];

    allowedDevices = [
      {
        node = "/dev/fuse";
        modifier = "rwm";
      }
      {
        node = "/dev/mapper/control";
        modifier = "rwm";
      }
      {
        node = "/dev/consotruele";
        modifier = "rwm";
      }
      {
        node = "/dev/kmsg";
        modifier = "rwm";
      }
    ];

    bindMounts = {
      k3s-token = {
        hostPath = tokenFile;
        mountPoint = tokenFile;
        isReadOnly = true;
      };
      kmsg = {
        hostPath = "/dev/kmsg";
        mountPoint = "/dev/kmsg";
        isReadOnly = false;
      };
      fuse = {
        hostPath = "/dev/fuse";
        mountPoint = "/dev/fuse";
        isReadOnly = false;
      };
    };

    config = {config, ...}: {
      # resolve host
      networking = {
        extraHosts = ''
          ${cfg.kubeMasterIP} ${cfg.kubeMasterHostname}
        '';
        defaultGateway = cfg.kubeMasterGateway;
        interfaces = {
          "${kubeMasterMacVlanInterface}".ipv4.addresses = [
            {
              address = ip;
              prefixLength = 24;
            }
          ];
        };
        firewall = {
          enable = true;
          allowedTCPPorts = [
            config.services.nginx.defaultHTTPListenPort
            config.services.nginx.defaultSSLListenPort
          ];
        };
      };

      # self signed certificate for nexus
      security.pki.certificates = [certfile];

      services.k3s = {
        inherit tokenFile;
        enable = true;
        role = "agent";
        serverAddr = "https://${cfg.kubeMasterHostname}:${
          toString cfg.kubeMasterAPIServerPort
        }";
        extraFlags = "--node-ip ${
          toString ip
        }"; # --container-runtime-endpoint unix:///run/containerd/containerd.sock";
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
in {
  options = {
    simulatedK3SCluster = {
      enable = lib.mkEnableOption "Enable the simulated k3s Cluster";

      kubeMasterIP = lib.mkOption {
        type = lib.types.str;
        example = "192.168.178.89";
        description = "IP address of the Kubernetes master.";
      };

      kubeMasterGateway = lib.mkOption {
        type = lib.types.str;
        example = "192.168.178.1";
        description = "Gateway IP address for the Kubernetes master.";
      };

      kubeMasterHostname = lib.mkOption {
        type = lib.types.str;
        example = "gestalt.local";
        description = "Hostname of the Kubernetes master.";
      };

      kubeMasterAPIServerPort = lib.mkOption {
        type = lib.types.int;
        default = 6443;
        description = "API server port for the Kubernetes master.";
      };

      kubeMasterInterface = lib.mkOption {
        type = lib.types.str;
        default = "eno1";
        description = "Network interface for the Kubernetes master.";
      };

      kubeAgents = lib.mkOption {
        type = lib.types.int;
        default = 1;
        description = "Number of Kubernetes agents.";
      };

      additionalPostgresqlAuthLines = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [];
        description = "Additional lines to add to PostgreSQL authentication configuration.";
      };

      nexusProxyRepo = {
        enable = lib.mkEnableOption "Enable Nexus proxy repository";

        port = lib.mkOption {
          type = lib.types.int;
          default = 8082;
          description = "Port for the Nexus proxy repository.";
        };
      };

      tokenFile = lib.mkOption {
        type = lib.types.path;
        example = ./k3s-server-token;
        description = "Path to k3s server token file.";
      };

      certPath = lib.mkOption {
        type = lib.types.path;
        example = ./selfsigned.crt;
        description = "Path to the SSL certificate file.";
      };

      certKeyPath = lib.mkOption {
        type = lib.types.path;
        example = ./selfsigned.key;
        description = "Path to the SSL certificate key file.";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    networking = {
      defaultGateway = cfg.kubeMasterGateway;
      # create macvlan for containers
      macvlans."${kubeMasterMacVlanHostInterface}" = {
        interface = cfg.kubeMasterInterface;
        mode = "bridge";
      };
      interfaces = {
        "${cfg.kubeMasterInterface}".ipv4.addresses = lib.mkForce [];
        "${kubeMasterMacVlanHostInterface}".ipv4.addresses = [
          {
            address = cfg.kubeMasterIP;
            prefixLength = 24;
          }
        ];
      };

      extraHosts = ''
        ${cfg.kubeMasterIP} ${cfg.kubeMasterHostname}
      '';

      firewall = {
        enable = true;
        allowedTCPPorts =
          [config.services.postgresql.settings.port cfg.kubeMasterAPIServerPort]
          ++ lib.lists.optionals cfg.nexusProxyRepo.enable [
            config.services.nginx.defaultSSLListenPort
            # config.services.nexus.listenPort # to allow accessing over localnetwork
          ];
      };
    };

    ### k8s/k3s

    services.k3s = {
      inherit tokenFile;
      enable = true;
      role = "server";
      extraFlags = "--disable traefik --flannel-backend=host-gw"; # --container-runtime-endpoint unix:///run/containerd/containerd.sock";
    };

    containers =
      lib.attrsets.mapAttrs'
      (name: value: lib.attrsets.nameValuePair name value)
      (builtins.listToAttrs kubeContainers);

    ### Nexus
    services.nexus = {
      enable = true;
      # listenAddress = "0.0.0.0"; # to allow accessing over localnetwork
    };

    # docker requires https for authenticated repos
    services.nginx = lib.mkIf cfg.nexusProxyRepo.enable {
      enable = true;

      recommendedProxySettings = true;
      recommendedTlsSettings = true;
      recommendedOptimisation = true;

      # admin web interface available over localhost
      virtualHosts."${cfg.kubeMasterHostname}" = {
        forceSSL = true;
        sslCertificate = cfg.certPath;
        sslCertificateKey = cfg.certKeyPath;

        locations."/" = {
          proxyPass = "http://${config.services.nexus.listenAddress}:${
            toString cfg.nexusProxyRepo.port
          }";
          extraConfig = ''
            proxy_pass_header Authorization;
          '';
        };
      };
    };

    # self signed certificate for nexus
    security.pki.certificates = [certfile];

    ### Postgresql
    services.postgresql = {
      enable = true;
      package = pkgs.postgresql_16_jit;
      enableTCPIP = true;
      authentication = pkgs.lib.mkOverride 10 ''
        local all all trust
        host all all 127.0.0.1/32 trust
        host all all ::1/128 trust
        host all all fe80::/10 trust
        host all all ${cfg.kubeMasterGateway}/24 trust
        host all all 100.64.0.0/10 trust
        ${lib.concatStringsSep "\n" cfg.additionalPostgresqlAuthLines}
      '';
      initialScript = pkgs.writeText "backend-initScript" ''
        CREATE DATABASE slotdb;
      '';
    };

    ### Other
    services.avahi = {
      enable = true;
      publish = {
        enable = true;
        addresses = true;
        workstation = true;
      };
    };
  };
}
