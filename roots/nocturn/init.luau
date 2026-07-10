local Client = require("@self/Client")
local PluginBuilder = require("@self/Client/PluginBuilder")
local Types = require("@self/Client/Types")

local Module = {}

export type Client = Types.Client<Client>
export type PrivatisedClient = Types.Localizer
export type Plugin = PluginBuilder.Plugin

-- Gateway intent flags; combine with Module.CombineIntents(...)
Module.Intents = {
    Guilds = bit32.lshift(1, 0),
    GuildMembers = bit32.lshift(1, 1),
    GuildModeration = bit32.lshift(1, 2),
    GuildExpressions = bit32.lshift(1, 3),
    GuildIntegrations = bit32.lshift(1, 4),
    GuildWebhooks = bit32.lshift(1, 5),
    GuildInvites = bit32.lshift(1, 6),
    GuildVoiceStates = bit32.lshift(1, 7),
    GuildPresences = bit32.lshift(1, 8),
    GuildMessages = bit32.lshift(1, 9),
    GuildMessageReactions = bit32.lshift(1, 10),
    GuildMessageTyping = bit32.lshift(1, 11),
    DirectMessages = bit32.lshift(1, 12),
    DirectMessageReactions = bit32.lshift(1, 13),
    DirectMessageTyping = bit32.lshift(1, 14),
    MessageContent = bit32.lshift(1, 15),
    GuildScheduledEvents = bit32.lshift(1, 16),
    AutoModerationConfiguration = bit32.lshift(1, 20),
    AutoModerationExecution = bit32.lshift(1, 21),
    GuildMessagePolls = bit32.lshift(1, 24),
    DirectMessagePolls = bit32.lshift(1, 25),
}

function Module.CombineIntents(...: number): number
    return bit32.bor(...)
end

Module._Bots = {} :: { [string]: Client }

function Module.new(Token: string, Intents: number?, Shards: number?): Client
    if Module._Bots[Token] then
        return Module._Bots[Token]
    end

    local Bot = Client(Token, Intents, Shards)
    Module._Bots[Token] = Bot :: any

    return Bot :: any
end

function Module.get(Token: string): Client?
    return Module._Bots[Token]
end

Module.CreatePlugin = PluginBuilder.new

return Module
