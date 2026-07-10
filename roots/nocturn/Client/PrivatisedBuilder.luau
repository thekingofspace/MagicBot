--#include[net, serde, process]
local Types = require("./Types")

local GatewayURL = "wss://gateway.discord.gg/?v=10&encoding=json"
local DefaultHeartbeat = 41.25

return {
    StaticThreads = {},
    ProcessorThreads = {},
    Gateways = {},
    StaticEntries = {},
    ShardInfo = {},
    ShardRec = 0,
    Resumable = false,
    Running = false,

    GetGateway = function(self: Types.Localizer, Shard: number, ResumeURL: string?): WebSocket
        local Gate = net.ws.connect(ResumeURL or GatewayURL)
        self.__Gateways[Shard] = Gate

        self.__ShardInfo[Shard] = self.__ShardInfo[Shard] or {
            RST = 0,
            HeartCount = DefaultHeartbeat,
            Guilds = {},
        }

        return Gate
    end,

    Identify = function(self: Types.Localizer, Gate: WebSocket, Shard: number)
        -- send may throw if the socket dropped right after connecting; the read loop handles the reconnect
        pcall(function()
            Gate:send(serde.encode("json", {
                op = 2,
                d = {
                    token = self.Token,
                    intents = self.Intents,
                    properties = {
                        os = process.platform,
                        browser = "nocturn",
                        device = "nocturn",
                    },
                    shard = { Shard, self.Shards },
                },
            }))
        end)
    end,

    Resume = function(self: Types.Localizer, Gate: WebSocket, Shard: number)
        local Info = self.__ShardInfo[Shard]

        pcall(function()
            Gate:send(serde.encode("json", {
                op = 6,
                d = {
                    token = self.Token,
                    session_id = Info.SessionID,
                    seq = Info.RST,
                },
            }))
        end)

        self:SpawnEvent("Resume", nil, Shard)
    end,

    -- Discord snowflakes exceed 32 bits, so this must be plain math, not bit32
    GetGuildShard = function(self: Types.Localizer, guildId: string | number, shardCount: number): number
        local Id = tonumber(guildId) or 0
        return math.floor(Id / 4194304) % math.max(shardCount, 1) -- (id >> 22) % shards
    end,
}
