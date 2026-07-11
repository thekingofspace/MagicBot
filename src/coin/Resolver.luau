--#include[random]
local Parser = require("@src/spell/Parser")

-- The mint. A coin design pools every rune in the border (rings, clusters,
-- and inner circles all melt into one crucible) and solves a single coin:
-- material, shape, emblem, edge, and an assayed value in bits.

local Rng = random.new()

export type Rgb = {r: number, g: number, b: number}

export type Material = {
    Name: string,
    Nobility: number,
    Light: Rgb,
    Mid: Rgb,
    Dark: Rgb,
    Deep: Rgb,
}

export type Emblem = {
    letter: string,
    name: string,
    phrase: string,
    power: number,
}

export type CoinPlan = {
    material: string,
    fineness: number,
    inlay: string?,
    shape: string, -- "round" | "square" | "wedge" | "scallop"
    holed: boolean,
    sizeMarks: number,
    diameter: number,
    emblem: Emblem?,
    mintmarks: {Emblem},
    numeral: string?,
    milled: boolean,
    spiral: number, -- +sunwise, -widdershins
    patina: number,
    wear: number,
    hammered: boolean,
    value: number,
    tier: string,
    denomination: string,
    name: string,
    edge: string,
    strike: string,
    seed: number,
    description: string,
    notes: {string},
}

local module = {}

module.Materials = {
    gold = {Name = "Gold", Nobility = 9,
        Light = {r = 255, g = 232, b = 150}, Mid = {r = 216, g = 178, b = 88},
        Dark = {r = 150, g = 110, b = 40}, Deep = {r = 84, g = 58, b = 18}},
    silver = {Name = "Silver", Nobility = 6,
        Light = {r = 240, g = 243, b = 250}, Mid = {r = 192, g = 197, b = 210},
        Dark = {r = 120, g = 126, b = 142}, Deep = {r = 62, g = 66, b = 80}},
    copper = {Name = "Copper", Nobility = 3,
        Light = {r = 242, g = 178, b = 128}, Mid = {r = 190, g = 120, b = 74},
        Dark = {r = 126, g = 70, b = 40}, Deep = {r = 66, g = 34, b = 18}},
    iron = {Name = "Iron", Nobility = 2,
        Light = {r = 200, g = 202, b = 206}, Mid = {r = 134, g = 137, b = 143},
        Dark = {r = 82, g = 84, b = 92}, Deep = {r = 40, g = 42, b = 48}},
    voidmetal = {Name = "Voidmetal", Nobility = 12,
        Light = {r = 150, g = 128, b = 196}, Mid = {r = 74, g = 60, b = 104},
        Dark = {r = 38, g = 30, b = 58}, Deep = {r = 14, g = 10, b = 26}},
    electrum = {Name = "Electrum", Nobility = 7,
        Light = {r = 250, g = 242, b = 180}, Mid = {r = 212, g = 198, b = 128},
        Dark = {r = 142, g = 128, b = 66}, Deep = {r = 78, g = 68, b = 30}},
    ancientbronze = {Name = "Ancient Bronze", Nobility = 4,
        Light = {r = 196, g = 188, b = 140}, Mid = {r = 138, g = 126, b = 82},
        Dark = {r = 88, g = 80, b = 52}, Deep = {r = 44, g = 40, b = 24}},
    slag = {Name = "Slag", Nobility = 1,
        Light = {r = 172, g = 162, b = 146}, Mid = {r = 118, g = 108, b = 96},
        Dark = {r = 70, g = 64, b = 56}, Deep = {r = 34, g = 30, b = 26}},
} :: {[string]: Material}

local MetalRunes = {
    ["!"] = "gold",
    ["^"] = "electrum",
    W = "silver",
    B = "copper",
    G = "iron",
    ["*"] = "voidmetal",
}

