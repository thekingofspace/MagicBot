--#include[random]
local Parser = require("@src/spell/Parser")
local Essences = require("@src/potion/Essences")
local Compounds = require("@src/potion/Compounds")
local Reactions = require("@src/potion/Reactions")

local Rng = random.new()

local function HashString(text: string): number
    local hash = 5381
    for i = 1, #text do
        hash = (hash * 33 + string.byte(text, i)) % 4294967296
    end
    return hash
end

local function NewRoll(seed: number): () -> number
    local state = seed % 2147483647
    if state <= 0 then
        state += 2147483646
    end
    return function()
        state = (state * 48271) % 2147483647
        return (state - 1) / 2147483646
    end
end

local module = {}

export type Charm = {
    letter: string?,
    unstable: boolean,
}

export type Phial = {
    Number: string,
    Drawn: boolean,
    Letter: string?,
    Power: number,
    Color: {r: number, g: number, b: number}?,
}

export type Brew = {
    Kind: "potion" | "poison" | "water" | "shattered",
    Title: string,
    Lines: {string},
    Notes: {string},
    Foretold: {string},
    Base: string?,
    Second: string?,
    Potency: number,
    PotencyLabel: string,
    Duration: number,
    Doses: number,
    Mode: "consume" | "apply" | "both" | "inhale",
    Vessel: "vial" | "flask" | "jug" | "heart" | "alembic" | "flute",
    Volatile: boolean,
    Soured: boolean,
    Masked: boolean,
    RotKind: string,
    Rot: number,
    Age: number,
    Bubbles: number,
    Swirls: number,
    Spirals: number,
    Thick: number,
    Sweet: number,
    Vapor: number,
    Label: string?,
    Sediment: number,
    Dregs: {string},
    Charms: {Charm},
    Hue: string,
    Color: {r: number, g: number, b: number},
    SecondColor: {r: number, g: number, b: number}?,
    Recipe: string,
    Compound: string?,
    Reaction: string?,
    Bind: string,
    Binds: string,
    Chain: string?,
    Phials: string?,
    Rack: {Phial},
    PerPour: boolean,
    Steeps: number,
    Frost: number,
    Rime: number,
    Boons: number,
    Quint: number,
    Radiant: boolean,
    Curdled: boolean,
    CurdColor: {r: number, g: number, b: number}?,
    Uneasy: boolean,
    Thunder: boolean,
    Blight: boolean,
    Augur: number,
    CatalystSeam: boolean,
    Hiss: boolean,
    CompoundBands: {{r: number, g: number, b: number}}?,
    ElixirBands: {{r: number, g: number, b: number}}?,
    TopTints: {{r: number, g: number, b: number}},
}

type SubResult = {
    power: {[string]: number},
    seq: {string},
    venom: number,
    caustic: number,
    unstable: boolean,
}

type Pot = {
    power: {[string]: number},
    order: {[string]: number},
    nextOrder: number,
    venom: number,
    caustic: number,
    steep: number,
    pours: number,
    age: number,
    consumeMarks: number,
    applyMarks: number,
    bubbles: number,
    swirls: number,
    spirals: number,
    thick: number,
    distill: number,
    dilute: number,
    sweet: number,
    vapor: number,
    label: string?,
    labelExtra: boolean,
    dregs: {[string]: number},
    charms: {Charm},
    catalyst: number,
    elixir: number,
    frost: number,
    quint: number,
    rime: number,
    boons: number,
    chains: number,
    resonance: number,
    augur: number,
    skims: number,
    scums: number,
    traceWaste: number,
    draws: {[string]: number},
    drawSeq: {string},
    rack: {[string]: SubResult},
    rackSeq: {string},
    brewNotes: {string},
    steeps: number,
    steepVolatile: boolean,
    extraSediment: number,
}

local function NewPot(): Pot
    return {
        power = {},
        order = {},
        nextOrder = 1,
        venom = 0,
        caustic = 0,
        steep = 0,
        pours = 0,
        age = 0,
        consumeMarks = 0,
        applyMarks = 0,
        bubbles = 0,
        swirls = 0,
        spirals = 0,
        thick = 0,
        distill = 0,
        dilute = 0,
        sweet = 0,
        vapor = 0,
        label = nil,
        labelExtra = false,
        dregs = {},
        charms = {},
        catalyst = 0,
        elixir = 0,
        frost = 0,
        quint = 0,
        rime = 0,
        boons = 0,
        chains = 0,
        resonance = 0,
        augur = 0,
        skims = 0,
        scums = 0,
        traceWaste = 0,
        draws = {},
        drawSeq = {},
        rack = {},
        rackSeq = {},
        brewNotes = {},
        steeps = 0,
        steepVolatile = false,
        extraSediment = 0,
    }
end

local ConsumeMarks = {S = true, O = true}
local ApplyMarks = {V = true, ["_"] = true, ["#"] = true}

local function Round1(value: number): number
    return math.floor(value * 10 + 0.5) / 10
end

local NumberWords = {"one", "two", "three", "four", "five", "six", "seven", "eight", "nine", "ten", "eleven", "twelve"}

local function NumberWord(value: number): string
    local whole = math.floor(value + 0.5)
    return NumberWords[whole] or tostring(whole)
end

local function ApplyRun(pot: Pot, run: Parser.Run, value: number)
    local letter, count = run.letter, run.count
    local essence = Essences.Get(letter)

    if string.match(letter, "%d") then
        pot.age += tonumber(letter) :: number * count
    elseif letter == "%" then
        pot.venom += value
    elseif letter == "/" then
        pot.caustic += value
    elseif essence then
        pot.power[letter] = (pot.power[letter] or 0) + value
        if not pot.order[letter] then
            pot.order[letter] = pot.nextOrder
            pot.nextOrder += 1
        end
    elseif letter == "H" then
        pot.steep += count
    elseif letter == "P" then
        pot.pours += count
    elseif ConsumeMarks[letter] then
        pot.consumeMarks += count
    elseif ApplyMarks[letter] then
        pot.applyMarks += count
    elseif letter == "." then
        pot.bubbles += count
    elseif letter == "&" then
        pot.swirls += count
    elseif letter == "(" or letter == ")" then
        pot.spirals += count
    elseif letter == "T" then
        pot.thick += count
    elseif letter == "X" then
        pot.distill += count
    elseif letter == "U" then
        pot.dilute += count
    elseif letter == "~" then
        pot.sweet += count
    elseif letter == "R" then
        pot.vapor += count
    elseif letter == "C" then
        pot.catalyst += count
    elseif letter == "E" then
        pot.elixir += count
    elseif letter == "I" then
        pot.frost += count
    elseif letter == "Q" then
        pot.quint += count
    elseif letter == "+" then
        pot.boons += count
    elseif letter == ";" then
        pot.chains += count
    elseif letter == "=" then
        pot.resonance += count
    elseif letter == "?" then
        pot.augur += count
    elseif letter == "-" then
        pot.rime += count
    elseif letter == ">" then
        pot.scums += count
    else
        pot.dregs[letter] = (pot.dregs[letter] or 0) + count
    end
