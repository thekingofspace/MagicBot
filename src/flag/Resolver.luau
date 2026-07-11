local Parser = require("@src/spell/Parser")
local Runes = require("@src/spell/Runes")
local Elements = require("@src/spell/elements")

local module = {}

export type RGB = {r: number, g: number, b: number}

export type FieldPlan = {
    element: string?,
    color: RGB,
    altColor: RGB,
    altElement: string?,
    bands: number,
    orientation: number, -- 0 upright, 1 level, 2 bendwise
}

export type LayerPlan = {
    kind: "bars" | "emblem" | "shield",
    emblem: string?,
    element: string?,
    color: RGB,
    tint: string,
    count: number,
    power: number,
    orientation: number,
    shield: any?,
    needsContrast: boolean?,
}

export type Plan = {
    field: FieldPlan,
    layers: {LayerPlan},
    fringe: RGB?,
    fringeTint: string?,
    warTorn: boolean,
    title: string,
    description: string,
    notes: {string},
    palette: {string},
    layerCount: number,
}

-- Cloth names for each element's dye. Field = the blazon word when the color
-- holds the whole field; Tint = the plain adjective used everywhere else.
local Tinctures = {
    Fire = {Field = "Gules", Tint = "crimson"},
    Water = {Field = "Azure", Tint = "azure"},
    Air = {Field = "Pearl", Tint = "pale-sky"},
    Ground = {Field = "Russet", Tint = "russet"},
    Life = {Field = "Vert", Tint = "verdant"},
    Light = {Field = "Or", Tint = "gold"},
    Volt = {Field = "Cerulean", Tint = "storm-blue"},
    Time = {Field = "Buff", Tint = "tan"},
    Space = {Field = "Purpure", Tint = "violet"},
    Gravity = {Field = "Amethyst", Tint = "amethyst"},
    Mind = {Field = "Rose", Tint = "rose"},
    Decay = {Field = "Murk", Tint = "murky"},
    Ruin = {Field = "Rust", Tint = "rust"},
}

-- Device runes: every emblem the loom knows how to raise above the field.
local Devices = {
    A = "chevron",
    X = "saltire",
    T = "cross",
    O = "roundel",
    V = "pile",
    C = "crescent",
    S = "wave",
    L = "canton",
    ["."] = "scatter",
}

local PointDevices = {
    roundel = true,
    crescent = true,
    star = true,
}

local SlateColor = {r = 96, g = 92, b = 108}
local NearBlack = {r = 18, g = 16, b = 26}
local ArgentColor = {r = 242, g = 238, b = 228}
local SableColor = {r = 34, g = 31, b = 42}

local function TintOf(element: string?): string
    if not element then
        return "slate"
    end
    local entry = Tinctures[element]
    return if entry then entry.Tint else string.lower(element)
end

local function ColorOf(element: string): RGB
    return Elements.Get(element).Color
end

local function Dusk(color: RGB): RGB
    return {
        r = math.floor(color.r + (NearBlack.r - color.r) * 0.55),
        g = math.floor(color.g + (NearBlack.g - color.g) * 0.55),
        b = math.floor(color.b + (NearBlack.b - color.b) * 0.55),
    }
end

local function Luminance(color: RGB): number
    return 0.299 * color.r + 0.587 * color.g + 0.114 * color.b
end

type ClusterInfo = {
    base: string,
    power: number,
    rCount: number,
    digit: number?,
    element: string?,
    strays: {string},
}

local function ReadCluster(group: Parser.Group): ClusterInfo
    local base = group.runs[1].letter
    local power = 0
    local rCount = 0
    local digit: number? = nil
    local firstElement: string? = nil
    local strays: {string} = {}

    for _, run in ipairs(group.runs) do
        if run.letter == base then
            power += run.count
        elseif string.match(run.letter, "%d") then
            if not digit then
                digit = tonumber(run.letter)
            end
        elseif run.letter == "R" then
            rCount += run.count
        else
            local entry = Runes.Get(run.letter)
            if entry.Class == "element" and entry.Element then
                if not firstElement then
                    firstElement = entry.Element
                end
            else
                table.insert(strays, run.letter)
            end
        end
    end

    return {base = base, power = power, rCount = rCount, digit = digit, element = firstElement, strays = strays}
