--#include[random]
-- The blade language. Same rune characters as spells, entirely different
-- meanings: this resolver reads a pattern as smithing instructions and
-- solves the finished weapon — category, material, stats, quality.
local Parser = require("@src/spell/Parser")

local module = {}

local Rng = random.new()

export type Etching = {text: string, scale: number}

export type Weapon = {
    Category: string, -- "sword" | "knife" | "greatsword" | "axe" | "hammer" | "spear" | "arrow" | "knuckles" | "sickle" | "shield" | "mace" | "ingot"
    TypeName: string,
    Name: string,
    Emoji: string,
    Material: string,
    Accents: {string},
    BladeSpans: number,
    HaftSpans: number,
    GripSpans: number,
    Guard: number,
    Pommel: number,
    Fuller: number,
    Edge: number,
    HeadPower: number,
    Curve: number,
    Wave: number,
    Serration: number,
    Fletching: number,
    MoonTip: number,
    Stretch: number,
    Quench: number,
    Wrap: number,
    Clip: number,
    TwinEdge: number,
    Hollow: number,
    Spine: number,
    Channel: number,
    Basket: number,
    Jewel: number,
    Tassel: number,
    Counterweight: number,
    Hook: number,
    Skull: number,
    Folds: number,
    Stock: number,
    Reach: number,
    Weight: number,
    Sharpness: number,
    Durability: number,
    Balance: number,
    Quality: string,
    QualityScore: number,
    Etchings: {Etching},
    Inscriptions: {string},
    ProofMark: string?,
    Warped: boolean,
    WarpLean: number,
    WarpBend: number,
    WarpSeed: number,
    Description: string,
    Notes: {string},
}

export type Material = {
    Name: string,
    Adjective: string,
    Line: string,
    Density: number,
    Durability: number,
    SharpBonus: number,
    Color: {r: number, g: number, b: number},
    Edge: {r: number, g: number, b: number},
    Glow: {r: number, g: number, b: number},
    AccentLine: string,
    PaintLine: string,
}

module.Materials = {
    Iron = {
        Name = "Iron", Adjective = "Iron", Line = "iron through and through",
        Density = 1.0, Durability = 6, SharpBonus = 0,
        Color = {r = 150, g = 152, b = 158}, Edge = {r = 228, g = 230, b = 238}, Glow = {r = 120, g = 125, b = 140},
        AccentLine = "banded with plain iron",
        PaintLine = "painted an honest grey",
    },
    Steel = {
        Name = "Steel", Adjective = "Steel", Line = "folded into true steel",
        Density = 1.0, Durability = 8, SharpBonus = 1,
        Color = {r = 176, g = 182, b = 194}, Edge = {r = 240, g = 244, b = 252}, Glow = {r = 150, g = 160, b = 185},
        AccentLine = "backed with a steel core",
        PaintLine = "painted in polished grey",
    },
    Damascus = {
        Name = "Damascus", Adjective = "Damascus", Line = "folded past steel into watered damascus",
        Density = 1.0, Durability = 9, SharpBonus = 1.5,
        Color = {r = 158, g = 164, b = 178}, Edge = {r = 236, g = 242, b = 252}, Glow = {r = 140, g = 165, b = 210},
        AccentLine = "cored with watered damascus",
        PaintLine = "painted in rippling grey waters",
    },
    Bronze = {
        Name = "Bronze", Adjective = "Bronze", Line = "cast of fire-forged bronze",
        Density = 1.1, Durability = 6, SharpBonus = 0,
        Color = {r = 186, g = 132, b = 72}, Edge = {r = 244, g = 208, b = 140}, Glow = {r = 210, g = 130, b = 50},
        AccentLine = "trimmed in fire-warmed bronze",
        PaintLine = "painted in burnt sienna",
    },
    ["Blued Steel"] = {
        Name = "Blued Steel", Adjective = "Blued Steel", Line = "of steel blued in the fire",
        Density = 1.0, Durability = 8.5, SharpBonus = 1,
        Color = {r = 98, g = 114, b = 152}, Edge = {r = 190, g = 212, b = 246}, Glow = {r = 90, g = 130, b = 220},
        AccentLine = "fire-blued along the spine",
        PaintLine = "painted a deep smith's blue",
    },
    Silver = {
        Name = "Silver", Adjective = "Silver", Line = "of moon-pale silver",
        Density = 0.95, Durability = 5, SharpBonus = 0.5,
        Color = {r = 214, g = 218, b = 230}, Edge = {r = 250, g = 250, b = 255}, Glow = {r = 200, g = 210, b = 240},
        AccentLine = "run with silver inlay",
        PaintLine = "painted moon-white",
    },
    Gold = {
        Name = "Gold", Adjective = "Gilded", Line = "chased in soft gold",
        Density = 1.5, Durability = 3.5, SharpBonus = -1,
        Color = {r = 232, g = 196, b = 110}, Edge = {r = 255, g = 240, b = 180}, Glow = {r = 240, g = 200, b = 90},
        AccentLine = "chased with gold",
        PaintLine = "laid with gold leaf",
    },
    Voidsteel = {
        Name = "Voidsteel", Adjective = "Voidsteel", Line = "of light-drinking voidsteel",
        Density = 1.2, Durability = 9, SharpBonus = 2,
        Color = {r = 72, g = 62, b = 98}, Edge = {r = 182, g = 152, b = 255}, Glow = {r = 130, g = 90, b = 220},
        AccentLine = "seamed with voidsteel",
        PaintLine = "painted a black that swallows torchlight",
    },
    Ancient = {
        Name = "Ancient", Adjective = "Ancient", Line = "of metal older than the forge, green with patina",
        Density = 1.0, Durability = 4.5, SharpBonus = -0.5,
        Color = {r = 132, g = 138, b = 116}, Edge = {r = 206, g = 212, b = 180}, Glow = {r = 120, g = 145, b = 100},
        AccentLine = "fitted with patinated relics",
        PaintLine = "painted in patina green",
    },
    ["Storm-Forged"] = {
        Name = "Storm-Forged", Adjective = "Storm-Forged", Line = "hammered under a living storm",
        Density = 0.9, Durability = 7.5, SharpBonus = 1,
        Color = {r = 126, g = 148, b = 188}, Edge = {r = 214, g = 236, b = 255}, Glow = {r = 120, g = 180, b = 255},
        AccentLine = "veined with storm-light",
        PaintLine = "painted storm-grey, streaked with lightning",
    },
    Corrupted = {
        Name = "Corrupted", Adjective = "Corrupted", Line = "of pitted, cursed metal that weeps at the edges",
        Density = 0.95, Durability = 3, SharpBonus = -1,
        Color = {r = 98, g = 88, b = 74}, Edge = {r = 152, g = 172, b = 92}, Glow = {r = 110, g = 145, b = 60},
        AccentLine = "scarred with cursed pitting",
        PaintLine = "painted in weeping rot-green",
    },
}

