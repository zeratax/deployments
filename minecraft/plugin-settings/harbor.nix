{ }:
{
  "Harbor/config.yml" = {
    night-skip = {
      enabled = true;
      percentage = 50;
      time-rate = 70;
      daytime-ticks = 1200;
      instant-skip = false;
      proportional-acceleration = false;
      clear-rain = true;
      clear-thunder = true;
      reset-phantom-statistic = true;
    };
    exclusions = {
      ignored-permission = true;
      exclude-adventure = true;
      exclude-creative = true;
      exclude-spectator = true;
      exclude-vanished = true;
    };
    afk-detection = {
      enabled = true;
      timeout = 15;
    };
    blacklisted-worlds = [
      "world_nether"
      "world_the_end"
    ];
    whitelist-mode = false;

    messages = {
      chat = {
        enabled = true;
        message-cooldown = 5;
        player-sleeping = "&e[player] is now sleeping ([sleeping]/[needed], [more] more needed to skip).";
        player-left-bed = "&e[player] got out of bed ([sleeping]/[needed], [more] more needed to skip).";
        night-skipping = [
          "&eAccelerating the night."
          "&eRapidly approaching daytime."
        ];
        night-skipped = [
          "&eThe night has been skipped."
          "&eAhhh, finally morning."
          "&eArghh, it's so bright outside."
          "&eRise and shine."
        ];
      };
      actionbar = {
        enabled = true;
        players-sleeping = "&e[sleeping] out of [needed] players are sleeping ([more] more needed to skip)";
        night-skipping = "&eEveryone is sleeping- sweet dreams!";
      };
      bossbar = {
        enabled = true;
        players-sleeping = {
          message = "&f&l[sleeping] out of [needed] are sleeping &7&l([more] more needed)";
          color = "BLUE";
        };
        night-skipping = {
          message = "&f&lEveryone is sleeping. Sweet dreams!";
          color = "GREEN";
        };
      };
      miscellaneous = {
        chat-prefix = "&8&l(&6&lHarbor&8&l)&f ";
        unrecognized-command = "Unrecognized command.";
      };
    };
    interval = 1;
    metrics = true;
    debug = false;
    version = "1.6.2";
  };
}