end

local function BuildPlan(spell: Parser.Spell, notes: {string}, noteSeen: {[string]: boolean}, depth: number): Plan
    local field: FieldPlan? = nil
    local layers: {LayerPlan} = {}
    local warTorn = spell.unstable
    local fringe: RGB? = nil
    local fringeTint: string? = nil

    local function AddNote(key: string, text: string)
        if not noteSeen[key] then
            noteSeen[key] = true
            table.insert(notes, text)
        end
    end

    for _, part in ipairs(spell.parts) do
        if part.kind == "spell" then
            local sub = BuildPlan(part :: Parser.Spell, notes, noteSeen, depth + 1)
            if sub.warTorn then
                warTorn = true
            end
            table.insert(layers, {
                kind = "shield",
                emblem = "shield",
                element = nil,
                color = ArgentColor,
                tint = "shield",
                count = 1,
                power = 1,
                orientation = 0,
                shield = sub,
            })
            continue
        end

        local info = ReadCluster(part :: Parser.Group)
        for _, stray in ipairs(info.strays) do
            AddNote(`stray:{stray}`, `The {stray} rune binds nothing on a banner — its stitch is skipped.`)
        end

        local baseEntry = Runes.Get(info.base)
        local isElement = baseEntry.Class == "element" and baseEntry.Element ~= nil

        if isElement and field == nil then
            -- The first color cluster paints the field; its power splits it into bands.
            local element = baseEntry.Element :: string
            local color = ColorOf(element)
            field = {
                element = element,
                color = color,
                altColor = if info.element then ColorOf(info.element :: string) else Dusk(color),
                altElement = info.element,
                bands = math.clamp(info.power, 1, 7),
                orientation = info.rCount % 3,
            }
        elseif isElement then
            if baseEntry.Element == "Space" and info.element then
                -- A void rune bound to a color is not a stripe — it is a star.
                table.insert(layers, {
                    kind = "emblem",
                    emblem = "star",
                    element = info.element,
                    color = ColorOf(info.element :: string),
                    tint = TintOf(info.element),
                    count = math.clamp(info.digit or 1, 1, 9),
                    power = info.power,
                    orientation = 0,
                })
            else
                local element = baseEntry.Element :: string
                table.insert(layers, {
                    kind = "bars",
                    emblem = nil,
                    element = element,
                    color = ColorOf(element),
                    tint = TintOf(element),
                    count = math.clamp(info.power, 1, 7),
                    power = info.power,
                    orientation = (1 + info.rCount) % 3,
                })
            end
        elseif Devices[info.base] then
            local name = Devices[info.base]
            local count = 1
            if name == "scatter" then
                count = math.clamp(info.digit or 7, 1, 12)
            elseif PointDevices[name] then
                count = math.clamp(info.digit or 1, 1, 9)
            end
            table.insert(layers, {
                kind = "emblem",
                emblem = name,
                element = info.element,
                color = if info.element then ColorOf(info.element :: string) else ArgentColor,
                tint = TintOf(info.element),
                count = count,
                power = info.power,
                orientation = info.rCount % 3,
                needsContrast = info.element == nil,
            })
        else
            AddNote(`device:{info.base}`, `The {info.base} rune raises no device — the loom leaves it out.`)
        end
    end

    local solvedField: FieldPlan = field or {
        element = nil,
        color = SlateColor,
        altColor = Dusk(SlateColor),
        altElement = nil,
        bands = 1,
        orientation = 0,
    }

    -- Unbound emblems take whichever of argent or sable stands out against the field.
    local fieldLum = Luminance(solvedField.color)
    if solvedField.bands > 1 then
        fieldLum = (fieldLum + Luminance(solvedField.altColor)) / 2
    end
    local contrastColor = if fieldLum > 150 then SableColor else ArgentColor
    local contrastTint = if fieldLum > 150 then "sable" else "argent"
    for _, layer in ipairs(layers) do
        if layer.needsContrast then
            layer.color = contrastColor
            layer.tint = contrastTint
            layer.needsContrast = nil
        end
    end

    -- Rings pressed against the border trim the banner's free edges.
    for _, run in ipairs(spell.rings) do
        local entry = Runes.Get(run.letter)
        if depth > 1 then
            AddNote("shieldring", "Rings on an inset shield find no edge to trim.")
        elseif entry.Class == "element" and entry.Element then
            if fringe then
                AddNote("fringe2", "Only one fringe can trim a banner — the second dye washes out.")
            else
                fringe = ColorOf(entry.Element :: string)
                fringeTint = TintOf(entry.Element)
            end
        else
            AddNote(`ring:{run.letter}`, `The {run.letter} ring finds no purchase on cloth — it flutters loose.`)
        end
    end

    return {
        field = solvedField,
        layers = layers,
        fringe = fringe,
        fringeTint = fringeTint,
        warTorn = warTorn,
        title = "",
        description = "",
        notes = notes,
        palette = {},
        layerCount = 1 + #layers,
    }