-- Element runes → the metal they call into the billet.
local MaterialRunes: {[string]: string} = {
    G = "Iron",
    B = "Bronze",
    W = "Silver",
    ["!"] = "Gold",
    ["*"] = "Voidsteel",
    [":"] = "Ancient",
    ["^"] = "Storm-Forged",
    ["%"] = "Corrupted",
    ["/"] = "Corrupted",
}

local CategoryEmoji = {
    sword = "⚔️", knife = "🗡️", greatsword = "⚔️",
    axe = "🪓", hammer = "🔨", spear = "🔱", ingot = "⚒️",
    arrow = "🏹", knuckles = "👊", sickle = "🌙",
    shield = "🛡️", mace = "⚙️",
}

type Totals = {
    counts: {[string]: number},
    firstSeen: {[string]: number},
    order: number,
    etchings: {Etching},
    inscriptions: {string},
    proof: string?,
    extraProof: boolean,
    wasted: {[string]: boolean},
    unstable: boolean,
}

local function NewTotals(): Totals
    return {
        counts = {},
        firstSeen = {},
        order = 0,
        etchings = {},
        inscriptions = {},
        proof = nil,
        extraProof = false,
        wasted = {},
        unstable = false,
    }
end

local AnatomyRunes = "ADMYVKSITHOURFGBWXEJN"

local function IsKnownRune(letter: string): boolean
    return string.find(AnatomyRunes, letter, 1, true) ~= nil
        or MaterialRunes[letter] ~= nil
        or letter == "(" or letter == ")" or letter == "&" or letter == "."
        or letter == "~" or letter == "$" or letter == "<"
        or letter == ">" or letter == "=" or letter == "_" or letter == "+"
        or letter == ";" or letter == "@" or letter == "'" or letter == ","
        or letter == "#" or letter == "?" or letter == "-"
        or string.match(letter, "%d") ~= nil
end

local function Tally(totals: Totals, letter: string, count: number)
    if string.match(letter, "%d") then
        if totals.proof then
            totals.extraProof = true
        else
            totals.proof = letter
        end
        return
    end
    if not IsKnownRune(letter) then
        totals.wasted[letter] = true
        return
    end
    totals.counts[letter] = (totals.counts[letter] or 0) + count
    if not totals.firstSeen[letter] then
        totals.order += 1
        totals.firstSeen[letter] = totals.order
    end
end

local function GatherInscription(spell: Parser.Spell): string
    local words = {}
    local ringText = ""
    for _, run in ipairs(spell.rings) do
        ringText ..= string.rep(run.letter, run.count)
    end
    if #ringText > 0 then
        table.insert(words, ringText)
    end
    for _, part in ipairs(spell.parts) do
        if part.kind == "group" then
            table.insert(words, (part :: Parser.Group).letters)
        else
            local inner = GatherInscription(part :: Parser.Spell)
            if #inner > 0 then
                table.insert(words, inner)
            end
        end
    end
    return table.concat(words, "·")
end

local function Walk(spell: Parser.Spell, totals: Totals, depth: number)
    if spell.unstable then
        totals.unstable = true
    end

    for _, run in ipairs(spell.rings) do
        Tally(totals, run.letter, run.count)
    end

    for _, part in ipairs(spell.parts) do
        if part.kind == "spell" then
            -- An inner circle is never read as runes — a smith reads it as an
            -- inscription rung about the tang.
            local sub = part :: Parser.Spell
            if sub.unstable then
                totals.unstable = true
            end
            table.insert(totals.inscriptions, GatherInscription(sub))
            continue
        end

        local group = part :: Parser.Group
        local base = group.runs[1]

        if base.letter == "$" then
            -- Etching cluster: the $ marks are chisel-weight, the letters
            -- after them are carved verbatim onto the flat.
            local scale = 0
            local text = ""
            for _, run in ipairs(group.runs) do
                if run.letter == "$" then
                    scale += run.count
                else
                    text ..= string.rep(run.letter, run.count)
                end
            end
            if #text > 0 then
                table.insert(totals.etchings, {text = text, scale = scale})
            end
            continue
        end

        for _, run in ipairs(group.runs) do
            Tally(totals, run.letter, run.count)
        end
    end
end

local function Count(totals: Totals, letter: string): number
    return totals.counts[letter] or 0
end

local function Round1(value: number): number
    return math.floor(value * 10 + 0.5) / 10
end

