{ pkgs, config, lib, ... }:

let
  domain = "any.${config.networking.domain}";
  plugin-smtp = pkgs.stdenv.mkDerivation rec {
    name = "smtp";

    src = pkgs.fetchFromGitHub {
      owner = "splitbrain";
      repo = "dokuwiki-plugin-smtp";
      rev = "2020-11-21";
      sha256 = "1vjpikl1ii91khmainlkwbf9k09spipxa0wgl2h9fgk7czqg0sl1";
    };

    preferLocalBuild = true;
    dontConfigure = true;
    installPhase = "mkdir -p $out; cp -R * $out/";
  };
  plugin-tag = pkgs.stdenv.mkDerivation rec {
    name = "tag";

    src = pkgs.fetchFromGitHub {
      owner = "dokufreaks";
      repo = "plugin-tag";
      rev = "43713280b4675158ba736f3518d64224ab9cbf95";
      sha256 = "1bhxjvpjnzdalmvryxk00ykqqq0b4jy5g3ynnzhlm53x8yi9phdj";
    };

    preferLocalBuild = true;
    dontConfigure = true;
    installPhase = "mkdir -p $out; cp -R * $out/";
  };
  plugin-pagelist = pkgs.stdenv.mkDerivation rec {
    name = "pagelist";

    src = pkgs.fetchFromGitHub {
      owner = "dokufreaks";
      repo = "plugin-pagelist";
      rev = "f07f56614330356190d44d26dd55e22718683433";
      sha256 = "04i833nqljghrq6iv2lnvksbbqbsykvnbb4j7rhgd9kyk9jaxbzs";
    };

    preferLocalBuild = true;
    dontConfigure = true;
    installPhase = "mkdir -p $out; cp -R * $out/";
  };
  plugin-mathjax = pkgs.stdenv.mkDerivation rec {
    name = "mathjax";

    src = pkgs.fetchFromGitHub {
      owner = "liffiton";
      repo = "dokuwiki-plugin-mathjax";
      rev = "fc0d3cb13d7ad7e32979e0ba5b2c2fc0f0e2c502";
      sha256 = "03790r87l6x9855j0bb27mxqz3pn3j3iwq7a0sslnm1x9z9495ny";
    };

    preferLocalBuild = true;
    dontConfigure = true;
    installPhase = "mkdir -p $out; cp -R * $out/";
  };
in
{
  # deployment.keys.dokuwiki-users.text = builtins.readFile ./dokuwiki-users.key;
  # deployment.keys.dokuwiki-acl.text = builtins.readFile ./dokuwiki-acl.key;

  # deployment.keys.dokuwiki-users.user = config.users.users.dokuwiki.name;
  # deployment.keys.dokuwiki-users.group = config.users.groups.nginx.name;
  # deployment.keys.dokuwiki-acl.user = config.users.users.dokuwiki.name;
  # deployment.keys.dokuwiki-acl.group = config.users.groups.nginx.name;
  # deployment.keys.dokuwiki-acl.permissions = "0750";

  services.dokuwiki."${domain}" = {
    enable = true;

    aclUse = true;
    # aclFile = config.deployment.keys.dokuwiki-acl.path;
    acl = ''
      *               @ALL        1
      *               @user       8
      *               @staff      16
      #
      # Grant full access to logged in user's namespace
      user:%USER%:*   %USER%      16
      #
      # Allow to browse own namespace via the index
      user:           %USER%      1
      #
      # Allow read only access to start page located in "user" namespace 
      user:start      %USER%      1
      #
      # Disable all access to user's home namespaces not owned by logged in user 
      # (include view namespaces via the index) 
      user:*          @user       1
      user:*          @ALL        0
    '';
    # usersFile = config.deployment.keys.dokuwiki-users.path;

    extraConfig = ''
      $conf['title'] = 'DMND';
      $conf['lang'] = 'en';
      $conf['mailfrom'] = 'noreply@dmnd.sh';
      $conf['plugin']['smtp']['smtp_host'] = 'smtp.zoho.com';
      $conf['plugin']['smtp']['smtp_port'] = 587;
      $conf['plugin']['smtp']['smtp_ssl'] = 'tls';
      ${builtins.readFile ./dokuwiki-smtp.key} 
    '';

    plugins = [
      plugin-smtp
      plugin-tag
      plugin-pagelist # required for plugin-tag  
      plugin-mathjax
    ];

    nginx = {
      enableACME = true;
      forceSSL = true;
    };
  };
}