module.Emblems = {
    A = {Name = "Sword", Phrase = "a sword, point to heaven"},
    C = {Name = "Crescent", Phrase = "a crescent moon with her star"},
    D = {Name = "Shield", Phrase = "a quartered shield"},
    K = {Name = "Crown", Phrase = "a three-pointed crown"},
    L = {Name = "Scepter", Phrase = "an orbed scepter"},
    S = {Name = "Serpent", Phrase = "a coiled serpent"},
    T = {Name = "Hammer", Phrase = "a smith's hammer"},
    U = {Name = "Chalice", Phrase = "a chalice"},
    Y = {Name = "Trident", Phrase = "a trident"},
    Z = {Name = "Thunderbolt", Phrase = "a thunderbolt"},
}

local ShapeRunes = {
    O = "round",
    ["#"] = "square",
    V = "wedge",
    X = "scallop",
}

module.FinenessWords = {"coarse", "honest", "fine", "very fine", "flawless"}

local BoldPhrases = {
    "lightly struck",
    "struck clean",
    "struck deep",
    "struck deep and bold",
    "struck so bold it near splits the flan",
}

local Tiers = {
    {3, "Bit"},
    {6, "Penny"},
    {10, "Groat"},
    {16, "Mark"},
    {26, "Crown"},
    {42, "Sovereign"},
    {math.huge, "Dynast"},
}

local function HashSeed(text: string): number
    local hash = 5381
    for index = 1, #text do
        hash = (hash * 33 + string.byte(text, index)) % 2147483647
    end
    return math.max(hash, 1)
end

local function FlattenRuns(spell: Parser.Spell, runs: {Parser.Run}, state: {unstable: boolean})
    if spell.unstable then
        state.unstable = true
    end
    for _, run in ipairs(spell.rings) do
        table.insert(runs, run)
    end
    for _, part in ipairs(spell.parts) do
        if part.kind == "group" then
            for _, run in ipairs((part :: Parser.Group).runs) do
                table.insert(runs, run)
            end
        else
            FlattenRuns(part :: Parser.Spell, runs, state)
        end
    end
end

