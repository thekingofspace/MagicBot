--#include[net, serde, task, stdio]
local Types = require("./Types")
local PluginBuilder = require("./PluginBuilder")

local EndPoint = "https://discord.com/api/v10"
local GatewayQuery = "?v=10&encoding=json"
local MaxRestRetries = 5
local IdentifyDelay = 5.5

-- Close codes that must not be reconnected (bad auth or bad configuration)
local FatalCloseCodes = {
    [4004] = true, -- authentication failed
    [4010] = true, -- invalid shard
    [4011] = true, -- sharding required
    [4012] = true, -- invalid API version
    [4013] = true, -- invalid intents
    [4014] = true, -- disallowed intents
}

-- Close codes after which the session is dead and a fresh identify is required
local ReidentifyCloseCodes = {
    [4003] = true, -- not authenticated
    [4007] = true, -- invalid sequence
    [4009] = true, -- session timed out
}

-- Reads frames until a decoded gateway payload or a close arrives.
-- Returns nil when the connection is gone, or { close = code } for close frames.
local function ReadPacket(Gate: WebSocket): any
    while true do
        local ok, Message = pcall(function()
            return Gate:receive()
        end)

        if not ok or Message == nil then
            return nil
        end

        if Message.type == "text" and Message.data then
            local decodedOk, Decoded = pcall(function()
                return serde.decode("json", Message.data :: string)
            end)

            if decodedOk then
                return Decoded
            end
        elseif Message.type == "close" then
            return { close = Message.code or 4000, reason = Message.reason }
        end
    end
end

local function SendJson(Gate: WebSocket, Packet: any): boolean
    return (pcall(function()
        Gate:send(serde.encode("json", Packet))
    end))
end