local function ResolveMaterial(totals: Totals): (string, {string})
    local best: string? = nil
    local bestCount = 0
    local bestOrder = math.huge
    local present: {[string]: number} = {}
    local presentOrder: {[string]: number} = {}

    -- Aggregate per metal, not per rune — % and / both feed Corrupted, and
    -- the strongest metal wins the billet by its total.
    for rune, key in pairs(MaterialRunes) do
        local count = Count(totals, rune)
        if count > 0 then
            present[key] = (present[key] or 0) + count
            local order = totals.firstSeen[rune] or math.huge
            if not presentOrder[key] or order < presentOrder[key] then
                presentOrder[key] = order
            end
        end
    end

    for key, count in pairs(present) do
        local order = presentOrder[key] or math.huge
        if count > bestCount or (count == bestCount and order < bestOrder) then
            best = key
            bestCount = count
            bestOrder = order
        end
    end

    if not best then
        return "Iron", {}
    end

    -- Craft rules: a heavy hand of iron trends to steel, a heavier one folds
    -- past it into damascus; fire laid over iron blues it instead of bronzing.
    if best == "Iron" and (present.Iron or 0) >= 5 then
        best = "Damascus"
    elseif best == "Iron" and (present.Iron or 0) >= 3 then
        best = "Steel"
    elseif best == "Bronze" and (present.Iron or 0) > 0 then
        best = "Blued Steel"
    end

    local accents = {}
    for key in pairs(present) do
        if key ~= best and not ((best == "Steel" or best == "Damascus") and key == "Iron") and not (best == "Blued Steel" and (key == "Bronze" or key == "Iron")) then
            table.insert(accents, key)
        end
    end
    table.sort(accents)

    return best, accents
end

local function QualityWord(score: number): string
    if score <= 1 then
        return "poor"
    elseif score <= 5 then
        return "common"
    elseif score <= 9 then
        return "fine"
    elseif score <= 13 then
        return "masterwork"
    end
    return "mythic"
end

local function SpanWord(count: number): string
    return if count == 1 then "span" else "spans"
end

local function Article(word: string): string
    return if string.match(word, "^[AEIOUaeiou]") then "An" else "A"
end

local function TimesWord(count: number): string
    if count == 1 then
        return "once"
    elseif count == 2 then
        return "twice"
    elseif count == 3 then
        return "thrice"
    end
    return `{count} times`
end

local function ResolveTypeName(category: string, weapon: Weapon): string
    if category == "knife" then
        if weapon.Wave > 0 then
            return "Kris"
        elseif weapon.Curve ~= 0 then
            return "Kukri"
        elseif weapon.Clip > 0 then
            return "Bowie Knife"
        elseif weapon.Serration > 0 then
            return "Sawback Dirk"
        end
        return "Dagger"
    elseif category == "sword" then
        if weapon.Wave > 0 then
            return "Flamberge"
        elseif weapon.Curve ~= 0 then
            if weapon.Guard > 0 and weapon.Wrap > 0 then
                return "Cutlass"
            end
            return "Scimitar"
        elseif weapon.Basket >= 2 then
            return "Broadsword"
        elseif weapon.BladeSpans >= 4 then
            return "Longsword"
        end
        return "Sword"
    elseif category == "greatsword" then
        if weapon.Wave > 0 then
            return "Great Flamberge"
        elseif weapon.Curve ~= 0 then
            return "Grand Falchion"
        end
        return "Greatsword"
    elseif category == "axe" then
        if weapon.Hook > 0 and weapon.HaftSpans >= 5 then
            return "Halberd"
        elseif weapon.HeadPower >= 6 then
            return "Double Axe"
        elseif weapon.Hook > 0 then
            return "Hooked Axe"
        elseif weapon.HaftSpans >= 5 then
            return "Poleaxe"
        elseif weapon.HeadPower >= 4 then
            return "Broadaxe"
        end
        return "Axe"
    elseif category == "hammer" then
        if weapon.HeadPower >= 5 then
            return "Maul"
        elseif weapon.HaftSpans >= 5 then
            return "Polehammer"
        end
        return "Warhammer"
    elseif category == "spear" then
        if weapon.HeadPower >= 4 then
            return "Trident"
        elseif weapon.HaftSpans >= 7 then
            return "Pike"
        end
        return "Spear"
    elseif category == "arrow" then
        if weapon.Serration > 0 then
            return "Barbed Arrow"
        elseif weapon.MoonTip > 0 then
            return "Crescent Arrow"
        elseif weapon.HeadPower >= 4 then
            return "Broadhead Arrow"
        elseif weapon.HaftSpans >= 6 then
            return "Cloth-Yard Shaft"
        end
        return "Arrow"
    elseif category == "knuckles" then
        if weapon.Serration > 0 then
            return "Spiked Knuckles"
        elseif weapon.HeadPower >= 5 then
            return "Weighted Knuckles"
        end
        return "Knuckles"
    elseif category == "sickle" then
        if weapon.HaftSpans >= 4 then
            return "Scythe"
        elseif weapon.HeadPower >= 5 then
            return "War Sickle"
        elseif weapon.Serration > 0 then
            return "Sawtooth Sickle"
        end
        return "Sickle"
    elseif category == "mace" then
        if weapon.Serration > 0 then
            return "Morning Star"
        elseif weapon.HeadPower >= 6 then
            return "Great Mace"
        elseif weapon.HaftSpans >= 5 then
            return "Polemace"
        end
        return "Mace"
    elseif category == "shield" then
        local base = if weapon.HeadPower >= 4 then "Tower Shield"
            elseif weapon.HeadPower == 3 then "Kite Shield"
            elseif weapon.HeadPower == 2 then "Round Shield"
            else "Buckler"
        if weapon.Serration > 0 then
            return `Spiked {base}`
        end
        return base
    end
    return "Ingot"
end

