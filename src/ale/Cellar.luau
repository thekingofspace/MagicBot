--#include[random]
local Parser = require("@src/spell/Parser")
local Brews = require("@src/ale/Brews")

-- Only rowdy pours ([ ] borders) roll — everything else is deterministic.
local Rng = random.new()

local module = {}

export type Pour = {
    Title: string,
    Lines: {string},
    Notes: {string},
    Family: string?,
    FamilyName: string,
    Splash: string?,
    Vessel: string,
    VesselName: string,
    VesselLabel: string,
    Size: number,
    Scale: number,
    Proof: number,
    ProofLabel: string,
    Age: number,
    AgeLabel: string,
    Vinegar: boolean,
    Head: number,
    HeadLabel: string,
    Fill: number,
    Bubbles: number,
    Nitro: number,
    Swirls: number,
    Honeyed: boolean,
    Fruit: boolean,
    Mulled: boolean,
    Chilled: boolean,
    Quality: string,
    QualityLabel: string,
    Verdict: string,
    Rowdy: boolean,
    Tilt: number,
    Overflow: boolean,
    Toast: string?,
    ToastCrooked: boolean,
    Tavern: string?,
    Sediment: number,
    Slops: {string},
    Color: {r: number, g: number, b: number},
    HeadColor: {r: number, g: number, b: number},
    Empty: boolean,
    FoamOnly: boolean,
    Legs: boolean,
    Bite: boolean,
    Cocktail: string?,
    Method: string?,
    Salt: boolean,
    Citrus: boolean,
    Garnish: string?,
    Umbrella: boolean,
    UmbrellaBent: boolean,
    Ice: number,
    Recipe: string,
}

type Keg = {
    family: {[string]: number},
    familyOrder: {[string]: number},
    nextFamily: number,
    glass: {[string]: number},
    glassOrder: {[string]: number},
    nextGlass: number,
    kick: number,
    age: number,
    head: number,
    body: number,
    thin: number,
    bubbles: number,
    nitro: number,
    swirls: number,
    shaken: number,
    salt: number,
    honey: number,
    fruit: number,
    mull: number,
    chill: number,
    tavern: string?,
    tavernExtra: boolean,
    toast: string?,
    toastCrooked: boolean,
    toastExtra: boolean,
    slops: {[string]: number},
}

local function NewKeg(): Keg
    return {
        family = {},
        familyOrder = {},
        nextFamily = 1,
        glass = {},
        glassOrder = {},
        nextGlass = 1,
        kick = 0,
        age = 0,
        head = 0,
        body = 0,
        thin = 0,
        bubbles = 0,
        nitro = 0,
        swirls = 0,
        shaken = 0,
        salt = 0,
        honey = 0,
        fruit = 0,
        mull = 0,
        chill = 0,
        tavern = nil,
        tavernExtra = false,
        toast = nil,
        toastCrooked = false,
        toastExtra = false,
        slops = {},
    }
end

local function BlendRGB(a: {r: number, g: number, b: number}, b: {r: number, g: number, b: number}, t: number): {r: number, g: number, b: number}
    return {
        r = math.floor(a.r + (b.r - a.r) * t),
        g = math.floor(a.g + (b.g - a.g) * t),
        b = math.floor(a.b + (b.b - a.b) * t),
    }
end

local function JoinAnd(parts: {string}): string
    if #parts == 1 then
        return parts[1]
    end
    if #parts == 2 then
        return `{parts[1]} and {parts[2]}`
    end
    return `{table.concat(parts, ", ", 1, #parts - 1)}, and {parts[#parts]}`
end

