--#include[random]
local Parser = require("@src/spell/Parser")
local Runes = require("@src/spell/Runes")
local Aspects = require("@src/spell/Aspects")
local Elements = require("@src/spell/elements")

local Rng = random.new()

export type Vec = {x: number, y: number}

export type GlyphPlan = {
    kind: "arrow" | "sigil" | "spreadband" | "aspect" | "target" | "motion" | "phial" | "unknown",
    letters: string,
    letter: string,
    power: number,
    slots: {number},
    bound: string?,
    element: string?,
    target: string?,
    spread: number,
}

export type LayerPlan = {
    glyphs: {GlyphPlan},
    sigils: {GlyphPlan},
    bands: {GlyphPlan},
    targets: {GlyphPlan},
    forms: {{text: string, scale: number}},
    rings: {Parser.Run},
    subs: {LayerPlan},
    element: string?,
    spread: number,
    description: string,
    phial: string?,
    trigger: string?,
    unstable: boolean,
}

export type Working = {
    Name: string,
    Verb: string,
    Fallback: string,
    power: number,
    element: string?,
    targets: {[string]: number},
}

export type Corruption = {
    Name: string,
    Power: number,
    Full: boolean,
}

export type Effect = {
    Element: string?,
    Components: {string}?,
    Strength: number,
    Spread: number,
    AngleDeg: number?,
    Compass: string?,
    Directional: boolean,
    Balance: number,
    Direction: Vec,
    Description: string,
    Notes: {string},
    Layers: number,
    Repeats: number,
    Endless: boolean,
    Sustain: number,
    Delay: number,
    Conditional: boolean,
    ConditionTarget: string?,
    Trigger: string?,
    Stopper: string?,
    Curve: number,
    Motes: number,
    Coil: number,
    Homing: boolean,
    Range: number,
    Tints: {[string]: number},
    Targets: {[string]: number},
    Workings: {Working},
    Unstable: number,
    Corruption: Corruption?,
}

type Totals = {
    kinetic: Vec,
    flow: Vec,
    arrowMag: number,
    flowMag: number,
    elementPower: {[string]: number},
    spread: number,
    layers: number,
    glyphCount: number,
    unknown: {[string]: boolean},
    workings: {Working},
    targets: {[string]: number},
    tints: {[string]: number},
    forms: {{parts: {string}, scale: number}},
    curve: number,
    motes: number,
    coil: number,
    homing: boolean,
    range: number,
    repeats: number,
    loopN: number,
    sustain: number,
    delay: number,
    conditionN: number,
    invertN: number,
    surgeN: number,
    conditionTarget: string?,
    trigger: string?,
    stopper: string?,
    instability: number,
    ringNotes: {string},
}

local module = {}

local function NewTotals(): Totals
    return {
        kinetic = {x = 0, y = 0},
        flow = {x = 0, y = 0},
        arrowMag = 0,
        flowMag = 0,
        elementPower = {},
        spread = 0,
        layers = 0,
        glyphCount = 0,
        unknown = {},
        workings = {},
        targets = {},
        tints = {},
        forms = {},
        curve = 0,
        motes = 0,
        coil = 0,
        homing = false,
        range = 0,
        repeats = 0,
        loopN = 0,
        sustain = 0,
        delay = 0,
        conditionN = 0,
        invertN = 0,
        surgeN = 0,
        conditionTarget = nil,
        trigger = nil,
        stopper = nil,
        instability = 0,
        ringNotes = {},
    }
end

local function AddVec(target: Vec, x: number, y: number)
    target.x += x
    target.y += y
end

local function RotateVec(vec: Vec, angle: number)
    local cosA, sinA = math.cos(angle), math.sin(angle)
    local x = vec.x * cosA - vec.y * sinA
    local y = vec.x * sinA + vec.y * cosA
    vec.x = x
    vec.y = y
end

local function Magnitude(vec: Vec): number
    return math.sqrt(vec.x * vec.x + vec.y * vec.y)
end