function module.Resolve(spell: Parser.Spell): Weapon
    local totals = NewTotals()
    Walk(spell, totals, 0)

    local materialName, accents = ResolveMaterial(totals)
    local material = module.Materials[materialName] :: Material

    local edge = Count(totals, "A")
    local bit = Count(totals, "D")
    local mass = Count(totals, "M")
    local fork = Count(totals, "Y")
    local point = Count(totals, "V")
    local bar = Count(totals, "K")
    local crescent = Count(totals, "S")
    local fletch = Count(totals, "F")
    local moon = Count(totals, "<")
    local spans = Count(totals, "I")
    local grip = Count(totals, "T")
    local guard = Count(totals, "H")
    local pommel = Count(totals, "O")
    local fuller = Count(totals, "U")
    local stretch = Count(totals, "R")
    local quench = Count(totals, "~")
    local wrap = Count(totals, "X")
    local curve = Count(totals, ")") - Count(totals, "(")
    local wave = Count(totals, "&")
    local serration = Count(totals, ".")
    local ward = Count(totals, "E")
    local flange = Count(totals, "J")
    local clip = Count(totals, ">")
    local twinEdge = Count(totals, "=")
    local hollow = Count(totals, "_")
    local spine = Count(totals, "+")
    local channel = Count(totals, ";")
    local basket = Count(totals, "@")
    local jewel = Count(totals, "'")
    local tassel = Count(totals, ",")
    local counterweight = Count(totals, "#")
    local hook = Count(totals, "?")
    local skull = Count(totals, "N")
    local folds = Count(totals, "G")
    local stock = Count(totals, "-")

    -- The dominant head-rune decides what the metal becomes. Ties fall to
    -- whichever rune was struck first.
    local heads = {
        {letter = "A", count = edge, category = "sword"},
        {letter = "D", count = bit, category = "axe"},
        {letter = "M", count = mass, category = "hammer"},
        {letter = "Y", count = fork, category = "spear"},
        {letter = "V", count = point, category = "arrow"},
        {letter = "K", count = bar, category = "knuckles"},
        {letter = "S", count = crescent, category = "sickle"},
        {letter = "E", count = ward, category = "shield"},
        {letter = "J", count = flange, category = "mace"},
    }
    local category = "sword"
    local headPower = 0
    local headOrder = math.huge
    local anyHead = false
    for _, head in ipairs(heads) do
        if head.count > 0 then
            anyHead = true
            local order = totals.firstSeen[head.letter] or math.huge
            if head.count > headPower or (head.count == headPower and order < headOrder) then
                category = head.category
                headPower = head.count
                headOrder = order
            end
        end
    end

    local anyMetal = anyHead or spans > 0 or grip > 0 or guard > 0 or pommel > 0
        or fuller > 0 or stretch > 0 or next(totals.counts) ~= nil

    if not anyMetal and #totals.etchings == 0 then
        category = "ingot"
    end

    local hafted = category == "axe" or category == "hammer" or category == "spear" or category == "sickle" or category == "mace"

    local bladeSpans = 0
    local haftSpans = 0
    if hafted then
        haftSpans = if spans > 0 then spans else (if category == "spear" then 5 elseif category == "sickle" then 1 else 3)
    elseif category == "arrow" then
        haftSpans = if spans > 0 then spans else 4
    elseif category == "shield" then
        -- On a shield, `I` is a ply of the face — the boards behind the metal.
        bladeSpans = if spans > 0 then spans else 2
    elseif category ~= "ingot" and category ~= "knuckles" then
        -- An unspanned blade falls to two spans, by habit of the hand.
        bladeSpans = if spans > 0 then spans else 2
        if bladeSpans <= 1 then
            category = "knife"
        elseif bladeSpans >= 5 then
            category = "greatsword"
        end
    end

    local bladed = category == "sword" or category == "knife" or category == "greatsword"

    local gripSpans = grip

    -- Warp: the uneven border bends the forging and rolls fresh every cast.
    local warped = totals.unstable
    local warpLean = 0
    local warpBend = 0
    local warpSeed = 0
    local warpQuality = 0
    local warpSharp = 0
    local warpDurability = 0
    local warpBalance = 0
    if warped then
        warpSeed = Rng:NextInteger(1, 2147483646)
        local sign = if Rng:NextBoolean() then 1 else -1
        warpLean = sign * (3 + Rng:NextNumber() * 9)
        warpBend = 0.35 + Rng:NextNumber() * 0.65
        warpQuality = Rng:NextInteger(-3, 1)
        warpSharp = Rng:NextInteger(-2, 1)
        warpDurability = Rng:NextInteger(1, 3)
        warpBalance = Rng:NextInteger(4, 18)
    end

    -- ── Stats ────────────────────────────────────────────────────────────
    local reach: number
    if category == "spear" then
        reach = haftSpans + fork * 0.5
    elseif category == "sickle" then
        reach = haftSpans + 0.5
    elseif hafted then
        reach = haftSpans
    elseif category == "arrow" then
        reach = 0.5
    elseif category == "knuckles" then
        reach = 0.2
    elseif category == "shield" then
        -- Coverage, not reach — how much of the line it walls off.
        reach = 0.5 + headPower
    elseif category == "ingot" then
        reach = 0
    else
        reach = bladeSpans + stretch * 0.5
    end
    reach = Round1(reach)

    local weight: number
    if category == "axe" then
        weight = (haftSpans * 0.35 + bit * 0.9 + pommel * 0.2 + stock * 0.3) * material.Density
    elseif category == "hammer" then
        weight = (haftSpans * 0.35 + mass * 1.3 + pommel * 0.2 + stock * 0.3) * material.Density
    elseif category == "spear" then
        weight = (haftSpans * 0.3 + fork * 0.3 + stock * 0.25) * material.Density
    elseif category == "sickle" then
        weight = (haftSpans * 0.3 + crescent * 0.5 + pommel * 0.2 + stock * 0.25) * material.Density
    elseif category == "arrow" then
        weight = (haftSpans * 0.05 + point * 0.04 + fletch * 0.01) * material.Density
    elseif category == "knuckles" then
        weight = (bar * 0.5 + spans * 0.15 + serration * 0.05) * material.Density
    elseif category == "mace" then
        weight = (haftSpans * 0.35 + flange * 0.85 + pommel * 0.2 + stock * 0.3) * material.Density
    elseif category == "shield" then
        weight = (headPower * 1.1 + bladeSpans * 0.35 + pommel * 0.3 + guard * 0.4 + stock * 0.45) * material.Density
    elseif category == "ingot" then
        weight = 4.0 * material.Density
    else
        local widthFactor = if category == "greatsword" then 1.4 elseif category == "knife" then 0.7 else 1.0
        weight = (bladeSpans * 0.6 * widthFactor + stock * 0.55 * widthFactor + guard * 0.25 * (1 + stock * 0.35) + pommel * 0.2 + gripSpans * 0.15 - fuller * 0.12
            + spine * 0.15 + twinEdge * 0.1 + basket * 0.3 + counterweight * 0.25 - hollow * 0.15 - channel * 0.05) * material.Density
    end
    weight = Round1(math.max(weight, if category == "arrow" then 0.1 else 0.3))

    local sharpness: number
    if category == "hammer" then
        sharpness = 0 + edge * 0.5
    elseif category == "spear" then
        sharpness = 4 + fork * 0.5 + edge * 0.5 + material.SharpBonus
    elseif category == "axe" then
        sharpness = 3 + bit * 0.4 + edge * 0.6 + material.SharpBonus + quench * 0.4
    elseif category == "sickle" then
        sharpness = 3 + crescent * 0.5 + edge * 0.6 + serration * 0.4 + material.SharpBonus + quench * 0.4
    elseif category == "arrow" then
        sharpness = 3 + point * 0.7 + edge * 0.5 + serration * 0.4 + material.SharpBonus + quench * 0.4
    elseif category == "knuckles" then
        sharpness = serration * 0.8
    elseif category == "mace" then
        sharpness = 1 + flange * 0.3 + serration * 0.7 + edge * 0.3
    elseif category == "shield" then
        sharpness = serration * 0.7
    elseif category == "ingot" then
        sharpness = 0
    else
        sharpness = 2 + edge * 1.1 + serration * 0.6 + material.SharpBonus + quench * 0.4
            + twinEdge * 0.7 + hollow * 0.6 + clip * 0.2 - stock * 0.3
    end
    sharpness = Round1(math.clamp(sharpness + warpSharp, 0, 10))

    local durability: number
    if category == "arrow" then
        durability = material.Durability * 0.55 + quench * 0.4 - serration * 0.2 - warpDurability
    elseif category == "knuckles" then
        durability = material.Durability + 1.5 + quench * 0.6 - warpDurability
    elseif category == "shield" then
        durability = material.Durability + quench * 0.6 + bladeSpans * 0.3 + guard * 0.5 + stock * 0.4 - warpDurability
    else
        durability = material.Durability + quench * 0.6 + fuller * 0.2 - serration * 0.2 + stock * 0.5 - warpDurability
            + (if bladed then spine * 0.8 - hollow * 0.6 else 0)
    end
    durability = Round1(math.clamp(durability, 0.5, 10))

    local balance: number
    local ratio = 0
    if hafted then
        balance = (if category == "spear" then 82 elseif category == "sickle" then 74 else 60) - headPower * 2 + (if pommel > 0 then 6 else 0) + (if wrap > 0 then 4 else 0)
    elseif category == "arrow" then
        balance = 58 + fletch * 9 - headPower + (if pommel > 0 then 4 else 0)
    elseif category == "knuckles" then
        balance = 86 - headPower + (if gripSpans > 0 then 5 else 0) + (if wrap > 0 then 4 else 0)
    elseif category == "shield" then
        balance = 62 - headPower * 3 + (if gripSpans > 0 then 8 else 0) + (if pommel > 0 then 3 else 0) + (if wrap > 0 then 3 else 0)
    elseif category == "ingot" then
        balance = 50
    else
        local gripForRatio = math.max(gripSpans, 1)
        ratio = bladeSpans / gripForRatio
        balance = 92 - math.abs(ratio - 3) * 7
            + (if pommel > 0 then 4 else -4)
            + (if guard > 0 then 2 else 0)
            + math.min(counterweight, 2) * 4
            + (if basket > 0 then 2 else 0)
            - math.min(stock, 4) * 3
    end
    balance = math.clamp(math.floor(balance - warpBalance + 0.5), 5, 99)

    -- ── Quality: the craft rules ─────────────────────────────────────────
    local score = 0
    local wastedList = {}
    for letter in pairs(totals.wasted) do
        table.insert(wastedList, letter)
    end
    table.sort(wastedList)

    if category ~= "ingot" then
        if hafted then
            score += if pommel > 0 then 1 else 0
            if category == "sickle" then
                score += if haftSpans <= 2 or haftSpans >= 4 then 3 else 1
            elseif haftSpans >= headPower then
                score += 3
            elseif haftSpans >= headPower - 1 then
                score += 1
            else
                score -= 2
            end
            score += if wrap > 0 then 2 else 0
        elseif category == "arrow" then
            score += if fletch > 0 then 2 else 0
            score += if pommel > 0 then 1 else 0
            score += if wrap > 0 then 1 else 0
            if haftSpans >= headPower * 2 then
                score += 3
            elseif haftSpans >= headPower then
                score += 1
            else
                score -= 2
            end
        elseif category == "knuckles" then
            score += if gripSpans > 0 then 2 else 0
            score += if wrap > 0 then 2 else 0
            score += if headPower >= 2 and headPower <= 4 then 3 else 1
        elseif category == "shield" then
            score += if pommel > 0 then 2 else 0
            score += if guard > 0 then 2 else 0
            score += if gripSpans > 0 then 2 else 0
            if bladeSpans >= headPower then
                score += 3
            elseif bladeSpans >= headPower - 1 then
                score += 1
            else
                score -= 2
            end
            score += if wrap > 0 then 1 else 0
        else
            score += if guard > 0 then 2 else 0
            score += if pommel > 0 then 2 else 0
            score += if gripSpans > 0 then 2 else 0
            if gripSpans > 0 then
                if ratio >= 2.2 and ratio <= 3.8 then
                    score += 3
                elseif ratio > 6 or ratio < 1 then
                    score -= 3
                end
            end
            score += if wrap > 0 then 1 else 0
            score += if fuller > 0 then 1 else 0
            score += if channel > 0 then 1 else 0
            score += if basket > 0 then 1 else 0
        end
        score += math.min(quench, 3)
        score += 2 * math.min(#totals.inscriptions, 2)
        score += if #totals.etchings > 0 then 1 else 0
        score += if jewel > 0 then 1 else 0
        score += if tassel > 0 then 1 else 0
    end
    score -= 2 * #wastedList
    if warped then
        score -= 2
        score += warpQuality
    end

    local quality = if category == "ingot" then "poor" else QualityWord(score)

    -- ── Assembly ─────────────────────────────────────────────────────────
    local weapon: Weapon = {
        Category = category,
        TypeName = "",
        Name = "",
        Emoji = CategoryEmoji[category] or "⚔️",
        Material = materialName,
        Accents = accents,
        BladeSpans = bladeSpans,
        HaftSpans = haftSpans,
        GripSpans = gripSpans,
        Guard = guard,
        Pommel = pommel,
        Fuller = fuller,
        Edge = edge,
        HeadPower = headPower,
        Curve = curve,
        Wave = wave,
        Serration = serration,
        Fletching = fletch,
        MoonTip = moon,
        Stretch = stretch,
        Quench = quench,
        Wrap = wrap,
        Clip = clip,
        TwinEdge = twinEdge,
        Hollow = hollow,
        Spine = spine,
        Channel = channel,
        Basket = basket,
        Jewel = jewel,
        Tassel = tassel,
        Counterweight = counterweight,
        Hook = hook,
        Skull = skull,
        Folds = if materialName == "Damascus" then folds else 0,
        Stock = stock,
        Reach = reach,
        Weight = weight,
        Sharpness = sharpness,
        Durability = durability,
        Balance = balance,
        Quality = quality,
        QualityScore = score,
        Etchings = totals.etchings,
        Inscriptions = totals.inscriptions,
        ProofMark = totals.proof,
        Warped = warped,
        WarpLean = warpLean,
        WarpBend = warpBend,
        WarpSeed = warpSeed,
        Description = "",
        Notes = {},
    }

    weapon.TypeName = ResolveTypeName(category, weapon)

    local nameParts = {}
    if warped then
        table.insert(nameParts, "Warped")
    end
    if quality == "poor" and category ~= "ingot" then
        table.insert(nameParts, "Crude")
    elseif quality == "fine" or quality == "masterwork" or quality == "mythic" then
        table.insert(nameParts, (string.gsub(quality, "^%l", string.upper)))
    end
    table.insert(nameParts, material.Adjective)
    table.insert(nameParts, if category == "ingot" then "Ingot" else weapon.TypeName)
    weapon.Name = table.concat(nameParts, " ")

    -- ── The readout, in the smithy voice ─────────────────────────────────
    local lines = {}
    local notes = {}

    local quenchPhrase = if quench > 0 then `, quenched {TimesWord(quench)}` else ""

    if category == "ingot" then
        table.insert(lines, "An unworked ingot — no shaping rune ever struck it. The anvil waits.")
    elseif category == "axe" then
        table.insert(lines, `The bit spreads {bit} {if bit == 1 then "hand" else "hands"} of {string.lower(materialName)} on a haft of {haftSpans} {SpanWord(haftSpans)}{quenchPhrase}.`)
    elseif category == "hammer" then
        table.insert(lines, `The head is a {mass}-weight block, {material.Line}, on a haft of {haftSpans} {SpanWord(haftSpans)}{quenchPhrase}.`)
    elseif category == "mace" then
        table.insert(lines, `The head bristles with {flange} {if flange == 1 then "flange" else "flanges"}, {material.Line}, on a haft of {haftSpans} {SpanWord(haftSpans)}{quenchPhrase}.`)
    elseif category == "spear" then
        table.insert(lines, `The point runs {fork} {if fork == 1 then "hand" else "hands"} long, {material.Line}, atop a shaft of {haftSpans} {SpanWord(haftSpans)}{quenchPhrase}.`)
    elseif category == "sickle" then
        table.insert(lines, `The crescent hooks inward {crescent} {if crescent == 1 then "hand" else "hands"} deep, {material.Line}, on a haft of {haftSpans} {SpanWord(haftSpans)}{quenchPhrase}.`)
    elseif category == "arrow" then
        table.insert(lines, `The shaft runs {haftSpans} {SpanWord(haftSpans)}{quenchPhrase}; the head is ground {point} {if point == 1 then "finger" else "fingers"} broad, {material.Line}.`)
    elseif category == "knuckles" then
        table.insert(lines, `Four finger-rings and a palm bar of {bar}-weight stock{quenchPhrase}, {material.Line}.`)
    elseif category == "shield" then
        local sizeLine = if headPower >= 4 then "A tower shield that walls the bearer boot to chin"
            elseif headPower == 3 then "A kite shield running shoulder to knee"
            elseif headPower == 2 then "A round shield a full arm's-length across"
            else "A buckler scarcely wider than the fist behind it"
        table.insert(lines, `{sizeLine}{quenchPhrase}, {material.Line}.`)
        if spans > 0 then
            table.insert(lines, `The face is laid up {bladeSpans} {if bladeSpans == 1 then "ply" else "plies"} thick.`)
        end
    else
        table.insert(lines, `The blade runs {bladeSpans} {SpanWord(bladeSpans)}{quenchPhrase}, {material.Line}.`)
    end

    if weapon.Folds >= 5 then
        local layers = 2 ^ math.min(folds, 8)
        table.insert(lines, `The billet was folded {TimesWord(folds)} — {layers} layers of watered grain ripple down the flat.`)
    end

    if stock > 0 then
        local fingerWord = if stock == 1 then "finger" else "fingers"
        if bladed then
            local stockLine = `The billet was left thick-stocked — {stock} {fingerWord} of spine behind the edge`
            if stock >= 4 then
                stockLine ..= ", a slab that owes more to the cleaver than the fencer"
            end
            if guard > 0 then
                stockLine ..= "; the guard is forged to match, a bar as thick as the blade it wards"
            end
            table.insert(lines, stockLine .. ".")
        elseif hafted then
            table.insert(lines, `The billet was left thick-stocked — the haft is turned {stock} {fingerWord} stout.`)
        elseif category == "shield" then
            table.insert(lines, `The billet was left thick-stocked — {stock} {fingerWord} of board behind the face.`)
        else
            table.insert(notes, "The stock bars found no billet to fatten — counted, nothing more.")
        end
    end

    if bladed then
        if edge >= 6 then
            table.insert(lines, `The edge was honed past reason — {edge} passes of the stone.`)
        elseif edge >= 3 then
            table.insert(lines, `The edge was honed keen — {edge} passes of the stone.`)
        elseif edge > 0 then
            table.insert(lines, `The edge took {edge} {if edge == 1 then "pass" else "passes"} of the stone — a working edge, no more.`)
        else
            table.insert(lines, "No edge rune was struck — it is a bar with ambitions.")
        end
    elseif category == "arrow" and edge > 0 then
        table.insert(lines, `The point was touched to the stone {TimesWord(edge)} — it will find the gap in mail.`)
    end

    if bladed then
        if twinEdge > 0 then
            table.insert(lines, "Both edges are ground true — it cuts on the draw and the backswing.")
        end
        if hollow > 0 then
            table.insert(lines, "Hollow-ground — the flat is scooped to a whisper behind the edge.")
        end
        if clip > 0 then
            table.insert(lines, "The spine is clipped straight to the point — a fighting point, quick to turn.")
        end
    end

    if curve ~= 0 and category ~= "arrow" and category ~= "knuckles" then
        local hand = if curve > 0 then "sunwise" else "widdershins"
        table.insert(lines, `It sweeps {hand} — a drawing cut, {math.abs(curve)} {if math.abs(curve) == 1 then "hand" else "hands"} of bend.`)
    end
    if wave > 0 and category ~= "arrow" and category ~= "knuckles" then
        table.insert(lines, "The edge ripples flame-wise down its length.")
    end
    if serration > 0 then
        if category == "arrow" then
            table.insert(lines, `Barbs are filed into the head ({serration} to the side) — it will not draw back out.`)
        elseif category == "knuckles" then
            table.insert(lines, `Spikes stand proud of the rings ({serration} to the row).`)
        elseif category == "mace" then
            table.insert(lines, `Spikes stand out between the flanges ({serration} to the round).`)
        elseif category == "shield" then
            if pommel > 0 then
                table.insert(lines, "The boss is drawn out into a wicked spike.")
            else
                table.insert(lines, `Spikes stud the face in a ring ({serration} to the round).`)
            end
        else
            table.insert(lines, `Saw-teeth line the back edge ({serration} to the span).`)
        end
    end
    if hook > 0 then
        if category == "axe" then
            table.insert(lines, "A hook curls from the back of the bit — made to pull shields down and riders from the saddle.")
        elseif category == "spear" then
            table.insert(lines, "A hooked lug juts below the head — for dragging a man off his feet.")
        elseif category == "arrow" then
            table.insert(lines, "The barbs are hooked back on themselves — cutting them out is butcher's work.")
        elseif category == "mace" then
            table.insert(lines, "A back-spike balances the flanges — made for the seams in plate.")
        elseif bladed then
            table.insert(lines, "A catching hook is worked into the spine near the point — a blade-breaker's trick.")
        end
    end
    if moon > 0 then
        if bladed then
            table.insert(lines, "The point flares into a crescent — a moon-shaped tip.")
        elseif category == "arrow" then
            table.insert(lines, "The head is forged as a crescent moon — made to cut, not to pierce.")
        end
    end
    if category == "arrow" and fletch > 0 then
        table.insert(lines, `Fletched with {fletch} {if fletch == 1 then "feather" else "feathers"}, set true at the nock.`)
    end
    if stretch > 0 then
        table.insert(lines, `Reach-drawn — the taper was stretched {stretch} {if stretch == 1 then "hand" else "hands"} past its weight.`)
    end
    if bladed and spine > 0 then
        table.insert(lines, "The spine is forged thick — a reinforced back that will not snap on the bind.")
    end
    if fuller > 0 then
        table.insert(lines, if fuller >= 2 then "Twin fullers run the flat — lighter, no weaker." else "A fuller runs the flat — lighter, no weaker.")
    end
    if bladed and channel > 0 then
        table.insert(lines, "A blood channel is cut hard against the edge — narrower than any fuller, and darker work.")
    end

    if bladed then
        local furniture = {}
        if guard > 0 then
            table.insert(furniture, `a crossguard of {guard} {if guard == 1 then "hand" else "hands"} shields the fist`)
        end
        if basket > 0 then
            table.insert(furniture, if basket >= 3 then "a full basket of steel ribs cages the hand"
                elseif basket == 2 then "a ringed knuckle-bow cages the fingers"
                else "a knuckle-bow sweeps from guard to pommel")
        end
        if gripSpans > 0 then
            local gripLine = `the grip takes {gripSpans} {SpanWord(gripSpans)}`
            if wrap > 0 then
                gripLine ..= ", wound in crossed wire"
            end
            table.insert(furniture, gripLine)
        elseif wrap > 0 then
            table.insert(furniture, "crossed wire binds the bare tang")
        end
        if pommel > 0 then
            if skull > 0 then
                table.insert(furniture, "a pommel carved as a grinning skull seats the tang")
            else
                table.insert(furniture, `a {if pommel >= 3 then "heavy" else "round"} pommel seats the tang`)
            end
        end
        if jewel > 0 then
            table.insert(furniture, `a {if jewel >= 3 then "jewel the size of a knuckle" else "cut jewel"} is set in the {if pommel > 0 then "pommel" else "tang"}`)
        end
        if counterweight > 0 then
            table.insert(furniture, `a counterweight is socketed behind the {if pommel > 0 then "pommel" else "grip"}`)
        end
        if tassel > 0 then
            table.insert(furniture, "a battle charm swings from the hilt on a crimson cord")
        end
        if #furniture > 0 then
            local sentence = table.concat(furniture, "; ")
            table.insert(lines, (string.gsub(sentence, "^%l", string.upper)) .. ".")
        end
        if guard == 0 then
            table.insert(notes, "No guard — the fingers ride bare against the steel.")
        end
        if gripSpans == 0 then
            table.insert(notes, "A bare tang — nothing was fitted for the hand to hold.")
        end
        if skull > 0 and pommel == 0 then
            table.insert(notes, "A skull rune with no pommel to carve — the grin waits in the billet.")
        end
    elseif hafted then
        local furniture = {}
        if wrap > 0 then
            table.insert(furniture, "the haft is wound in crossed wire")
        end
        if pommel > 0 then
            table.insert(furniture, `{string.lower(Article(materialName))} {string.lower(materialName)} butt-cap weights the heel`)
        end
        if guard > 0 then
            table.insert(furniture, "a hand-stop collars the grip")
        end
        if jewel > 0 then
            table.insert(furniture, "a jewel is set at the heel")
        end
        if tassel > 0 then
            table.insert(furniture, "a battle charm swings at the heel")
        end
        if #furniture > 0 then
            local sentence = table.concat(furniture, "; ")
            table.insert(lines, (string.gsub(sentence, "^%l", string.upper)) .. ".")
        end
    elseif category == "shield" then
        local furniture = {}
        if pommel > 0 then
            table.insert(furniture, `{string.lower(Article(materialName))} {string.lower(materialName)} boss stands proud at the center`)
        end
        if guard > 0 then
            table.insert(furniture, `the rim is {if guard >= 2 then "double-banded" else "banded"} in {string.lower(materialName)}, riveted fast`)
        end
        if gripSpans > 0 then
            local strapLine = "riveted straps take the forearm"
            if wrap > 0 then
                strapLine ..= ", laced with crossed cord"
            end
            table.insert(furniture, strapLine)
        elseif wrap > 0 then
            table.insert(furniture, "crossed cord binds the bare handle")
        end
        if jewel > 0 then
            table.insert(furniture, `a {if jewel >= 3 then "jewel the size of a knuckle" else "cut jewel"} is set at the boss`)
        end
        if tassel > 0 then
            table.insert(furniture, "a champion's tassel hangs from the rim")
        end
        if #furniture > 0 then
            local sentence = table.concat(furniture, "; ")
            table.insert(lines, (string.gsub(sentence, "^%l", string.upper)) .. ".")
        end
        table.insert(lines, `Raised well, it walls off {reach} spans of the line.`)
        if gripSpans == 0 then
            table.insert(notes, "No straps — it rides the arm by hope alone.")
        end
    elseif category == "arrow" then
        local furniture = {}
        if wrap > 0 then
            table.insert(furniture, "cord whipping binds the head to the shaft")
        end
        if pommel > 0 then
            table.insert(furniture, "a cut nock seats the string")
        end
        if #furniture > 0 then
            local sentence = table.concat(furniture, "; ")
            table.insert(lines, (string.gsub(sentence, "^%l", string.upper)) .. ".")
        end
        table.insert(lines, "Reach is the bow's affair — in the hand it is half a span of trouble.")
        if fletch == 0 then
            table.insert(notes, "Unfletched — it will tumble in flight.")
        end
    elseif category == "knuckles" then
        local furniture = {}
        if gripSpans > 0 then
            local barLine = "the palm bar is padded for the fist"
            if wrap > 0 then
                barLine ..= ", wound in crossed wire"
            end
            table.insert(furniture, barLine)
        elseif wrap > 0 then
            table.insert(furniture, "crossed wire binds the bare bar")
        end
        if #furniture > 0 then
            local sentence = table.concat(furniture, "; ")
            table.insert(lines, (string.gsub(sentence, "^%l", string.upper)) .. ".")
        end
        table.insert(lines, "Its reach ends where the fist does.")
        if gripSpans == 0 then
            table.insert(notes, "A bare bar — the palm rides raw metal.")
        end
    end

    for _, accent in ipairs(accents) do
        if category == "shield" then
            table.insert(lines, `The field is {module.Materials[accent].PaintLine}.`)
        else
            table.insert(lines, (string.gsub(module.Materials[accent].AccentLine, "^%l", string.upper)) .. ".")
        end
    end

    for _, etching in ipairs(weapon.Etchings) do
        if category == "shield" then
            table.insert(lines, `The device “{etching.text}” is painted large across the face.`)
        else
            table.insert(lines, `Etched on the flat: “{etching.text}”.`)
        end
    end
    for _, inscription in ipairs(weapon.Inscriptions) do
        if #inscription > 0 then
            table.insert(lines, `A smith's inscription rings the tang: “{inscription}”.`)
        else
            table.insert(lines, "An empty inscription rings the tang — a circle of silence.")
        end
    end
    if totals.proof then
        table.insert(lines, `Proof-mark {totals.proof} is stamped at the ricasso.`)
    end
    if totals.extraProof then
        table.insert(notes, "Only one proof-mark takes — the extra numerals were filed off.")
    end

    if warped then
        local leanDeg = math.floor(math.abs(warpLean) + 0.5)
        if category == "shield" then
            table.insert(lines, `The forging warped it — the face leans {leanDeg}° off true and a crack walks the boards.`)
        else
            table.insert(lines, `The quench warped it — it leans {leanDeg}° off true and the edge runs jagged.`)
        end
    end

    local verdicts = {
        poor = "Poor work — the honest thing would be to melt it down.",
        common = "Common work — it will serve.",
        fine = "Fine work — a keeper.",
        masterwork = "Masterwork — the balance sings in the hand.",
        mythic = "Mythic work — the forge will not see its like again.",
    }
    if category ~= "ingot" then
        table.insert(lines, verdicts[quality])
    end

    for _, letter in ipairs(wastedList) do
        table.insert(notes, `The {letter} found no purchase in the metal — slag on the shop floor.`)
    end
    if not anyHead and category ~= "ingot" and not hafted then
        table.insert(notes, "No head-rune was struck — the billet fell to a plain edge by default.")
    end

    weapon.Description = table.concat(lines, " ")
    weapon.Notes = notes

    return weapon
end

return module
