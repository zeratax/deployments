{}:
{
  "DiscordSRV/config.yml" = {
    AvatarUrl = "https://crafatar.com/avatars/{uuid-nodashes}.png?size={size}&overlay#{texture}";
    BotToken = "BOTTOKEN";
    CancelConsoleCommandIfLoggingFailed = true;
    ChannelTopicUpdaterChannelTopicsAtShutdownEnabled = true;
    ChannelTopicUpdaterRateInMinutes = 10;
    Channels = {
      global = "000000000000000000";
    };
    ConfigVersion = "1.22.0";
    DateFormat = "yyyy-MM-dd";
    DebugJDA = false;
    DebugJDARestActions = false;
    DebugLevel = 0;
    DisabledPluginHooks = [ ];
    DiscordCannedResponses = {
      "!ip" = "yourserveripchange.me";
      "!site" = "http://yoursiteurl.net";
    };
    DiscordChatChannelAllowedMentions = [ "user" "channel" "emote" ];
    DiscordChatChannelBlockBots = false;
    DiscordChatChannelBlockedIds = [ "000000000000000000" "000000000000000000" "000000000000000000" ];
    DiscordChatChannelBroadcastDiscordMessagesToConsole = true;
    DiscordChatChannelConsoleCommandEnabled = true;
    DiscordChatChannelConsoleCommandExpiration = 0;
    DiscordChatChannelConsoleCommandExpirationDeleteRequest = true;
    DiscordChatChannelConsoleCommandNotifyErrors = true;
    DiscordChatChannelConsoleCommandPrefix = "!c";
    DiscordChatChannelConsoleCommandRolesAllowed = [ "Developer" "Owner" ];
    DiscordChatChannelConsoleCommandWhitelist = [ "say" "lag" "tps" ];
    DiscordChatChannelConsoleCommandWhitelistActsAsBlacklist = false;
    DiscordChatChannelConsoleCommandWhitelistBypassRoles = [ "Owner" "Developer" ];
    DiscordChatChannelDiscordFilters = {
      ".*Online players\\(.*" = "";
      ".*\\*\\*No online players\\*\\*.*" = "";
    };
    DiscordChatChannelDiscordToMinecraft = true;
    DiscordChatChannelGameFilters = { };
    DiscordChatChannelListCommandEnabled = true;
    DiscordChatChannelListCommandExpiration = 10;
    DiscordChatChannelListCommandExpirationDeleteRequest = true;
    DiscordChatChannelListCommandMessage = "playerlist";
    DiscordChatChannelMinecraftToDiscord = true;
    DiscordChatChannelPrefixRequiredToProcessMessage = "";
    DiscordChatChannelRequireLinkedAccount = false;
    DiscordChatChannelRoleAliases = {
      Developer = "Dev";
    };
    DiscordChatChannelRolesAllowedToUseColorCodesInChat = [ "Developer" "Owner" "Admin" "Moderator" ];
    DiscordChatChannelRolesSelection = [ "Don't show me!" "Misc role" ];
    DiscordChatChannelRolesSelectionAsWhitelist = false;
    DiscordChatChannelTranslateMentions = true;
    DiscordChatChannelTruncateLength = 256;
    DiscordConsoleChannelAllowPluginUpload = false;
    DiscordConsoleChannelBlacklistActsAsWhitelist = false;
    DiscordConsoleChannelBlacklistedCommands = [ "?" "op" "deop" "execute" ];
    DiscordConsoleChannelFilters = {
      ".*(?i)async chat thread.*" = "";
      ".*There are \\d+ of a max of \\d+ players online.*" = "";
    };
    DiscordConsoleChannelId = "000000000000000000";
    DiscordConsoleChannelLevels = [ "info" "warn" "error" ];
    DiscordConsoleChannelLogRefreshRateInSeconds = 5;
    DiscordConsoleChannelUsageLog = "Console-%date%.log";
    DiscordGameStatus = "Minecraft";
    DiscordInviteLink = "discord.gg/changethisintheconfig.yml";
    EnablePresenceInformation = false;
    Experiment_JdbcAccountLinkBackend = "jdbc:mysql://HOST:PORT/DATABASE?autoReconnect=true&useSSL=false";
    Experiment_JdbcPassword = "password";
    Experiment_JdbcTablePrefix = "discordsrv";
    Experiment_JdbcUsername = "username";
    Experiment_MCDiscordReserializer_InBroadcast = false;
    Experiment_MCDiscordReserializer_ToDiscord = false;
    Experiment_MCDiscordReserializer_ToMinecraft = false;
    Experiment_WebhookChatMessageAvatarFromDiscord = false;
    Experiment_WebhookChatMessageDelivery = false;
    Experiment_WebhookChatMessageFormat = "%message%";
    Experiment_WebhookChatMessageUsernameFormat = "%displayname%";
    Experiment_WebhookChatMessageUsernameFromDiscord = false;
    ForceTLSv12 = true;
    ForcedLanguage = "none";
    MaximumAttemptsForSystemDNSBeforeUsingFallbackDNS = 3;
    MinecraftDiscordAccountLinkedAllowRelinkBySendingANewCode = false;
    MinecraftDiscordAccountLinkedConsoleCommands = [ "" "" "" ];
    MinecraftDiscordAccountLinkedRoleNameToAddUserTo = "Linked";
    MinecraftDiscordAccountUnlinkedConsoleCommands = [ "" "" "" ];
    NoopHostnameVerifier = false;
    ParseEmojisToNames = true;
    PrintGuildsAndChannels = true;
    ServerWatchdogEnabled = true;
    ServerWatchdogMessageCount = 3;
    ServerWatchdogTimeout = 30;
    StatusUpdateRateInMinutes = 2;
    TimestampFormat = "EEE, d. MMM yyyy HH:mm:ss z";
    Timezone = "UTC";
    UseModernPaperChatEvent = false;
    VentureChatBungee = false;
  };
}
