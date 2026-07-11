--#include[random]
local Parser = require("@src/spell/Parser")

local Rng = random.new()

export type Rgb = {r: number, g: number, b: number}

export type Material = {
    Name: string,
    NameWord: string,
    Bound: string,
    Trim: string,
    Nobility: number,
    Light: Rgb,
    Mid: Rgb,
    Dark: Rgb,
    Deep: Rgb,
}

export type Sigil = {
    letter: string,
    name: string,
    phrase: string,
    power: number,
}

export type GrimoirePlan = {
    material: string,
    trim: string?,
    fineness: number,
    sigil: Sigil?,
    exlibris: Sigil?,
    exlibrisPlate: boolean,
    clasps: number,
    locked: boolean,
    corners: boolean,
    ribs: number,
    pages: number,
    pageCount: number,
    ribbons: number,
    studs: number,
    gilt: boolean,
    chained: boolean,
    edition: string?,
    title: string?,
    metal: string,
    cursed: boolean,
    score: number,
    quality: number,
    qualityWord: string,
    tierNoun: string,
    name: string,
    description: string,
    notes: {string},
    seed: number,
}

local module = {}

module.Materials = {
    leather = {Name = "Tooled Leather", NameWord = "Leather-Bound", Bound = "tooled leather", Trim = "tooled leather", Nobility = 3,
        Light = {r = 176, g = 126, b = 82}, Mid = {r = 128, g = 86, b = 52},
        Dark = {r = 84, g = 54, b = 32}, Deep = {r = 46, g = 28, b = 16}},
    dragonhide = {Name = "Dragonhide", NameWord = "Dragonhide", Bound = "red-scaled dragonhide", Trim = "dragonhide", Nobility = 7,
        Light = {r = 206, g = 88, b = 66}, Mid = {r = 148, g = 48, b = 40},
        Dark = {r = 94, g = 26, b = 24}, Deep = {r = 50, g = 12, b = 14}},
    vellum = {Name = "Moon-Pale Vellum", NameWord = "Pale Vellum", Bound = "moon-pale vellum", Trim = "pale vellum", Nobility = 5,
        Light = {r = 246, g = 241, b = 226}, Mid = {r = 216, g = 207, b = 184},
        Dark = {r = 162, g = 152, b = 130}, Deep = {r = 98, g = 90, b = 74}},
    gilt = {Name = "Gilt Panels", NameWord = "Gilt-Panelled", Bound = "gilt panelling", Trim = "gilt", Nobility = 8,
        Light = {r = 255, g = 228, b = 142}, Mid = {r = 208, g = 168, b = 82},
        Dark = {r = 140, g = 104, b = 40}, Deep = {r = 76, g = 54, b = 18}},
    void = {Name = "Void-Black", NameWord = "Void", Bound = "void-black hide that drinks the light", Trim = "void-black", Nobility = 10,
        Light = {r = 98, g = 82, b = 138}, Mid = {r = 46, g = 38, b = 68},
        Dark = {r = 24, g = 19, b = 37}, Deep = {r = 9, g = 7, b = 17}},
    ancient = {Name = "Ancient Cracked Leather", NameWord = "Ancient", Bound = "ancient cracked leather", Trim = "cracked leather", Nobility = 4,
        Light = {r = 160, g = 130, b = 92}, Mid = {r = 112, g = 88, b = 58},
        Dark = {r = 72, g = 55, b = 36}, Deep = {r = 38, g = 28, b = 18}},
    storm = {Name = "Storm-Touched Hide", NameWord = "Storm-Touched", Bound = "storm-touched hide", Trim = "storm-hide", Nobility = 6,
        Light = {r = 150, g = 168, b = 202}, Mid = {r = 92, g = 106, b = 140},
        Dark = {r = 54, g = 64, b = 92}, Deep = {r = 26, g = 32, b = 50}},
    dream = {Name = "Dream-Bound", NameWord = "Dream-Bound", Bound = "dream-bound opaline skin", Trim = "opaline dream-skin", Nobility = 9,
        Light = {r = 240, g = 231, b = 244}, Mid = {r = 204, g = 190, b = 216},
        Dark = {r = 148, g = 134, b = 168}, Deep = {r = 88, g = 78, b = 106}},
    flesh = {Name = "Rotting Flesh", NameWord = "Rotting Flesh-Bound", Bound = "rotting flesh, stitched and weeping", Trim = "flesh", Nobility = 1,
        Light = {r = 196, g = 158, b = 136}, Mid = {r = 148, g = 106, b = 92},
        Dark = {r = 98, g = 62, b = 56}, Deep = {r = 54, g = 32, b = 30}},
    ruin = {Name = "Ruinbound Ash", NameWord = "Ruinbound", Bound = "ruinbound ash-hide, scarred with dead script", Trim = "ash", Nobility = 2,
        Light = {r = 152, g = 148, b = 142}, Mid = {r = 102, g = 98, b = 94},
        Dark = {r = 64, g = 60, b = 58}, Deep = {r = 33, g = 31, b = 30}},
} :: {[string]: Material}