end

local function ProcessRuns(pot: Pot, runs: {Parser.Run})
    local halve: {[number]: number} = {}
    local skip: {[number]: boolean} = {}
    for index, run in ipairs(runs) do
        if skip[index] then
            continue
        end
        local letter = run.letter
        if letter == "$" then
            local text = ""
            for rest = index + 1, #runs do
                local tail = runs[rest]
                if tail.letter ~= "$" then
                    text ..= string.rep(tail.letter, tail.count)
                end
            end
            if pot.label then
                pot.labelExtra = true
            else
                pot.label = text
            end
            return
        elseif letter == "," then
            local following = runs[index + 1]
            if following and Essences.Get(following.letter) then
                halve[index + 1] = run.count
            else
                pot.traceWaste += 1
            end
        elseif letter == "<" then
            local following = runs[index + 1]
            if following and string.match(following.letter, "%d") then
                skip[index + 1] = true
                local number = following.letter
                if not pot.draws[number] then
                    table.insert(pot.drawSeq, number)
                end
                pot.draws[number] = (pot.draws[number] or 0) + following.count
            else
                pot.skims += run.count
            end
        else
            ApplyRun(pot, run, run.count / 2 ^ (halve[index] or 0))
        end
    end
end

local function CollectCharm(spell: Parser.Spell): Charm
    local best: string? = nil
    local bestPower = 0
    local unstable = spell.unstable

    local function Walk(layer: Parser.Spell)
        if layer.unstable then
            unstable = true
        end
        local powers: {[string]: number} = {}
        local function Add(run: Parser.Run)
            if Essences.Get(run.letter) then
                powers[run.letter] = (powers[run.letter] or 0) + run.count
            end
        end
        for _, run in ipairs(layer.rings) do
            Add(run)
        end
        for _, part in ipairs(layer.parts) do
            if part.kind == "spell" then
                Walk(part :: Parser.Spell)
            else
                for _, run in ipairs((part :: Parser.Group).runs) do
                    Add(run)
                end
            end
        end
        for letter, power in pairs(powers) do
            if power > bestPower then
                bestPower = power
                best = letter
            end
        end
    end
    Walk(spell)

    return {letter = best, unstable = unstable}
end

local function ClassifyPress(rings: {Parser.Run}): ("phial" | "steep" | "none", string?, {Parser.Run})
    local digitIndex: number? = nil
    local steepIndex: number? = nil
    for index, run in ipairs(rings) do
        if string.match(run.letter, "%d") then
            digitIndex = index
        elseif run.letter == ">" and not steepIndex then
            steepIndex = index
        end
    end
    if digitIndex then
        local rest = {}
        for index, run in ipairs(rings) do
            if index ~= digitIndex then
                table.insert(rest, run)
            end
        end
        return "phial", rings[digitIndex :: number].letter, rest
    end
    if steepIndex then
        local rest = {}
        for index, run in ipairs(rings) do
            if index == steepIndex then
                if run.count > 1 then
                    table.insert(rest, {letter = ">", count = run.count - 1})
                end
            else
                table.insert(rest, run)
            end
        end
        return "steep", nil, rest
    end
    return "none", nil, rings
end

type SubPot = {
    power: {[string]: number},
    seq: {string},
    venom: number,
    caustic: number,
    age: number,
    scums: number,
    skims: number,
    distill: number,
    dilute: number,
    unstable: boolean,
}

local function SubApplyRuns(sub: SubPot, runs: {Parser.Run})
    local halve: {[number]: number} = {}
    local skip: {[number]: boolean} = {}
    for index, run in ipairs(runs) do
        if skip[index] then
            continue
        end
        local letter = run.letter
        if letter == "," then
            local following = runs[index + 1]
            if following and Essences.Get(following.letter) then
                halve[index + 1] = run.count
            end
        elseif letter == "<" then
            local following = runs[index + 1]
            if following and string.match(following.letter, "%d") then
                skip[index + 1] = true
            else
                sub.skims += run.count
            end
        elseif string.match(letter, "%d") then
            sub.age += tonumber(letter) :: number * run.count
        elseif letter == "%" then
            sub.venom += run.count / 2 ^ (halve[index] or 0)
        elseif letter == "/" then
            sub.caustic += run.count / 2 ^ (halve[index] or 0)
        elseif Essences.Get(letter) then
            local value = run.count / 2 ^ (halve[index] or 0)
            if not sub.power[letter] then
                table.insert(sub.seq, letter)
            end
            sub.power[letter] = (sub.power[letter] or 0) + value
        elseif letter == ">" then
            sub.scums += run.count
        elseif letter == "X" then
            sub.distill += run.count
        elseif letter == "U" then
            sub.dilute += run.count
        end
    end
end

local function SubStrongest(result: SubResult): (string?, number)
    local best: string? = nil
    local bestPower = 0
    for _, letter in ipairs(result.seq) do
        local power = result.power[letter]
        if power and power > bestPower then
            best = letter
            bestPower = power
        end
    end
    return best, bestPower
end

