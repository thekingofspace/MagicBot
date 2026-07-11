--#include[random]
local Parser = require("@src/spell/Parser")

local Rng = random.new()

export type Rgb = {r: number, g: number, b: number}

export type Wood = {
    Name: string,
    Phrase: string,
    Adjective: string,
    GlowName: string,
    Nobility: number,
    Light: Rgb,
    Mid: Rgb,
    Dark: Rgb,
    Deep: Rgb,
    Glow: Rgb,
    Signature: string,
    Cores: {string},
}

export type StaffPlan = {
    wood: string,
    handleWood: string?,
    spans: number,
    silhouette: string,
    curveSign: number,
    curveAmount: number,
    spiral: number,
    knots: number,
    taper: number,
    head: string,
    headPower: number,
    foot: string,
    vine: boolean,
    collars: number,
    wrap: number,
    knuckles: number,
    hangings: number,
    skull: number,
    bells: number,
    teeth: boolean,
    ribbons: number,
    dreamcatcher: boolean,
    gems: number,
    moss: number,
    wisps: number,
    serpent: boolean,
    keys: boolean,
    rope: boolean,
    waxed: boolean,
    mark: string?,
    inscription: string?,
    bands: number,
    groove: number,
    charms: number,
    charmWood: string?,
    core: string,
    quality: string,
    score: number,
    wild: boolean,
    seed: number,
    name: string,
    description: string,
    notes: {string},
}

export type WandPlan = {
    wood: string,
    handleWood: string?,
    spans: number,
    handleSpans: number,
    silhouette: string,
    curveSign: number,
    curveAmount: number,
    spiral: number,
    knots: number,
    taper: number,
    tip: string,
    tipPower: number,
    pommel: number,
    wrap: number,
    collar: number,
    knuckles: number,
    tassel: number,
    skull: number,
    mark: string?,
    inscription: string?,
    bands: number,
    groove: number,
    charms: number,
    charmWood: string?,
    core: string,
    quality: string,
    score: number,
    wild: boolean,
    seed: number,
    name: string,
    description: string,
    notes: {string},
}

local module = {}

module.Woods = {
    oak = {Name = "Oak", Phrase = "honest oak", Adjective = "Oaken", GlowName = "amber", Nobility = 3,
        Light = {r = 186, g = 140, b = 96}, Mid = {r = 138, g = 98, b = 60},
        Dark = {r = 92, g = 62, b = 36}, Deep = {r = 50, g = 32, b = 18},
        Glow = {r = 255, g = 196, b = 120},
        Signature = "a knot of century oak-heart",
        Cores = {"a knot of century oak-heart", "an acorn that refused to fall", "a nail drawn from an honest door"}},
    cherry = {Name = "Cherrywood", Phrase = "orchard cherrywood", Adjective = "Cherrywood", GlowName = "rose", Nobility = 4,
        Light = {r = 198, g = 112, b = 86}, Mid = {r = 156, g = 74, b = 56},
        Dark = {r = 104, g = 44, b = 34}, Deep = {r = 58, g = 24, b = 18},
        Glow = {r = 255, g = 146, b = 152},
        Signature = "a drop of orchard amber",
        Cores = {"a drop of orchard amber", "the last petal of a late frost", "a curl of blossom-smoke"}},
    willow = {Name = "Willow", Phrase = "pale willow", Adjective = "Willow", GlowName = "moon-pale", Nobility = 3,
        Light = {r = 232, g = 220, b = 196}, Mid = {r = 200, g = 184, b = 156},
        Dark = {r = 150, g = 134, b = 108}, Deep = {r = 96, g = 84, b = 64},
        Glow = {r = 226, g = 240, b = 255},
        Signature = "a willow-wisp caught at dusk",
        Cores = {"a willow-wisp caught at dusk", "a ribbon of riverlight", "the sigh of a very patient tree"}},
    goldenwood = {Name = "Goldenwood", Phrase = "true goldenwood", Adjective = "Goldenwood", GlowName = "gilded", Nobility = 8,
        Light = {r = 252, g = 216, b = 122}, Mid = {r = 214, g = 168, b = 72},
        Dark = {r = 150, g = 110, b = 42}, Deep = {r = 88, g = 62, b = 22},
        Glow = {r = 255, g = 226, b = 120},
        Signature = "a leaf of beaten gold",
        Cores = {"a leaf of beaten gold", "a promise, notarized", "the interest on a dragon's hoard"}},
    ebonwood = {Name = "Ebon void-wood", Phrase = "ebon void-wood", Adjective = "Ebonwood", GlowName = "violet", Nobility = 9,
        Light = {r = 98, g = 82, b = 128}, Mid = {r = 56, g = 44, b = 78},
        Dark = {r = 32, g = 24, b = 48}, Deep = {r = 14, g = 10, b = 24},
        Glow = {r = 182, g = 122, b = 255},
        Signature = "a sliver of the starless void",
        Cores = {"a sliver of the starless void", "one bee from the swarm between worlds", "a breath held since the first dark"}},
    petrified = {Name = "Petrified wood", Phrase = "petrified elderwood", Adjective = "Petrified", GlowName = "jade", Nobility = 7,
        Light = {r = 184, g = 178, b = 168}, Mid = {r = 136, g = 130, b = 124},
        Dark = {r = 92, g = 88, b = 84}, Deep = {r = 50, g = 48, b = 46},
        Glow = {r = 172, g = 224, b = 192},
        Signature = "dust of the first forest",
        Cores = {"dust of the first forest", "a fern pressed by ten thousand years", "the patience of stone"}},
    ash = {Name = "Lightning-struck ash", Phrase = "lightning-struck ash", Adjective = "Lightning-Ash", GlowName = "storm-blue", Nobility = 6,
        Light = {r = 208, g = 206, b = 200}, Mid = {r = 160, g = 158, b = 152},
        Dark = {r = 104, g = 102, b = 98}, Deep = {r = 56, g = 54, b = 52},
        Glow = {r = 160, g = 212, b = 255},
        Signature = "a core of storm-glass",
        Cores = {"a core of storm-glass", "the echo of the strike that split it", "a thundercount, still counting"}},
    dreamwood = {Name = "Dreamwood", Phrase = "dreamwood", Adjective = "Dreamwood", GlowName = "opaline", Nobility = 7,
        Light = {r = 238, g = 226, b = 240}, Mid = {r = 198, g = 182, b = 208},
        Dark = {r = 142, g = 126, b = 156}, Deep = {r = 84, g = 72, b = 98},
        Glow = {r = 232, g = 182, b = 255},
        Signature = "a strand of a sleeper's dream",
        Cores = {"a strand of a sleeper's dream", "moonlight, folded eight times", "the name you almost remember on waking"}},
    greenwood = {Name = "Living greenwood", Phrase = "living greenwood", Adjective = "Greenwood", GlowName = "leaf-green", Nobility = 5,
        Light = {r = 150, g = 180, b = 110}, Mid = {r = 104, g = 138, b = 72},
        Dark = {r = 66, g = 94, b = 46}, Deep = {r = 34, g = 50, b = 24},
        Glow = {r = 152, g = 236, b = 130},
        Signature = "a living seed, still counting springs",
        Cores = {"a living seed, still counting springs", "the first birdsong of an unwritten year", "sap that refuses to slow"}},
    blightwood = {Name = "Blighted wood", Phrase = "blighted wood", Adjective = "Blighted", GlowName = "sickly", Nobility = 1,
        Light = {r = 150, g = 148, b = 110}, Mid = {r = 108, g = 106, b = 76},
        Dark = {r = 70, g = 68, b = 48}, Deep = {r = 36, g = 34, b = 24},
        Glow = {r = 172, g = 210, b = 92},
        Signature = "something that weeps in the dark",
        Cores = {"something that weeps in the dark", "a tooth from the orchard's bad year", "the silence where the birds were"}},
    pine = {Name = "Plain pine", Phrase = "plain pine", Adjective = "Pine", GlowName = "hearth-warm", Nobility = 2,
        Light = {r = 222, g = 196, b = 150}, Mid = {r = 180, g = 152, b = 108},
        Dark = {r = 126, g = 104, b = 70}, Deep = {r = 70, g = 56, b = 36},
        Glow = {r = 240, g = 224, b = 184},
        Signature = "a pine knot, nothing fancy",
        Cores = {"a pine knot, nothing fancy", "honest pitch and good intentions", "a splinter of the workbench itself"}},
} :: {[string]: Wood}