local CoverRunes = {
    G = "leather",
    B = "dragonhide",
    W = "vellum",
    ["!"] = "gilt",
    ["*"] = "void",
    [":"] = "ancient",
    ["^"] = "storm",
    ["'"] = "dream",
    ["%"] = "flesh",
    ["/"] = "ruin",
}

module.Sigils = {
    C = {Name = "Circle-Seal", Phrase = "a graven circle-seal"},
    D = {Name = "Crossed Ward", Phrase = "a crossed ward"},
    X = {Name = "Woven Knot", Phrase = "an endless woven knot"},
    O = {Name = "Ring-Seal", Phrase = "a double ring-seal"},
    A = {Name = "Chevron-Blade", Phrase = "a chevron-blade, point to heaven"},
    S = {Name = "Serpent", Phrase = "a sinuous serpent"},
    Y = {Name = "World-Tree", Phrase = "a branching world-tree"},
    T = {Name = "Tower", Phrase = "a lone watchtower"},
    M = {Name = "Three Peaks", Phrase = "a range of three peaks"},
    E = {Name = "Unblinking Eye", Phrase = "an unblinking eye"},
}

module.FinenessWords = {"rough-cut", "honest", "well-cured", "supple", "flawless"}
module.QualityWords = {"shoddy", "honest", "fine", "masterwork", "legendary"}
module.TierNouns = {"Chapbook", "Journal", "Tome", "Grimoire", "Codex"}
module.EmbossWords = {"faintly tooled", "cleanly tooled", "struck deep", "struck deep and bold", "branded to the very boards"}
module.ThicknessWords = {"a slim binding", "a modest block", "a solid block", "a heavy block", "a ponderous block", "a back-breaking block"}
module.RibbonNames = {"crimson", "forest-green", "midnight-blue", "old-gold"}

local Verdicts = {
    "a shoddy chapbook, fit for kindling.",
    "an honest journal, plainly sewn and sound.",
    "a fine tome any shelf would be proud of.",
    "a masterwork grimoire — shelve it under guard.",
    "a legendary codex — libraries have gone to war for less.",
}

local CountWords = {"one", "two", "three", "four", "five", "six", "seven", "eight"}

local function HashSeed(text: string): number
    local hash = 5381
    for index = 1, #text do
        hash = (hash * 33 + string.byte(text, index)) % 2147483647
    end
    return math.max(hash, 1)
end

type WalkState = {
    cursed: boolean,
    nested: boolean,
    coverCount: {[string]: number},
    sigilPower: {[string]: number},
    sigilOrder: {string},
    innerPower: {[string]: number},
    innerOrder: {string},
    clasps: number,
    locked: boolean,
    corners: boolean,
    ribs: number,
    pages: number,
    ribbons: number,
    studs: number,
    gilt: boolean,
    chained: boolean,
    edition: string,
    title: string,
    strayTitleMark: boolean,
    unknown: {[string]: boolean},
}

