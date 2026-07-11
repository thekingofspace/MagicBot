--#include[random]
local Parser = require("@src/spell/Parser")
local Pantry = require("@src/soup/Pantry")

-- Only the chaotic ladle ([ ] borders) rolls — every other bowl is deterministic.
local Rng = random.new()

local module = {}

export type Piece = {letter: string, count: number}

export type Side = {
    kind: "plate" | "cup" | "empty",
    letter: string?,
    count: number,
    surprise: boolean,
}

export type Dish = {
    Title: string,
    Lines: {string},
    Notes: {string},
    Stock: string?,
    StockField: string,
    Color: {r: number, g: number, b: number},
    Blend: string?,
    Ingredients: {Piece},
    TotalPieces: number,
    Heat: number,
    HeatLabel: string,
    Steam: number,
    Drops: number,
    TasteLabel: string,
    Sweet: number,
    Pepper: number,
    Cream: number,
    Stirred: number,
    Simmer: number,
    SimmerLabel: string,
    Body: number,
    BodyLabel: string,
    Spoiled: boolean,
    Taint: number,
    Mystery: boolean,
    Quality: string,
    Verdict: string,
    Serves: number,
    ServesLabel: string,
    Chef: string?,
    Side: Side?,
    Scraps: {string},
    Seed: string,
    Recipe: string,
}

type Pot = {
    stocks: {[string]: number},
    stockOrder: {[string]: number},
    nextStock: number,
    ingredients: {[string]: number},
    ingredientOrder: {string},
    taint: number,
    heat: number,
    chill: number,
    sweet: number,
    pepper: number,
    cream: number,
    stirred: number,
    simmer: number,
    thick: number,
    thin: number,
    chef: string?,
    chefExtra: boolean,
    scraps: {[string]: number},
    sides: {Side},
}

local function NewPot(): Pot
    return {
        stocks = {},
        stockOrder = {},
        nextStock = 1,
        ingredients = {},
        ingredientOrder = {},
        taint = 0,
        heat = 0,
        chill = 0,
        sweet = 0,
        pepper = 0,
        cream = 0,
        stirred = 0,
        simmer = 0,
        thick = 0,
        thin = 0,
        chef = nil,
        chefExtra = false,
        scraps = {},
        sides = {},
    }
end

local function RollInt(low: number, high: number): number
    return low + math.floor(Rng:NextNumber() * (high - low + 1) * 0.9999)
end

local function ApplyRun(pot: Pot, run: Parser.Run)
    local letter, count = run.letter, run.count

    if string.match(letter, "%d") then
        pot.simmer += tonumber(letter) :: number * count
    elseif letter == "%" then
        pot.taint += count
    elseif Pantry.GetStock(letter) then
        pot.stocks[letter] = (pot.stocks[letter] or 0) + count
        if not pot.stockOrder[letter] then
            pot.stockOrder[letter] = pot.nextStock
            pot.nextStock += 1
        end
    elseif Pantry.GetIngredient(letter) then
        if not pot.ingredients[letter] then
            table.insert(pot.ingredientOrder, letter)
        end
        pot.ingredients[letter] = (pot.ingredients[letter] or 0) + count
    elseif letter == "^" then
        pot.heat += count
    elseif letter == "-" then
        pot.chill += count
    elseif letter == "~" then
        pot.sweet += count
    elseif letter == "." then
        pot.pepper += count
    elseif letter == "&" then
        pot.cream += count
    elseif letter == "(" or letter == ")" then
        pot.stirred += count
    elseif letter == "H" then
        pot.thick += count
    elseif letter == "R" then
        pot.thin += count
    else
        pot.scraps[letter] = (pot.scraps[letter] or 0) + count
    end
end

-- A $ turns the rest of its cluster into the chef's name chalked on the
-- board — those letters are written, not cooked.
local function ProcessRuns(pot: Pot, runs: {Parser.Run})
    for index, run in ipairs(runs) do
        if run.letter == "$" then
            local text = ""
            for rest = index + 1, #runs do
                local tail = runs[rest]
                if tail.letter ~= "$" then
                    text ..= string.rep(tail.letter, tail.count)
                end
            end
            if pot.chef then
                pot.chefExtra = true
            else
                pot.chef = text
            end
            return
        end
        ApplyRun(pot, run)
    end