local WoodRunes = {
    G = "oak",
    B = "cherry",
    W = "willow",
    ["!"] = "goldenwood",
    ["*"] = "ebonwood",
    [":"] = "petrified",
    ["^"] = "ash",
    J = "greenwood",
    ["%"] = "blightwood",
}

module.TipNames = {
    orb = "Glass orb",
    crystal = "Crystal point",
    fork = "Forked twin-tip",
    crescent = "Crescent",
    gem = "Dream-gem",
    seal = "Sealed flat",
    point = "Tapered point",
    bare = "Bare wood",
}

local TipNouns = {
    orb = "Orb-",
    crystal = "Crystal-",
    crescent = "Crescent-",
    gem = "Gem-",
    fork = "Forked ",
}

local Showpiece = {orb = true, crystal = true, fork = true, crescent = true, gem = true}

module.GlowWords = {"lit faintly", "lit steady", "burning bright", "blazing", "blazing fit to read by"}

module.SpanWords = {
    "a thumb-stub", "short work", "the maker's standard", "long", "long and sure",
    "a rod", "a rod", "staff-length", "staff-length", "a full staff",
}

local NumberWords = {"one", "two", "three", "four", "five", "six", "seven", "eight", "nine", "ten", "eleven", "twelve"}

local Verdicts = {
    twig = "kindling. It may yet surprise.",
    apprentice = "an honest first effort — it will cast.",
    journeyman = "sound work. It will serve a lifetime.",
    master = "master's work — wands like this choose their owners.",
    heirloom = "an heirloom. Bury it with someone worthy.",
}

local WildCores = {
    "a hair of something that should not have been caught",
    "a spark with no fire to belong to",
    "a whisker plucked from a sleeping omen",
    "the last word of an argument between storms",
    "a feather that fell upward",
}

module.HeadNames = {
    crystal = "Crystal in a claw cradle",
    orb = "Floating orb between prongs",
    lantern = "Lantern cage",
    fork = "Forked crown",
    crescent = "Crescent moon holder",
    knotgem = "Gnarled knot, gem-set",
    antler = "Antler crown",
    bare = "Bare crown",
}

module.StaffSpanWords = {
    [8] = "shoulder-high",
    [9] = "caster-height",
    [10] = "a head above its bearer",
    [11] = "gate-tall",
    [12] = "gate-tall, a door's argument",
}

module.FootNames = {
    ferrule = "Iron ferrule",
    spike = "Ground iron spike",
    worn = "Worn heel",
}

local HeadRunes = {
    A = "crystal",
    O = "orb",
    L = "lantern",
    Y = "fork",
    C = "crescent",
    D = "antler",
}

local HeadNouns = {
    crystal = "Crystal-",
    orb = "Orb-",
    lantern = "Lantern-",
    crescent = "Crescent-",
    knotgem = "Gemknot-",
    fork = "Forked ",
    antler = "Antlered ",
}

local StaffVerdicts = {
    twig = "a walking stick with ambitions.",
    apprentice = "an honest lean — it will hold a road.",
    journeyman = "sound timber. Mountains respect it.",
    master = "master's work — it will outwalk its bearer.",
    heirloom = "an heirloom. Towers are built around such staves.",
}

local function HashSeed(text: string): number
    local hash = 5381
    for index = 1, #text do
        hash = (hash * 33 + string.byte(text, index)) % 2147483647
    end
    return math.max(hash, 1)
end