local function ProcessRun(run: Parser.Run, depth: number, state: WalkState)
    local letter = run.letter
    if CoverRunes[letter] then
        local key = CoverRunes[letter]
        state.coverCount[key] = (state.coverCount[key] or 0) + run.count
    elseif module.Sigils[letter] then
        if depth > 1 then
            state.innerPower[letter] = (state.innerPower[letter] or 0) + run.count
            if state.innerPower[letter] == run.count then
                table.insert(state.innerOrder, letter)
            end
        else
            state.sigilPower[letter] = (state.sigilPower[letter] or 0) + run.count
            if state.sigilPower[letter] == run.count then
                table.insert(state.sigilOrder, letter)
            end
        end
    elseif letter == "H" then
        state.clasps += run.count
    elseif letter == "K" then
        state.locked = true
    elseif letter == "R" then
        state.corners = true
    elseif letter == "U" then
        state.ribs += run.count
    elseif letter == "I" then
        state.pages += run.count
    elseif letter == "F" then
        state.ribbons += run.count
    elseif letter == "." then
        state.studs += run.count
    elseif letter == "~" then
        state.gilt = true
    elseif letter == "&" then
        state.chained = true
    elseif letter == "$" then
        state.strayTitleMark = true
    elseif string.match(letter, "%d") then
        state.edition ..= string.rep(letter, run.count)
    else
        state.unknown[letter] = true
    end
end

local function ProcessGroup(group: Parser.Group, depth: number, state: WalkState)
    local mark = string.find(group.letters, "$", 1, true)
    if mark then
        local before = string.sub(group.letters, 1, mark - 1)
        local after = string.gsub(string.sub(group.letters, mark + 1), "%$", "")
        after = string.gsub(after, "[^%w]", "")
        if #after > 0 then
            if #state.title > 0 then
                state.title ..= " "
            end
            state.title ..= after
        else
            state.strayTitleMark = true
        end
        local index = 1
        while index <= #before do
            local letter = string.sub(before, index, index)
            local count = 1
            while index + count <= #before and string.sub(before, index + count, index + count) == letter do
                count += 1
            end
            ProcessRun({letter = letter, count = count}, depth, state)
            index += count
        end
    else
        for _, run in ipairs(group.runs) do
            ProcessRun(run, depth, state)
        end
    end
end

local function WalkSpell(spell: Parser.Spell, depth: number, state: WalkState)
    if spell.unstable then
        state.cursed = true
    end
    for _, run in ipairs(spell.rings) do
        ProcessRun(run, depth, state)
    end
    for _, part in ipairs(spell.parts) do
        if part.kind == "group" then
            ProcessGroup(part :: Parser.Group, depth, state)
        else
            state.nested = true
            WalkSpell(part :: Parser.Spell, depth + 1, state)
        end
    end
end

local function BuildSigil(letter: string, power: number): Sigil
    local entry = module.Sigils[letter]
    return {
        letter = letter,
        name = entry.Name,
        phrase = entry.Phrase,
        power = math.clamp(power, 1, 5),
    }
end