--[[
    Owns one shard for the lifetime of the client: connects, identifies or
    resumes, heartbeats, dispatches events, and reconnects on failure.
    Settle is called once, when the shard first becomes ready (or permanently fails).
]]
local function RunShard(self: Types.Localizer, Shard: number, Settle: (ReadyData: any?) -> ())
    local WantResume = self.__Resumable

    while self.__Running do
        local Existing = self.__ShardInfo[Shard]
        local ResumeURL = if WantResume and Existing then Existing.ResumeGate else nil

        local Gate = self:__GetGateway(Shard, ResumeURL)
        local Info = self.__ShardInfo[Shard]

        -- Discord opens with Hello (op 10) carrying the heartbeat interval
        local Hello = ReadPacket(Gate)

        if not Hello or Hello.close then
            if Hello and FatalCloseCodes[Hello.close] then
                stdio.ewrite(`[nocturn] Shard {Shard} was refused with fatal close code {Hello.close}: {Hello.reason or "?"}\n`)
                self:SpawnEvent("Shard_Closed", Hello.close, Shard)
                break
            end

            task.wait(2)
            continue
        end

        if Hello.op == 10 then
            Info.HeartCount = Hello.d.heartbeat_interval / 1000
        end

        if WantResume and Info.SessionID then
            self:__Resume(Gate, Shard)
        else
            self:__Identify(Gate, Shard)
        end

        Info.Acked = true

        local Beater = task.spawn(function()
            task.wait(Info.HeartCount * math.random()) -- jitter, per Discord docs

            while true do
                if not Info.Acked then
                    -- No ACK since the last beat: zombie connection, force a reconnect
                    pcall(function()
                        Gate:close(4000, "heartbeat timeout")
                    end)
                    break
                end

                Info.Acked = false

                if not SendJson(Gate, { op = 1, d = Info.RST }) then
                    break
                end

                self:SpawnEvent("Heartbeat", nil, Shard)
                task.wait(Info.HeartCount)
            end
        end)
        self.__ProcessorThreads[Beater] = os.time()

        local CloseCode: number? = nil
        local NextAction = "resume"

        while true do
            local Packet = ReadPacket(Gate)

            if not Packet then
                break
            end

            if Packet.close then
                CloseCode = Packet.close
                break
            end

            if Packet.s then
                Info.RST = Packet.s
            end

            if Packet.op == 11 then -- heartbeat ACK
                Info.Acked = true
            elseif Packet.op == 1 then -- server requested an immediate heartbeat
                SendJson(Gate, { op = 1, d = Info.RST })
            elseif Packet.op == 7 then -- server requested a reconnect + resume
                pcall(function()
                    Gate:close(4000, "reconnect requested")
                end)
                break
            elseif Packet.op == 9 then -- invalid session; d says whether it is resumable
                NextAction = if Packet.d == true then "resume" else "identify"
                pcall(function()
                    Gate:close(4000, "invalid session")
                end)
                break
            elseif Packet.op == 0 and Packet.t then -- dispatch
                local EventName = Packet.t:lower()

                self:t_SpawnProcess(PluginBuilder.OnEvent, self, EventName, Packet.d, Shard)

                if Packet.t == "READY" then
                    Info.SessionID = Packet.d.session_id

                    if Packet.d.resume_gateway_url then
                        Info.ResumeGate = Packet.d.resume_gateway_url .. GatewayQuery
                    end

                    table.clear(Info.Guilds)
                    for _, Guild in ipairs(Packet.d.guilds) do
                        table.insert(Info.Guilds, Guild)
                    end

                    self:SpawnEvent("Shard_Started", Packet.d, Shard)
                    Settle(Packet.d)
                elseif Packet.t == "RESUMED" then
                    Settle(nil)
                    self:SpawnEvent(Packet.t, Packet.d, Shard)
                elseif PluginBuilder.IgnoreList[EventName] ~= true then
                    self:SpawnEvent(Packet.t, Packet.d, Shard)
                end
            end
        end

        pcall(function()
            Beater:Cancel()
        end)
        self.__ProcessorThreads[Beater] = nil

        if not self.__Running then
            break
        end

        if CloseCode and FatalCloseCodes[CloseCode] then
            stdio.ewrite(`[nocturn] Shard {Shard} closed with fatal code {CloseCode}; not reconnecting.\n`)
            self:SpawnEvent("Shard_Closed", CloseCode, Shard)
            break
        end

        if NextAction == "identify" or (CloseCode and ReidentifyCloseCodes[CloseCode]) then
            WantResume = false
            task.wait(1 + math.random() * 4) -- 1-5s before re-identifying, per Discord docs
        else
            WantResume = true
            task.wait(0.5)
        end
    end

    Settle(nil)
end