local function BuildRuns(letters: string): {Parser.Run}
    local runs: {Parser.Run} = {}
    for index = 1, #letters do
        local letter = string.sub(letters, index, index)
        local last = runs[#runs]
        if last and last.letter == letter then
            last.count += 1
        else
            table.insert(runs, {letter = letter, count = 1})
        end
    end
    return runs
end

type Entry = {letter: string, count: number, index: number}

type WalkState = {
    entries: {Entry},
    inscription: string,
    charms: number,
    charmWoodCount: {[string]: number},
    wild: boolean,
    nextIndex: number,
}

local function AddRun(state: WalkState, run: Parser.Run, inCharm: boolean)
    state.nextIndex += 1
    table.insert(state.entries, {letter = run.letter, count = run.count, index = state.nextIndex})
    if inCharm and WoodRunes[run.letter] then
        local key = WoodRunes[run.letter]
        state.charmWoodCount[key] = (state.charmWoodCount[key] or 0) + run.count
    end
end

local function Walk(spell: Parser.Spell, state: WalkState, inCharm: boolean)
    if spell.unstable then
        state.wild = true
    end
    for _, run in ipairs(spell.rings) do
        AddRun(state, run, inCharm)
    end
    for _, part in ipairs(spell.parts) do
        if part.kind == "group" then
            local letters = (part :: Parser.Group).letters
            local dollar = string.find(letters, "$", 1, true)
            if dollar then
                local pre = string.sub(letters, 1, dollar - 1)
                local post = string.gsub(string.sub(letters, dollar + 1), "[^%w]", "")
                state.inscription ..= post
                for _, run in ipairs(BuildRuns(pre)) do
                    AddRun(state, run, inCharm)
                end
            else
                for _, run in ipairs((part :: Parser.Group).runs) do
                    AddRun(state, run, inCharm)
                end
            end
        else
            state.charms += 1
            Walk(part :: Parser.Spell, state, true)
        end
    end
end

function module.Resolve(spell: Parser.Spell): WandPlan
    local state: WalkState = {
        entries = {},
        inscription = "",
        charms = 0,
        charmWoodCount = {},
        wild = false,
        nextIndex = 0,
    }
    Walk(spell, state, false)

    local notes: {string} = {}
    local seedBase = HashSeed(string.upper(spell.raw))

    local woodCount: {[string]: number} = {}
    local woodFirst: {[string]: number} = {}
    local tipCount: {[string]: number} = {}
    local tipFirst: {[string]: number} = {}
    local formCount: {[string]: number} = {}
    local formFirst: {[string]: number} = {}
    local oFirstCount = 0
    local oExtra = 0
    local apostrophes = 0
    local apostropheFirst = math.huge
    local parenNet = 0
    local parenTotal = 0
    local parenFirst = math.huge
    local spans = 0
    local handleSpans = 0
    local spiral = 0
    local knots = 0
    local taper = 0
    local vCount = 0
    local wrap = 0
    local collar = 0
    local knuckles = 0
    local tassel = 0
    local skull = 0
    local bands = 0
    local groove = 0
    local mark = ""
    local unknown: {[string]: boolean} = {}

    local function Tally(counts, firsts, key, entry)
        counts[key] = (counts[key] or 0) + entry.count
        if not firsts[key] then
            firsts[key] = entry.index
        end
    end

    for _, entry in ipairs(state.entries) do
        local letter = entry.letter
        if WoodRunes[letter] then
            Tally(woodCount, woodFirst, WoodRunes[letter], entry)
        elseif letter == "'" then
            apostrophes += entry.count
            apostropheFirst = math.min(apostropheFirst, entry.index)
        elseif letter == "A" or letter == "Y" or letter == "C" then
            local key = if letter == "A" then "crystal" elseif letter == "Y" then "fork" else "crescent"
            Tally(tipCount, tipFirst, key, entry)
        elseif letter == "O" then
            if oFirstCount == 0 then
                oFirstCount = entry.count
                Tally(tipCount, tipFirst, "orb", entry)
            else
                oExtra += entry.count
            end
        elseif letter == "V" then
            vCount += entry.count
        elseif letter == "I" then
            spans += entry.count
        elseif letter == "T" then
            handleSpans += entry.count
        elseif letter == "S" or letter == "Z" or letter == "=" then
            local key = if letter == "S" then "serpent" elseif letter == "Z" then "zigzag" else "straight"
            Tally(formCount, formFirst, key, entry)
        elseif letter == ")" then
            parenNet += entry.count
            parenTotal += entry.count
            parenFirst = math.min(parenFirst, entry.index)
        elseif letter == "(" then
            parenNet -= entry.count
            parenTotal += entry.count
            parenFirst = math.min(parenFirst, entry.index)
        elseif letter == "&" then
            spiral += entry.count
        elseif letter == "." then
            knots += entry.count
        elseif letter == "R" then
            taper += entry.count
        elseif letter == "X" then
            wrap += entry.count
        elseif letter == "H" then
            collar += entry.count
        elseif letter == "K" then
            knuckles += entry.count
        elseif letter == "F" then
            tassel += entry.count
        elseif letter == "N" then
            skull += entry.count
        elseif letter == "~" then
            bands += entry.count
        elseif letter == "U" then
            groove += entry.count
        elseif string.match(letter, "%d") then
            mark ..= string.rep(letter, entry.count)
        else
            unknown[letter] = true
        end
    end

    if apostrophes >= 2 then
        woodCount.dreamwood = (woodCount.dreamwood or 0) + apostrophes
        if not woodFirst.dreamwood then
            woodFirst.dreamwood = apostropheFirst
        end
    end

    local ranked: {{key: string, count: number}} = {}
    for key, count in pairs(woodCount) do
        table.insert(ranked, {key = key, count = count})
    end
    table.sort(ranked, function(a, b)
        if a.count ~= b.count then
            return a.count > b.count
        end
        if module.Woods[a.key].Nobility ~= module.Woods[b.key].Nobility then
            return module.Woods[a.key].Nobility > module.Woods[b.key].Nobility
        end
        return woodFirst[a.key] < woodFirst[b.key]
    end)

    local wood = "pine"
    local handleWood: string? = nil
    if #ranked > 0 then
        wood = ranked[1].key
        if #ranked > 1 then
            handleWood = ranked[2].key
        end
    else
        table.insert(notes, "No wood was named — the maker cuts honest pine.")
    end

    if apostrophes == 1 then
        tipCount.gem = 1
        tipFirst.gem = apostropheFirst
    end

    local tip = "bare"
    local tipPower = 0
    local bestTip = 0
    local bestTipFirst = math.huge
    for key, count in pairs(tipCount) do
        if count > bestTip or (count == bestTip and tipFirst[key] < bestTipFirst) then
            tip = key
            bestTip = count
            bestTipFirst = tipFirst[key]
        end
    end
    if bestTip > 0 then
        tipPower = math.clamp(bestTip, 1, 5)
    elseif vCount > 0 then
        tip = "point"
        tipPower = 1
    elseif handleSpans > 0 then
        tip = "seal"
        tipPower = 1
    end

    local pommel = oExtra
    if tipCount.orb and tip ~= "orb" then
        pommel += oFirstCount
        table.insert(notes, "The orb lost the tip to a bolder rune — it slides down to seat as a pommel.")
    end
    pommel = math.min(pommel, 4)

    if spans == 0 then
        spans = 3
    end
    if spans > 10 then
        table.insert(notes, "No wand wants to be a fencepost — the lathe stops at ten spans.")
        spans = 10
    end
    if handleSpans > 4 then
        table.insert(notes, "Four spans of grip is plenty for any two hands.")
        handleSpans = 4
    end
    if handleSpans == 0 and (wrap > 0 or knuckles > 0 or collar > 0 or skull > 0 or tassel > 0 or pommel > 0 or #mark > 0) then
        handleSpans = 1
        table.insert(notes, "Grip-work wants a grip — the maker allows one span.")
    end

    local silhouette = "natural"
    local curveSign = if parenNet >= 0 then 1 else -1
    local curveAmount = math.abs(parenNet)
    local bestForm = 0
    local bestFormFirst = math.huge
    for key, count in pairs(formCount) do
        if count > bestForm or (count == bestForm and formFirst[key] < bestFormFirst) then
            silhouette = key
            bestForm = count
            bestFormFirst = formFirst[key]
        end
    end
    if curveAmount > bestForm or (curveAmount == bestForm and curveAmount > 0 and parenFirst < bestFormFirst) then
        silhouette = "curve"
        bestForm = curveAmount
    end
    if bestForm == 0 then
        silhouette = "natural"
    end
    if parenTotal > 0 and parenNet == 0 then
        table.insert(notes, "The sweeps cancel — the shaft stays true.")
    end
    local formPower = math.clamp(bestForm, 1, 5)

    if knots > 7 then
        table.insert(notes, "Seven knots and the wood is more fist than finger.")
        knots = 7
    end
    if bands > 7 then
        table.insert(notes, "Seven gilt bands and it is jewelry, not a wand.")
        bands = 7
    end
    spiral = math.min(spiral, 5)
    taper = math.min(taper, 4)
    collar = math.min(collar, 2)

    if #mark > 4 then
        mark = string.sub(mark, 1, 4)
        table.insert(notes, "The brand iron holds but four figures.")
    end

    local inscription = state.inscription
    if #inscription > 12 then
        inscription = string.sub(inscription, 1, 12)
        table.insert(notes, "The grain holds twelve letters — the rest scatter as smoke.")
    end

    local charms = state.charms
    if charms > 3 then
        table.insert(notes, "Three charms will orbit; more just argue.")
        charms = 3
    end
    local charmWood: string? = nil
    local bestCharm = 0
    for key, count in pairs(state.charmWoodCount) do
        if count > bestCharm or (count == bestCharm and module.Woods[key].Nobility > module.Woods[charmWood or key].Nobility) then
            charmWood = key
            bestCharm = count
        end
    end

    local unknownLetters = {}
    for letter in pairs(unknown) do
        table.insert(unknownLetters, letter)
    end
    table.sort(unknownLetters)
    for _, letter in ipairs(unknownLetters) do
        table.insert(notes, `The {letter} rune means nothing to the wandmaker — it is planed away.`)
    end

    local wild = state.wild
    local woodEntry = module.Woods[wood]

    local core: string
    if wild then
        core = WildCores[Rng:NextInteger(1, #WildCores)]
    else
        local rival: string? = nil
        local rivalCount = 0
        for index = 2, #ranked do
            local candidate = ranked[index]
            if candidate.count >= 3 and candidate.count > rivalCount then
                rival = candidate.key
                rivalCount = candidate.count
            end
        end
        if rival then
            core = module.Woods[rival :: string].Signature
        else
            core = woodEntry.Cores[seedBase % #woodEntry.Cores + 1]
        end
    end

    local ornamentCount = 0
    for _, present in ipairs({bands > 0, #inscription > 0, charms > 0, groove > 0, wrap > 0, knuckles > 0, collar > 0, skull > 0, tassel > 0, #mark > 0}) do
        if present then
            ornamentCount += 1
        end
    end
    local ornamentScore = 0
    if ornamentCount >= 6 then
        table.insert(notes, "So much finery — the maker mutters about gaudy work.")
    elseif ornamentCount >= 4 then
        ornamentScore = 1
    elseif ornamentCount >= 1 then
        ornamentScore = 2
    end

    local proportion = 1
    if handleSpans > 0 then
        local ratio = spans / handleSpans
        if ratio >= 2 and ratio <= 5 then
            proportion = 2
        elseif ratio >= 1 and ratio <= 7 then
            proportion = 1
        else
            proportion = 0
        end
    end

    local tipScore = 0
    if Showpiece[tip] then
        tipScore = 2
    elseif tip == "point" or tip == "seal" then
        tipScore = 1
    end

    local score = woodEntry.Nobility + tipScore + proportion + ornamentScore
    if wood == "blightwood" then
        score -= 3
    end
    if handleWood == "blightwood" then
        score -= 1
    end

    local quality
    if score < 4 then
        quality = "twig"
    elseif score < 7 then
        quality = "apprentice"
    elseif score < 10 then
        quality = "journeyman"
    elseif score < 13 then
        quality = "master"
    else
        quality = "heirloom"
    end

    local nameParts = {}
    if wild then
        table.insert(nameParts, "Wild")
    end
    if quality == "master" then
        table.insert(nameParts, "Master's")
    elseif quality == "heirloom" then
        table.insert(nameParts, "Heirloom")
    end
    table.insert(nameParts, woodEntry.Adjective)
    local noun = if quality == "twig" then "Twig" elseif spans >= 8 then "Staff" else "Wand"
    if quality ~= "twig" then
        if Showpiece[tip] then
            local prefix = TipNouns[tip]
            if string.sub(prefix, -1) == "-" then
                noun = prefix .. noun
            else
                table.insert(nameParts, (string.gsub(prefix, "%s+$", "")))
            end
        elseif silhouette == "zigzag" then
            table.insert(nameParts, "Zigzag")
        elseif silhouette == "serpent" then
            table.insert(nameParts, "Serpentine")
        elseif spiral > 0 then
            table.insert(nameParts, "Spiraled")
        elseif knots > 0 then
            table.insert(nameParts, "Gnarled")
        elseif silhouette == "curve" then
            table.insert(nameParts, "Bowed")
        end
    end
    table.insert(nameParts, noun)
    local name = table.concat(nameParts, " ")

    local lines = {}
    local spanWord = NumberWords[spans] or tostring(spans)
    table.insert(lines, `A wand of {woodEntry.Phrase}, {spanWord} {if spans == 1 then "span" else "spans"} heel to tip — {module.SpanWords[spans]}.`)

    if handleWood then
        table.insert(lines, `The handle is cut of {module.Woods[handleWood :: string].Phrase} — two-tone work.`)
    end

    if silhouette == "straight" then
        table.insert(lines, "The shaft is lathe-turned dead straight — you could sight a star along it.")
    elseif silhouette == "curve" then
        table.insert(lines, `The shaft sweeps in one long {if curveSign > 0 then "sunwise" else "widdershins"} curve.`)
    elseif silhouette == "serpent" then
        table.insert(lines, "The shaft runs serpentine, wave upon wave.")
    elseif silhouette == "zigzag" then
        table.insert(lines, "The shaft breaks and breaks again — a zigzag of caught lightning.")
    else
        table.insert(lines, "The shaft keeps the gentle bow the branch was born with.")
    end

    if spiral > 0 then
        table.insert(lines, "A helical carving winds it heel to tip.")
    end
    if knots > 0 then
        table.insert(lines, `{string.upper(string.sub(NumberWords[knots], 1, 1))}{string.sub(NumberWords[knots], 2)} gnarled {if knots == 1 then "knot rides" else "knots ride"} the grain.`)
    end
    if taper > 0 then
        table.insert(lines, "It tapers to a point a duelist would envy.")
    end

    local glowWord = module.GlowWords[math.clamp(tipPower, 1, 5)]
    if tip == "orb" then
        table.insert(lines, `A glass orb rides the tip, {glowWord} with {woodEntry.GlowName} light.`)
    elseif tip == "crystal" then
        table.insert(lines, `A faceted crystal crowns it, {glowWord} with {woodEntry.GlowName} light.`)
    elseif tip == "fork" then
        table.insert(lines, "The tip forks twin — two points that never quite agree.")
    elseif tip == "crescent" then
        table.insert(lines, `A {woodEntry.GlowName}-lit crescent horns the tip.`)
    elseif tip == "gem" then
        table.insert(lines, "A single drop of dream hardened at the tip into a small gem.")
    elseif tip == "seal" then
        table.insert(lines, "The tip is sealed flat — all restraint.")
    elseif tip == "point" then
        table.insert(lines, "The tip is a plain tapered point, polished past pride.")
    else
        table.insert(lines, "The tip is left bare wood, the way the first wands were.")
    end

    table.insert(lines, `At its heart: {core}.`)

    if handleSpans > 0 then
        local grip = `The grip runs {NumberWords[handleSpans]} {if handleSpans == 1 then "span" else "spans"}`
        if wrap > 0 then
            grip ..= ", cross-wrapped in leather"
        end
        if knuckles > 0 then
            grip ..= ", carved for the knuckles"
        end
        table.insert(lines, grip .. ".")
    end
    if collar > 0 then
        table.insert(lines, "A gilt collar guards the joint.")
    end
    if pommel > 0 then
        table.insert(lines, "A knob of the same wood pommels the heel.")
    end
    if skull > 0 then
        table.insert(lines, "A small skull is carved at the heel — a memento.")
    end
    if tassel > 0 then
        table.insert(lines, "A charm-cord tassel swings from the butt.")
    end
    if #mark > 0 then
        table.insert(lines, `The maker's mark — {mark} — is burned beside the grip.`)
    end

    if bands > 0 then
        table.insert(lines, `{string.upper(string.sub(NumberWords[bands], 1, 1))}{string.sub(NumberWords[bands], 2)} gilt {if bands == 1 then "band rings" else "bands ring"} the shaft.`)
    end
    if #inscription > 0 then
        table.insert(lines, `An inscription is burned down the grain: "{inscription}".`)
    end
    if charms > 0 then
        table.insert(lines, `{if charms == 1 then "A charm is bound above the tip — a mote that will not stop orbiting" else `Charms are bound above the tip — {NumberWords[charms]} motes that will not stop orbiting`}.`)
    end
    if groove > 0 then
        table.insert(lines, "A runic groove channels the shaft, faintly alight.")
    end

    if wild then
        table.insert(lines, "It is a wild wand — crooked, sparking, deaf to instruction.")
    end

    table.insert(lines, `The maker's verdict: {Verdicts[quality]}`)

    local seed = if wild then Rng:NextInteger(1, 2147483646) else seedBase

    return {
        wood = wood,
        handleWood = handleWood,
        spans = spans,
        handleSpans = handleSpans,
        silhouette = silhouette,
        curveSign = curveSign,
        curveAmount = math.min(curveAmount, 5),
        spiral = spiral,
        knots = knots,
        taper = taper,
        tip = tip,
        tipPower = tipPower,
        pommel = pommel,
        wrap = wrap,
        collar = collar,
        knuckles = knuckles,
        tassel = tassel,
        skull = skull,
        mark = if #mark > 0 then mark else nil,
        inscription = if #inscription > 0 then inscription else nil,
        bands = bands,
        groove = groove,
        charms = charms,
        charmWood = charmWood,
        core = core,
        quality = quality,
        score = score,
        wild = wild,
        seed = seed,
        name = name,
        description = table.concat(lines, " "),
        notes = notes,
    }
end

function module.ResolveStaff(spell: Parser.Spell): StaffPlan
    local state: WalkState = {
        entries = {},
        inscription = "",
        charms = 0,
        charmWoodCount = {},
        wild = false,
        nextIndex = 0,
    }
    Walk(spell, state, false)

    local notes: {string} = {}
    local seedBase = HashSeed("STAFF\0" .. string.upper(spell.raw))

    local woodCount: {[string]: number} = {}
    local woodFirst: {[string]: number} = {}
    local headCount: {[string]: number} = {}
    local headFirst: {[string]: number} = {}
    local formCount: {[string]: number} = {}
    local formFirst: {[string]: number} = {}
    local apostrophes = 0
    local apostropheFirst = math.huge
    local parenNet = 0
    local parenTotal = 0
    local parenFirst = math.huge
    local heightRunes = 0
    local spikeCount = 0
    local spikeFirst = math.huge
    local ferruleCount = 0
    local ferruleFirst = math.huge
    local spiral = 0
    local knots = 0
    local taper = 0
    local wrap = 0
    local collars = 0
    local knuckles = 0
    local hangings = 0
    local skull = 0
    local bands = 0
    local groove = 0
    local vineRunes = 0
    local bells = 0
    local teethRunes = 0
    local ribbons = 0
    local webRunes = 0
    local gems = 0
    local moss = 0
    local wisps = 0
    local serpentRunes = 0
    local keyRunes = 0
    local ropeRunes = 0
    local mark = ""
    local unknown: {[string]: boolean} = {}

    local function Tally(counts, firsts, key, entry)
        counts[key] = (counts[key] or 0) + entry.count
        if not firsts[key] then
            firsts[key] = entry.index
        end
    end

    for _, entry in ipairs(state.entries) do
        local letter = entry.letter
        if letter == "J" then
            Tally(woodCount, woodFirst, "greenwood", entry)
            vineRunes += entry.count
        elseif WoodRunes[letter] then
            Tally(woodCount, woodFirst, WoodRunes[letter], entry)
        elseif letter == "'" then
            apostrophes += entry.count
            apostropheFirst = math.min(apostropheFirst, entry.index)
        elseif HeadRunes[letter] then
            Tally(headCount, headFirst, HeadRunes[letter], entry)
        elseif letter == "V" then
            spikeCount += entry.count
            spikeFirst = math.min(spikeFirst, entry.index)
        elseif letter == "T" then
            ferruleCount += entry.count
            ferruleFirst = math.min(ferruleFirst, entry.index)
        elseif letter == "I" then
            heightRunes += entry.count
        elseif letter == "S" or letter == "Z" or letter == "=" then
            local key = if letter == "S" then "serpent" elseif letter == "Z" then "zigzag" else "straight"
            Tally(formCount, formFirst, key, entry)
        elseif letter == ")" then
            parenNet += entry.count
            parenTotal += entry.count
            parenFirst = math.min(parenFirst, entry.index)
        elseif letter == "(" then
            parenNet -= entry.count
            parenTotal += entry.count
            parenFirst = math.min(parenFirst, entry.index)
        elseif letter == "&" then
            spiral += entry.count
        elseif letter == "." then
            knots += entry.count
        elseif letter == "R" then
            taper += entry.count
        elseif letter == "X" then
            wrap += entry.count
        elseif letter == "H" then
            collars += entry.count
        elseif letter == "K" then
            knuckles += entry.count
        elseif letter == "F" then
            hangings += entry.count
        elseif letter == "N" then
            skull += entry.count
        elseif letter == "~" then
            bands += entry.count
        elseif letter == "U" then
            groove += entry.count
        elseif letter == "+" then
            bells += entry.count
        elseif letter == ";" then
            teethRunes += entry.count
        elseif letter == "/" then
            ribbons += entry.count
        elseif letter == "#" then
            webRunes += entry.count
        elseif letter == "<" then
            gems += entry.count
        elseif letter == "M" then
            moss += entry.count
        elseif letter == "E" then
            wisps += entry.count
        elseif letter == "Q" then
            serpentRunes += entry.count
        elseif letter == "-" then
            keyRunes += entry.count
        elseif letter == "@" then
            ropeRunes += entry.count
        elseif string.match(letter, "%d") then
            mark ..= string.rep(letter, entry.count)
        else
            unknown[letter] = true
        end
    end

    if apostrophes >= 2 then
        woodCount.dreamwood = (woodCount.dreamwood or 0) + apostrophes
        if not woodFirst.dreamwood then
            woodFirst.dreamwood = apostropheFirst
        end
    end

    local ranked: {{key: string, count: number}} = {}
    for key, count in pairs(woodCount) do
        table.insert(ranked, {key = key, count = count})
    end
    table.sort(ranked, function(a, b)
        if a.count ~= b.count then
            return a.count > b.count
        end
        if module.Woods[a.key].Nobility ~= module.Woods[b.key].Nobility then
            return module.Woods[a.key].Nobility > module.Woods[b.key].Nobility
        end
        return woodFirst[a.key] < woodFirst[b.key]
    end)

    local wood = "pine"
    local handleWood: string? = nil
    if #ranked > 0 then
        wood = ranked[1].key
        if #ranked > 1 then
            handleWood = ranked[2].key
        end
    else
        table.insert(notes, "No wood was named — the maker cuts honest pine.")
    end

    local vine = vineRunes > 0 and wood ~= "greenwood"
    local teeth = teethRunes > 0
    local dreamcatcher = webRunes > 0
    local serpent = serpentRunes > 0
    local keys = keyRunes > 0
    local rope = ropeRunes > 0

    if apostrophes == 1 then
        headCount.knotgem = 1
        headFirst.knotgem = apostropheFirst
    end

    local head = "bare"
    local headPower = 0
    local bestHead = 0
    local bestHeadFirst = math.huge
    for key, count in pairs(headCount) do
        if count > bestHead or (count == bestHead and headFirst[key] < bestHeadFirst) then
            head = key
            bestHead = count
            bestHeadFirst = headFirst[key]
        end
    end
    if bestHead > 0 then
        headPower = math.clamp(bestHead, 1, 5)
    end

    local waxed = head == "lantern" and headPower >= 2

    local foot = "worn"
    if spikeCount > ferruleCount or (spikeCount == ferruleCount and spikeCount > 0 and spikeFirst < ferruleFirst) then
        foot = "spike"
    elseif ferruleCount > 0 then
        foot = "ferrule"
    end

    local spans = 9
    if heightRunes > 0 then
        spans = 8 + math.min(heightRunes, 4)
        if heightRunes > 4 then
            table.insert(notes, "Twelve spans is a door's argument — the rest fall away.")
        end
    end

    local silhouette = "natural"
    local curveSign = if parenNet >= 0 then 1 else -1
    local curveAmount = math.abs(parenNet)
    local bestForm = 0
    local bestFormFirst = math.huge
    for key, count in pairs(formCount) do
        if count > bestForm or (count == bestForm and formFirst[key] < bestFormFirst) then
            silhouette = key
            bestForm = count
            bestFormFirst = formFirst[key]
        end
    end
    if curveAmount > bestForm or (curveAmount == bestForm and curveAmount > 0 and parenFirst < bestFormFirst) then
        silhouette = "curve"
        bestForm = curveAmount
    end
    if bestForm == 0 then
        silhouette = "natural"
    end
    if parenTotal > 0 and parenNet == 0 then
        table.insert(notes, "The sweeps cancel — the shaft stays true.")
    end

    if knots > 7 then
        table.insert(notes, "Seven knots and the wood is more fist than finger.")
        knots = 7
    end
    if bands > 7 then
        table.insert(notes, "Seven gilt bands and it is jewelry, not a staff.")
        bands = 7
    end
    if collars > 4 then
        table.insert(notes, "Four collars segment any staff that means it.")
        collars = 4
    end
    if hangings > 3 then
        table.insert(notes, "Three cords will swing; more is a curtain.")
        hangings = 3
    end
    if bells > 4 then
        table.insert(notes, "Four bells; more is a carillon, and a different commission.")
        bells = 4
    end
    if ribbons > 4 then
        table.insert(notes, "Four ribbons pray plenty — the wind cannot read faster.")
        ribbons = 4
    end
    if gems > 4 then
        table.insert(notes, "Four gem clusters; past that the shaft is a mine.")
        gems = 4
    end
    moss = math.min(moss, 3)
    wisps = math.min(wisps, 4)
    spiral = math.min(spiral, 5)
    taper = math.min(taper, 4)

    if #mark > 4 then
        mark = string.sub(mark, 1, 4)
        table.insert(notes, "The brand iron holds but four figures.")
    end

    local inscription = state.inscription
    if #inscription > 12 then
        inscription = string.sub(inscription, 1, 12)
        table.insert(notes, "The grain holds twelve letters — the rest scatter as smoke.")
    end

    local charms = state.charms
    if charms > 3 then
        table.insert(notes, "Three charms will orbit; more just argue.")
        charms = 3
    end
    local charmWood: string? = nil
    local bestCharm = 0
    for key, count in pairs(state.charmWoodCount) do
        if count > bestCharm or (count == bestCharm and module.Woods[key].Nobility > module.Woods[charmWood or key].Nobility) then
            charmWood = key
            bestCharm = count
        end
    end

    local unknownLetters = {}
    for letter in pairs(unknown) do
        table.insert(unknownLetters, letter)
    end
    table.sort(unknownLetters)
    for _, letter in ipairs(unknownLetters) do
        table.insert(notes, `The {letter} rune means nothing to the staffwright — it is planed away.`)
    end

    local wild = state.wild
    local woodEntry = module.Woods[wood]

    local core: string
    if wild then
        core = WildCores[Rng:NextInteger(1, #WildCores)]
    else
        local rival: string? = nil
        local rivalCount = 0
        for index = 2, #ranked do
            local candidate = ranked[index]
            if candidate.count >= 3 and candidate.count > rivalCount then
                rival = candidate.key
                rivalCount = candidate.count
            end
        end
        if rival then
            core = module.Woods[rival :: string].Signature
        else
            core = woodEntry.Cores[seedBase % #woodEntry.Cores + 1]
        end
    end

    local ornamentCount = 0
    for _, present in ipairs({bands > 0, #inscription > 0, charms > 0, groove > 0, wrap > 0, knuckles > 0, collars > 0, skull > 0, hangings > 0, #mark > 0, vine, bells > 0, teeth, ribbons > 0, dreamcatcher, gems > 0, moss > 0, wisps > 0, serpent, keys, rope}) do
        if present then
            ornamentCount += 1
        end
    end
    local ornamentScore = 0
    if ornamentCount >= 6 then
        table.insert(notes, "So much finery — the maker mutters about gaudy work.")
    elseif ornamentCount >= 4 then
        ornamentScore = 1
    elseif ornamentCount >= 1 then
        ornamentScore = 2
    end

    local headScore = if head ~= "bare" then 2 else 0
    local balance = 0
    if head ~= "bare" and foot ~= "worn" then
        balance = 2
    elseif head ~= "bare" or foot ~= "worn" then
        balance = 1
    end

    local score = woodEntry.Nobility + headScore + balance + ornamentScore
    if wood == "blightwood" then
        score -= 3
    end
    if handleWood == "blightwood" then
        score -= 1
    end

    local quality
    if score < 4 then
        quality = "twig"
    elseif score < 7 then
        quality = "apprentice"
    elseif score < 10 then
        quality = "journeyman"
    elseif score < 13 then
        quality = "master"
    else
        quality = "heirloom"
    end

    local nameParts = {}
    if wild then
        table.insert(nameParts, "Wild")
    end
    if quality == "master" then
        table.insert(nameParts, "Master's")
    elseif quality == "heirloom" then
        table.insert(nameParts, "Heirloom")
    end
    table.insert(nameParts, woodEntry.Adjective)
    local noun = if quality == "twig" then "Pole" else "Staff"
    if quality ~= "twig" then
        if HeadNouns[head] then
            local prefix = HeadNouns[head]
            if string.sub(prefix, -1) == "-" then
                noun = prefix .. noun
            else
                table.insert(nameParts, (string.gsub(prefix, "%s+$", "")))
            end
        elseif silhouette == "zigzag" then
            table.insert(nameParts, "Crooked")
        elseif silhouette == "serpent" then
            table.insert(nameParts, "Serpentine")
        elseif spiral > 0 then
            table.insert(nameParts, "Spiraled")
        elseif knots > 0 then
            table.insert(nameParts, "Gnarled")
        elseif silhouette == "curve" then
            table.insert(nameParts, "Bowed")
        end
    end
    table.insert(nameParts, noun)
    local name = table.concat(nameParts, " ")

    local lines = {}
    local spanWord = NumberWords[spans] or tostring(spans)
    table.insert(lines, `A staff of {woodEntry.Phrase}, {spanWord} spans crown to heel — {module.StaffSpanWords[spans]}.`)

    if handleWood then
        table.insert(lines, `The crown is worked in {module.Woods[handleWood :: string].Phrase} — two-tone work.`)
    end

    if silhouette == "straight" then
        table.insert(lines, "The shaft is planed dead straight — a pilgrim's mile-eater.")
    elseif silhouette == "curve" then
        table.insert(lines, `The shaft leans in one long {if curveSign > 0 then "sunwise" else "widdershins"} bow.`)
    elseif silhouette == "serpent" then
        table.insert(lines, "The shaft sways serpentine, root to crown.")
    elseif silhouette == "zigzag" then
        table.insert(lines, "The shaft is crooked as a march uphill, and proud of it.")
    else
        table.insert(lines, "The shaft keeps the honest lean of the tree it was.")
    end

    if spiral > 0 then
        table.insert(lines, "A helical carving winds it crown to heel.")
    end
    if knots > 0 then
        table.insert(lines, `{string.upper(string.sub(NumberWords[knots], 1, 1))}{string.sub(NumberWords[knots], 2)} gnarled {if knots == 1 then "knot rides" else "knots ride"} the grain.`)
    end
    if taper > 0 then
        table.insert(lines, "It draws thin toward the crown, light in the hand.")
    end
    if vine then
        table.insert(lines, "A living vine winds the shaft, still sprouting leaves.")
    end
    if collars > 0 then
        table.insert(lines, `{string.upper(string.sub(NumberWords[collars], 1, 1))}{string.sub(NumberWords[collars], 2)} metal {if collars == 1 then "collar segments" else "collars segment"} the shaft.`)
    end

    local glowWord = module.GlowWords[math.clamp(headPower, 1, 5)]
    if head == "crystal" then
        table.insert(lines, `A raw crystal rides in a claw of twisted wood, {glowWord} with {woodEntry.GlowName} light.`)
    elseif head == "orb" then
        table.insert(lines, `An orb floats caged between prongs, never quite touching, {glowWord}.`)
    elseif head == "lantern" then
        table.insert(lines, `A lantern cage crowns it, its little fire {glowWord}.`)
    elseif head == "fork" then
        table.insert(lines, `The crown forks {if headPower >= 3 then "three ways" else "twin"} — bare prongs that catch the weather.`)
    elseif head == "crescent" then
        table.insert(lines, `A crescent moon is held at the crown, {glowWord}.`)
    elseif head == "knotgem" then
        table.insert(lines, `The crown is a gnarled knot with a gem grown into it, {glowWord}.`)
    elseif head == "antler" then
        table.insert(lines, `An antler crown spreads from the head — {woodEntry.GlowName} light snagged in the tines.`)
    else
        table.insert(lines, "The crown is left bare — a wanderer's plain top.")
    end

    table.insert(lines, `At its heart: {core}.`)

    if wrap > 0 then
        local grip = "A leather grip is wrapped where the hand falls"
        if knuckles > 0 then
            grip ..= ", carved for the fingers"
        end
        table.insert(lines, grip .. ".")
    elseif knuckles > 0 then
        table.insert(lines, "Finger-rests are carved where the hand falls.")
    end

    if skull > 0 then
        table.insert(lines, "A small skull is bound beneath the crown — a memento.")
    end
    if hangings > 0 then
        table.insert(lines, `{string.upper(string.sub(NumberWords[hangings], 1, 1))}{string.sub(NumberWords[hangings], 2)} {if hangings == 1 then "cord swings" else "cords swing"} beneath the crown — feathers and beads that remember weather.`)
    end
    if #mark > 0 then
        table.insert(lines, `The maker's mark — {mark} — is burned at the grip.`)
    end

    if bands > 0 then
        table.insert(lines, `{string.upper(string.sub(NumberWords[bands], 1, 1))}{string.sub(NumberWords[bands], 2)} gilt {if bands == 1 then "band rings" else "bands ring"} the shaft.`)
    end
    if #inscription > 0 then
        table.insert(lines, `An inscription spirals down the grain: "{inscription}".`)
    end
    if charms > 0 then
        table.insert(lines, `{if charms == 1 then "A charm is bound about the crown — a mote that will not stop orbiting" else `Charms are bound about the crown — {NumberWords[charms]} motes that will not stop orbiting`}.`)
    end
    if groove > 0 then
        table.insert(lines, "A runic groove channels the shaft, faintly alight.")
    end

    if rope then
        table.insert(lines, "A knotted rope binds a second grip, salt-stiff and sure.")
    end
    if serpent then
        table.insert(lines, "A carved serpent climbs the shaft, patient as winter.")
    end
    if gems > 0 then
        table.insert(lines, `{string.upper(string.sub(NumberWords[gems], 1, 1))}{string.sub(NumberWords[gems], 2)} gem {if gems == 1 then "cluster sprouts" else "clusters sprout"} from the grain like frost.`)
    end
    if moss > 0 then
        table.insert(lines, "Moss quilts the old wood, and tiny mushrooms keep it company.")
    end
    if bells > 0 then
        table.insert(lines, if bells == 1
            then "A bell hangs beneath the crown — it chimes when the road turns."
            else `{string.upper(string.sub(NumberWords[bells], 1, 1))}{string.sub(NumberWords[bells], 2)} bells hang beneath the crown — they chime when the road turns.`)
    end
    if teeth then
        table.insert(lines, "A string of old teeth and knuckle-bones clicks against the wood.")
    end
    if ribbons > 0 then
        table.insert(lines, if ribbons == 1
            then "A prayer ribbon is tied below the crown, still mid-sentence."
            else `{string.upper(string.sub(NumberWords[ribbons], 1, 1))}{string.sub(NumberWords[ribbons], 2)} prayer ribbons are tied below the crown, still mid-sentence.`)
    end
    if dreamcatcher then
        table.insert(lines, if head == "fork"
            then "A dreamcatcher web is strung between the prongs."
            else "A dreamcatcher hoop hangs beneath the crown, patient for nightmares.")
    end
    if wisps > 0 then
        table.insert(lines, if wisps == 1
            then "A spirit wisp drifts about it, paying no rent."
            else `{string.upper(string.sub(NumberWords[wisps], 1, 1))}{string.sub(NumberWords[wisps], 2)} spirit wisps drift about it, paying no rent.`)
    end
    if keys then
        table.insert(lines, "A ring of old keys hangs at the grip — none of them fit anything anymore.")
    end
    if waxed then
        table.insert(lines, "Old wax has wept down from the lantern and been left.")
    end

    if foot == "ferrule" then
        table.insert(lines, "The heel is shod in an iron ferrule.")
    elseif foot == "spike" then
        table.insert(lines, "The heel ends in a ground iron spike.")
    else
        table.insert(lines, "The heel is bare wood, worn round by miles.")
    end

    if wild then
        table.insert(lines, "It is a wild staff — crooked, sparking, and loyal to no road.")
    end

    table.insert(lines, `The maker's verdict: {StaffVerdicts[quality]}`)

    local seed = if wild then Rng:NextInteger(1, 2147483646) else seedBase

    return {
        wood = wood,
        handleWood = handleWood,
        spans = spans,
        silhouette = silhouette,
        curveSign = curveSign,
        curveAmount = math.min(curveAmount, 5),
        spiral = spiral,
        knots = knots,
        taper = taper,
        head = head,
        headPower = headPower,
        foot = foot,
        vine = vine,
        collars = collars,
        wrap = wrap,
        knuckles = knuckles,
        hangings = hangings,
        skull = skull,
        bells = bells,
        teeth = teeth,
        ribbons = ribbons,
        dreamcatcher = dreamcatcher,
        gems = gems,
        moss = moss,
        wisps = wisps,
        serpent = serpent,
        keys = keys,
        rope = rope,
        waxed = waxed,
        mark = if #mark > 0 then mark else nil,
        inscription = if #inscription > 0 then inscription else nil,
        bands = bands,
        groove = groove,
        charms = charms,
        charmWood = charmWood,
        core = core,
        quality = quality,
        score = score,
        wild = wild,
        seed = seed,
        name = name,
        description = table.concat(lines, " "),
        notes = notes,
    }
end

return module
