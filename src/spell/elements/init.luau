local Types = require("@src/spell/elements/Types")

export type Context = Types.Context
export type ElementModule = Types.ElementModule

local module = {}

module.Registry = {
    Arcana = require("@src/spell/elements/Arcana"),
    Fire = require("@src/spell/elements/Fire"),
    Water = require("@src/spell/elements/Water"),
    Air = require("@src/spell/elements/Air"),
    Ground = require("@src/spell/elements/Ground"),
    Life = require("@src/spell/elements/Life"),
    Space = require("@src/spell/elements/Space"),
    Gravity = require("@src/spell/elements/Gravity"),
    Light = require("@src/spell/elements/Light"),
    Steam = require("@src/spell/elements/Steam"),
    Magma = require("@src/spell/elements/Magma"),
    Wildfire = require("@src/spell/elements/Wildfire"),
    Mist = require("@src/spell/elements/Mist"),
    Mud = require("@src/spell/elements/Mud"),
    Sandstorm = require("@src/spell/elements/Sandstorm"),
    Spirit = require("@src/spell/elements/Spirit"),
    Bloom = require("@src/spell/elements/Bloom"),
    Verdure = require("@src/spell/elements/Verdure"),
    Ash = require("@src/spell/elements/Ash"),
    Singularity = require("@src/spell/elements/Singularity"),
    Star = require("@src/spell/elements/Star"),
    Crystal = require("@src/spell/elements/Crystal"),
    Prism = require("@src/spell/elements/Prism"),
    Solar = require("@src/spell/elements/Solar"),
    Meteor = require("@src/spell/elements/Meteor"),
    Abyss = require("@src/spell/elements/Abyss"),
    Tempest = require("@src/spell/elements/Tempest"),
    Bedrock = require("@src/spell/elements/Bedrock"),
    Nebula = require("@src/spell/elements/Nebula"),
    Aether = require("@src/spell/elements/Aether"),
    Moon = require("@src/spell/elements/Moon"),
    Dawn = require("@src/spell/elements/Dawn"),
    Dream = require("@src/spell/elements/Dream"),
    Wither = require("@src/spell/elements/Wither"),
    Beacon = require("@src/spell/elements/Beacon"),
    Eclipse = require("@src/spell/elements/Eclipse"),
    Mirage = require("@src/spell/elements/Mirage"),
    Volt = require("@src/spell/elements/Volt"),
    Plasma = require("@src/spell/elements/Plasma"),
    Storm = require("@src/spell/elements/Storm"),
    Ion = require("@src/spell/elements/Ion"),
    Magnet = require("@src/spell/elements/Magnet"),
    Nerve = require("@src/spell/elements/Nerve"),
    Laser = require("@src/spell/elements/Laser"),
    Aurora = require("@src/spell/elements/Aurora"),
    Pulsar = require("@src/spell/elements/Pulsar"),
    Decay = require("@src/spell/elements/Decay"),
    Ruin = require("@src/spell/elements/Ruin"),
    Oblivion = require("@src/spell/elements/Oblivion"),
    Time = require("@src/spell/elements/Time"),
    Mind = require("@src/spell/elements/Mind"),
    Smolder = require("@src/spell/elements/Smolder"),
    Glacier = require("@src/spell/elements/Glacier"),
    Echo = require("@src/spell/elements/Echo"),
    Fossil = require("@src/spell/elements/Fossil"),
    Elder = require("@src/spell/elements/Elder"),
    Twilight = require("@src/spell/elements/Twilight"),
    Flash = require("@src/spell/elements/Flash"),
    Eternity = require("@src/spell/elements/Eternity"),
    Stasis = require("@src/spell/elements/Stasis"),
    Erosion = require("@src/spell/elements/Erosion"),
    Fervor = require("@src/spell/elements/Fervor"),
    Reverie = require("@src/spell/elements/Reverie"),
    Whisper = require("@src/spell/elements/Whisper"),
    Resolve = require("@src/spell/elements/Resolve"),
    Instinct = require("@src/spell/elements/Instinct"),
    Clarity = require("@src/spell/elements/Clarity"),
    Impulse = require("@src/spell/elements/Impulse"),
    Memory = require("@src/spell/elements/Memory"),
    Astral = require("@src/spell/elements/Astral"),
    Burden = require("@src/spell/elements/Burden"),
} :: {[string]: Types.ElementModule}

module.BaseOrder = {"Arcana", "Fire", "Water", "Air", "Ground", "Life", "Light", "Volt", "Time", "Space", "Gravity", "Mind", "Decay", "Ruin"}

module.Corruptors = {
    Decay = true,
    Ruin = true,
} :: {[string]: boolean}

