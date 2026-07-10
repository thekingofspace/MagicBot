local PluginBuilder = require("@self/PluginBuilder")
local PrivateBuilder = require("@self/PrivatisedBuilder")
local Threading = require("@self/ThreadManager")
local PublicBuilder = require("@self/PublicBuilders")
local Types = require("@self/Types")

-- Per-client default state, cloned into every new client
local StandardProperties: { [string]: any } = {}

-- Shared method table, resolved through the metatable
local StandardMethods: { [string]: any } = {}

for Key, Item in pairs(PrivateBuilder) do
    if typeof(Item) == "function" then
        StandardMethods["__" .. Key] = Item
    else
        StandardProperties["__" .. Key] = Item
    end
end

for Key, Item in pairs(Threading) do
    StandardMethods["t_" .. Key] = Item
end

for Key, Item in pairs(PublicBuilder) do
    if typeof(Item) == "function" then
        StandardMethods[Key] = Item
    else
        StandardProperties[Key] = Item
    end
end

local Metatable = {
    __index = function(_, Key: string)
        return StandardMethods[Key] or PluginBuilder.ExposedMethods[Key]
    end,

    __newindex = function(self, Key: string, Value: any)
        -- Built-in and plugin methods cannot be overwritten
        if StandardMethods[Key] or PluginBuilder.ExposedMethods[Key] then
            return
        end

        rawset(self, Key, Value)
    end,
}

return function(Token: string, Intents: number?, Shards: number?): Types.Localizer
    local Properties = {}

    for Key, Item in pairs(StandardProperties) do
        Properties[Key] = if typeof(Item) == "table" then table.clone(Item) else Item
    end

    local Client: Types.Localizer = setmetatable(Properties, Metatable) :: any

    Client.Token = Token
    Client.Intents = Intents or 1 -- GUILDS
    Client.Shards = Shards or 0 -- 0 = use Discord's recommended count

    PluginBuilder.ApplyPlugins(Client)

    return Client
end
