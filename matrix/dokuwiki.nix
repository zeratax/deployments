{ pkgs, config, lib, ... }:

let
  domain = config.services.matrix-synapse.server_name;
  fqdn =
    let
      join = hostName: domain: hostName + lib.strings.optionalString (domain != null) ".${domain}";
    in
    join config.networking.hostName config.networking.domain;
in
{
  deployment.keys.dokuwiki-users.text = builtins.readFile ./dokuwiki-users.key;
  deployment.keys.dokuwiki-acl.text = builtins.readFile ./dokuwiki-acl.key;

  services.dokuwiki.dmnd = {
    enable = true;

    aclUse = true;
    aclFile = config.deployment.keys.dokuwiki-acl.path;
    userFile = config.deployment.keys.dokuwiki-users.path;

    hostName = fqdn;
    nginx = {
      enableACME = true;
      forceSSL = true;
      server_name = "any.${config.networking.domain}";
    };
  };
}