local function ResolveSubSpell(child: Parser.Spell, restRings: {Parser.Run}): SubResult
    local sub: SubPot = {
        power = {},
        seq = {},
        venom = 0,
        caustic = 0,
        age = 0,
        scums = 0,
        skims = 0,
        distill = 0,
        dilute = 0,
        unstable = child.unstable,
    }
    SubApplyRuns(sub, restRings)
    for _, part in ipairs(child.parts) do
        if part.kind == "spell" then
            local grandchild = part :: Parser.Spell
            local pressKind, _, rest = ClassifyPress(grandchild.rings)
            if pressKind == "steep" and grandchild.depth <= 3 then
                local inner = ResolveSubSpell(grandchild, rest)
                for _, letter in ipairs(inner.seq) do
                    if not sub.power[letter] then
                        table.insert(sub.seq, letter)
                    end
                    sub.power[letter] = (sub.power[letter] or 0) + inner.power[letter]
                end
                sub.venom += inner.venom
                sub.caustic += inner.caustic
                if inner.unstable then
                    sub.unstable = true
                end
            end
        else
            SubApplyRuns(sub, (part :: Parser.Group).runs)
        end
    end

    local function Reduce(amount: number)
        while amount > 0 and (sub.venom > 0 or sub.caustic > 0) do
            if sub.venom >= sub.caustic then
                sub.venom = math.max(0, sub.venom - 1)
            else
                sub.caustic = math.max(0, sub.caustic - 1)
            end
            amount -= 1
        end
    end
    Reduce(sub.scums)
    Reduce(math.floor(sub.age / 2))

    for _ = 1, sub.skims do
        local weakest: string? = nil
        local weakestPower = math.huge
        for _, letter in ipairs(sub.seq) do
            local power = sub.power[letter]
            if power and power <= weakestPower then
                weakest = letter
                weakestPower = power
            end
        end
        if weakest then
            sub.power[weakest] = nil
            local at = table.find(sub.seq, weakest)
            if at then
                table.remove(sub.seq, at)
            end
        end
    end

    if #sub.seq > 0 and (sub.distill > 0 or sub.dilute > 0) then
        local strongest: string? = nil
        local strongestPower = 0
        for _, letter in ipairs(sub.seq) do
            local power = sub.power[letter]
            if power and power > strongestPower then
                strongest = letter
                strongestPower = power
            end
        end
        if strongest then
            sub.power[strongest] = math.max(1, strongestPower + sub.distill - sub.dilute)
        end
    end

    return {
        power = sub.power,
        seq = sub.seq,
        venom = sub.venom,
        caustic = sub.caustic,
        unstable = sub.unstable,
    }
end

local function SteepNote(result: SubResult): string
    local strongest, power = SubStrongest(result)
    if strongest then
        return `An inner brew steeps through the glass — {Essences.Get(strongest).Name} ({Round1(power)}) joins the pot.`
    elseif result.venom + result.caustic > 0 then
        return "An inner brew steeps through the glass — nothing but ferment joins the pot."
    end
    return "An inner brew steeps through the glass — nothing but water joins the pot."
end

local function Accumulate(spell: Parser.Spell, pot: Pot)
    ProcessRuns(pot, spell.rings)
    for _, part in ipairs(spell.parts) do
        if part.kind == "spell" then
            local child = part :: Parser.Spell
            local pressKind, digit, rest = ClassifyPress(child.rings)
            if pressKind == "phial" and child.depth == 2 then
                local resolved = ResolveSubSpell(child, rest)
                local number = digit :: string
                if pot.rack[number] then
                    table.insert(pot.brewNotes, `Phial {number} is already corked — the second brew spills into the fire.`)
                else
                    pot.rack[number] = resolved
                    table.insert(pot.rackSeq, number)
                end
            elseif pressKind == "steep" and child.depth <= 3 then
                local resolved = ResolveSubSpell(child, rest)
                for _, letter in ipairs(resolved.seq) do
                    pot.power[letter] = (pot.power[letter] or 0) + resolved.power[letter]
                    if not pot.order[letter] then
                        pot.order[letter] = pot.nextOrder
                        pot.nextOrder += 1
                    end
                end
                pot.venom += resolved.venom
                pot.caustic += resolved.caustic
                if resolved.unstable then
                    pot.steepVolatile = true
                end
                pot.steeps += 1
                table.insert(pot.brewNotes, SteepNote(resolved))
            else
                table.insert(pot.charms, CollectCharm(child))
            end
        else
            ProcessRuns(pot, (part :: Parser.Group).runs)
        end
    end
end

local function RankEssences(pot: Pot): {{letter: string, power: number}}
    local ranked = {}
    for letter, power in pairs(pot.power) do
        table.insert(ranked, {letter = letter, power = power})
    end
    table.sort(ranked, function(a, b)
        if a.power == b.power then
            return pot.order[a.letter] < pot.order[b.letter]
        end
        return a.power > b.power
    end)
    return ranked
end

