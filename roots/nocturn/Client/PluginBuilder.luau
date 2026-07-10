--#include[stdio]
local Module = {}
local Types = require("./Types")

-- Event names (lowercase) that plugins have claimed; suppressed from user event dispatch
Module.IgnoreList = {} :: { [string]: boolean }

-- Methods plugins expose onto every client, resolved through the client metatable
Module.ExposedMethods = {} :: { [string]: (...any) -> any }

local LoadPlugins = {}

export type Plugin = {
    Name: string,
    Version: string,
    LoadOrder: number,

    RegisterMethod: (self: Plugin, Method: string, Callback: (self: Types.Localizer, ...any) -> any) -> Plugin,
    Ignore: (self: Plugin, Event: string) -> Plugin,

    LoadAction: ((client: Types.Localizer) -> ())?,
    StopAction: ((client: Types.Localizer) -> ())?,
    StartAction: ((client: Types.Localizer) -> ())?,
    EventAction: ((client: Types.Localizer, Event: string, Data: any) -> ())?,
}

local PluginMethods = {}
PluginMethods.__index = PluginMethods

function PluginMethods.Ignore(self: Plugin, Event: string): Plugin
    Module.IgnoreList[Event:lower()] = true
    return self
end

function PluginMethods.RegisterMethod(self: Plugin, Method: string, Callback: (self: Types.Localizer, ...any) -> any): Plugin
    Module.ExposedMethods[Method] = Callback
    return self
end

local function SafeCall(Plugin: Plugin, MethodName: string, Fn: ((...any) -> ())?, ...)
    if not Fn then
        return
    end

    local ok, err = pcall(Fn, ...)

    if not ok then
        stdio.ewrite(`[nocturn] Plugin "{Plugin.Name}" {MethodName} failed:\n{err}\n`)
    end
end

function Module.new(): Plugin
    local self = setmetatable({
        Name = "",
        Version = "",
        LoadOrder = 1,
    }, PluginMethods) :: any

    table.insert(LoadPlugins, self)
    return self
end

function Module.ApplyPlugins(Client: Types.Localizer)
    table.sort(LoadPlugins, function(A, B)
        return A.LoadOrder < B.LoadOrder
    end)

    for _, Item in ipairs(LoadPlugins) do
        SafeCall(Item, "LoadAction", Item.LoadAction, Client)
    end
end

function Module.OnStart(Client: Types.Localizer)
    for _, Item in ipairs(LoadPlugins) do
        SafeCall(Item, "StartAction", Item.StartAction, Client)
    end
end

function Module.OnStop(Client: Types.Localizer)
    for _, Item in ipairs(LoadPlugins) do
        SafeCall(Item, "StopAction", Item.StopAction, Client)
    end
end

function Module.OnEvent(Client: Types.Localizer, Event: string, Data: any, Shard: number?)
    for _, Item in ipairs(LoadPlugins) do
        SafeCall(Item, "EventAction", Item.EventAction, Client, Event, Data, Shard)
    end
end

-- Legacy global, kept so old plugin scripts written against `plugin.new()` keep working.
plugin = { new = Module.new }

return Module
