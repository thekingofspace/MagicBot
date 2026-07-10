export type ShardInfo = {
    SessionID: any,
    RST: number, -- last received sequence number
    HeartCount: number, -- heartbeat interval, in seconds
    ResumeGate: string?,
    Acked: boolean?, -- whether the last heartbeat was acknowledged
    Guilds: { { id: string, unavailable: boolean? } },
}

export type Client<self> = {
    Token: string,
    Intents: number,
    Shards: number,

    RestSend: (self: self, Method: string, Path: string, Body: any?, Headers: { [string]: any }?) -> any,
    SendSocket: (self: self, Packet: any, Server: (string | number)?) -> self,
    SendShard: (self: self, Packet: any, Shard: number) -> self,
    SpawnEvent: (self: self, Event: string, ...any) -> self,
    IsEvent: (self: self, Event: string) -> boolean,
    On: (self: self, Event: string, Callback: (...any) -> ()) -> self,
    Off: (self: self, Event: string) -> self,
    GetShardInfo: (self: self, Shard: number) -> ShardInfo?,

    Start: (self: self) -> self,
    Stop: (self: self) -> self,
}

export type Private<self> = {
    -- Event handler tasks; cancelled by t_DestroyThreadStatic
    __StaticThreads: { [Task]: number },

    -- Gateway read/heartbeat tasks; cancelled by t_KillProcess on Stop
    __ProcessorThreads: { [Task]: number },

    -- One live gateway socket per shard, keyed by shard id
    __Gateways: { [number]: WebSocket },

    __ShardInfo: { [number]: ShardInfo },

    -- Event name (lowercase) -> registered callbacks
    __StaticEntries: { [string]: { (...any) -> () } },

    __Resumable: boolean,
    __Running: boolean,
    __ShardRec: number,

    __GetGateway: (self: self, Shard: number, ResumeURL: string?) -> WebSocket,
    __GetGuildShard: (self: self, guildId: string | number, shardCount: number) -> number,
    __Identify: (self: self, Gate: WebSocket, Shard: number) -> (),
    __Resume: (self: self, Gate: WebSocket, Shard: number) -> (),
}

export type ThreadMethods<self> = {
    t_SpawnProcess: (self: self, FN: (...any) -> (), ...any) -> self,
    t_KillProcess: (self: self) -> self,

    t_CreateStatic: (self: self, ID: string, FN: (...any) -> ()) -> self,
    t_RemoveStatic: (self: self, ID: string) -> self,
    t_RunStatic: (self: self, ID: string, ...any) -> self,
    t_DestroyThreadStatic: (self: self) -> self,

    -- Legacy spellings, kept so older bot code keeps working
    t_SpawnProccess: (self: self, FN: (...any) -> (), ...any) -> self,
    t_KillProccess: (self: self) -> self,
}

export type Localizer = Client<Localizer> & Private<Localizer> & ThreadMethods<Localizer>

return true
