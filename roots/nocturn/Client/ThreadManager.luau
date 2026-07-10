--#include[task, stdio]
local Module = {}
local Types = require("./Types")

local function RunGuarded(fn, ...)
    local ok, err = pcall(fn, ...)

    if not ok then
        stdio.ewrite(`[nocturn] Task error: {err}\n`)
    end
end

-- Drop handles for tasks that already ran to completion so registries stay small
local function Sweep(Registry: { [Task]: number })
    for Handle in pairs(Registry) do
        if Handle:IsFinished() or Handle:IsCancelled() then
            Registry[Handle] = nil
        end
    end
end

local function Track(Registry: { [Task]: number }, fn, ...): Task
    Sweep(Registry)

    local Handle = task.spawn(RunGuarded, fn, ...)
    Registry[Handle] = os.time()

    return Handle
end

local function CancelAll(Registry: { [Task]: number })
    for Handle in pairs(Registry) do
        pcall(function()
            Handle:Cancel()
        end)
    end

    table.clear(Registry)
end

function Module.SpawnProcess(self: Types.Localizer, fn: (...any) -> (), ...)
    Track(self.__ProcessorThreads, fn, ...)
    return self
end

function Module.KillProcess(self: Types.Localizer)
    CancelAll(self.__ProcessorThreads)
    return self
end

function Module.CreateStatic(self: Types.Localizer, ID: string, FN: (...any) -> ())
    local Key = ID:lower()
    local Callbacks = self.__StaticEntries[Key]

    if not Callbacks then
        Callbacks = {}
        self.__StaticEntries[Key] = Callbacks
    end

    table.insert(Callbacks, FN)
    return self
end

function Module.RemoveStatic(self: Types.Localizer, ID: string)
    self.__StaticEntries[ID:lower()] = nil
    return self
end

function Module.RunStatic(self: Types.Localizer, ID: string, ...)
    local Callbacks = self.__StaticEntries[ID:lower()]

    if Callbacks then
        for _, Callback in ipairs(Callbacks) do
            Track(self.__StaticThreads, Callback, ...)
        end
    end

    return self
end

function Module.DestroyThreadStatic(self: Types.Localizer)
    CancelAll(self.__StaticThreads)
    return self
end

-- Legacy spellings, kept so older bot code keeps working
Module.SpawnProccess = Module.SpawnProcess
Module.KillProccess = Module.KillProcess

return Module