local function ApplyRun(keg: Keg, run: Parser.Run)
    local letter, count = run.letter, run.count

    if string.match(letter, "%d") then
        keg.age += tonumber(letter) :: number * count
    elseif Brews.Families[letter] then
        keg.family[letter] = (keg.family[letter] or 0) + count
        if not keg.familyOrder[letter] then
            keg.familyOrder[letter] = keg.nextFamily
            keg.nextFamily += 1
        end
        if letter == "^" then
            keg.kick += count
        end
    elseif Brews.Vessels[letter] then
        keg.glass[letter] = (keg.glass[letter] or 0) + count
        if not keg.glassOrder[letter] then
            keg.glassOrder[letter] = keg.nextGlass
            keg.nextGlass += 1
        end
    elseif letter == "P" then
        keg.head += count
    elseif letter == "H" then
        keg.body += count
    elseif letter == "R" then
        keg.thin += count
    elseif letter == "." then
        keg.bubbles += count
    elseif letter == "&" then
        keg.nitro += count
    elseif letter == "(" or letter == ")" then
        keg.swirls += count
    elseif letter == "S" then
        keg.shaken += count
    elseif letter == "=" then
        keg.salt += count
    elseif letter == "~" then
        keg.honey += count
    elseif letter == "F" then
        keg.fruit += count
    elseif letter == "N" then
        keg.mull += count
    elseif letter == "-" then
        keg.chill += count
    else
        keg.slops[letter] = (keg.slops[letter] or 0) + count
    end
end

-- A $ turns the rest of its cluster into the tavern's name — those letters
-- are painted on the house's ware, not poured into the drink.
local function ProcessRuns(keg: Keg, runs: {Parser.Run})
    for index, run in ipairs(runs) do
        if run.letter == "$" then
            local text = ""
            for rest = index + 1, #runs do
                local tail = runs[rest]
                if string.match(tail.letter, "%w") then
                    text ..= string.rep(tail.letter, tail.count)
                end
            end
            if keg.tavern then
                keg.tavernExtra = true
            else
                keg.tavern = text
            end
            return
        end
        ApplyRun(keg, run)
    end
end

-- A nested border is a toast carved on the glass. Runes pressed against a
-- toast's border steep into the drink like any rim runes.
local function CollectToast(spell: Parser.Spell): (string, boolean)
    local words = {}
    local crooked = spell.unstable

    local function Walk(layer: Parser.Spell)
        if layer.unstable then
            crooked = true
        end
        for _, part in ipairs(layer.parts) do
            if part.kind == "spell" then
                Walk(part :: Parser.Spell)
            else
                local word = ""
                for _, run in ipairs((part :: Parser.Group).runs) do
                    if string.match(run.letter, "[%w']") then
                        word ..= string.rep(run.letter, run.count)
                    end
                end
                if #word > 0 then
                    table.insert(words, word)
                end
            end
        end
    end
    Walk(spell)

    return table.concat(words, " "), crooked
end

local function Accumulate(spell: Parser.Spell, keg: Keg)
    ProcessRuns(keg, spell.rings)
    for _, part in ipairs(spell.parts) do
        if part.kind == "spell" then
            local sub = part :: Parser.Spell
            ProcessRuns(keg, sub.rings)
            local text, crooked = CollectToast(sub)
            if keg.toast then
                keg.toastExtra = true
            else
                keg.toast = text
                keg.toastCrooked = crooked
            end
        else
            ProcessRuns(keg, (part :: Parser.Group).runs)
        end
    end
end

local function Rank(power: {[string]: number}, order: {[string]: number}): {{letter: string, power: number}}
    local ranked = {}
    for letter, strength in pairs(power) do
        table.insert(ranked, {letter = letter, power = strength})
    end
    table.sort(ranked, function(a, b)
        if a.power == b.power then
            return order[a.letter] < order[b.letter]
        end
        return a.power > b.power
    end)
    return ranked
end

