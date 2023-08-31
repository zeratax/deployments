{ pkgs, lib, config, ... }:
let
  kubeMasterIP = "192.168.188.89";
  kubeMasterGateway = "192.168.188.1";
  kubeMasterHostname = "gestalt.local";
  kubeMasterAPIServerPort = 6443;
  # kubeMasterCAPort = 6444;

  nexusProxyRepoPort = 8082;

  certPath = ./certs/selfsigned.crt;
  certKeyPath = ./certs/selfsigned.key;

  certfile = builtins.readFile certPath; # need to be created manually

  mkNode = { ip }: {
    # use macvlan
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
      k3s-token = {
        hostPath = "${toString config.services.k3s.tokenFile}";
        mountPoint = "/home/jonaa/git/deployments/gestalt/k3s-server-token.key";
        isReadOnly = true;
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
          mv-eno1.ipv4.addresses = [ { address = ip; prefixLength = 24;}];
        };
      };

      security.pki.certificates = [ certfile ];	

      services.k3s = {
        enable = true;
        role = "agent";
        tokenFile = /home/jonaa/git/deployments/gestalt/k3s-server-token.key; # directly use bindMounts value?
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
      environment.etc."resolv.conf".text = "nameserver 192.168.188.1";
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
      eno1.ipv4.addresses = lib.mkForce [];
      mv-eno1-host.ipv4.addresses = [{ address = kubeMasterIP; prefixLength = 24;}];
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
        9200 # elasticsearch
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

  services.k3s = {
    enable = true;
    role = "server";
    tokenFile = ./k3s-server-token.key;
    extraFlags = "--disable traefik --flannel-backend=host-gw"; # --container-runtime-endpoint unix:///run/containerd/containerd.sock";
  };

  containers.kube1 = mkNode { ip = "192.168.188.101"; };
  containers.kube2 = mkNode { ip = "192.168.188.102"; };
  containers.kube3 = mkNode { ip = "192.168.188.103"; };	 
  containers.kube4 = mkNode { ip = "192.168.188.104"; }; 	
  containers.kube5 = mkNode { ip = "192.168.188.105"; };	
  containers.kube6 = mkNode { ip = "192.168.188.106"; };	
  containers.kube7 = mkNode { ip = "192.168.188.107"; };	
  containers.kube8 = mkNode { ip = "192.168.188.108"; };	
  containers.kube9 = mkNode { ip = "192.168.188.109"; };	
  containers.kube10 = mkNode { ip = "192.168.188.110"; };	
  containers.kube11 = mkNode { ip = "192.168.188.111"; };	
  containers.kube12 = mkNode { ip = "192.168.188.112"; };	
  containers.kube13 = mkNode { ip = "192.168.188.113"; };	
  containers.kube14 = mkNode { ip = "192.168.188.114"; };	
  containers.kube15 = mkNode { ip = "192.168.188.115"; };	
  containers.kube16 = mkNode { ip = "192.168.188.116"; };	
  containers.kube17 = mkNode { ip = "192.168.188.117"; };	
  containers.kube18 = mkNode { ip = "192.168.188.118"; };	
  containers.kube19 = mkNode { ip = "192.168.188.119"; };	
  containers.kube20 = mkNode { ip = "192.168.188.120"; };	
  containers.kube21 = mkNode { ip = "192.168.188.121"; };	
  containers.kube22 = mkNode { ip = "192.168.188.122"; };	
  containers.kube23 = mkNode { ip = "192.168.188.123"; };	
  containers.kube24 = mkNode { ip = "192.168.188.124"; };	
  # containers.kube25 = mkNode { ip = "192.168.188.125"; };	
  # containers.kube26 = mkNode { ip = "192.168.188.126"; };	
  # containers.kube27 = mkNode { ip = "192.168.188.127"; };	
  # containers.kube28 = mkNode { ip = "192.168.188.128"; };	
  # containers.kube29 = mkNode { ip = "192.168.188.129"; };	
  # containers.kube30 = mkNode { ip = "192.168.188.130"; };	
  # containers.kube31 = mkNode { ip = "192.168.188.131"; };	
  # containers.kube32 = mkNode { ip = "192.168.188.132"; };	
  # containers.kube33 = mkNode { ip = "192.168.188.133"; };	
  # containers.kube34 = mkNode { ip = "192.168.188.134"; };	
  # containers.kube35 = mkNode { ip = "192.168.188.135"; };	
  # containers.kube36 = mkNode { ip = "192.168.188.136"; };	
  # containers.kube37 = mkNode { ip = "192.168.188.137"; };	
  # containers.kube38 = mkNode { ip = "192.168.188.138"; };	
  # containers.kube39 = mkNode { ip = "192.168.188.139"; };	
  # containers.kube40 = mkNode { ip = "192.168.188.140"; };	
  # containers.kube41 = mkNode { ip = "192.168.188.141"; };	
  # containers.kube42 = mkNode { ip = "192.168.188.142"; };	
  # containers.kube43 = mkNode { ip = "192.168.188.143"; };	
  # containers.kube44 = mkNode { ip = "192.168.188.144"; };	
  # containers.kube45 = mkNode { ip = "192.168.188.145"; };	
  # containers.kube46 = mkNode { ip = "192.168.188.146"; };	
  # containers.kube47 = mkNode { ip = "192.168.188.147"; };	
  # containers.kube48 = mkNode { ip = "192.168.188.148"; };	
  # containers.kube49 = mkNode { ip = "192.168.188.149"; };	

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

    # admin web interface available at localhost:8081
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

  security.pki.certificates = [ certfile ];	

  services.postgresql = {
    enable = true;
    package = pkgs.postgresql_15;
    enableTCPIP = true;
    authentication = pkgs.lib.mkOverride 10 ''
      local all all trust
      host all all 127.0.0.1/32 trust
      host all all ::1/128 trust
      host all all fe80::/10 trust
      host all all ${kubeMasterGateway}/24 trust
      host all all 10.42.0.1/24 trust
      host all all 100.64.0.0/10 trust
    '';
    initialScript = pkgs.writeText "backend-initScript" ''
      CREATE DATABASE slotdb;
    '';
  };
}