end

local NumberWords = {"one", "two", "three", "four", "five", "six", "seven", "eight", "nine", "ten", "eleven", "twelve"}

local function NumberWord(n: number): string
    return NumberWords[n] or tostring(n)
end

local function Cap(text: string): string
    return string.upper(string.sub(text, 1, 1)) .. string.sub(text, 2)
end

local function Article(word: string): string
    return if string.match(word, "^[aeiouAEIOU]") then "an" else "a"
end

local OrientWords = {[0] = "upright", [1] = "level", [2] = "bendwise"}
local OrientTitles = {[0] = "Paly", [1] = "Barry", [2] = "Bendy"}
local BarNames = {[0] = "pallet", [1] = "bar", [2] = "bendlet"}

local function FieldTitle(field: FieldPlan): string
    if field.bands <= 1 then
        if not field.element then
            return "Slate"
        end
        local entry = Tinctures[field.element]
        return if entry then entry.Field else Cap(string.lower(field.element))
    end
    local tintA = TintOf(field.element)
    local tintB = if field.altElement then TintOf(field.altElement) else "dusk"
    return `{OrientTitles[field.orientation]} of {NumberWord(field.bands)}, {tintA} and {tintB}`
end

local function FieldSentence(field: FieldPlan): string
    if not field.element then
        return "The field is bare slate — no color was named."
    end
    if field.bands <= 1 then
        return `The field is {TintOf(field.element)}, hoist to fly.`
    end
    local tintB = if field.altElement then TintOf(field.altElement) else "dusk"
    return `The field breaks into {NumberWord(field.bands)} {OrientWords[field.orientation]} bands — {TintOf(field.element)} against {tintB}.`
end

local function ShieldSummary(sub: Plan): string
    local fieldWord = TintOf(sub.field.element)
    if not sub.field.element then
        fieldWord = "slate"
    end
    if sub.field.bands > 1 then
        fieldWord = `banded {fieldWord}`
    end
    local charges = #sub.layers
    if charges == 0 then
        return `{fieldWord}, plain`
    end
    return `{fieldWord}, bearing {NumberWord(charges)} {if charges == 1 then "charge" else "charges"}`
end