function module.Serve(spell: Parser.Spell): Pour
    local keg = NewKeg()
    Accumulate(spell, keg)

    local lines: {string} = {}
    local notes: {string} = {}
    local rowdy = spell.unstable

    -- === The glass ===
    local rankedGlass = Rank(keg.glass, keg.glassOrder)
    local choseGlass = rankedGlass[1] ~= nil
    local vessel: Brews.Vessel = Brews.Pint
    local size = 1
    local bottleIntro: string? = nil
    if choseGlass then
        local top = rankedGlass[1]
        if top.letter == "Q" then
            local bottle = Brews.Bottles[math.min(top.power, #Brews.Bottles)]
            vessel = {Letter = "Q", Key = bottle.Key, Name = bottle.Name, Phrase = bottle.Phrase, Fits = bottle.Fits}
            bottleIntro = bottle.Intro
        else
            vessel = Brews.Vessels[top.letter]
            size = math.min(top.power, 3)
        end
    end
    local isBottle = Brews.BottleKeys[vessel.Key] == true
    if rankedGlass[2] then
        table.insert(notes, `One drink wants one glass — the {Brews.Vessels[rankedGlass[2].letter].Name} goes back on the shelf.`)
    end
    local vesselLabel = vessel.Name
    local vesselPhrase = vessel.Phrase
    if size == 2 then
        vesselLabel = `generous {vessel.Name}`
        vesselPhrase = `a generous {vessel.Name}`
    elseif size >= 3 then
        vesselLabel = `giant's {vessel.Name}`
        vesselPhrase = `a giant's {vessel.Name}`
    end

    -- === The drink ===
    local rankedFamily = Rank(keg.family, keg.familyOrder)
    local base = rankedFamily[1]
    local family = if base then Brews.Families[base.letter] else nil

    local foamOnly = family == nil and (keg.head + keg.bubbles + keg.nitro) > 0
    local empty = family == nil and not foamOnly
    local swill = family ~= nil and (family :: Brews.Family).Letter == "%"

    -- === The mixing book: shaken, stirred, or built in a cocktail glass ===
    local citrus = keg.fruit >= 2
    local mixer = rankedFamily[2]
    local mixerFamily = if mixer then Brews.Families[mixer.letter] else nil
    local mixingTrigger = keg.shaken > 0 or keg.swirls > 0 or Brews.CocktailGlasses[vessel.Key] == true
    local cocktail: Brews.Cocktail? = nil
    local houseMix = false
    if family and mixingTrigger and (mixer ~= nil or citrus or keg.bubbles > 0) then
        local baseL = (family :: Brews.Family).Letter
        local mixL = if mixer then mixer.letter else nil
        if baseL == "%" or mixL == "%" then
            if mixL ~= nil or citrus then
                cocktail = Brews.Regret
            end
        else
            for _, entry in ipairs(Brews.Cocktails) do
                local famMatch
                if entry.B then
                    famMatch = mixL ~= nil and ((baseL == entry.A and mixL == entry.B) or (baseL == entry.B and mixL == entry.A))
                else
                    famMatch = baseL == entry.A or mixL == entry.A
                end
                if famMatch
                    and (not entry.Citrus or citrus)
                    and (not entry.Salt or keg.salt > 0)
                    and (not entry.Bubbles or keg.bubbles > 0) then
                    cocktail = entry
                    break
                end
            end
            if not cocktail and mixL ~= nil then
                houseMix = true
            end
        end
    end
    local isCocktail = cocktail ~= nil or houseMix
    local regret = cocktail ~= nil and (cocktail :: Brews.Cocktail).Name == "The Regret"
    local method = if keg.shaken > 0 then "shaken" elseif keg.swirls > 0 then "stirred" else "built"

    local splash: string? = nil
    if isCocktail then
        if rankedFamily[3] then
            table.insert(notes, "The third bottle stays on the shelf — two spirits to a glass.")
        end
    elseif base and rankedFamily[2] and rankedFamily[2].power * 2 >= base.power then
        splash = rankedFamily[2].letter
        table.insert(notes, `Cut with a splash of {Brews.Families[splash :: string].Name} — the tapster's own blend.`)
        if rankedFamily[3] then
            table.insert(notes, "The rest of the blend loses itself in the pour.")
        end
    end
    if keg.shaken > 0 and not isCocktail and family then
        table.insert(notes, "Shaken over ice — the tapster humors you.")
    end

    -- === Age, proof, fill ===
    local age = keg.age
    local agesWell = if family then (family :: Brews.Family).AgesWell else false
    local vinegar = family ~= nil and age >= 10 and not agesWell and not isCocktail
    if isCocktail and age > 0 then
        table.insert(notes, "Nobody cellars a cocktail — the years slide off it.")
    end

    local proof = if family then (family :: Brews.Family).BaseProof + keg.kick * 7 else 0
    if isCocktail then
        local fam = family :: Brews.Family
        proof = math.floor(fam.BaseProof * 0.6 + (if mixerFamily then (mixerFamily :: Brews.Family).BaseProof * 0.4 else 0) + 0.5) + keg.kick * 7
    end
    if rowdy and family then
        proof = math.max(3, math.floor(proof * (0.85 + Rng:NextNumber() * 0.30) + 0.5))
    end
    proof = math.min(proof, 160)
    local legs = proof >= 45
    local bite = proof >= 70

    local fill = 0.70 + 0.07 * math.min(keg.body, 3) - 0.13 * math.min(keg.thin, 3)
    if isCocktail then
        local baseFill = if vessel.Key == "rocks" then 0.52
            elseif vessel.Key == "highball" then 0.80
            elseif vessel.Key == "coupe" or vessel.Key == "martini" then 0.90
            else 0.70
        fill = baseFill + 0.06 * math.min(keg.body, 3) - 0.10 * math.min(keg.thin, 3)
    end
    if isBottle then
        fill = 0.88
        if keg.body + keg.thin > 0 then
            table.insert(notes, "A bottle pours itself — no hand can hurry or heavy it.")
        end
    elseif rowdy then
        fill -= 0.08 + Rng:NextNumber() * 0.10
    end
    fill = math.clamp(fill, 0.30, 0.94)

    -- === Head ===
    local headScale = if family then (family :: Brews.Family).HeadScale else 1.0
    local fingers = 0
    if isCocktail then
        fingers = 0
    elseif swill then
        if keg.head > 0 then
            table.insert(notes, "Even the foam has abandoned it.")
        end
    elseif family or foamOnly then
        if headScale <= 0.15 and not foamOnly then
            if keg.head > 0 then
                table.insert(notes, `Foam wants no part of {(family :: Brews.Family).Noun} — the pour shrugs it off.`)
            end
        else
            local raw = headScale * (1 + math.min(keg.head, 4)) + keg.bubbles * 0.25 + keg.nitro * 0.5
            if foamOnly then
                raw = 2 + math.min(keg.head, 2)
            end
            fingers = math.clamp(math.floor(raw + 0.35), 0, 4)
        end
    end

    -- === Flavor ===
    local mulled = keg.mull > 0
    local chilled = keg.chill > 0
    if mulled and chilled then
        chilled = false
        table.insert(notes, "The frost gives up against a mulled cup.")
    end

    -- === Garnish ===
    local garnish: string? = nil
    local wheel = keg.fruit == 1
    local umbrella = false
    if isCocktail then
        local entryGarnish = if cocktail then (cocktail :: Brews.Cocktail).Garnish else nil
        if entryGarnish == "umbrella" then
            umbrella = true
        elseif entryGarnish == "wheel" then
            wheel = true
        elseif entryGarnish then
            garnish = entryGarnish
        elseif citrus then
            garnish = "lime"
        end
        if rowdy then
            umbrella = true
        end
    elseif citrus then
        garnish = "lime"
    end
    local umbrellaBent = umbrella and rowdy

    -- === Quality ===
    local quality = "honest"
    if isCocktail then
        if regret then
            quality = "swill"
        else
            local score = 1
            if cocktail then
                score += 1
                if (cocktail :: Brews.Cocktail).Glass == vessel.Key then
                    score += 1
                    table.insert(notes, `The {vessel.Name} is the proper glass for it — the house nods.`)
                end
            end
            if score <= 0 then
                quality = "swill"
            elseif score == 1 then
                quality = "honest"
            elseif score == 2 then
                quality = "fine"
            else
                quality = "prized"
            end
        end
    elseif swill or foamOnly then
        quality = "swill"
    elseif empty then
        quality = ""
    else
        local fam = family :: Brews.Family
        local score = 1
        if choseGlass and vessel.Fits[fam.Letter] then
            score += 1
            table.insert(notes, `The {vessel.Name} suits it — the shelf approves.`)
        end
        if age > 0 then
            if vinegar then
                score -= 1
            elseif agesWell then
                score += 1
            end
        end
        if keg.head > 0 then
            if headScale >= 0.8 then
                score += 1
            elseif headScale <= 0.15 then
                score -= 1
            end
        end
        if keg.nitro > 0 then
            if Brews.NitroFits[fam.Letter] then
                score += 1
            else
                table.insert(notes, `The nitro swirl does {fam.Noun} no favors.`)
            end
        end
        if mulled then
            if Brews.MullFits[fam.Letter] then
                score += 1
            elseif Brews.MullClash[fam.Letter] then
                score -= 1
                table.insert(notes, "Mulled lager — the tapster mutters a prayer for your soul.")
            end
        end
        if score <= 0 then
            quality = "swill"
        elseif score == 1 then
            quality = "honest"
        elseif score == 2 then
            quality = "fine"
        elseif score == 3 then
            quality = "prized"
        else
            quality = "legendary"
        end
    end

    -- === Toast and tavern ===
    local toast = keg.toast
    if toast and #toast > 18 then
        toast = string.sub(toast, 1, 18)
        table.insert(notes, `The chisel ran out of glass — only "{toast}" fits.`)
    end
    if keg.toastExtra then
        table.insert(notes, "One toast per glass — the rest are drunk, not carved.")
    end
    local tavern = keg.tavern
    if tavern then
        if #tavern > 14 then
            tavern = string.sub(tavern, 1, 14)
            table.insert(notes, `The signpainter charges by the letter — "{tavern}" is all the house paid for.`)
        elseif #tavern == 0 then
            table.insert(notes, "The tavern never got around to a name.")
            tavern = nil
        end
    end
    if keg.tavernExtra then
        table.insert(notes, "One house pours this drink — the other names wash off.")
    end

    -- === Slops ===
    local slops = {}
    local slopCount = 0
    for letter, count in pairs(keg.slops) do
        table.insert(slops, letter)
        slopCount += count
    end
    table.sort(slops)
    if #slops > 0 then
        table.insert(notes, `The tapster fishes out {table.concat(slops, ", ")} — they never belonged in a drink.`)
    end

    local sediment = (if isCocktail then 0 else math.min(math.floor(age / 2), 10)) + slopCount
        + (if swill and not isCocktail then 6 else 0) + (if regret then 4 else 0)

    -- === Color ===
    local color: {r: number, g: number, b: number}
    local headColor: {r: number, g: number, b: number}
    if isCocktail then
        local fam = family :: Brews.Family
        headColor = fam.HeadColor
        local override = if cocktail then (cocktail :: Brews.Cocktail).Color else nil
        if override then
            color = override :: {r: number, g: number, b: number}
        else
            color = if mixerFamily then BlendRGB(fam.Color, (mixerFamily :: Brews.Family).Color, 0.45) else fam.Color
            if citrus then
                color = BlendRGB(color, {r = 210, g = 226, b = 140}, 0.35)
            end
        end
    elseif family then
        local fam = family :: Brews.Family
        color = fam.Color
        headColor = fam.HeadColor
        if splash then
            color = BlendRGB(color, Brews.Families[splash :: string].Color, 0.22)
        end
        if age > 0 then
            color = BlendRGB(color, {r = 16, g = 10, b = 8}, math.min(age * 0.018, 0.38))
        end
        if vinegar then
            color = BlendRGB(color, {r = 150, g = 130, b = 60}, 0.3)
        end
    elseif foamOnly then
        color = {r = 236, g = 228, b = 205}
        headColor = {r = 244, g = 238, b = 222}
    else
        color = {r = 140, g = 150, b = 160}
        headColor = {r = 244, g = 238, b = 222}
    end

    -- === Rowdy rolls ===
    local tilt = 0
    if rowdy and not empty then
        tilt = (0.06 + Rng:NextNumber() * 0.09) * (if Rng:NextNumber() < 0.5 then -1 else 1)
    end
    local overflow = fingers >= 4 or (rowdy and fingers >= 1)

    local ice = if isCocktail and vessel.Key == "rocks" then 1
        elseif isCocktail and vessel.Key == "highball" then 2
        else 0

    -- === Readout lines ===
    local fillWord = if fill >= 0.85 then "brimming"
        elseif fill >= 0.70 then "full"
        elseif fill >= 0.55 then "fair"
        elseif fill >= 0.40 then "shy"
        else "thin"

    if empty then
        table.insert(lines, "Nothing on tap — a polished glass and a long wait.")
    elseif isCocktail then
        local fam = family :: Brews.Family
        if regret then
            table.insert(lines, `The house calls this one The Regret — {(cocktail :: Brews.Cocktail).Tag}.`)
        elseif cocktail then
            table.insert(lines, `The house calls this one a {(cocktail :: Brews.Cocktail).Name} — {(cocktail :: Brews.Cocktail).Tag}.`)
        else
            table.insert(lines, "The house pours your invention and declines to name it.")
        end

        if method == "shaken" then
            table.insert(lines, "Shaken over ice until the shaker frosts, then strained sharp.")
        elseif method == "stirred" then
            table.insert(lines, "Stirred slow over ice, the spoon ringing the glass like a bell.")
        else
            table.insert(lines, "Built right in the glass, the house way.")
        end

        local parts = {fam.Name}
        if mixerFamily then
            table.insert(parts, (mixerFamily :: Brews.Family).Name)
        end
        if citrus then
            table.insert(parts, "lime pressed sharp")
        end
        if keg.honey > 0 then
            table.insert(parts, "a spoon of honey")
        end
        if keg.salt > 0 then
            table.insert(parts, "a salted rim")
        end
        table.insert(lines, `In it: {JoinAnd(parts)}.`)

        local iceWord = if ice == 1 then " over a fist of ice" elseif ice == 2 then " over stacked ice" else ""
        table.insert(lines, `Poured {fillWord} into {vesselPhrase}{iceWord}.`)

        if wheel then
            table.insert(lines, "An orange wheel rides the rim.")
        end
        if garnish == "lime" then
            table.insert(lines, "A wedge of lime bites the rim.")
        elseif garnish == "olive" then
            table.insert(lines, "An olive rides a pick across the mouth.")
        end
        if umbrella then
            if umbrellaBent then
                table.insert(lines, "A paper umbrella lists in it, bent double by the pour.")
            else
                table.insert(lines, "A paper umbrella leans in it, ambition outrunning dignity.")
            end
        end
        if keg.bubbles > 0 then
            table.insert(lines, "Bubble streams climb it without rest.")
        end
        if mulled then
            table.insert(lines, "Mulled and steaming, with spice adrift in it.")
        end
        if chilled then
            table.insert(lines, "Served cold enough to frost the glass.")
        end

        if bite then
            table.insert(lines, `Runs {proof} proofs — it bites, and the fumes bite first.`)
        elseif legs then
            table.insert(lines, `Runs {proof} proofs — slow legs cling to the glass.`)
        else
            table.insert(lines, `Runs a gentle {proof} proofs.`)
        end
    elseif foamOnly then
        table.insert(lines, `A pull of pure foam settles in {vesselPhrase} — all head, no heart.`)
    else
        local fam = family :: Brews.Family
        if isBottle then
            table.insert(lines, `{bottleIntro :: string} {fam.Phrase}, laid on the shelf.`)
        else
            table.insert(lines, `A {fillWord} pour of {fam.Phrase}, served in {vesselPhrase}.`)
        end
        if keg.thin > 0 and not isBottle then
            table.insert(lines, "Pulled thin and quick — the tapster had somewhere to be.")
        end

        if fingers == 1 then
            table.insert(lines, "A thin collar of foam rings the glass.")
        elseif fingers == 2 then
            table.insert(lines, "Two fingers of cream stand proud and leave lace where they cling.")
        elseif fingers == 3 then
            table.insert(lines, "A proud crown of foam stands over it.")
        elseif fingers >= 4 then
            table.insert(lines, "The head overruns the rim and will not be told.")
        elseif headScale >= 0.8 and not swill then
            table.insert(lines, "It pours flat — not a bubble to its name.")
        end

        if keg.nitro > 0 then
            table.insert(lines, "Nitro-poured — a cascade tumbles down the glass in slow waves.")
        end
        if keg.bubbles > 0 then
            table.insert(lines, "Bubble streams climb it without rest.")
        end
        if keg.swirls > 0 then
            table.insert(lines, "Stirred sunwise — the drink is still turning.")
        end
        if keg.honey > 0 then
            table.insert(lines, "Honeyed — it drinks sweet and slow.")
        end
        if keg.fruit == 1 then
            if isBottle or vessel.Key == "horn" or vessel.Key == "clayjug" then
                table.insert(lines, "An orange wheel waits beside it — no rim will take it.")
            else
                table.insert(lines, "An orange wheel rides the rim.")
            end
        elseif keg.fruit >= 2 then
            table.insert(lines, "Lime pressed in sharp, and a wedge bites the rim.")
        end
        if keg.salt > 0 then
            table.insert(lines, "The rim wears a crust of sea-salt.")
        end
        if mulled then
            table.insert(lines, "Mulled and steaming, with spice adrift in it.")
        end
        if chilled then
            table.insert(lines, "Served cold enough to frost the glass.")
        end

        if age > 0 then
            local years = if age == 1 then "year" else "years"
            if vinegar then
                table.insert(lines, `Laid down {age} {years} — and gone to vinegar; {fam.Noun} was never meant to wait.`)
            elseif agesWell then
                table.insert(lines, `Laid down {age} {years} — it pours the darker and the wiser for it.`)
            else
                table.insert(lines, `Laid down {age} {years} — it holds, but only just.`)
            end
        end

        if bite then
            table.insert(lines, `Runs {proof} proofs — it bites, and the fumes bite first.`)
        elseif legs then
            table.insert(lines, `Runs {proof} proofs — slow legs cling to the glass.`)
        else
            table.insert(lines, `Runs a gentle {proof} proofs.`)
        end
    end

    local carvedVessel = vessel.Key == "barrel" or vessel.Key == "horn" or vessel.Key == "clayjug"
    if toast then
        if #toast == 0 then
            table.insert(lines, if carvedVessel then "An empty toast is carved into it — to nothing and no one." else "The glass is etched with an empty toast — to nothing and no one.")
        elseif keg.toastCrooked then
            table.insert(lines, if carvedVessel then `Carved crooked into it — the knife-hand was drinking too: "{toast}".` else `Etched crooked on the glass — the engraver was drinking too: "{toast}".`)
        else
            table.insert(lines, if carvedVessel then `Carved into it: "{toast}".` else `Etched on the glass: "{toast}".`)
        end
    end
    if tavern then
        if vessel.Key == "barrel" then
            table.insert(lines, `The house name is burned into the staves — "{tavern}".`)
        elseif isBottle then
            table.insert(lines, `The label names the house — "{tavern}".`)
        else
            table.insert(lines, `The coaster names the house — "{tavern}".`)
        end
    end
    if rowdy and not empty then
        table.insert(lines, "A rowdy pour — the shelf gets its share and the floor gets the rest.")
    end

    if empty then
        table.insert(lines, Brews.EmptyVerdict)
    elseif foamOnly then
        table.insert(lines, Brews.FoamVerdict)
    elseif regret or (swill and not isCocktail) then
        table.insert(lines, Brews.SwillVerdict)
    else
        table.insert(lines, Brews.Verdicts[quality])
    end

    -- === Title ===
    local title: string
    if empty then
        title = "An Empty Glass"
    elseif isCocktail then
        local parts = {}
        if rowdy then
            table.insert(parts, "Rowdy")
        end
        if regret then
            table.insert(parts, "The Regret")
        else
            local adj = Brews.QualityAdj[quality]
            if adj then
                table.insert(parts, adj)
            end
            table.insert(parts, if cocktail then (cocktail :: Brews.Cocktail).Name else "House Mix")
        end
        title = table.concat(parts, " ")
    elseif foamOnly then
        title = "A Glass of Foam"
    elseif swill then
        title = if rowdy then "Rowdy Skunked Swill" else "Skunked Swill"
    else
        local fam = family :: Brews.Family
        local parts = {}
        if rowdy then
            table.insert(parts, "Rowdy")
        end
        local adj = Brews.QualityAdj[quality]
        if adj then
            table.insert(parts, adj)
        end
        if vinegar then
            table.insert(parts, "Vinegared")
        elseif age > 0 then
            table.insert(parts, if vessel.Key == "barrel" then "Oak-Aged" else `{age}-Year`)
        elseif mulled then
            table.insert(parts, "Mulled")
        elseif keg.nitro > 0 then
            table.insert(parts, "Nitro")
        elseif chilled then
            table.insert(parts, "Frosted")
        elseif keg.honey > 0 then
            table.insert(parts, "Honeyed")
        end
        table.insert(parts, fam.Noun)
        title = table.concat(parts, " ")
    end

    local familyName: string
    if isCocktail then
        local fam = family :: Brews.Family
        if mixerFamily then
            familyName = `{fam.Name} + {(mixerFamily :: Brews.Family).Name}`
        elseif citrus then
            familyName = `{fam.Name} + lime`
        else
            familyName = fam.Name
        end
    elseif family then
        familyName = (family :: Brews.Family).Name
    elseif foamOnly then
        familyName = "foam"
    else
        familyName = "—"
    end

    return {
        Title = title,
        Lines = lines,
        Notes = notes,
        Family = if family then (family :: Brews.Family).Letter else nil,
        FamilyName = familyName,
        Splash = splash,
        Vessel = vessel.Key,
        VesselName = vessel.Name,
        VesselLabel = vesselLabel,
        Size = size,
        Scale = 1 + 0.12 * (size - 1),
        Proof = proof,
        ProofLabel = if family then `{proof} proofs` else "—",
        Age = age,
        AgeLabel = if family == nil or isCocktail then "—"
            elseif age == 0 then "fresh from the tap"
            elseif vinegar then `{age} {if age == 1 then "year" else "years"} (vinegar)`
            else `laid down {age} {if age == 1 then "year" else "years"}`,
        Vinegar = vinegar,
        Head = fingers,
        HeadLabel = Brews.HeadLabels[fingers],
        Fill = fill,
        Bubbles = keg.bubbles,
        Nitro = keg.nitro,
        Swirls = keg.swirls,
        Honeyed = keg.honey > 0,
        Fruit = wheel,
        Mulled = mulled,
        Chilled = chilled,
        Quality = quality,
        QualityLabel = if empty then "—" else Brews.QualityLabels[quality],
        Verdict = lines[#lines],
        Rowdy = rowdy,
        Tilt = tilt,
        Overflow = overflow,
        Toast = toast,
        ToastCrooked = keg.toastCrooked,
        Tavern = tavern,
        Sediment = sediment,
        Slops = slops,
        Color = color,
        HeadColor = headColor,
        Empty = empty,
        FoamOnly = foamOnly,
        Legs = legs and not empty and not foamOnly,
        Bite = bite,
        Cocktail = if regret then "The Regret"
            elseif cocktail then (cocktail :: Brews.Cocktail).Name
            elseif houseMix then "an unnamed house mix"
            else nil,
        Method = if isCocktail then method else nil,
        Salt = keg.salt > 0,
        Citrus = citrus,
        Garnish = garnish,
        Umbrella = umbrella,
        UmbrellaBent = umbrellaBent,
        Ice = ice,
        Recipe = spell.raw,
    }
end

return module