end

-- A nested border is a side dish: its best ingredient goes on a small plate,
-- or its best stock into a little cup. A chaotic side is the ladle's choice.
local function CollectSide(spell: Parser.Spell): Side
    local ingredients: {[string]: number} = {}
    local ingredientOrder: {string} = {}
    local stocks: {[string]: number} = {}
    local stockOrder: {string} = {}
    local surprise = spell.unstable

    local function Add(run: Parser.Run)
        if Pantry.GetIngredient(run.letter) then
            if not ingredients[run.letter] then
                table.insert(ingredientOrder, run.letter)
            end
            ingredients[run.letter] = (ingredients[run.letter] or 0) + run.count
        elseif Pantry.GetStock(run.letter) and run.letter ~= "%" then
            if not stocks[run.letter] then
                table.insert(stockOrder, run.letter)
            end
            stocks[run.letter] = (stocks[run.letter] or 0) + run.count
        end
    end

    local function Walk(layer: Parser.Spell)
        if layer.unstable then
            surprise = true
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
    end
    Walk(spell)

    if surprise then
        local letter = Pantry.MysteryIngredients[RollInt(1, #Pantry.MysteryIngredients)]
        return {kind = "plate", letter = letter, count = RollInt(1, 3), surprise = true}
    end

    local bestIngredient: string? = nil
    for _, letter in ipairs(ingredientOrder) do
        if not bestIngredient or ingredients[letter] > ingredients[bestIngredient] then
            bestIngredient = letter
        end
    end
    if bestIngredient then
        return {kind = "plate", letter = bestIngredient, count = ingredients[bestIngredient], surprise = false}
    end

    local bestStock: string? = nil
    for _, letter in ipairs(stockOrder) do
        if not bestStock or stocks[letter] > stocks[bestStock] then
            bestStock = letter
        end
    end
    if bestStock then
        return {kind = "cup", letter = bestStock, count = 1, surprise = false}
    end

    return {kind = "empty", letter = nil, count = 0, surprise = false}
end

local function Accumulate(spell: Parser.Spell, pot: Pot)
    ProcessRuns(pot, spell.rings)
    for _, part in ipairs(spell.parts) do
        if part.kind == "spell" then
            table.insert(pot.sides, CollectSide(part :: Parser.Spell))
        else
            ProcessRuns(pot, (part :: Parser.Group).runs)
        end
    end
end

local function RankStocks(pot: Pot): {{letter: string, count: number}}
    local ranked = {}
    for letter, count in pairs(pot.stocks) do
        table.insert(ranked, {letter = letter, count = count})
    end
    table.sort(ranked, function(a, b)
        if a.count == b.count then
            return pot.stockOrder[a.letter] < pot.stockOrder[b.letter]
        end
        return a.count > b.count
    end)
    return ranked
end

local function BlendRGB(a: {r: number, g: number, b: number}, b: {r: number, g: number, b: number}, t: number): {r: number, g: number, b: number}
    return {
        r = math.floor(a.r + (b.r - a.r) * t),
        g = math.floor(a.g + (b.g - a.g) * t),
        b = math.floor(a.b + (b.b - a.b) * t),
    }
end

local function PieceProse(letter: string, count: number): string
    local ingredient = Pantry.GetIngredient(letter) :: Pantry.Ingredient
    if count == 1 then
        return ingredient.One
    end
    return `{Pantry.NumberWord(count)} {ingredient.Many}`
end

local function ListProse(parts: {string}): string
    if #parts == 0 then
        return ""
    elseif #parts == 1 then
        return parts[1]
    elseif #parts == 2 then
        return `{parts[1]} and {parts[2]}`
    end
    local head = {}
    for i = 1, #parts - 1 do
        table.insert(head, parts[i])
    end
    return `{table.concat(head, ", ")}, and {parts[#parts]}`
end

function module.Solve(spell: Parser.Spell): Dish
    local pot = NewPot()
    Accumulate(spell, pot)

    local lines: {string} = {}
    local notes: {string} = {}
    local mystery = spell.unstable

    -- The chaotic ladle: hue and ingredients roll fresh with every serving.
    local rolledSuffix = ""
    if mystery then
        local stockLetter = Pantry.MysteryStocks[RollInt(1, #Pantry.MysteryStocks)]
        pot.stocks = {[stockLetter] = RollInt(3, 6)}
        pot.stockOrder = {[stockLetter] = 1}
        pot.ingredients = {}
        pot.ingredientOrder = {}
        local kinds = RollInt(2, 4)
        local pool = table.clone(Pantry.MysteryIngredients)
        for _ = 1, kinds do
            local pick = table.remove(pool, RollInt(1, #pool)) :: string
            table.insert(pot.ingredientOrder, pick)
            pot.ingredients[pick] = RollInt(1, 4)
        end
        rolledSuffix = `|{stockLetter}{pot.stocks[stockLetter]}`
        for _, letter in ipairs(pot.ingredientOrder) do
            rolledSuffix ..= `{letter}{pot.ingredients[letter]}`
        end
    end

    local ranked = RankStocks(pot)
    local base = ranked[1]
    local second = ranked[2]

    -- The half rule: a second stock joins the pot only with at least half
    -- the base's strength. A third always waits its turn.
    if base and second then
        if second.count * 2 < base.count then
            second = nil
        elseif ranked[3] then
            local third = Pantry.GetStock(ranked[3].letter) :: Pantry.Stock
            table.insert(notes, `Only two stocks fit in one pot — the {third.Name} waits its turn.`)
        end
    end

    -- Spoilage: a long simmer cooks the taint into confession.
    local mellow = math.floor(pot.simmer / 2)
    local taint = math.max(0, pot.taint - mellow)
    local spoiled = taint > 0 and (not base or taint >= base.count)
    if pot.taint > 0 and mellow > 0 then
        if taint == 0 then
            table.insert(notes, `Whatever had turned ({pot.taint}), the long simmer cooked it clean away.`)
        else
            table.insert(notes, `The simmer fights the taint ({pot.taint} → {taint}) — it is losing.`)
        end
    end
    if taint > 0 and not spoiled then
        table.insert(notes, `A sour whiff rides the steam (taint {taint}) — eat it today or not at all.`)
    end

    -- Temperature.
    local net = pot.heat - pot.chill
    local heatLabel: string
    local steam = 0
    local drops = 0
    if net >= 3 then
        heatLabel = "piping hot"
        steam = math.min(2 + net, 8)
    elseif net >= 1 then
        heatLabel = "steaming"
        steam = 1 + net
    elseif net <= -3 then
        heatLabel = "ice-cold"
        drops = math.min(12 + (-net) * 3, 28)
    elseif net <= -1 then
        heatLabel = "chilled"
        drops = 8 + (-net) * 3
    elseif pot.heat > 0 or pot.chill > 0 then
        heatLabel = "lukewarm"
    else
        heatLabel = "table-warm"
    end

    -- Ingredients, in the order they were written.
    local pieces: {Piece} = {}
    local totalPieces = 0
    for _, letter in ipairs(pot.ingredientOrder) do
        table.insert(pieces, {letter = letter, count = pot.ingredients[letter]})
        totalPieces += pot.ingredients[letter]
    end

    local body = pot.thick - pot.thin
    local chilled = net <= -1

    -- Quality, solved from the whole composition.
    local seasonMarks = (if pot.sweet > 0 then 1 else 0) + (if pot.pepper > 0 then 1 else 0)
        + (if pot.cream > 0 then 1 else 0) + (if pot.stirred > 0 then 1 else 0)
    local dishwater = (not base and totalPieces == 0)
        or (base ~= nil and base.letter == "W" and totalPieces == 0 and seasonMarks == 0 and pot.simmer == 0 and not second)
        or (base ~= nil and body <= -3 and totalPieces == 0 and seasonMarks == 0 and pot.simmer == 0)

    local score = 0
    if base then
        score += math.min(base.count, 6)
    end
    score += 2 * math.min(#pieces, 5)
    if totalPieces >= 3 and totalPieces <= 14 then
        score += 1
    elseif totalPieces > 20 then
        score -= 1
    end
    score += math.min(seasonMarks, 3)
    score += math.min(math.floor(pot.simmer / 2), 4)
    if pot.heat > 0 or pot.chill > 0 then
        score += 1
    end
    if body <= -3 then
        score -= 1
    elseif body ~= 0 then
        score += 1
    end
    if taint > 0 and not spoiled then
        score -= 4
    end

    local tier: Pantry.Tier
    if spoiled then
        tier = Pantry.Tiers.hazard
    elseif dishwater then
        tier = Pantry.Tiers.dishwater
    elseif not base then
        tier = if score <= 3 then Pantry.Tiers.poor else Pantry.Tiers.honest
    elseif score <= 3 then
        tier = Pantry.Tiers.poor
    elseif score <= 7 then
        tier = Pantry.Tiers.honest
    elseif score <= 11 then
        tier = Pantry.Tiers.hearty
    elseif score <= 16 then
        tier = Pantry.Tiers.exquisite
    else
        tier = Pantry.Tiers.legendary
    end

    -- Color: the stock's hue, cut by a blend, deepened by the simmer.
    local baseStock = if base then Pantry.GetStock(base.letter) else nil
    local secondStock = if second then Pantry.GetStock(second.letter) else nil
    local color: {r: number, g: number, b: number}
    local stockField: string
    if spoiled then
        local rancid = Pantry.GetStock("%") :: Pantry.Stock
        color = rancid.Color
        stockField = rancid.Hue
    elseif baseStock then
        color = baseStock.Color
        stockField = baseStock.Hue
        if secondStock then
            color = BlendRGB(color, secondStock.Color, 0.35)
            stockField = `{baseStock.Hue}, cut with {secondStock.Hue}`
        end
    else
        color = Pantry.WaterColor
        stockField = Pantry.WaterHue
    end
    if pot.simmer > 0 then
        color = BlendRGB(color, {r = 24, g = 14, b = 8}, math.min(pot.simmer * 0.04, 0.32))
    end
    if body < 0 then
        color = BlendRGB(color, {r = 235, g = 235, b = 230}, math.min(-body * 0.09, 0.27))
    end

    -- The dish name.
    local fishCount = pot.ingredients.F or 0
    local noodleCount = (pot.ingredients.O or 0) + (pot.ingredients.I or 0)
    local noun = "Soup"
    if body > 0 then
        noun = "Stew"
    elseif body <= -3 then
        noun = "Broth"
    elseif body < 0 then
        noun = "Consommé"
    elseif pot.cream > 0 and fishCount > 0 then
        noun = "Bisque"
    elseif pot.cream > 0 then
        noun = "Velouté"
    elseif chilled and base and (base.letter == "J" or base.letter == "B") then
        noun = "Gazpacho"
    elseif noodleCount >= 3 then
        noun = "Noodle Soup"
    elseif base and base.letter == "W" and totalPieces == 0 then
        noun = "Broth"
    end

    local title: string
    if spoiled then
        title = `Rancid {noun}`
    elseif dishwater then
        title = "Dishwater"
    elseif mystery then
        title = `Mystery {noun}`
    else
        local stockName = if baseStock then baseStock.Name else nil
        if stockName then
            title = `{stockName} {noun}`
        else
            title = `Watery {noun}`
        end
        if body <= -3 then
            title = `Thin {title}`
        end
        if chilled and noun ~= "Gazpacho" then
            title = `Chilled {title}`
        end
        if tier == Pantry.Tiers.legendary then
            title = `Legendary {title}`
        end
    end

    -- The viscosity dial: watery → thin → light → honest → thick → spoon-standing → stew-solid.
    local bodyLabel = "honest"
    if body <= -3 then
        bodyLabel = "watery"
    elseif body == -2 then
        bodyLabel = "thin"
    elseif body == -1 then
        bodyLabel = "light"
    elseif body == 1 then
        bodyLabel = "thick"
    elseif body == 2 then
        bodyLabel = "spoon-standing"
    elseif body >= 3 then
        bodyLabel = "stew-solid"
    end

    -- Readout lines — solved, never raw.
    if mystery then
        local rolled = Pantry.GetStock((base :: {letter: string, count: number}).letter) :: Pantry.Stock
        table.insert(lines, `The chaotic ladle serves what it will — today it dredges up {string.lower(rolled.Name)} stock, {rolled.Hue}.`)
    elseif spoiled then
        local rancid = Pantry.GetStock("%") :: Pantry.Stock
        table.insert(lines, rancid.Prose)
    elseif baseStock then
        table.insert(lines, baseStock.Prose)
        if secondStock then
            table.insert(notes, `Cut with a {string.lower(secondStock.Name)} stock — the two get along.`)
        end
    elseif totalPieces > 0 then
        table.insert(lines, "No stock to speak of — just water doing its best impression of soup.")
    else
        table.insert(lines, "Plain water, ladled with conviction and served as soup.")
    end

    if totalPieces > 0 then
        local parts = {}
        for _, piece in ipairs(pieces) do
            table.insert(parts, PieceProse(piece.letter, piece.count))
        end
        local opener = if spoiled then "Adrift in it, unfortunately:" elseif mystery then "The ladle brought up" else "Adrift in it:"
        table.insert(lines, `{opener} {ListProse(parts)}.`)
    elseif base then
        table.insert(lines, "Nothing floats in it — the broth stands alone.")
    end

    if heatLabel == "piping hot" then
        table.insert(lines, "Served piping hot — steam climbs off it in ribbons.")
    elseif heatLabel == "steaming" then
        table.insert(lines, "Served steaming hot, the first spoonful a small act of courage.")
    elseif heatLabel == "chilled" then
        table.insert(lines, "Served chilled — the bowl sweats cold beads onto the table.")
    elseif heatLabel == "ice-cold" then
        table.insert(lines, "Served ice-cold, condensation running down the ceramic in little rivers.")
    elseif heatLabel == "lukewarm" then
        table.insert(lines, "Served lukewarm — the kitchen argued about the fire and nobody won.")
    else
        table.insert(lines, "Served table-warm, no ceremony about it.")
    end

    local tasteParts = {}
    local tasteShort = {}
    if pot.sweet > 0 then
        table.insert(tasteParts, "sweetened with a slow spoon of honey")
        table.insert(tasteShort, "sweet")
    end
    if pot.pepper > 2 then
        table.insert(tasteParts, "peppered until it bites back")
        table.insert(tasteShort, "peppered")
    elseif pot.pepper > 0 then
        table.insert(tasteParts, "dusted with cracked pepper")
        table.insert(tasteShort, "peppered")
    end
    if pot.cream > 0 then
        table.insert(tasteParts, "a swirl of cream drawn through the surface")
        table.insert(tasteShort, "creamed")
    end
    if pot.stirred > 0 then
        table.insert(tasteParts, "stirred to a lazy spiral")
        table.insert(tasteShort, "stirred")
    end
    if #tasteParts > 0 then
        local sentence = table.concat(tasteParts, "; ")
        table.insert(lines, `{string.upper(string.sub(sentence, 1, 1))}{string.sub(sentence, 2)}.`)
    else
        table.insert(lines, "Unseasoned — the salt sits on the table if you must.")
    end
    local tasteLabel = if #tasteShort > 0 then table.concat(tasteShort, ", ") else "unseasoned"

    local simmerLabel = "—"
    if pot.simmer > 0 then
        simmerLabel = if pot.simmer == 1 then "1 hour" else `{pot.simmer} hours`
        if pot.simmer <= 2 then
            table.insert(lines, `Given a quick simmer — {Pantry.NumberWord(pot.simmer)} {if pot.simmer == 1 then "hour" else "hours"} and straight to the table.`)
        elseif pot.simmer <= 5 then
            table.insert(lines, `Simmered {Pantry.NumberWord(pot.simmer)} hours, until the flavors stopped arguing.`)
        elseif pot.simmer <= 9 then
            table.insert(lines, `Slow-simmered {Pantry.NumberWord(pot.simmer)} hours — the pot did the thinking.`)
        else
            table.insert(lines, `Simmered {pot.simmer} hours, all day and into the night — the pot knows things now.`)
        end
    end

    if body >= 3 then
        table.insert(lines, "Stew-solid — less a soup than a landscape with gravy.")
    elseif body == 2 then
        table.insert(lines, "Thick enough to stand a spoon in.")
    elseif body == 1 then
        table.insert(lines, "Thickened to a proper stew — the ladle drags through it.")
    elseif body == -1 then
        table.insert(lines, "Light-bodied — it slips off the spoon without a second thought.")
    elseif body == -2 then
        table.insert(lines, "Drawn down to a thin consommé, clear enough to read the maker's mark through.")
    elseif body <= -3 then
        table.insert(lines, "Thinned to the edge of being water — the spoon comes up with little more than a memory of flavor.")
    end

    -- The side dish: the table fits one plate.
    local side: Side? = pot.sides[1]
    if side then
        local s = side :: Side
        if s.kind == "plate" then
            local prose = PieceProse(s.letter :: string, math.min(s.count, 5))
            if s.surprise then
                table.insert(lines, `On the side, the ladle's choice today: {prose}.`)
            else
                table.insert(lines, `On the side: a small plate of {prose}.`)
            end
        elseif s.kind == "cup" then
            local stock = Pantry.GetStock(s.letter :: string) :: Pantry.Stock
            table.insert(lines, `On the side: a little cup of {string.lower(stock.Name)} broth, for sipping between spoonfuls.`)
        else
            table.insert(lines, "On the side: an empty plate — the kitchen's little joke.")
        end
    end
    if #pot.sides > 1 then
        table.insert(notes, "The table fits one side plate — the rest wait in the kitchen.")
    end

    table.insert(lines, tier.Verdict)

    -- Serves.
    local serves = math.clamp(1 + math.floor(totalPieces / 6) + (if body > 0 then 1 else 0), 1, 5)
    local servesLabels = {"one", "two", "three", "four", "a table of five"}
    local servesLabel = servesLabels[serves]

    -- Chef and scraps.
    local chef = pot.chef
    if chef then
        if #chef > 10 then
            chef = string.sub(chef, 1, 10)
            table.insert(notes, `The chalk ran short — the board reads "{chef}".`)
        elseif #chef == 0 then
            chef = nil
            table.insert(notes, "A blank board leans by the bowl — the chef stays anonymous.")
        else
            table.insert(notes, `Chalked on the board: soup by {chef}.`)
        end
    end
    if pot.chefExtra then
        table.insert(notes, "One name fits on the board — the rest wash dishes.")
    end

    local scrapLetters = {}
    for letter in pairs(pot.scraps) do
        table.insert(scrapLetters, letter)
    end
    table.sort(scrapLetters)
    if #scrapLetters > 0 then
        table.insert(notes, `The kitchen cannot place {table.concat(scrapLetters, ", ")} — it sinks quietly to the bottom.`)
    end

    if mystery then
        table.insert(notes, "A chaotic ladle — every serving comes up different.")
    end

    return {
        Title = title,
        Lines = lines,
        Notes = notes,
        Stock = if spoiled then "%" elseif base then base.letter else nil,
        StockField = stockField,
        Color = color,
        Blend = if secondStock and not spoiled then (second :: {letter: string, count: number}).letter else nil,
        Ingredients = pieces,
        TotalPieces = totalPieces,
        Heat = net,
        HeatLabel = heatLabel,
        Steam = steam,
        Drops = drops,
        TasteLabel = tasteLabel,
        Sweet = pot.sweet,
        Pepper = pot.pepper,
        Cream = pot.cream,
        Stirred = pot.stirred,
        Simmer = pot.simmer,
        SimmerLabel = simmerLabel,
        Body = body,
        BodyLabel = bodyLabel,
        Spoiled = spoiled,
        Taint = taint,
        Mystery = mystery,
        Quality = tier.Label,
        Verdict = tier.Verdict,
        Serves = serves,
        ServesLabel = servesLabel,
        Chef = chef,
        Side = side,
        Scraps = scrapLetters,
        Seed = spell.raw .. rolledSuffix,
        Recipe = spell.raw,
    }
end

return module