local function LayerWords(layer: LayerPlan): (string, string)
    if layer.kind == "bars" then
        local barName = BarNames[layer.orientation]
        if layer.count == 1 then
            local title = `{Article(layer.tint)} {barName} {layer.tint}`
            local sentence = if layer.orientation == 0
                then `{Cap(Article(layer.tint))} {layer.tint} pallet stands upright upon it.`
                elseif layer.orientation == 2 then `{Cap(Article(layer.tint))} {layer.tint} bendlet cuts across it.`
                else `{Cap(Article(layer.tint))} {layer.tint} bar lies across it.`
            return title, sentence
        end
        local title = `{NumberWord(layer.count)} {barName}s {layer.tint}`
        local sentence = if layer.orientation == 0
            then `{Cap(NumberWord(layer.count))} {layer.tint} pallets stand upright upon it.`
            elseif layer.orientation == 2 then `{Cap(NumberWord(layer.count))} {layer.tint} bendlets cut across it.`
            else `{Cap(NumberWord(layer.count))} {layer.tint} bars lie across it.`
        return title, sentence
    end

    if layer.kind == "shield" then
        return "an inescutcheon", `An inset shield rides at its heart — {ShieldSummary(layer.shield)}.`
    end

    local emblem = layer.emblem
    local tint = layer.tint
    if emblem == "chevron" then
        return `{Article(tint)} {tint} chevron`, `{Cap(Article(tint))} {tint} chevron rises from the base.`
    elseif emblem == "saltire" then
        return `{Article(tint)} {tint} saltire`, `{Cap(Article(tint))} {tint} saltire spans corner to corner.`
    elseif emblem == "cross" then
        return `{Article(tint)} {tint} cross`, `{Cap(Article(tint))} {tint} cross quarters the cloth.`
    elseif emblem == "roundel" then
        if layer.count == 1 then
            return `{Article(tint)} {tint} roundel`, `{Cap(Article(tint))} {tint} roundel rests at the heart.`
        end
        return `{NumberWord(layer.count)} {tint} roundels`, `{Cap(NumberWord(layer.count))} {tint} roundels march in file.`
    elseif emblem == "pile" then
        return `{Article(tint)} {tint} pile`, `{Cap(Article(tint))} {tint} pile drives in from the hoist.`
    elseif emblem == "crescent" then
        if layer.count == 1 then
            return `{Article(tint)} {tint} crescent`, `{Cap(Article(tint))} {tint} crescent turns its horns to the fly.`
        end
        return `{NumberWord(layer.count)} {tint} crescents`, `{Cap(NumberWord(layer.count))} {tint} crescents turn their horns to the fly.`
    elseif emblem == "wave" then
        return `{Article(tint)} {tint} wave`, `{Cap(Article(tint))} {tint} wave runs the cloth's length.`
    elseif emblem == "canton" then
        return `{Article(tint)} {tint} canton`, `{Cap(Article(tint))} {tint} canton holds the upper hoist.`
    elseif emblem == "scatter" then
        return `{NumberWord(layer.count)} {tint} stars strewn`, `{Cap(NumberWord(layer.count))} {tint} stars are strewn across the field.`
    elseif emblem == "star" then
        if layer.count == 1 then
            return `{Article(tint)} {tint} star`, `{Cap(Article(tint))} {tint} star burns at the heart.`
        end
        return `{NumberWord(layer.count)} {tint} stars`, `{Cap(NumberWord(layer.count))} {tint} stars burn in file.`
    end
    return `{Article(tint)} {tint} charge`, `{Cap(Article(tint))} {tint} charge sits upon it.`
end

local function GatherPalette(plan: Plan, palette: {string}, seen: {[string]: boolean})
    local function Add(name: string?)
        if name and name ~= "shield" and not seen[name] then
            seen[name] = true
            table.insert(palette, name)
        end
    end

    Add(TintOf(plan.field.element))
    if plan.field.bands > 1 then
        Add(if plan.field.altElement then TintOf(plan.field.altElement) else "dusk")
    end
    for _, layer in ipairs(plan.layers) do
        if layer.kind == "shield" then
            GatherPalette(layer.shield, palette, seen)
        else
            Add(layer.tint)
        end
    end
    Add(plan.fringeTint)
end

local function BuildWords(plan: Plan)
    local titleParts = {FieldTitle(plan.field)}
    local sentences = {FieldSentence(plan.field)}

    for index, layer in ipairs(plan.layers) do
        local titlePhrase, sentence = LayerWords(layer)
        if index <= 4 then
            table.insert(titleParts, titlePhrase)
        elseif index == 5 then
            table.insert(titleParts, "and more")
        end
        table.insert(sentences, sentence)
    end

    if #plan.layers == 0 then
        titleParts = {`{titleParts[1]}, plain`}
    end

    if plan.fringeTint then
        table.insert(sentences, `{Cap(plan.fringeTint)} fringe trims its free edges.`)
    end
    if plan.warTorn then
        table.insert(sentences, "The fly hangs in ribbons and the weave is stained — this banner has seen war.")
    end

    plan.title = table.concat(titleParts, ", ")
    plan.description = table.concat(sentences, " ")

    local palette = {}
    GatherPalette(plan, palette, {})
    plan.palette = palette
end

function module.Resolve(spell: Parser.Spell): Plan
    local notes: {string} = {}
    local plan = BuildPlan(spell, notes, {}, 1)
    BuildWords(plan)
    return plan
end

return module