function module.Resolve(spell: Parser.Spell): CoinPlan
    local runs: {Parser.Run} = {}
    local state = {unstable = false}
    FlattenRuns(spell, runs, state)

    local notes: {string} = {}

    local metalCount: {[string]: number} = {}
    local shapeCount: {[string]: number} = {}
    local shapeFirst: {[string]: number} = {}
    local emblemPower: {[string]: number} = {}
    local emblemOrder: {string} = {}
    local numeral = ""
    local holed = false
    local milled = false
    local spiral = 0
    local patina = 0
    local wear = 0
    local sizeRunes = 0
    local unknown: {[string]: boolean} = {}

    for index, run in ipairs(runs) do
        local letter = run.letter
        if MetalRunes[letter] then
            local key = MetalRunes[letter]
            metalCount[key] = (metalCount[key] or 0) + run.count
        elseif letter == ":" then
            patina += run.count
        elseif letter == "%" then
            wear += run.count
        elseif ShapeRunes[letter] then
            local key = ShapeRunes[letter]
            shapeCount[key] = (shapeCount[key] or 0) + run.count
            if not shapeFirst[key] then
                shapeFirst[key] = index
            end
        elseif letter == "." then
            holed = true
        elseif letter == "R" then
            sizeRunes += run.count
        elseif letter == "&" then
            milled = true
        elseif letter == ")" then
            spiral += run.count
        elseif letter == "(" then
            spiral -= run.count
        elseif module.Emblems[letter] then
            emblemPower[letter] = (emblemPower[letter] or 0) + run.count
            if emblemPower[letter] == run.count then
                table.insert(emblemOrder, letter)
            end
        elseif string.match(letter, "%d") then
            numeral ..= string.rep(letter, run.count)
        else
            unknown[letter] = true
        end
    end

    -- Material: the strongest true metal takes the body; the second becomes
    -- the ring inlay. Aeon and Rot are overlays (age, corrosion) unless no
    -- true metal was named at all.
    local material: string? = nil
    local inlay: string? = nil
    local bodyCount = 0

    local rankedMetals: {{key: string, count: number}} = {}
    for key, count in pairs(metalCount) do
        table.insert(rankedMetals, {key = key, count = count})
    end
    table.sort(rankedMetals, function(a, b)
        if a.count == b.count then
            return module.Materials[a.key].Nobility > module.Materials[b.key].Nobility
        end
        return a.count > b.count
    end)

    if #rankedMetals > 0 then
        material = rankedMetals[1].key
        bodyCount = rankedMetals[1].count
        if #rankedMetals > 1 then
            inlay = rankedMetals[2].key
        end
    elseif patina > 0 and patina >= wear then
        material = "ancientbronze"
        bodyCount = patina
    elseif wear > 0 then
        material = "slag"
        bodyCount = wear
    end

    if not material then
        material = "copper"
        bodyCount = 1
        table.insert(notes, "No metal was named — the mint pours honest copper.")
    end

    local fineness = math.clamp(bodyCount, 1, 5)

    -- Shape: the strongest shape rune wins; ties go to the first written.
    local shape = "round"
    local bestShapeCount = 0
    local bestShapeFirst = math.huge
    for key, count in pairs(shapeCount) do
        if count > bestShapeCount or (count == bestShapeCount and shapeFirst[key] < bestShapeFirst) then
            shape = key
            bestShapeCount = count
            bestShapeFirst = shapeFirst[key]
        end
    end

    local sizeMarks = math.min(sizeRunes, 4)
    if sizeRunes > 4 then
        table.insert(notes, "The mint's largest collar is four Reaches wide — the rest fall away.")
    end
    local diameter = 24 + 6 * sizeMarks

    -- Emblems: the first named is the face device; the next two become the
    -- mint's small marks; anything further is set aside.
    local emblem: Emblem? = nil
    local mintmarks: {Emblem} = {}
    for index, letter in ipairs(emblemOrder) do
        local entry = module.Emblems[letter]
        local built: Emblem = {
            letter = letter,
            name = entry.Name,
            phrase = entry.Phrase,
            power = emblemPower[letter],
        }
        if index == 1 then
            emblem = built
        elseif index <= 3 then
            table.insert(mintmarks, built)
        else
            table.insert(notes, `The die holds one device and two marks — the {string.lower(entry.Name)} is set aside.`)
        end
    end

    if #numeral > 4 then
        numeral = string.sub(numeral, 1, 4)
        table.insert(notes, "The die holds but four figures — the rest are set aside.")
    end

    local unknownLetters = {}
    for letter in pairs(unknown) do
        table.insert(unknownLetters, letter)
    end
    table.sort(unknownLetters)
    for _, letter in ipairs(unknownLetters) do
        table.insert(notes, `The {letter} rune means nothing to the mint — it is not struck.`)
    end

    local hammered = state.unstable

    -- Value: nobility × size × craft. The hammer is honest work but rough —
    -- its craft rolls fresh with every strike.
    local craft = 1
    if emblem then
        craft += 0.15 + 0.05 * math.min((emblem :: Emblem).power, 5)
    end
    craft += 0.05 * #mintmarks
    if #numeral > 0 then
        craft += 0.1
    end
    if milled then
        craft += 0.2
    end
    if spiral ~= 0 then
        craft += 0.15
    end
    craft *= 0.7 + 0.06 * fineness
    if hammered then
        craft *= 0.55 + Rng:NextNumber() * 0.3
    end

    local sizeFactor = diameter / 24
    if holed then
        sizeFactor *= 0.85
    end

    local matEntry = module.Materials[material]
    local value = matEntry.Nobility * sizeFactor * craft
    if inlay then
        value += module.Materials[inlay :: string].Nobility * 0.3 * sizeFactor
    end
    if patina > 0 then
        value *= 1 + 0.25 * math.min(patina, 4)
    end
    if wear > 0 then
        value *= math.max(0.3, 1 - 0.15 * math.min(wear, 4))
    end
    value = math.max(1, math.floor(value + 0.5))

    local tier = "Bit"
    for _, entry in ipairs(Tiers) do
        if value < entry[1] then
            tier = entry[2] :: string
            break
        end
    end
    local tierNoun = if holed then "Cash" else tier

    -- Name
    local nameParts = {}
    if hammered then
        table.insert(nameParts, "Hammered")
    end
    if patina > 0 and material ~= "ancientbronze" then
        table.insert(nameParts, "Ancient")
    end
    if wear > 0 and material ~= "slag" then
        table.insert(nameParts, "Corroded")
    end
    if holed then
        table.insert(nameParts, "Holed")
    end
    table.insert(nameParts, matEntry.Name)
    table.insert(nameParts, tierNoun)
    local name = table.concat(nameParts, " ")

    -- Edge & strike readouts
    local edge
    if hammered then
        edge = "irregular (hammered)"
    elseif milled and shape == "scallop" then
        edge = "scalloped, milled"
    elseif milled then
        edge = "milled"
    elseif shape == "scallop" then
        edge = "scalloped"
    else
        edge = "plain"
    end

    local strike = if hammered then "hammered, off-center" else "true"
    if spiral > 0 then
        strike ..= ", turned sunwise"
    elseif spiral < 0 then
        strike ..= ", turned widdershins"
    end

    -- The solved readout
    local lines = {}
    local strikeWord = if hammered then "off-center under the hammer" else "true"
    table.insert(lines, `A {string.lower(tierNoun)} of {module.FinenessWords[fineness]} {string.lower(matEntry.Name)}, struck {strikeWord} at {diameter} mm across.`)

    if shape == "square" then
        table.insert(lines, "Its flan is cut four-square.")
    elseif shape == "wedge" then
        table.insert(lines, "Its flan is a wedge — one cut of a broader wheel.")
    elseif shape == "scallop" then
        table.insert(lines, "Its edge blooms in twelve scallops.")
    end

    if inlay then
        table.insert(lines, `{module.Materials[inlay :: string].Name} rings its field — bimetal work of the old mints.`)
    end

    if emblem then
        local built = emblem :: Emblem
        table.insert(lines, `Its face bears {built.phrase}, {BoldPhrases[math.clamp(built.power, 1, 5)]}.`)
    end

    if #mintmarks > 0 then
        local markNames = {}
        for _, mark in ipairs(mintmarks) do
            table.insert(markNames, `the {string.lower(mark.name)}`)
        end
        table.insert(lines, `Beside it sit the mint's small marks: {table.concat(markNames, ", ")}.`)
    end

    if #numeral > 0 then
        table.insert(lines, `The figure {numeral} names its face.`)
    end

    if holed then
        table.insert(lines, "A square hole pierces its heart, cut for the stringing cord.")
    end

    if milled then
        table.insert(lines, "The edge is milled fine against the clipper's shears.")
    end

    if spiral ~= 0 then
        local turn = if spiral > 0 then "sunwise" else "widdershins"
        table.insert(lines, `The die turned {turn} in the striking — the device sits askew.`)
    end

    if patina > 0 then
        if material == "ancientbronze" then
            table.insert(lines, "Verdigris blooms across the old bronze; centuries sit upon it.")
        else
            table.insert(lines, "Verdigris lies upon the field; age has multiplied its worth.")
        end
    end

    if wear > 0 then
        if material == "slag" then
            table.insert(lines, "It is more corrosion than coin — debased pot-metal, fit for a beggar's purse.")
        else
            table.insert(lines, "Corrosion pits the field — debased metal, and the assayers mark it down.")
        end
    end

    if hammered then
        table.insert(lines, "Hammer-struck on an uneven flan — no two of its kind fall alike.")
    end

    table.insert(lines, `Assayed at {value} {if value == 1 then "bit" else "bits"}.`)

    local seed = if hammered
        then Rng:NextInteger(1, 2147483646)
        else HashSeed(string.upper(spell.raw))

    return {
        material = material,
        fineness = fineness,
        inlay = inlay,
        shape = shape,
        holed = holed,
        sizeMarks = sizeMarks,
        diameter = diameter,
        emblem = emblem,
        mintmarks = mintmarks,
        numeral = if #numeral > 0 then numeral else nil,
        milled = milled,
        spiral = spiral,
        patina = patina,
        wear = wear,
        hammered = hammered,
        value = value,
        tier = tier,
        denomination = tierNoun,
        name = name,
        edge = edge,
        strike = strike,
        seed = seed,
        description = table.concat(lines, " "),
        notes = notes,
    }
end

return module