local function MergeTotals(into: Totals, from: Totals)
    AddVec(into.kinetic, from.kinetic.x, from.kinetic.y)
    AddVec(into.flow, from.flow.x, from.flow.y)
    into.arrowMag += from.arrowMag
    into.flowMag += from.flowMag
    into.spread += from.spread
    into.layers += from.layers
    into.glyphCount += from.glyphCount
    into.instability += from.instability
    into.curve += from.curve
    into.motes += from.motes
    into.coil += from.coil
    into.homing = into.homing or from.homing
    into.range += from.range
    for _, form in ipairs(from.forms) do
        table.insert(into.forms, form)
    end
    for element, power in pairs(from.elementPower) do
        into.elementPower[element] = (into.elementPower[element] or 0) + power
    end
    for letter in pairs(from.unknown) do
        into.unknown[letter] = true
    end
    for _, working in ipairs(from.workings) do
        table.insert(into.workings, working)
    end
    for name, count in pairs(from.targets) do
        into.targets[name] = (into.targets[name] or 0) + count
    end
    for name, power in pairs(from.tints) do
        into.tints[name] = (into.tints[name] or 0) + power
    end
end

local function CompassOf(vec: Vec): string?
    if Magnitude(vec) < 1e-6 then
        return nil
    end
    local names = {"east", "southeast", "south", "southwest", "west", "northwest", "north", "northeast"}
    local angle = math.deg(math.atan2(vec.y, vec.x))
    local bucket = math.floor((angle + 22.5) / 45) % 8
    if bucket < 0 then
        bucket += 8
    end
    return names[bucket + 1]
end

local function TargetsPhrase(map: {[string]: number}): string?
    local names = {}
    for name in pairs(map) do
        table.insert(names, name)
    end
    if #names == 0 then
        return nil
    end
    table.sort(names)
    local parts = {}
    for _, name in ipairs(names) do
        local count = map[name]
        table.insert(parts, if count > 1 then `{name} ×{count}` else name)
    end
    return table.concat(parts, ", ")
end

local function RankElements(totals: Totals): {{name: string, power: number}}
    local ranked = {}
    for name, power in pairs(totals.elementPower) do
        table.insert(ranked, {name = name, power = power})
    end
    table.sort(ranked, function(a, b)
        if a.power == b.power then
            return a.name < b.name
        end
        return a.power > b.power
    end)
    return ranked
end