module.MixOrder = {
    "Steam", "Magma", "Wildfire", "Mist", "Mud", "Sandstorm",
    "Bloom", "Verdure", "Ash", "Spirit", "Crystal", "Prism",
    "Solar", "Meteor", "Abyss", "Tempest", "Bedrock", "Nebula",
    "Aether", "Moon", "Dawn", "Dream", "Wither", "Beacon",
    "Eclipse", "Mirage", "Plasma", "Storm", "Ion", "Magnet",
    "Nerve", "Laser", "Aurora", "Pulsar", "Smolder", "Erosion",
    "Glacier", "Echo", "Fossil", "Elder", "Twilight", "Flash",
    "Eternity", "Stasis", "Oblivion", "Singularity", "Star",
    "Fervor", "Reverie", "Whisper", "Resolve", "Instinct",
    "Clarity", "Impulse", "Memory", "Astral", "Burden",
}

local MixTable = {
    ["Air+Fire"] = "Wildfire",
    ["Fire+Water"] = "Steam",
    ["Fire+Ground"] = "Magma",
    ["Ground+Water"] = "Mud",
    ["Air+Water"] = "Mist",
    ["Air+Ground"] = "Sandstorm",
    ["Air+Life"] = "Spirit",
    ["Life+Water"] = "Bloom",
    ["Ground+Life"] = "Verdure",
    ["Fire+Life"] = "Ash",
    ["Ground+Light"] = "Crystal",
    ["Light+Water"] = "Prism",
    ["Gravity+Space"] = "Singularity",
    ["Fire+Space"] = "Star",
    ["Fire+Light"] = "Solar",
    ["Fire+Gravity"] = "Meteor",
    ["Gravity+Water"] = "Abyss",
    ["Air+Gravity"] = "Tempest",
    ["Gravity+Ground"] = "Bedrock",
    ["Space+Water"] = "Nebula",
    ["Air+Space"] = "Aether",
    ["Ground+Space"] = "Moon",
    ["Life+Light"] = "Dawn",
    ["Life+Space"] = "Dream",
    ["Gravity+Life"] = "Wither",
    ["Light+Space"] = "Beacon",
    ["Gravity+Light"] = "Eclipse",
    ["Air+Light"] = "Mirage",
    ["Fire+Volt"] = "Plasma",
    ["Volt+Water"] = "Storm",
    ["Air+Volt"] = "Ion",
    ["Ground+Volt"] = "Magnet",
    ["Life+Volt"] = "Nerve",
    ["Light+Volt"] = "Laser",
    ["Space+Volt"] = "Aurora",
    ["Gravity+Volt"] = "Pulsar",
    ["Decay+Ruin"] = "Oblivion",
    ["Fire+Time"] = "Smolder",
    ["Time+Water"] = "Erosion",
    ["Air+Time"] = "Echo",
    ["Ground+Time"] = "Fossil",
    ["Life+Time"] = "Elder",
    ["Light+Time"] = "Twilight",
    ["Time+Volt"] = "Flash",
    ["Space+Time"] = "Eternity",
    ["Gravity+Time"] = "Stasis",
    ["Fire+Mind"] = "Fervor",
    ["Mind+Water"] = "Reverie",
    ["Air+Mind"] = "Whisper",
    ["Ground+Mind"] = "Resolve",
    ["Life+Mind"] = "Instinct",
    ["Light+Mind"] = "Clarity",
    ["Mind+Volt"] = "Impulse",
    ["Mind+Time"] = "Memory",
    ["Mind+Space"] = "Astral",
    ["Gravity+Mind"] = "Burden",
}

function module.MixOf(a: string, b: string): string?
    local first, second = a, b
    if second < first then
        first, second = second, first
    end
    return MixTable[`{first}+{second}`]
end

function module.MixesOf(name: string): {{with: string, result: string}}
    local mixes = {}
    for pair, result in pairs(MixTable) do
        local a, b = string.match(pair, "^(.+)%+(.+)$")
        if a == name then
            table.insert(mixes, {with = b :: string, result = result})
        elseif b == name then
            table.insert(mixes, {with = a :: string, result = result})
        end
    end
    table.sort(mixes, function(x, y)
        return x.result < y.result
    end)
    return mixes
end

function module.Recipe(result: string): (string?, string?)
    for pair, mixed in pairs(MixTable) do
        if mixed == result then
            local a, b = string.match(pair, "^(.+)%+(.+)$")
            return a, b
        end
    end
    return nil, nil
end

function module.Get(name: string?): Types.ElementModule
    return module.Registry[name or "Arcana"] or module.Registry.Arcana
end

return module