function module.Brew(spell: Parser.Spell): Brew
    local pot = NewPot()
    Accumulate(spell, pot)

    local notes: {string} = {}
    local lines: {string} = {}
    local foretold: {string} = {}

    for _, note in ipairs(pot.brewNotes) do
        table.insert(notes, note)
    end

    if pot.skims > 0 then
        local skimmedAny = false
        for _ = 1, pot.skims do
            local weakest: {letter: string, power: number}? = nil
            for letter, power in pairs(pot.power) do
                if not weakest
                    or power < weakest.power
                    or (power == weakest.power and pot.order[letter] > pot.order[weakest.letter]) then
                    weakest = {letter = letter, power = power}
                end
            end
            if weakest then
                skimmedAny = true
                pot.power[weakest.letter] = nil
                table.insert(notes, `The ladle skims the {Essences.Get(weakest.letter).Name} ({Round1(weakest.power)}) out of the pot.`)
            end
        end
        if not skimmedAny then
            table.insert(notes, "The ladle finds nothing to skim.")
        end
    end

    if pot.scums > 0 then
        local before = pot.venom + pot.caustic
        if before > 0 then
            local amount = pot.scums
            while amount > 0 and (pot.venom > 0 or pot.caustic > 0) do
                if pot.venom >= pot.caustic then
                    pot.venom = math.max(0, pot.venom - 1)
                else
                    pot.caustic = math.max(0, pot.caustic - 1)
                end
                amount -= 1
            end
            table.insert(notes, `The scum is poured off — the ferment thins ({Round1(before)} → {Round1(pot.venom + pot.caustic)}).`)
        end
    end

    for _ = 1, pot.traceWaste do
        table.insert(notes, "A drop of nothing, stirred in and lost.")
    end

    local ranked = RankEssences(pot)
    local base = ranked[1]
    local second = ranked[2]
    local hadSecondCandidate = second ~= nil

    local function ClearsBar(power: number, basePower: number): boolean
        if pot.catalyst >= 2 then
            return power >= 1
        elseif pot.catalyst == 1 then
            return power * 3 >= basePower
        end
        return power * 2 >= basePower
    end

    local bindField = "—"
    local bindsField = "—"
    local compound: Compounds.Compound? = nil
    local reactionField: string? = nil
    local uneasy = false
    local curdled = false
    local curdLetter: string? = nil
    local thunder = false
    local shattered = false
    local naturally = false

    if base and second then
        naturally = second.power * 2 >= base.power
        if not ClearsBar(second.power, base.power) then
            local weakName = Essences.Get(second.letter).Name
            local baseName = Essences.Get(base.letter).Name
            local tease = Compounds.Get(base.letter, second.letter)
            if pot.catalyst > 0 then
                table.insert(notes, `The {weakName} ({Round1(second.power)}) is too weak even for the catalyst — it needs a third of the {baseName}'s strength ({Round1(base.power)}).`)
            elseif tease then
                table.insert(notes, `The {weakName} ({Round1(second.power)}) is too weak to color the brew — it needs half the {baseName}'s strength ({Round1(base.power)}) — {tease.Title} waits past that line.`)
            else
                table.insert(notes, `The {weakName} ({Round1(second.power)}) is too weak to color the brew — it needs half the {baseName}'s strength ({Round1(base.power)}).`)
            end
            second = nil
        end
    end

    if base and second then
        local reaction = Reactions.Get(base.letter, second.letter)
        if reaction then
            local baseName = Essences.Get(base.letter).Name
            local secondName = Essences.Get(second.letter).Name
            if reaction.Kind == "curdle" then
                if pot.catalyst >= 2 and pot.age == 0 then
                    uneasy = true
                    bindField = "uneasy"
                    table.insert(notes, `The catalyst forces the {secondName} against the {baseName} — an uneasy blend, churning in the glass.`)
                else
                    table.insert(notes, reaction.Message)
                    if pot.catalyst >= 2 then
                        table.insert(notes, "Time undoes what the catalyst forced — the blend curdles in the cellar.")
                    end
                    curdled = true
                    curdLetter = second.letter
                    reactionField = reaction.Field
                    bindField = "curdled"
                    pot.extraSediment += 3
                    second = nil
                end
            elseif reaction.Kind == "fizz" then
                table.insert(notes, reaction.Message)
                reactionField = reaction.Field
                base.power = math.max(0, base.power - 1)
                pot.bubbles += 3
                second = nil
                if base.power <= 0 then
                    pot.power[base.letter] = nil
                    base = nil
                end
            elseif reaction.Kind == "thunder" then
                thunder = true
                reactionField = reaction.Field
                if spell.unstable then
                    shattered = true
                else
                    table.insert(notes, reaction.Message)
                    second = nil
                end
            end
        end
    end

    if shattered then
        return {
            Kind = "shattered",
            Title = "Shattered Vessel",
            Lines = {"The glass gives way — nothing survives the war of weight and weightlessness."},
            Notes = {},
            Foretold = {},
            Base = if base then base.letter else nil,
            Second = if second then second.letter else nil,
            Potency = 0,
            PotencyLabel = "—",
            Duration = 0,
            Doses = 0,
            Mode = "consume",
            Vessel = "flask",
            Volatile = true,
            Soured = false,
            Masked = false,
            RotKind = "venom",
            Rot = 0,
            Age = pot.age,
            Bubbles = 0,
            Swirls = 0,
            Spirals = 0,
            Thick = 0,
            Sweet = 0,
            Vapor = 0,
            Label = nil,
            Sediment = 0,
            Dregs = {},
            Charms = {},
            Hue = "a spilled shimmer",
            Color = {r = 190, g = 200, b = 230},
            SecondColor = nil,
            Recipe = spell.raw,
            Compound = nil,
            Reaction = reactionField,
            Bind = "—",
            Binds = "—",
            Chain = nil,
            Phials = nil,
            Rack = {},
            PerPour = true,
            Steeps = pot.steeps,
            Frost = 0,
            Rime = 0,
            Boons = 0,
            Quint = 0,
            Radiant = false,
            Curdled = false,
            CurdColor = nil,
            Uneasy = false,
            Thunder = true,
            Blight = false,
            Augur = 0,
            CatalystSeam = false,
            Hiss = false,
            CompoundBands = nil,
            ElixirBands = nil,
            TopTints = {},
        }
    end

    local mindPair: Essences.MindPair? = nil
    local forced = false
    if base and second then
        if base.letter == "'" then
            mindPair = Essences.MindPairs[second.letter]
        elseif second.letter == "'" then
            mindPair = Essences.MindPairs[base.letter]
        end
        if not mindPair and not uneasy then
            compound = Compounds.Get(base.letter, second.letter)
        end
        if not naturally and not uneasy then
            forced = true
            table.insert(notes, `The catalyst forces the {Essences.Get(second.letter).Name} into the bind — a harsh marriage.`)
        end
        if not uneasy then
            bindField = if forced then "forced" else (if compound then "fused" else "clause")
            if mindPair and not forced then
                bindField = "fused"
            end
        end
        bindsField = "two"
    end

    if pot.catalyst > 0 and not hadSecondCandidate then
        table.insert(notes, "The catalyst finds nothing to hurry.")
    end

    local third: {letter: string, power: number}? = nil
    if base and second and ranked[3] then
        local candidate = ranked[3]
        if pot.elixir > 0 and ClearsBar(candidate.power, base.power) then
            third = candidate
            bindsField = "three (elixir)"
            if ranked[4] then
                table.insert(notes, `A fourth essence ({Essences.Get(ranked[4].letter).Name}) settles out — even an elixir binds but three.`)
            end
        else
            local settleName = Essences.Get(candidate.letter).Name
            local tease = Compounds.Get(base.letter, candidate.letter)
            local note: string
            if compound then
                note = `A third essence ({settleName}) settles out — a brew binds only two — even {compound.Title} holds no third.`
            else
                note = `A third essence ({settleName}) settles out — a brew binds only two.`
            end
            if tease then
                note ..= ` (Had it bound the {Essences.Get(base.letter).Name}, {tease.Title} waited.)`
            end
            table.insert(notes, note)
        end
    end

    local rotRaw = pot.venom + pot.caustic
    local rotKind = if pot.caustic > pot.venom then "caustic" else "venom"
    local mellow = math.floor(pot.age / 2)
    local rot = math.max(0, rotRaw - mellow)
    if rotRaw > 0 and mellow > 0 then
        if rot == 0 then
            table.insert(notes, `Aged {pot.age} seasons — the ferment ({Round1(rotRaw)}) mellows away entirely.`)
        else
            table.insert(notes, `Aged {pot.age} seasons — the ferment mellows ({Round1(rotRaw)} → {Round1(rot)}).`)
        end
    elseif pot.age > 0 then
        table.insert(notes, `Aged {pot.age} {if pot.age == 1 then "season" else "seasons"} — the brew drinks smoother for it.`)
    end

    local volatile = spell.unstable or pot.steepVolatile or thunder
    local perPour = (spell.unstable or pot.steepVolatile) and pot.frost == 0
    local Roll = if perPour
        then function()
            return Rng:NextNumber()
        end
        else NewRoll(HashString(spell.raw or "empty"))
    local potency = if base then base.power else 0
    local rollLo: number? = nil
    local rollHi: number? = nil
    if volatile then
        if base then
            if pot.rime >= 3 and not thunder then
                volatile = false
                table.insert(notes, "Brewed on ice — the bind steadies.")
            else
                local narrowing = if thunder then 1 else (3 - math.min(pot.rime, 3)) / 3
                local swing = 0.75 + Roll() * 0.6
                swing = 1 + (swing - 1) * narrowing
                potency = math.max(1, math.floor(base.power * swing + 0.5))
                rollLo = math.max(1, math.floor(base.power * (1 - 0.25 * narrowing) + 0.5))
                rollHi = math.floor(base.power * (1 + 0.35 * narrowing) + 0.5)
                if pot.quint > 0 and not thunder then
                    potency = math.max(potency, math.floor(base.power + 0.5))
                    rollLo = math.max(rollLo :: number, math.floor(base.power + 0.5))
                    table.insert(notes, "The quintessence sings — the roll never lands below the written strength.")
                end
                if pot.frost > 0 and not thunder then
                    table.insert(notes, "The frost stills the fizz — this pour is the pour forever.")
                end
            end
        end
        if volatile and rot > 0 then
            rot = Round1(rot * (0.8 + Roll() * 0.6))
        end
    end

    if compound and second then
        potency += math.floor(second.power / 2)
    end

    if base and pot.distill > 0 then
        if compound and second and pot.distill >= 3 then
            table.insert(notes, `The still cracks the {(compound :: Compounds.Compound).Title} — {Essences.Get(second.letter).Name} rides out with the vapor.`)
            potency -= math.floor(second.power / 2)
            compound = nil
            second = nil
            third = nil
            bindField = "—"
            bindsField = "—"
        end
        potency += pot.distill
        local times = if pot.distill == 1 then "once" elseif pot.distill == 2 then "twice" else `{pot.distill} times`
        table.insert(notes, `Distilled {times} over — fiercer for it, but the bottle holds less.`)
    end
    if base and pot.dilute > 0 then
        potency = math.max(1, potency - pot.dilute)
        table.insert(notes, "Watered thin — a gentler draught, and more of it.")
    end

    local soured = false
    if base then
        if rot >= potency then
            soured = true
        elseif rot * 2 >= potency then
            table.insert(notes, `A sour ferment rides beneath the taste ({rotKind} {rot}) — drink it fresh, or not at all.`)
        elseif rot > 0 then
            table.insert(notes, `A sour note boils off in the brewing — the ferment ({rot}) is too weak to spoil it.`)
        end
    elseif rot > 0 then
        soured = true
    end
    if soured and volatile and base then
        table.insert(notes, "The volatile bind let the ferment outrun the brewing — this pour soured in the glass.")
    end

    local blight = false
    if soured and pot.venom > 0 and pot.caustic > 0 and pot.venom * 2 >= pot.caustic and pot.caustic * 2 >= pot.venom then
        blight = true
    end

    local kind: "potion" | "poison" | "water" = "potion"
    if soured then
        kind = "poison"
    elseif not base then
        kind = "water"
    end

    if pot.elixir > 0 and kind == "poison" then
        table.insert(notes, "An elixir base wants a virtue — the ferment is none.")
    end

    local boonsGranted = 0
    if pot.boons > 0 then
        if kind == "poison" then
            table.insert(notes, "No kindness amplifies a poison.")
        else
            local wasted = pot.boons
            if kind == "potion" then
                boonsGranted = math.min(pot.boons, 3)
                potency += boonsGranted
                wasted = pot.boons - boonsGranted
            end
            if wasted > 0 then
                pot.extraSediment += wasted
                local word = if wasted == 1 then "boon settles" else "boons settle"
                table.insert(notes, `Virtue holds only so much — {wasted} wasted {word} as sediment.`)
            end
        end
    end

    if pot.quint > 0 then
        if kind == "poison" then
            local before = rot
            rot += pot.quint
            table.insert(notes, `Quintessence exalts whatever it finds — the rot deepens ({Round1(before)} → {Round1(rot)}).`)
        elseif kind == "potion" then
            potency += pot.quint * 2
        end
    end

    potency = math.floor(potency + 0.5)

    local radiant = false
    if pot.resonance > 0 then
        if soured then
            table.insert(notes, "Nothing wholesome answers — the resonance dies in the sour.")
        elseif not second then
            table.insert(notes, "Nothing answers the resonance.")
        elseif compound or mindPair then
            radiant = true
            local radiantName = if compound then (compound :: Compounds.Compound).Title else (mindPair :: Essences.MindPair).Title
            table.insert(notes, `The resonance turns the {radiantName} radiant — rings of light shimmer on the surface.`)
        end
    end

    local topTints: {{r: number, g: number, b: number}} = {}
    local topClauses = ""
    local hueTints: {string} = {}
    for _, number in ipairs(pot.drawSeq) do
        local count = pot.draws[number]
        local phial = pot.rack[number]
        if not phial then
            table.insert(notes, `Nothing fills phial {number} — the ladle comes up empty.`)
        else
            local strongest, power = SubStrongest(phial)
            if not strongest then
                table.insert(notes, `Phial {number} holds nothing but water — no note rises.`)
            elseif base and power * 2 >= base.power and kind == "potion" then
                potency += count
                topClauses ..= Essences.Get(strongest).Clause
                table.insert(hueTints, Essences.Get(strongest).Hue)
                table.insert(topTints, Essences.Get(strongest).Color)
            else
                table.insert(notes, `A top-note of {Essences.Get(strongest).Name}, more scent than substance.`)
            end
        end
    end

    local mindPairResolved = if second then mindPair else nil
    mindPair = mindPairResolved

    local forgetting = kind == "poison" and base ~= nil and base.letter == "'" and rotKind == "venom" and not blight
    local masked = kind == "poison" and rotKind == "venom" and pot.sweet > 0 and pot.vapor == 0 and not forgetting and not blight
    local trance = kind == "potion" and base ~= nil and base.letter == "'" and second == nil and potency >= 6

    local vaporous = pot.vapor > 0 and pot.frost == 0
    if pot.vapor > 0 and pot.frost > 0 then
        table.insert(notes, "Frozen fast — no vapor rises.")
    end

    local doses = math.max(1, 1 + pot.pours + pot.dilute - pot.distill)
    local mode: "consume" | "apply" | "both" | "inhale" = "consume"
    if vaporous then
        mode = "inhale"
    elseif pot.consumeMarks > 0 and pot.applyMarks > 0 then
        mode = "both"
    elseif pot.applyMarks > 0 then
        mode = "apply"
    end

    local hiss = false
    if kind == "potion" and (pot.rime > 0 or pot.frost > 0) then
        if (base and base.letter == "B") or (second and second.letter == "B") then
            hiss = true
            table.insert(notes, "The Ember hisses against the ice — a thread of steam slips past the cork.")
        end
    end

    local duration = 0
    if kind == "potion" then
        duration = potency * 3 + pot.steep * 4 + pot.age + pot.thick * 3
        duration += pot.frost * 2 + pot.rime
        if radiant then
            duration += 2
        end
        duration -= pot.augur
        if hiss then
            duration -= 1
        end
        duration = math.max(1, duration)
        if second and second.letter == ":" then
            duration *= 2
        end
    elseif kind == "poison" then
        duration = math.max(2, math.floor(rot + 0.5) * 2 + pot.steep * 4) + pot.thick * 3
        duration += pot.frost * 2 + pot.rime - pot.augur
        duration = math.max(1, duration)
    end

    local vesselStrength = if kind == "poison" then math.floor(rot + 0.5) else potency
    local vessel: "vial" | "flask" | "jug" | "heart" | "alembic" | "flute" = "flask"
    if doses >= 4 or vesselStrength >= 9 then
        vessel = "jug"
    elseif doses == 1 and vesselStrength <= 3 then
        vessel = "vial"
    end
    if base and pot.distill > 0 then
        vessel = "alembic"
    elseif (mindPair ~= nil or trance or forgetting) and doses <= 2 and vesselStrength <= 8 then
        vessel = "heart"
    elseif third and kind == "potion" then
        vessel = "flute"
    end

    local baseEssence = if base then Essences.Get(base.letter) else nil
    local secondEssence = if second then Essences.Get(second.letter) else nil
    local thirdEssence = if third then Essences.Get((third :: {letter: string, power: number}).letter) else nil
    local clause = if secondEssence then secondEssence.Clause else ""
    if thirdEssence then
        clause ..= thirdEssence.Clause
    end
    clause ..= topClauses

    local consumeLead = if pot.frost > 0 then "On consume (let melt on the tongue):" else "On consume:"

    local blankElixir = kind == "water" and pot.elixir > 0
    local quintWater = kind == "water" and pot.quint > 0 and not blankElixir

    if kind == "water" then
        if blankElixir then
            table.insert(lines, `{consumeLead} a base awaiting a virtue — it tastes of possibility and nothing else.`)
        elseif quintWater then
            table.insert(lines, `{consumeLead} water more watery than water — quenches a week's thirst in one sip.`)
        elseif vaporous then
            table.insert(lines, "On inhale: cool as morning fog — nothing more.")
        else
            table.insert(lines, `{consumeLead} quenches thirst — nothing more.`)
        end
    elseif kind == "poison" then
        if blight then
            table.insert(lines, `{consumeLead} a blight that sickens and scars in one — drunk or applied, it does not care (blight {rot}) for {duration} beats.`)
        elseif forgetting then
            table.insert(lines, `{consumeLead} gently unwrites the drinker's last days (venom {rot}) for {duration} beats.`)
        elseif masked then
            table.insert(lines, `{consumeLead} tastes of warm honey and easy comfort.`)
        elseif vaporous then
            table.insert(lines, `On inhale: a foul reek that gripes lungs and wits alike ({rotKind} {rot}) for {duration} beats.`)
        elseif rotKind == "caustic" then
            table.insert(lines, `On apply: eats at flesh, cloth, and lock alike (caustic {rot}) — do not drink.`)
        else
            table.insert(lines, `{consumeLead} sickens the gut (venom {rot}) for {duration} beats.`)
        end
    elseif mindPair then
        local pair = mindPair :: Essences.MindPair
        local mindClause = (if thirdEssence then thirdEssence.Clause else "") .. topClauses
        if mode == "inhale" then
            table.insert(lines, `On inhale: {pair.Inhale}{mindClause} (potency {potency}) for {duration} beats.`)
        else
            if mode == "consume" or mode == "both" then
                table.insert(lines, `{consumeLead} {pair.Consume}{mindClause} (potency {potency}) for {duration} beats.`)
            end
            if mode == "apply" or mode == "both" then
                table.insert(lines, `On apply: {pair.Apply}{mindClause} (potency {potency}) for {duration} beats.`)
            end
        end
    elseif trance then
        if mode == "inhale" then
            table.insert(lines, `On inhale: {Essences.Trance.Inhale} (potency {potency}) for {duration} beats.`)
        else
            if mode == "consume" or mode == "both" then
                table.insert(lines, `{consumeLead} {Essences.Trance.Consume} (potency {potency}) for {duration} beats.`)
            end
            if mode == "apply" or mode == "both" then
                table.insert(lines, `On apply: {Essences.Trance.Apply} (potency {potency}) for {duration} beats.`)
            end
        end
    elseif compound then
        local fused = compound :: Compounds.Compound
        local fusedClause = (if thirdEssence then thirdEssence.Clause else "") .. topClauses
        if mode == "inhale" then
            table.insert(lines, `On inhale: {fused.Line}{fusedClause} (potency {potency}) for {duration} beats.`)
        else
            if mode == "consume" or mode == "both" then
                table.insert(lines, `{consumeLead} {fused.Line}{fusedClause} (potency {potency}) for {duration} beats.`)
            end
            if mode == "apply" or mode == "both" then
                table.insert(lines, `On apply: {fused.Line}{fusedClause} (potency {potency}) for {duration} beats.`)
            end
        end
    else
        local essence = baseEssence :: Essences.Essence
        if mode == "inhale" then
            table.insert(lines, `On inhale: {essence.Inhale}{clause} (potency {potency}) for {duration} beats.`)
        end
        if mode == "consume" or mode == "both" then
            table.insert(lines, `{consumeLead} {essence.Consume}{clause} (potency {potency}) for {duration} beats.`)
        end
        if mode == "apply" or mode == "both" then
            table.insert(lines, `On apply: {essence.Apply}{clause} (potency {potency}) for {duration} beats.`)
        end
    end

    if pot.resonance > 0 and secondEssence and not compound and not mindPair and not soured and kind == "potion" then
        local voice = secondEssence :: Essences.Essence
        local voicePotency = Round1((second :: {letter: string, power: number}).power)
        if mode == "inhale" then
            table.insert(lines, `On inhale: {voice.Inhale} (potency {voicePotency}) for {duration} beats.`)
        else
            if mode == "consume" or mode == "both" then
                table.insert(lines, `{consumeLead} {voice.Consume} (potency {voicePotency}) for {duration} beats.`)
            end
            if mode == "apply" or mode == "both" then
                table.insert(lines, `On apply: {voice.Apply} (potency {voicePotency}) for {duration} beats.`)
            end
        end
        table.insert(notes, `The resonance gives the {voice.Name} its own voice — two virtues speak outright.`)
    end

    for index, charm in ipairs(pot.charms) do
        if index > 3 then
            table.insert(notes, "The glass holds three charms at most — the rest dissolve.")
            break
        end
        if charm.letter then
            local trembling = if charm.unstable then ", trembling in its bind" else ""
            table.insert(lines, `A charm of {string.lower(Essences.Get(charm.letter).Title)} hangs suspended in the glass{trembling}.`)
        else
            table.insert(lines, "An empty glass bead hangs suspended — a charm of nothing.")
        end
    end

    local rack: {Phial} = {}
    local phialParts: {string} = {}
    local rackNumbers: {string} = {}
    for number in pairs(pot.rack) do
        table.insert(rackNumbers, number)
    end
    table.sort(rackNumbers)
    for _, number in ipairs(rackNumbers) do
        local phial = pot.rack[number]
        local drawn = pot.draws[number] ~= nil
        local strongest = SubStrongest(phial)
        table.insert(rack, {
            Number = number,
            Drawn = drawn,
            Letter = strongest,
            Power = if strongest then phial.power[strongest :: string] else 0,
            Color = if strongest then Essences.Get(strongest :: string).Color else nil,
        })
        table.insert(phialParts, `{number}: {if drawn then "drawn" else "corked"}`)
        if not drawn then
            table.insert(notes, `Phial {number} stays corked in the glass.`)
        end
    end
    local phialsField = if #phialParts > 0 then table.concat(phialParts, " · ") else nil

    if pot.bubbles > 0 then
        table.insert(notes, if pot.bubbles > 2 then "It seethes with bubbles." else "It bubbles gently against the stopper.")
    end
    if pot.swirls > 0 then
        table.insert(notes, "Slow currents swirl the brew.")
    end
    if pot.spirals > 0 then
        table.insert(notes, "A spiral current winds through it, top to bottom.")
    end
    if pot.thick > 0 then
        table.insert(notes, "Thickened to a slow syrup — it pours slow and lasts long.")
    end
    if pot.frost > 0 then
        table.insert(notes, "The frost sets every dose into a faceted lozenge.")
    end
    if pot.sweet > 0 and not masked then
        if forgetting then
            table.insert(notes, "Honey cannot sweeten what the drinker will not remember.")
        elseif curdled then
            table.insert(notes, "Honey cannot marry what curdles.")
        elseif kind == "poison" and rotKind == "caustic" then
            table.insert(notes, "Honey does nothing for a caustic slime — it is not for drinking anyway.")
        else
            table.insert(notes, "Sweetened with a spoon of honey — it goes down easy.")
        end
    end
    if vaporous then
        table.insert(notes, "Brewed vaporous — uncork it and breathe; it is never drunk.")
        if compound and mode == "inhale" then
            table.insert(notes, `The {(compound :: Compounds.Compound).Title} rides the vapor.`)
        end
    end

    local dregLetters = {}
    local sediment = pot.extraSediment
    for letter, count in pairs(pot.dregs) do
        table.insert(dregLetters, letter)
        sediment += count
    end
    table.sort(dregLetters)
    if #dregLetters > 0 then
        table.insert(notes, `Dregs settle at the bottom — {table.concat(dregLetters, ", ")} hold no essence a body can drink.`)
    end
    if kind == "poison" then
        sediment += 5
    end

    local label = pot.label
    if label then
        if #label > 12 then
            label = string.sub(label, 1, 12)
            table.insert(notes, `The label runs long — only "{label}" fits on the paper.`)
        elseif #label == 0 then
            table.insert(notes, "A blank paper label is glued to the glass — the brewer forgot the name.")
        else
            table.insert(notes, `A paper label is glued to the glass — it reads "{label}".`)
        end
    end
    if pot.labelExtra then
        table.insert(notes, "The glue holds one label to a bottle — the rest flutter off.")
    end

    if volatile and not soured and not thunder and pot.frost == 0 then
        table.insert(notes, "The brew fizzes in its bind — potency rolls with every pour.")
    end

    if masked then
        table.insert(notes, `Beneath the honey: a soured brew that sickens the gut (venom {rot}) for {duration} beats — a sweet lie.`)
    end

    local chainField: string? = nil
    if pot.chains > 0 then
        if doses <= 1 then
            table.insert(notes, "Nothing follows the only dose — the chain hangs slack.")
        else
            local chained = math.min(doses, 1 + pot.chains)
            local total = duration * chained
            chainField = `{chained} doses, {total} beats end to end`
            local grim = if kind == "poison" then " — the poisoner's drip" else ""
            table.insert(notes, `Each dose wakes as the last fades — {chained} doses, {total} beats end to end{grim}.`)
        end
    end

    if pot.augur > 0 then
        local told = false
        if masked then
            table.insert(foretold, `The honey lies — beneath it a soured brew that sickens the gut (venom {rot}).`)
            told = true
        end
        if volatile and rollLo and rollHi then
            table.insert(foretold, `This bind rolls between {rollLo} and {rollHi}.`)
            told = true
        end
        if curdled and base and curdLetter then
            local wouldName = Compounds.Get(base.letter, curdLetter :: string)
            local refused = if wouldName then wouldName.Title else `{Essences.Get(curdLetter :: string).Adj} {Essences.Get(base.letter).Title}`
            table.insert(foretold, `What would have been {refused} curdles in the glass.`)
            told = true
        end
        if forgetting then
            table.insert(foretold, `{NumberWord(rot)} days, taken gently.`)
            told = true
        elseif soured and not masked and base then
            local wouldBe: string
            if second and compound then
                wouldBe = (compound :: Compounds.Compound).Title
            elseif second and secondEssence then
                local wouldCompound = Compounds.Get(base.letter, (second :: {letter: string, power: number}).letter)
                wouldBe = if wouldCompound then wouldCompound.Title else `{(secondEssence :: Essences.Essence).Adj} {(baseEssence :: Essences.Essence).Title}`
            else
                wouldBe = (baseEssence :: Essences.Essence).Title
            end
            table.insert(foretold, `What would have been {wouldBe} sours in the glass.`)
            told = true
        end
        if not told then
            table.insert(foretold, "The augury reads clean — no lie beneath.")
        end
    end

    local title: string
    local color: {r: number, g: number, b: number}
    local secondColor: {r: number, g: number, b: number}? = nil
    local hue: string
    local compoundField: string? = nil
    local compoundBands: {{r: number, g: number, b: number}}? = nil
    local elixirBands: {{r: number, g: number, b: number}}? = nil

    if kind == "water" then
        if blankElixir then
            title = "Blank Elixir"
            color = {r = 240, g = 236, b = 228}
            hue = "pearl white"
        elseif quintWater then
            title = "Quintessence of Water"
            color = Essences.WaterColor
            hue = "colorless"
        else
            title = if vaporous then "Clear Mist" else "Clear Water"
            color = Essences.WaterColor
            hue = "colorless"
        end
    elseif kind == "poison" then
        if blight then
            title = "Blightwater"
            color = {r = 32, g = 52, b = 36}
            hue = "black-green"
        elseif forgetting then
            title = "Draught of Forgetting"
            color = Essences.Forgetting.Color
            hue = Essences.Forgetting.Hue
        elseif masked then
            title = "Honeyed Cordial"
            color = Essences.HoneyMask.Color
            hue = Essences.HoneyMask.Hue
        else
            local rotEssence = Essences.Get(if rotKind == "caustic" then "/" else "%")
            if vaporous then
                title = "Soured Brew — a foul miasma"
            elseif rotKind == "caustic" then
                title = "Soured Brew — a caustic slime"
            else
                title = "Soured Brew — a thin poison"
            end
            color = rotEssence.Color
            hue = rotEssence.Hue
        end
        if volatile then
            title = "Volatile " .. title
        end
    else
        local essence = baseEssence :: Essences.Essence
        color = essence.Color
        hue = essence.Hue

        local noun: string
        if mode == "both" then
            noun = "Liniment"
        elseif mode == "apply" then
            noun = "Oil"
        elseif mode == "inhale" then
            noun = "Mist"
        elseif vessel == "alembic" then
            noun = "Distillate"
        elseif vessel == "vial" or vessel == "heart" then
            noun = "Phial"
        elseif vessel == "jug" then
            noun = "Jug"
        else
            noun = if secondEssence then "Draught" else "Tonic"
        end

        if compound then
            local fused = compound :: Compounds.Compound
            color = fused.Color
            hue = fused.Hue
            compoundBands = {essence.Color, (secondEssence :: Essences.Essence).Color}
            compoundField = `{essence.Name} + {(secondEssence :: Essences.Essence).Name} → {fused.Title}`
        elseif secondEssence then
            secondColor = (secondEssence :: Essences.Essence).Color
            hue = `{essence.Hue}, layered over {(secondEssence :: Essences.Essence).Hue}`
        end
        if curdled and curdLetter then
            local curdEssence = Essences.Get(curdLetter :: string)
            hue = `{essence.Hue}, curdled over {curdEssence.Hue}`
        end
        if thirdEssence then
            hue ..= `, banded with {(thirdEssence :: Essences.Essence).Hue}`
            if compound then
                elixirBands = {(compoundBands :: {{r: number, g: number, b: number}})[1], (compoundBands :: {{r: number, g: number, b: number}})[2], (thirdEssence :: Essences.Essence).Color}
            else
                elixirBands = {essence.Color, (secondEssence :: Essences.Essence).Color, (thirdEssence :: Essences.Essence).Color}
            end
            if compoundField then
                compoundField ..= ` (+ {(thirdEssence :: Essences.Essence).Name} rides third)`
            end
        end
        for _, tint in ipairs(hueTints) do
            hue ..= `, shot through with {tint}`
        end
        if radiant then
            hue ..= ", shimmering"
        end

        if mindPair then
            title = (mindPair :: Essences.MindPair).Title
        elseif trance then
            title = `{noun} of the Deep Trance`
        elseif compound then
            if thirdEssence then
                noun = "Elixir"
            end
            title = `{noun} of {(compound :: Compounds.Compound).Title}`
        elseif secondEssence then
            if thirdEssence then
                noun = "Elixir"
            end
            title = `{noun} of {(secondEssence :: Essences.Essence).Adj} {essence.Title}`
        else
            title = `{essence.Title} {noun}`
        end
        if pot.quint > 0 and (compound ~= nil or mindPair ~= nil) then
            title = "Quintessent " .. title
        end
        if volatile then
            title = "Volatile " .. title
        end
    end

    return {
        Kind = kind,
        Title = title,
        Lines = lines,
        Notes = notes,
        Foretold = foretold,
        Base = if base then base.letter else nil,
        Second = if second then second.letter else nil,
        Potency = if kind == "poison" then rot else potency,
        PotencyLabel = if kind == "poison" then (if masked then tostring(rot) elseif blight then `{rot} (blight)` else `{rot} ({rotKind})`) else tostring(potency),
        Duration = duration,
        Doses = doses,
        Mode = mode,
        Vessel = vessel,
        Volatile = volatile,
        Soured = soured,
        Masked = masked,
        RotKind = rotKind,
        Rot = rot,
        Age = pot.age,
        Bubbles = pot.bubbles,
        Swirls = pot.swirls,
        Spirals = pot.spirals,
        Thick = pot.thick,
        Sweet = pot.sweet,
        Vapor = pot.vapor,
        Label = label,
        Sediment = sediment,
        Dregs = dregLetters,
        Charms = pot.charms,
        Hue = hue,
        Color = color,
        SecondColor = secondColor,
        Recipe = spell.raw,
        Compound = compoundField,
        Reaction = reactionField,
        Bind = bindField,
        Binds = bindsField,
        Chain = chainField,
        Phials = phialsField,
        Rack = rack,
        PerPour = perPour and volatile,
        Steeps = pot.steeps,
        Frost = pot.frost,
        Rime = pot.rime,
        Boons = boonsGranted,
        Quint = pot.quint,
        Radiant = radiant,
        Curdled = curdled,
        CurdColor = if curdLetter then Essences.Get(curdLetter :: string).Color else nil,
        Uneasy = uneasy,
        Thunder = thunder,
        Blight = blight,
        Augur = pot.augur,
        CatalystSeam = (forced or uneasy) and second ~= nil,
        Hiss = hiss,
        CompoundBands = compoundBands,
        ElixirBands = elixirBands,
        TopTints = topTints,
    }
end

return module
