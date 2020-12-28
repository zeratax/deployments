{ pkgs, config, lib, ...}:

let
  domain = config.services.matrix-synapse.server_name;
  fqdn =
    let
      join = hostName: domain: hostName + lib.strings.optionalString (domain != null) ".${domain}";
    in join config.networking.hostName config.networking.domain;
in {
  deployment.keys.mautrix-telegram-secrets.text = builtins.readFile ./mautrix-telegram-secrets.key;

  services.mautrix-telegram = {
    enable = true;
    environmentFile = /run/keys/mautrix-telegram-secrets;
    settings = {
      homeserver = {
        address = "http://localhost:8008";
        domain = domain;
      };
      appservice = {
        provisioning = {
          enabled = true;
          prefix = "/_matrix/appservice-telegram/provision";
        };
        id = "telegram";
        public = {
          enabled = true;
          prefix = "/_matrix/appservice-telegram";
          external = "https://${fqdn}/_matrix/appservice-telegram";
        };
        bot_username =  "_telegram_bot";
        bot_displayname = "Telegram Bridge Bot";
        bot_avatar = "mxc://maunium.net/tJCRmUyJDsgRNgqhOgoiHWbX";
      };
      bridge = {
        permissions = {
          "@pascal:${domain}" = "admin";
          "@kaine:${domain}" = "admin";
        };
      };
    };
  };
}