return {
    RestSend = function(self: Types.Localizer, Method: string, Path: string, Body: any?, Headers: { [string]: any }?)
        local RequestHeaders: { [string]: any } = {
            ["Authorization"] = `Bot {self.Token}`,
            ["Content-Type"] = "application/json",
        }

        if Headers then
            for Key, Value in pairs(Headers) do
                RequestHeaders[Key] = Value
            end
        end

        local Options: HttpRequestOptions = {
            url = `{EndPoint}/{Path}`,
            method = Method:upper(),
            headers = RequestHeaders,
        }

        if typeof(Body) == "table" then
            Options.json = Body
        elseif Body ~= nil then
            Options.body = Body
        end

        local Response: HttpResponse

        for _ = 1, MaxRestRetries do
            Response = net.http.request(Options)

            if Response.status ~= 429 then
                break
            end

            local RetryAfter = tonumber(Response.headers["retry-after"]) or 1
            local ok, ErrorBody = pcall(function()
                return serde.decode("json", Response.body)
            end)

            if ok and typeof(ErrorBody) == "table" and tonumber(ErrorBody.retry_after) then
                RetryAfter = tonumber(ErrorBody.retry_after) :: number
            end

            task.wait(RetryAfter + 0.05)
        end

        if not Response.ok then
            error(`[nocturn] {Method:upper()} /{Path} failed ({Response.status} {Response.statusText}):\n{Response.body}`)
        end

        if Response.body == nil or Response.body == "" then
            return nil
        end

        local ok, Decoded = pcall(function()
            return serde.decode("json", Response.body)
        end)
        return if ok then Decoded else Response.body
    end,

    SpawnEvent = function(self: Types.Localizer, Event: string, ...)
        local Key = Event:lower()

        if self.__StaticEntries[Key] then
            self:t_RunStatic(Key, ...)
        elseif self.__StaticEntries["undefined"] then
            self:t_RunStatic("undefined", Key, ...)
        end

        return self
    end,

    SendSocket = function(self: Types.Localizer, Packet: any, Server: (string | number)?)
        if Server ~= nil then
            local ShardId = self:__GetGuildShard(Server, self.Shards)
            local Gate = self.__Gateways[ShardId]

            if Gate then
                SendJson(Gate, Packet)
            end
        else
            for _, Gate in pairs(self.__Gateways) do
                SendJson(Gate, Packet)
            end
        end

        return self
    end,

    SendShard = function(self: Types.Localizer, Packet: any, Shard: number)
        local Gate = self.__Gateways[Shard]

        if Gate then
            SendJson(Gate, Packet)
        end

        return self
    end,

    IsEvent = function(self: Types.Localizer, Event: string)
        return self.__StaticEntries[Event:lower()] ~= nil
    end,

    GetShardInfo = function(self: Types.Localizer, Shard: number)
        return self.__ShardInfo[Shard]
    end,

    On = function(self: Types.Localizer, Event: string, Callback: (...any) -> ())
        self:t_CreateStatic(Event, Callback)
        return self
    end,

    Off = function(self: Types.Localizer, Event: string)
        self:t_RemoveStatic(Event)
        return self
    end,

    Start = function(self: Types.Localizer)
        if self.__Running then
            return self
        end

        local GatewayInfo = self:RestSend("GET", "gateway/bot")
        self.__ShardRec = GatewayInfo.shards

        if self.Shards == 0 then
            self.Shards = GatewayInfo.shards
        end

        if self.Shards ~= GatewayInfo.shards then
            print(`[nocturn] Shard count differs from Discord's recommendation (using {self.Shards}, recommended {GatewayInfo.shards}).`)
        end

        local SessionLimit = GatewayInfo.session_start_limit or {}
        local MaxConcurrency = SessionLimit.max_concurrency or 1

        self.__Running = true

        self:SpawnEvent("Start", nil, 0)
        PluginBuilder.OnStart(self)

        local Ready = { guilds = {} }
        local Pending = self.Shards
        local ActiveIdentifies = 0

        for I = 1, self.Shards do
            local Shard = I - 1

            while ActiveIdentifies >= MaxConcurrency do
                task.wait(0.1)
            end

            ActiveIdentifies += 1

            local Settled = false
            local function Settle(ReadyData: any?)
                if Settled then
                    return
                end
                Settled = true

                if ReadyData then
                    Ready.user = Ready.user or ReadyData.user
                    Ready.application = Ready.application or ReadyData.application
                    Ready.guilds[Shard] = self.__ShardInfo[Shard].Guilds
                end

                ActiveIdentifies -= 1
                Pending -= 1
            end

            self:t_SpawnProcess(RunShard, self, Shard, Settle)

            if MaxConcurrency == 1 and I ~= self.Shards then
                task.wait(IdentifyDelay)
            end
        end

        while Pending > 0 do
            task.wait(0.1)
        end

        self:SpawnEvent("Started", nil, 0)
        self:SpawnEvent("Ready", Ready, 0)

        return self
    end,

    Stop = function(self: Types.Localizer)
        self.__Running = false

        PluginBuilder.OnStop(self)

        for _, Gate in pairs(self.__Gateways) do
            pcall(function()
                Gate:close(4000, "client stopped") -- non-1000 close keeps the session resumable
            end)
        end

        table.clear(self.__Gateways)

        self.__Resumable = true

        self:t_DestroyThreadStatic()
        self:t_KillProcess()

        return self
    end,
}