function module.Resolve(spell: Parser.Spell): GrimoirePlan
    local state: WalkState = {
        cursed = false,
        nested = false,
        coverCount = {},
        sigilPower = {},
        sigilOrder = {},
        innerPower = {},
        innerOrder = {},
        clasps = 0,
        locked = false,
        corners = false,
        ribs = 0,
        pages = 0,
        ribbons = 0,
        studs = 0,
        gilt = false,
        chained = false,
        edition = "",
        title = "",
        strayTitleMark = false,
        unknown = {},
    }
    WalkSpell(spell, 1, state)

    local notes: {string} = {}

    local ranked: {{key: string, count: number}} = {}
    for key, count in pairs(state.coverCount) do
        table.insert(ranked, {key = key, count = count})
    end
    table.sort(ranked, function(a, b)
        if a.count == b.count then
            return module.Materials[a.key].Nobility > module.Materials[b.key].Nobility
        end
        return a.count > b.count
    end)

    local material: string
    local trim: string? = nil
    local bodyCount = 1
    if #ranked > 0 then
        material = ranked[1].key
        bodyCount = ranked[1].count
        if #ranked > 1 then
            trim = ranked[2].key
        end
    else
        material = "leather"
        table.insert(notes, "No hide was named — the bindery cuts honest tooled leather.")
    end
    local fineness = math.clamp(bodyCount, 1, 5)

    local sigil: Sigil? = nil
    for index, letter in ipairs(state.sigilOrder) do
        if index == 1 then
            sigil = BuildSigil(letter, state.sigilPower[letter])
        else
            table.insert(notes, `The bindery stamps one sigil to a cover — the {string.lower(module.Sigils[letter].Name)} is set aside.`)
        end
    end

    local exlibris: Sigil? = nil
    for index, letter in ipairs(state.innerOrder) do
        if index == 1 then
            exlibris = BuildSigil(letter, state.innerPower[letter])
        else
            table.insert(notes, `The ex-libris holds one mark — the {string.lower(module.Sigils[letter].Name)} is set aside.`)
        end
    end

    local clasps = state.clasps
    if clasps > 3 then
        clasps = 3
        table.insert(notes, "The bindery fits three clasps at most — the rest go back in the scrap bin.")
    end

    local ribs = state.ribs
    if ribs > 6 then
        ribs = 6
        table.insert(notes, "Six cords are all a spine will carry — the rest are trimmed away.")
    end

    local pages = state.pages
    if pages > 5 then
        pages = 5
        table.insert(notes, "No press could close a fatter block — the extra quires are set aside.")
    end

    local ribbons = state.ribbons
    if ribbons > 4 then
        ribbons = 4
        table.insert(notes, "Four ribbons and no more — the offcuts go to the binder's daughter.")
    end

    local studs = state.studs
    if studs > 8 then
        studs = 8
        table.insert(notes, "Eight bosses to a board — the rest rattle in the drawer.")
    end

    local edition = state.edition
    if #edition > 4 then
        edition = string.sub(edition, 1, 4)
        table.insert(notes, "The spine holds but four figures — the rest are set aside.")
    end

    local title = state.title
    if #title > 16 then
        title = string.sub(title, 1, 16)
        table.insert(notes, "The cover holds sixteen letters — the title is cut short.")
    end
    if state.strayTitleMark and #title == 0 then
        table.insert(notes, "A title mark with no letters behind it — the cover stays unnamed.")
    end

    local unknownLetters = {}
    for letter in pairs(state.unknown) do
        table.insert(unknownLetters, letter)
    end
    table.sort(unknownLetters)
    for _, letter in ipairs(unknownLetters) do
        table.insert(notes, `The {letter} rune means nothing to the bindery — it is left untooled.`)
    end

    local metal = if material == "void" or material == "storm" or material == "ruin" then "iron" else "brass"
    local metalWord = if metal == "iron" then "black iron" else "brass"
    local pageCount = 60 + 62 * pages
    local cursed = state.cursed

    local matEntry = module.Materials[material]
    local score = matEntry.Nobility * (0.7 + 0.12 * fineness)
    if sigil then
        score += 0.8 + 0.4 * (sigil :: Sigil).power
    end
    score += 0.7 * clasps
    if state.locked then
        score += 1.2
    end
    if state.corners then
        score += 1.0
    end
    score += 0.3 * ribs
    score += 0.4 * ribbons
    score += 0.15 * studs
    score += 0.3 * pages
    if state.gilt then
        score += 1.4
    end
    if state.chained then
        score += 1.0
    end
    if #edition > 0 then
        score += 0.7
    end
    if #title > 0 then
        score += 1.4
    end
    if state.nested then
        score += 1.0
    end
    if trim then
        score += 0.4
    end

    if cursed then
        score *= 0.5 + Rng:NextNumber() * 0.3
    end

    local quality = 1
    if score >= 20 then
        quality = 5
    elseif score >= 14 then
        quality = 4
    elseif score >= 9 then
        quality = 3
    elseif score >= 5 then
        quality = 2
    end

    local qualityWord = module.QualityWords[quality]
    local tierNoun = module.TierNouns[quality]

    local nameParts = {}
    if cursed then
        table.insert(nameParts, "Cursed")
    end
    if state.chained then
        table.insert(nameParts, "Chained")
    elseif state.locked then
        table.insert(nameParts, "Locked")
    end
    if #nameParts == 0 then
        table.insert(nameParts, (string.gsub(qualityWord, "^%l", string.upper)))
    end
    table.insert(nameParts, matEntry.NameWord)
    table.insert(nameParts, tierNoun)
    local name = table.concat(nameParts, " ")

    local lines = {}
    local article = if qualityWord == "honest" then "An" else "A"
    local opening = `{article} {qualityWord} {string.lower(tierNoun)} bound in {module.FinenessWords[fineness]} {matEntry.Bound}`
    if trim then
        opening ..= `, trimmed in {module.Materials[trim :: string].Trim}`
    end
    table.insert(lines, opening .. ".")

    if sigil then
        local built = sigil :: Sigil
        table.insert(lines, `Its cover bears {built.phrase}, {module.EmbossWords[built.power]}.`)
    end

    if #title > 0 then
        table.insert(lines, `The title "{title}" is tooled across the head.`)
    end

    if clasps > 0 then
        local line = if clasps == 1
            then `A single {metalWord} clasp holds it shut`
            else `{string.gsub(CountWords[clasps], "^%l", string.upper)} {metalWord} clasps hold it shut`
        if state.locked then
            line ..= ", and a heavy hasp-lock besides."
        else
            line ..= "."
        end
        table.insert(lines, line)
    elseif state.locked then
        table.insert(lines, "A heavy hasp-lock holds it shut — the key is another matter.")
    end

    if state.corners and studs > 0 then
        table.insert(lines, `Its corners are capped in {metalWord} and its boards set with {CountWords[studs]} bosses.`)
    elseif state.corners then
        table.insert(lines, `Its corners are capped in {metalWord}.`)
    elseif studs > 0 then
        local line = if studs == 1
            then `A single {metalWord} boss is set in the board.`
            else `Its boards are set with {CountWords[studs]} {metalWord} bosses.`
        table.insert(lines, line)
    end

    if ribs > 0 then
        local line = if ribs == 1
            then "One raised cord ribs the spine"
            else `{string.gsub(CountWords[ribs], "^%l", string.upper)} raised cords rib the spine`
        if #edition > 0 then
            line ..= `; the figure {edition} stands at its head.`
        else
            line ..= "."
        end
        table.insert(lines, line)
    elseif #edition > 0 then
        table.insert(lines, `The figure {edition} is tooled upon the smooth spine.`)
    end

    local pageLine = `{pageCount} leaves make {module.ThicknessWords[pages + 1]}`
    if state.gilt then
        pageLine ..= ", gilt at the edges."
    else
        pageLine ..= "."
    end
    table.insert(lines, pageLine)

    if ribbons == 1 then
        table.insert(lines, `A {module.RibbonNames[1]} ribbon marks the reader's place.`)
    elseif ribbons > 1 then
        local colors = {}
        for index = 1, ribbons do
            table.insert(colors, module.RibbonNames[index])
        end
        table.insert(lines, `{string.gsub(CountWords[ribbons], "^%l", string.upper)} ribbons — {table.concat(colors, ", ")} — trail from the block.`)
    end

    if state.nested then
        if exlibris then
            table.insert(lines, `An ex-libris seal is set at the foot, bearing {(exlibris :: Sigil).phrase}.`)
        else
            table.insert(lines, "An ex-libris seal is set at the foot, its field left blank.")
        end
    end

    if state.chained then
        table.insert(lines, "A shelf-chain is stapled to the board — this book does not leave the library.")
    end

    if cursed then
        table.insert(lines, "The binding is torn and the threads hang loose — a curse gnaws this book, and no two summonings find it the same.")
    end

    table.insert(lines, `The binder's verdict: {Verdicts[quality]}`)

    local seed = if cursed
        then Rng:NextInteger(1, 2147483646)
        else HashSeed(string.upper(spell.raw))

    return {
        material = material,
        trim = trim,
        fineness = fineness,
        sigil = sigil,
        exlibris = exlibris,
        exlibrisPlate = state.nested,
        clasps = clasps,
        locked = state.locked,
        corners = state.corners,
        ribs = ribs,
        pages = pages,
        pageCount = pageCount,
        ribbons = ribbons,
        studs = studs,
        gilt = state.gilt,
        chained = state.chained,
        edition = if #edition > 0 then edition else nil,
        title = if #title > 0 then title else nil,
        metal = metal,
        cursed = cursed,
        score = score,
        quality = quality,
        qualityWord = qualityWord,
        tierNoun = tierNoun,
        name = name,
        description = table.concat(lines, " "),
        notes = notes,
        seed = seed,
    }
end

return module
