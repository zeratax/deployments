{ pkgs, lib, config, ... }:
let
  ### Variables:
  kubeMasterIP = "192.168.188.89";
  kubeMasterGateway = "192.168.188.1";
  kubeMasterHostname = "gestalt.local";
  kubeMasterAPIServerPort = 6443;
  kubeMasterInterface = "eno1";
  kubeMasterMacVlanInterface = "mv-${kubeMasterInterface}";

  kubeAgents = 5;

  # since we need this file to be visible at evaluation for host
  # as well as all containers we need an absolute path
  # that is the same on the all systems
  tokenFile = builtins.toPath ./k3s-server-token.key;

  nexusProxyRepoPort = 8082;

  ## Certificates
  # needs to be created manually
  certPath = ./certs/selfsigned.crt;
  certKeyPath = ./certs/selfsigned.key;

  certfile = builtins.readFile certPath;


  ### Containers
  subnet = builtins.head (builtins.match "([0-9]+\\.[0-9]+\\.[0-9]+)\\.[0-9]+" kubeMasterGateway);

  kubeContainers = map 
    (idx: let ipEnding = 100 + idx; 
          in lib.attrsets.nameValuePair 
            ("kube${toString idx}") 
            (mkNode { ip = "${subnet}.${toString ipEnding}"; }))
    (lib.lists.range 1 kubeAgents);

  mkNode = { ip }: {
    # use macvlan
    autoStart = true;
    macvlans = [ kubeMasterInterface ];
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
      { node = "/dev/consotruele"; modifier = "rwm"; }
      { node = "/dev/kmsg"; modifier = "rwm"; }
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

    config = { config, pkgs, ... }: {
      # resolve host
      networking = {
        extraHosts = ''
          ${kubeMasterIP} ${kubeMasterHostname}
        '';
        defaultGateway = kubeMasterGateway;
        interfaces = {
          "${kubeMasterMacVlanInterface}".ipv4.addresses = [ { address = ip; prefixLength = 24;}];
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
      security.pki.certificates = [ certfile ];	

      services.k3s = {
        inherit tokenFile;
        enable = true;
        role = "agent";
        serverAddr = "https://${kubeMasterHostname}:${toString kubeMasterAPIServerPort}";
        extraFlags = "--node-ip ${toString ip}"; # --container-runtime-endpoint unix:///run/containerd/containerd.sock";
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
  networking = let kubeMasterMacVlanHostInterface = "${kubeMasterMacVlanInterface}-host"; in {
    defaultGateway = kubeMasterGateway;
    # create macvlan for containers
    macvlans."${kubeMasterMacVlanHostInterface}" = {
      interface = kubeMasterInterface;
      mode = "bridge";
    };
    interfaces = {
      "${kubeMasterInterface}".ipv4.addresses = lib.mkForce [];
      "${kubeMasterMacVlanHostInterface}".ipv4.addresses = [{ address = kubeMasterIP; prefixLength = 24;}];
    };

    extraHosts = ''
      ${kubeMasterIP} ${kubeMasterHostname}
    '';

    firewall = {
      enable = true;
      allowedTCPPorts = [ 
        config.services.postgresql.port
        config.services.nginx.defaultSSLListenPort
        # config.services.nexus.listenPort # to allow accessing over localnetwork
        kubeMasterAPIServerPort
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

  containers = lib.attrsets.mapAttrs' 
    (name: value: lib.attrsets.nameValuePair name value) 
    (builtins.listToAttrs kubeContainers);

  ### Nexus
  services.nexus = {
    enable = true;
    # listenAddress = "0.0.0.0"; # to allow accessing over localnetwork
  };

  # docker requires https for authenticated repos
  services.nginx = {
    enable = true;

    recommendedProxySettings = true;
    recommendedTlsSettings = true;
    recommendedOptimisation= true;

    # admin web interface available over localhost
    virtualHosts."${kubeMasterHostname}" = {
      forceSSL = true;
      sslCertificate = certPath;
      sslCertificateKey = certKeyPath;

      locations."/" = {
        proxyPass = "http://${config.services.nexus.listenAddress}:${toString nexusProxyRepoPort}";
        extraConfig = ''
          proxy_pass_header Authorization;
        '';
      };
    };
  };

  # self signed certificate for nexus
  security.pki.certificates = [ certfile ];	

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
      host all all ${kubeMasterGateway}/24 trust
      host all all 100.64.0.0/10 trust
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
}