local function BuildEffect(totals: Totals): Effect
    local rankedAll = RankElements(totals)
    local notes: {string} = {}

    local normals = {}
    local corruptPower = 0
    local corruptName: string? = nil
    local corruptBest = 0
    for _, entry in ipairs(rankedAll) do
        if Elements.Corruptors[entry.name] then
            corruptPower += entry.power
            if entry.power > corruptBest then
                corruptBest = entry.power
                corruptName = entry.name
            end
        else
            table.insert(normals, entry)
        end
    end

    local ranked = if #normals > 0 then normals else rankedAll

    local elementName: string? = nil
    local components: {string}? = nil

    if #ranked >= 2 and ranked[2].power * 2 >= ranked[1].power then
        local mixed = Elements.MixOf(ranked[1].name, ranked[2].name)
        if mixed then
            elementName = mixed
            components = {ranked[1].name, ranked[2].name}
            if #ranked >= 3 then
                table.insert(notes, `A third element ({ranked[3].name}) slips away — only two can bind.`)
            end
        else
            elementName = ranked[1].name
            table.insert(notes, `{ranked[1].name} and {ranked[2].name} refuse to bind — no mixture is known.`)
        end
    elseif #ranked >= 1 then
        elementName = ranked[1].name
        if #ranked >= 2 then
            table.insert(notes, `The {ranked[2].name} ({ranked[2].power}) is too weak to bind with the {ranked[1].name} ({ranked[1].power}) — it needs at least half its power.`)
        end
    end

    local AspectTransforms = {
        Hoar = {Water = "Glacier"},
    }
    for _, working in ipairs(totals.workings) do
        local transforms = AspectTransforms[working.Name]
        if transforms and elementName and transforms[elementName] then
            elementName = transforms[elementName]
            components = nil
        end
    end

    local corruption: Corruption? = nil
    if #normals > 0 and corruptName then
        if corruptPower * 2 >= ranked[1].power then
            corruption = {
                Name = corruptName,
                Power = math.floor(corruptPower * 10 + 0.5) / 10,
                Full = corruptPower >= ranked[1].power,
            }
        else
            table.insert(notes, `The {corruptName} ({corruptPower}) is too weak to touch the {elementName} ({ranked[1].power}).`)
        end
    end

    local elementSum = 0
    for _, entry in ipairs(rankedAll) do
        elementSum += entry.power
    end

    local tintSum = 0
    local topTint: string? = nil
    local topTintPower = 0
    for name, power in pairs(totals.tints) do
        tintSum += power
        if power > topTintPower or (power == topTintPower and (topTint == nil or name < topTint)) then
            topTintPower = power
            topTint = name
        end
    end

    local tintBecameElement = false
    if elementName == nil and topTint then
        elementName = topTint
        tintBecameElement = true
    end

    local direction: Vec = {
        x = totals.kinetic.x + totals.flow.x,
        y = totals.kinetic.y + totals.flow.y,
    }

    local kineticRatio = if totals.arrowMag > 0 then Magnitude(totals.kinetic) / totals.arrowMag else 0
    local flowRatio = if totals.flowMag > 0 then Magnitude(totals.flow) / totals.flowMag else 0
    local drift = math.clamp(math.max(kineticRatio, flowRatio), 0, 1)
    local directional = totals.arrowMag > 0 and drift > 0.25 and Magnitude(direction) > 1e-6

    local angleDeg: number? = nil
    local compass: string? = nil
    if totals.homing then
        directional = totals.arrowMag > 0 or elementSum > 0 or tintSum > 0
    elseif directional then
        local screenDeg = math.deg(math.atan2(direction.y, direction.x))
        angleDeg = math.floor((360 - screenDeg) % 360 + 0.5) % 360
        compass = CompassOf(direction)
    end

    local strength = elementSum + totals.arrowMag + tintSum

    local ctx: Elements.Context = {
        Strength = math.floor(strength + 0.5),
        AngleDeg = angleDeg,
        Compass = compass,
        Directional = directional,
        Homing = totals.homing,
        Spread = totals.spread,
        SpreadArcDeg = math.clamp(20 + totals.spread * 15, 20, 120),
        Balance = math.clamp(1 - drift, 0, 1),
        Layers = totals.layers,
        GlyphCount = totals.glyphCount,
        Components = components,
    }

    local lines = {}
    local inert = elementName == nil and totals.arrowMag == 0 and totals.spread == 0
    if not (inert and #totals.workings > 0) then
        table.insert(lines, Elements.Get(elementName).Describe(ctx))
    end

    for _, working in ipairs(totals.workings) do
        local phrase = TargetsPhrase(working.targets) or TargetsPhrase(totals.targets)
        local object: string
        if working.element and phrase then
            object = `{string.lower(working.element)} within {phrase}`
        elseif working.element then
            object = string.lower(working.element)
        elseif phrase then
            object = phrase
        else
            object = working.Fallback
        end
        table.insert(lines, `{working.Name} {working.Verb} {object} (power {working.power}).`)
    end

    for _, form in ipairs(totals.forms) do
        local shapes = table.concat(form.parts, ", then ")
        if shapes == "" then
            shapes = "a formless mass"
        end
        local sizing = if form.scale > 1 then ` ({form.scale} spans)` else ""
        local formTargets = TargetsPhrase(totals.targets)
        if formTargets then
            table.insert(lines, `It reshapes {formTargets}{sizing} — {shapes}.`)
        else
            table.insert(lines, `It takes shape{sizing} — {shapes}.`)
        end
    end

    if next(totals.targets) and #totals.workings == 0 and #totals.forms == 0 then
        table.insert(lines, `Marked: {TargetsPhrase(totals.targets)} — no working binds them.`)
    end

    if not tintBecameElement then
        local tintNames = {}
        for name in pairs(totals.tints) do
            table.insert(tintNames, name)
        end
        table.sort(tintNames)
        for _, name in ipairs(tintNames) do
            table.insert(lines, `It runs tinged with {string.lower(name)} ({totals.tints[name]}).`)
        end
    end

    if corruption then
        if corruption.Full then
            local fullVerbs = {
                Decay = "it rots what it touches",
                Ruin = "it breaks what it touches",
            }
            table.insert(lines, `It is corrupted by {string.lower(corruption.Name)} ({corruption.Power}) — {fullVerbs[corruption.Name] or "it eats at what it touches"}.`)
        else
            local mildLines = {
                Decay = `A thread of decay runs through it ({corruption.Power}) — a slow ferment, not a rot.`,
                Ruin = `A seam of ruin runs through it ({corruption.Power}) — weakening, not yet breaking.`,
            }
            table.insert(lines, mildLines[corruption.Name] or `A trace of {string.lower(corruption.Name)} runs through it ({corruption.Power}).`)
        end
    end

    if totals.curve ~= 0 then
        local turn = if totals.curve > 0 then "sunwise (clockwise)" else "widdershins (counter-clockwise)"
        local bendDeg = math.floor(math.clamp(20 * math.abs(totals.curve), 20, 160))
        table.insert(lines, `It bends {turn}, about {bendDeg}° over its flight.`)
    end
    if totals.motes > 0 then
        table.insert(lines, `It scatters into {totals.motes + 1} motes.`)
    end
    if totals.coil > 0 then
        table.insert(lines, `It coils {totals.coil} {if totals.coil == 1 then "turn" else "turns"} along its path.`)
    end
    if totals.range > 0 then
        table.insert(lines, `It lands {totals.range} {if totals.range == 1 then "span" else "spans"} out.`)
    end

    if totals.loopN > 0 then
        if totals.stopper then
            table.insert(lines, `It repeats until {totals.stopper}.`)
        else
            table.insert(lines, "It repeats endlessly.")
        end
    elseif totals.repeats > 0 then
        table.insert(lines, `It repeats ×{totals.repeats + 1}.`)
    end
    if totals.stopper and totals.loopN == 0 then
        table.insert(lines, `It runs until {totals.stopper}.`)
    end
    if totals.sustain > 0 then
        table.insert(lines, `It holds for {totals.sustain} beats.`)
    end
    if totals.delay > 0 then
        table.insert(lines, `It waits {totals.delay} beats before firing.`)
    end
    if totals.trigger then
        table.insert(lines, 1, `Held until {totals.trigger} —`)
    end
    if totals.conditionN > 0 then
        if totals.conditionTarget then
            table.insert(lines, `It acts only while {totals.conditionTarget} holds.`)
        elseif not totals.trigger and not totals.stopper then
            table.insert(lines, "It acts only while its condition holds.")
        end
    end
    if totals.invertN % 2 == 1 then
        table.insert(lines, "Its flow is inverted.")
    end
    if totals.instability > 0 then
        table.insert(lines, "Its border is uneven — the spell is unstable.")
    end

    for _, note in ipairs(totals.ringNotes) do
        table.insert(notes, note)
    end

    return {
        Element = elementName,
        Components = components,
        Strength = ctx.Strength,
        Spread = totals.spread,
        AngleDeg = angleDeg,
        Compass = compass,
        Directional = directional,
        Balance = ctx.Balance,
        Direction = direction,
        Description = table.concat(lines, " "),
        Notes = notes,
        Layers = totals.layers,
        Repeats = totals.repeats,
        Endless = totals.loopN > 0,
        Sustain = totals.sustain,
        Delay = totals.delay,
        Conditional = totals.conditionN > 0,
        ConditionTarget = totals.conditionTarget,
        Trigger = totals.trigger,
        Stopper = totals.stopper,
        Curve = totals.curve,
        Motes = totals.motes,
        Coil = totals.coil,
        Homing = totals.homing,
        Range = totals.range,
        Tints = totals.tints,
        Targets = totals.targets,
        Workings = totals.workings,
        Unstable = totals.instability,
        Corruption = corruption,
    }
end

local function ApplyMotion(totals: Totals, motion: string, count: number)
    if motion == "curl_cw" then
        totals.curve += count
    elseif motion == "curl_ccw" then
        totals.curve -= count
    elseif motion == "motes" then
        totals.motes += count
    elseif motion == "coil" then
        totals.coil += count
    elseif motion == "homing" then
        totals.homing = true
    elseif motion == "range" then
        totals.range += count
    end
end

local AspectTriggers = {
    C = "something is crafted nearby",
    D = "something is unmade nearby",
    L = "light falls upon it",
    F = "it is sought",
    K = "its likeness appears",
    M = "word is spoken nearby",
    X = "a bond is woven nearby",
    ["~"] = "something changes nearby",
    ["-"] = "cold sets in nearby",
}

local TriggerBlocks = {
    A = "it strikes something",
    R = "something comes within reach",
    V = "it is touched",
    ["&"] = "it is shaken",
    ["."] = "it is broken",
    ["("] = "it is moved",
    [")"] = "it is moved",
    ["?"] = "a spell is cast upon it",
}

local TargetLoss = {
    vessel = "the vessel is lost",
    essence = "the essence is spent",
    tether = "the tether is severed",
    self = "the self departs",
    other = "the other departs",
    place = "the place is unmade",
    offering = "the offering is taken",
}

local FormShapes = {
    A = "a peaked arch", B = "a double-bulge", C = "an open crescent", D = "a half-round",
    E = "a comb of prongs", F = "a flag of prongs", G = "a hooked crescent", H = "a bridged pair of pillars",
    I = "a straight pillar", J = "a hooked rod", K = "a braced strut", L = "a right-angle",
    M = "a ridged wall", N = "a sloped brace", O = "a closed ring", P = "a headed post",
    Q = "a tailed ring", R = "a legged loop", S = "a winding curve", T = "a crossbeam on a post",
    U = "an open trough", V = "a wedge", W = "a doubled wedge", X = "a cross",
    Y = "a fork", Z = "a zigzag",
}

local function SetSense(totals: Totals, negated: boolean, phrase: string)
    if negated then
        totals.stopper = totals.stopper or phrase
    else
        totals.trigger = totals.trigger or phrase
    end
end

local function ApplyRun(totals: Totals, letter: string, count: number, hasQuery: boolean, negated: boolean)
    local entry = Runes.Get(letter)

    if hasQuery and TriggerBlocks[letter] then
        SetSense(totals, negated, TriggerBlocks[letter])
        return
    end

    if entry.Class == "flow" then
        if entry.Flow == "repeat" then
            totals.repeats += count
        elseif entry.Flow == "loop" then
            totals.loopN += count
        elseif entry.Flow == "sustain" then
            totals.sustain += count
        elseif entry.Flow == "delay" then
            totals.delay += count
        elseif entry.Flow == "condition" then
            totals.conditionN += count
        elseif entry.Flow == "invert" then
            totals.invertN += count
        elseif entry.Flow == "surge" then
            totals.surgeN += count
        end
    elseif entry.Class == "element" and entry.Element then
        if hasQuery then
            local phrase = if entry.Element == "Time"
                then "its hour comes"
                else `{string.lower(entry.Element :: string)} is found`
            SetSense(totals, negated, phrase)
        else
            totals.elementPower[entry.Element :: string] = (totals.elementPower[entry.Element :: string] or 0) + count
        end
    elseif entry.Class == "modifier" then
        totals.spread += count
    elseif entry.Class == "motion" and entry.Motion then
        ApplyMotion(totals, entry.Motion :: string, count)
    elseif entry.Class == "target" and entry.Target then
        if hasQuery and negated then
            totals.stopper = totals.stopper or TargetLoss[entry.Target :: string] or `the {entry.Target} is lost`
        else
            totals.conditionTarget = totals.conditionTarget or ("the " .. (entry.Target :: string))
        end
    elseif entry.Class == "aspect" and hasQuery then
        SetSense(totals, negated, AspectTriggers[letter] or `the {string.lower(entry.Name)} stirs`)
    else
        table.insert(totals.ringNotes, `The {letter} rune has no flow — it idles on its ring.`)
    end
end

local function AnalyzeLayer(spell: Parser.Spell): (LayerPlan, Totals)
    local totals = NewTotals()
    totals.layers = 1

    local plan: LayerPlan = {
        glyphs = {},
        sigils = {},
        bands = {},
        targets = {},
        forms = {},
        rings = table.clone(spell.rings),
        subs = {},
        element = nil,
        spread = 0,
        description = "",
        phial = nil,
        unstable = spell.unstable,
    }

    local slotted: {GlyphPlan} = {}
    local slotsNeeded = 0
    local inlineFlow: {Parser.Run} = {}
    local phials: {[string]: Totals} = {}
    local usedPhials: {[string]: boolean} = {}

    for _, part in ipairs(spell.parts) do
        if part.kind == "spell" then
            local sub = part :: Parser.Spell
            local digit: string? = nil
            local ringHasQuery = false
            for _, run in ipairs(sub.rings) do
                if run.letter == "Q" then
                    ringHasQuery = true
                end
            end
            if not ringHasQuery then
                for _, run in ipairs(sub.rings) do
                    if string.match(run.letter, "%d") then
                        digit = run.letter
                        break
                    end
                end
            end

            local subPlan, subTotals = AnalyzeLayer(sub)
            table.insert(plan.subs, subPlan)

            if digit then
                subPlan.phial = digit
                phials[digit] = subTotals
            else
                MergeTotals(totals, subTotals)
            end
        end
    end

    local function Inject(digit: string): string?
        local phial = phials[digit]
        if not phial then
            table.insert(totals.ringNotes, `Nothing fills phial {digit} — the injection fizzles.`)
            return nil
        end
        usedPhials[digit] = true

        local ranked = RankElements(phial)
        local tintName: string? = nil
        if #ranked >= 2 and ranked[2].power * 2 >= ranked[1].power then
            tintName = Elements.MixOf(ranked[1].name, ranked[2].name)
        end
        if not tintName and #ranked > 0 then
            tintName = ranked[1].name
        end

        if tintName then
            local total = 0
            for _, entry in ipairs(ranked) do
                total += entry.power
            end
            totals.tints[tintName] = (totals.tints[tintName] or 0) + total
        end
        for name, power in pairs(phial.tints) do
            totals.tints[name] = (totals.tints[name] or 0) + power
        end
        for _, working in ipairs(phial.workings) do
            table.insert(totals.workings, working)
        end
        for name, count in pairs(phial.targets) do
            totals.targets[name] = (totals.targets[name] or 0) + count
        end
        totals.curve += phial.curve
        totals.motes += phial.motes
        totals.coil += phial.coil
        totals.instability += phial.instability

        return tintName
    end

    for _, part in ipairs(spell.parts) do
        if part.kind == "spell" then
            continue
        end

        local group = part :: Parser.Group
        local base = group.runs[1]
        local entry = Runes.Get(base.letter)

        if entry.Class == "form" then
            local parts = {}
            local scale = 0
            for _, run in ipairs(group.runs) do
                if run.letter == "$" then
                    scale += run.count
                else
                    local shape = FormShapes[run.letter] or string.lower(Runes.Get(run.letter).Name)
                    table.insert(parts, if run.count > 1 then `{shape} ×{run.count}` else shape)
                end
            end
            table.insert(totals.forms, {parts = parts, scale = scale})
            table.insert(plan.forms, {
                text = (string.gsub(group.letters, "%$", "")),
                scale = scale,
            })
            totals.glyphCount += 1
            continue
        end

        local power = 0
        local modifiers: {[string]: number} = {}
        for _, run in ipairs(group.runs) do
            if run.letter == base.letter then
                power += run.count
            else
                modifiers[run.letter] = (modifiers[run.letter] or 0) + run.count
            end
        end

        local bound: string? = nil
        local groupTargets: {[string]: number} = {}
        for letter, count in pairs(modifiers) do
            if string.match(letter, "%d") then
                local tintElement = Inject(letter)
                if tintElement and not bound then
                    bound = tintElement
                end
                continue
            end
            local modEntry = Runes.Get(letter)
            if modEntry.Class == "element" and modEntry.Element then
                if not bound then
                    bound = modEntry.Element
                end
                totals.elementPower[modEntry.Element :: string] = (totals.elementPower[modEntry.Element :: string] or 0) + count
            elseif modEntry.Class == "target" and modEntry.Target then
                groupTargets[modEntry.Target :: string] = (groupTargets[modEntry.Target :: string] or 0) + count
            elseif modEntry.Class == "motion" and modEntry.Motion then
                ApplyMotion(totals, modEntry.Motion :: string, count)
            elseif modEntry.Class == "unknown" then
                totals.unknown[letter] = true
            end
        end

        totals.glyphCount += 1

        local glyph: GlyphPlan = {
            kind = "unknown",
            letters = group.letters,
            letter = base.letter,
            power = power,
            slots = {},
            bound = bound,
            element = nil,
            target = nil,
            spread = 0,
        }

        if string.match(base.letter, "%d") then
            glyph.kind = "phial"
            local tintElement = Inject(base.letter)
            glyph.bound = tintElement
            slotsNeeded += 1
            table.insert(glyph.slots, 0)
            table.insert(slotted, glyph)
            table.insert(plan.glyphs, glyph)
        elseif entry.Class == "shape" then
            glyph.kind = "arrow"
            local coverage = if (modifiers.R or 0) > 0 then 2 else 1
            slotsNeeded += coverage
            for _ = 1, coverage do
                table.insert(glyph.slots, 0)
            end
            table.insert(slotted, glyph)
            table.insert(plan.glyphs, glyph)
        elseif entry.Class == "element" then
            glyph.kind = "sigil"
            glyph.element = entry.Element
            glyph.spread = modifiers.R or 0
            totals.elementPower[entry.Element :: string] = (totals.elementPower[entry.Element :: string] or 0) + power
            totals.spread += glyph.spread
            table.insert(plan.sigils, glyph)
        elseif entry.Class == "aspect" then
            glyph.kind = "aspect"
            local coverage = if (modifiers.R or 0) > 0 then 2 else 1
            slotsNeeded += coverage
            for _ = 1, coverage do
                table.insert(glyph.slots, 0)
            end
            table.insert(slotted, glyph)
            table.insert(plan.glyphs, glyph)

            local aspect = Aspects.Get(base.letter)
            table.insert(totals.workings, {
                Name = if aspect then aspect.Name else entry.Name,
                Verb = if aspect then aspect.Verb else "stirs",
                Fallback = if aspect then aspect.Fallback else "nothing in particular",
                power = power,
                element = bound,
                targets = groupTargets,
            })
        elseif entry.Class == "target" and entry.Target then
            glyph.kind = "target"
            glyph.target = entry.Target
            totals.targets[entry.Target :: string] = (totals.targets[entry.Target :: string] or 0) + power
            table.insert(plan.targets, glyph)
        elseif entry.Class == "flow" then
            table.insert(inlineFlow, {letter = base.letter, count = power})
        elseif entry.Class == "motion" and entry.Motion then
            glyph.kind = "motion"
            ApplyMotion(totals, entry.Motion :: string, power)
            slotsNeeded += 1
            table.insert(glyph.slots, 0)
            table.insert(slotted, glyph)
            table.insert(plan.glyphs, glyph)
        elseif entry.Class == "modifier" and base.letter == "R" then
            glyph.kind = "spreadband"
            totals.spread += power
            table.insert(plan.bands, glyph)
        else
            totals.unknown[base.letter] = true
            slotsNeeded += 1
            table.insert(glyph.slots, 0)
            table.insert(slotted, glyph)
            table.insert(plan.glyphs, glyph)
        end
    end

    local slotIndex = 0
    for _, glyph in ipairs(slotted) do
        for position = 1, #glyph.slots do
            local angle = -math.pi / 2 - (2 * math.pi * slotIndex) / math.max(slotsNeeded, 1)
            glyph.slots[position] = angle
            slotIndex += 1

            if glyph.kind == "arrow" then
                local ux = -math.cos(angle)
                local uy = -math.sin(angle)
                AddVec(totals.kinetic, ux * glyph.power, uy * glyph.power)
                totals.arrowMag += glyph.power
                if glyph.bound then
                    AddVec(totals.flow, ux * glyph.power, uy * glyph.power)
                    totals.flowMag += glyph.power
                end
            end
        end
    end

    local ringRuns: {Parser.Run} = {}
    for _, run in ipairs(spell.rings) do
        table.insert(ringRuns, run)
    end
    for _, run in ipairs(inlineFlow) do
        table.insert(ringRuns, run)
        table.insert(plan.rings, run)
    end

    local hasQuery = false
    local negatedQuery = false
    local consumedNull: {[number]: boolean} = {}
    for i, run in ipairs(ringRuns) do
        if run.letter == "Q" then
            hasQuery = true
            local previous = ringRuns[i - 1]
            if previous and previous.letter == "N" then
                negatedQuery = true
                consumedNull[i - 1] = true
            end
        end
    end

    local senseConsumed: {[number]: boolean} = {}
    if hasQuery then
        local elementIndex: number? = nil
        local elementName: string? = nil
        local selfIndex: number? = nil
        local digitValue: string? = nil

        for i, run in ipairs(ringRuns) do
            local ringEntry = Runes.Get(run.letter)
            if ringEntry.Class == "element" and ringEntry.Element and not elementName then
                elementName = ringEntry.Element
                elementIndex = i
            elseif run.letter == "S" and not selfIndex then
                selfIndex = i
            elseif string.match(run.letter, "%d") and not digitValue then
                digitValue = run.letter
            end
        end

        if elementName and selfIndex then
            SetSense(totals, negatedQuery, `it outweighs the {string.lower(elementName)}`)
            senseConsumed[elementIndex :: number] = true
            senseConsumed[selfIndex] = true
        elseif elementName and digitValue then
            SetSense(totals, negatedQuery, `{string.lower(elementName)} is {digitValue} parts in ten of the whole`)
            senseConsumed[elementIndex :: number] = true
        end
    end

    for i, run in ipairs(ringRuns) do
        if not string.match(run.letter, "%d") and not consumedNull[i] and not senseConsumed[i] then
            ApplyRun(totals, run.letter, run.count, hasQuery, negatedQuery)
        end
    end

    local corked = {}
    for digit in pairs(phials) do
        if not usedPhials[digit] then
            table.insert(corked, digit)
        end
    end
    table.sort(corked)
    for _, digit in ipairs(corked) do
        table.insert(totals.ringNotes, `Phial {digit} is corked — nothing draws on it.`)
    end

    if totals.surgeN > 0 then
        local mult = 1 + totals.surgeN
        totals.kinetic.x *= mult
        totals.kinetic.y *= mult
        totals.flow.x *= mult
        totals.flow.y *= mult
        totals.arrowMag *= mult
        totals.flowMag *= mult
        for element, power in pairs(totals.elementPower) do
            totals.elementPower[element] = power * mult
        end
    end

    if totals.invertN % 2 == 1 then
        totals.kinetic.x = -totals.kinetic.x
        totals.kinetic.y = -totals.kinetic.y
        totals.flow.x = -totals.flow.x
        totals.flow.y = -totals.flow.y
    end

    if spell.unstable then
        totals.instability += 1

        local jitter = (Rng:NextNumber() - 0.5) * math.rad(70)
        RotateVec(totals.kinetic, jitter)
        RotateVec(totals.flow, jitter)

        local elementSum = 0
        for _, power in pairs(totals.elementPower) do
            elementSum += power
        end

        local basis = math.max(totals.arrowMag, elementSum)
        if basis > 0 then
            local leak = (0.15 + Rng:NextNumber() * 0.25) * basis
            local leakAngle = Rng:NextNumber() * 2 * math.pi
            AddVec(totals.kinetic, math.cos(leakAngle) * leak, math.sin(leakAngle) * leak)
            totals.arrowMag += leak
        end

        local surge = 0.8 + Rng:NextNumber() * 0.6
        for element, power in pairs(totals.elementPower) do
            totals.elementPower[element] = math.floor(power * surge * 10 + 0.5) / 10
        end

        totals.spread += Rng:NextInteger(0, 2)
    end

    local layerEffect = BuildEffect(totals)
    plan.element = layerEffect.Element
    plan.spread = totals.spread
    plan.description = layerEffect.Description
    plan.trigger = totals.trigger

    return plan, totals
end

function module.Resolve(spell: Parser.Spell): (Effect, LayerPlan)
    local plan, totals = AnalyzeLayer(spell)
    local effect = BuildEffect(totals)

    for letter in pairs(totals.unknown) do
        table.insert(effect.Notes, `The rune {letter} is unbound — the circle ignores it (for now).`)
    end

    for _, sub in ipairs(plan.subs) do
        if sub.phial then
            table.insert(effect.Notes, `Phial {sub.phial}: {sub.description}`)
        elseif sub.trigger then
            table.insert(effect.Notes, `Payload: {sub.description}`)
        else
            table.insert(effect.Notes, `Inner circle: {sub.description}`)
        end
    end

    return effect, plan
end

return module
