--#include[random]
local Parser = require("@src/spell/Parser")
local Larder = require("@src/feast/Larder")

local Rng = random.new()

local module = {}

local GlazeSet = {["~"] = true, [":"] = true, ["&"] = true, [";"] = true}
local GarnishSet = {J = true, C = true, E = true, G = true}
local CraftSet = {T = true, A = true, H = true, R = true}

local function RollInt(low: number, high: number): number
    return low + math.floor(Rng:NextNumber() * (high - low + 1) * 0.9999)
end

local Ordinals = {
    [12] = "twelfth", [13] = "thirteenth", [14] = "fourteenth", [15] = "fifteenth",
    [16] = "sixteenth", [17] = "seventeenth", [18] = "eighteenth", [19] = "nineteenth", [20] = "twentieth",
}

local function OrdinalWord(n: number): string
    return Ordinals[n] or `{n}th`
end

local function NewFeastPot()
    return {
        Heat = 0,
        Chill = 0,
        Candles = 0,
        Card = nil :: string?,
        CardExtra = false,
        Scraps = {},
        ScrapOrder = {},
    }
end

local function AddScrap(feast, letter: string)
    if not feast.Scraps[letter] then
        feast.Scraps[letter] = true
        table.insert(feast.ScrapOrder, letter)
    end
end

local function ProcessRuns(runs, feast, apply)
    for index, run in ipairs(runs) do
        local letter = run.letter
        if letter == "$" then
            local text = ""
            for rest = index + 1, #runs do
                local tail = runs[rest]
                if tail.letter ~= "$" then
                    text ..= string.rep(tail.letter, tail.count)
                end
            end
            if feast.Card then
                feast.CardExtra = true
            else
                feast.Card = text
            end
            return
        elseif letter == "^" then
            feast.Heat += run.count
        elseif letter == "-" then
            feast.Chill += run.count
        elseif letter == "'" then
            feast.Candles += run.count
        else
            apply(letter, run.count)
        end
    end
end

local function FlattenCircle(circle: Parser.Spell)
    local clusters = {}
    local folded = false
    local function Walk(layer: Parser.Spell, root: boolean)
        if #layer.rings > 0 then
            table.insert(clusters, layer.rings)
        end
        for _, part in ipairs(layer.parts) do
            if part.kind == "spell" then
                folded = true
                Walk(part :: Parser.Spell, false)
            else
                table.insert(clusters, (part :: Parser.Group).runs)
            end
        end
    end
    Walk(circle, true)
    local total = 0
    local glazeOnly = true
    for _, runs in ipairs(clusters) do
        for _, run in ipairs(runs) do
            total += run.count
            if not GlazeSet[run.letter] then
                glazeOnly = false
            end
        end
    end
    return {
        Clusters = clusters,
        Folded = folded,
        Empty = total == 0,
        GlazeOnly = glazeOnly and total > 0,
        Unstable = circle.unstable,
    }
end

local function NewEntreePot()
    return {
        Mains = {},
        MainOrder = {},
        Glazes = {},
        GlazeOrder = {},
        Garnish = {},
        Craft = {},
        Spit = 0,
        Slices = 0,
        Pepper = 0,
        Salt = 0,
        Taint = 0,
        Hours = 0,
        HoursWritten = false,
        Touched = false,
    }
end

local function AddCounted(map, order, letter: string, count: number)
    if not map[letter] then
        table.insert(order, letter)
    end
    map[letter] = (map[letter] or 0) + count
end

local function RankCounted(map, order)
    local ranked = {}
    for index, letter in ipairs(order) do
        table.insert(ranked, {Letter = letter, Count = map[letter], Order = index})
    end
    table.sort(ranked, function(a, b)
        if a.Count == b.Count then
            return a.Order < b.Order
        end
        return a.Count > b.Count
    end)
    return ranked
end

local function MakeEntreeApply(pot, feast)
    return function(letter: string, count: number)
        pot.Touched = true
        if string.match(letter, "%d") then
            pot.Hours += (tonumber(letter) :: number) * count
            pot.HoursWritten = true
        elseif letter == "%" then
            pot.Taint += count
        elseif GlazeSet[letter] then
            AddCounted(pot.Glazes, pot.GlazeOrder, letter, count)
        elseif GarnishSet[letter] then
            pot.Garnish[letter] = (pot.Garnish[letter] or 0) + count
        elseif CraftSet[letter] then
            pot.Craft[letter] = (pot.Craft[letter] or 0) + count
        elseif letter == "(" or letter == ")" then
            pot.Spit += count
        elseif letter == "/" then
            pot.Slices += count
        elseif letter == "." then
            pot.Pepper += count
        elseif letter == "," then
            pot.Salt += count
        elseif Larder.GetEntree(letter) then
            AddCounted(pot.Mains, pot.MainOrder, letter, count)
        else
            AddScrap(feast, letter)
        end
    end
end

local function NewSidePot()
    return {
        Mains = {},
        MainOrder = {},
        Butter = 0,
        Cream = 0,
        Tossed = 0,
        Fanned = 0,
        Pepper = 0,
        Salt = 0,
        Taint = 0,
        Hours = 0,
        HoursWritten = false,
    }
end

local function MakeSideApply(pot, feast)
    return function(letter: string, count: number)
        if string.match(letter, "%d") then
            pot.Hours += (tonumber(letter) :: number) * count
            pot.HoursWritten = true
        elseif letter == "%" then
            pot.Taint += count
        elseif letter == "~" then
            pot.Butter += count
        elseif letter == "&" then
            pot.Cream += count
        elseif letter == "(" or letter == ")" then
            pot.Tossed += count
        elseif letter == "/" then
            pot.Fanned += count
        elseif letter == "." then
            pot.Pepper += count
        elseif letter == "," then
            pot.Salt += count
        elseif Larder.GetSide(letter) then
            AddCounted(pot.Mains, pot.MainOrder, letter, count)
        else
            AddScrap(feast, letter)
        end
    end
end

local function NewBreadPot()
    return {
        Shapes = {},
        ShapeOrder = {},
        Flour = nil :: string?,
        FlourExtra = false,
        Cuts = 0,
        Seeds = 0,
        Gloss = 0,
        Salt = 0,
        Pepper = 0,
        Rosemary = 0,
        Crock = 0,
        Taint = 0,
        Hours = 0,
        HoursWritten = false,
    }
end

local function MakeBreadApply(pot, feast)
    return function(letter: string, count: number)
        if string.match(letter, "%d") then
            pot.Hours += (tonumber(letter) :: number) * count
            pot.HoursWritten = true
        elseif letter == "%" then
            pot.Taint += count
        elseif letter == "/" then
            pot.Cuts += count
        elseif Larder.Flours[letter] then
            if pot.Flour then
                pot.FlourExtra = true
            else
                pot.Flour = letter
            end
        elseif Larder.GetLoaf(letter) then
            AddCounted(pot.Shapes, pot.ShapeOrder, letter, count)
        elseif letter == "S" then
            pot.Seeds += count
        elseif letter == "~" then
            pot.Gloss += count
        elseif letter == "," then
            pot.Salt += count
        elseif letter == "." then
            pot.Pepper += count
        elseif letter == "J" then
            pot.Rosemary += count
        elseif letter == "&" then
            pot.Crock += count
        else
            AddScrap(feast, letter)
        end
    end
end

local function FightTaint(taint: number, hours: number, hoursWritten: boolean, strength: number, courseName: string, notes)
    if taint <= 0 then
        return 0, false, false
    end
    local mellow = if hoursWritten then math.floor(hours / 2) else 0
    local effective = math.max(0, taint - mellow)
    if mellow > 0 then
        if effective == 0 then
            table.insert(notes, `Whatever had turned in the {courseName} ({taint}), the hours over the fire cooked it clean away.`)
        else
            table.insert(notes, `The fire fights the taint in the {courseName} ({taint} → {effective}) — it is losing.`)
        end
    end
    if effective == 0 then
        return 0, false, false
    end
    if effective >= math.max(strength, 1) then
        table.insert(notes, `The {courseName} has turned — gray-green, and the flies have found it.`)
        return effective, false, true
    end
    table.insert(notes, `A sour whiff rides the {courseName} (taint {effective}) — eat it tonight or not at all.`)
    return effective, true, false
end

local function SolveEntree(pot, feast, notes, potluck: boolean, suffixParts)
    local record = {
        Present = false,
        Empty = true,
        Letter = nil :: string?,
        Count = 0,
        SizeTier = 1,
        Kind = "",
        Name = "",
        Prose = "",
        Filling = nil :: string?,
        Hours = nil :: number?,
        DonenessLabel = "",
        DonenessLine = "",
        DonenessField = "",
        Interior = {r = 206, g = 140, b = 120},
        ProperFire = false,
        Reignited = false,
        Mushy = false,
        Charred = false,
        BlueRare = false,
        DulledBands = false,
        Glaze = nil :: string?,
        GlazeDepth = 0,
        Garnish = pot.Garnish,
        Craft = pot.Craft,
        Spit = pot.Spit > 0,
        Slices = math.min(pot.Slices, 4),
        Pepper = pot.Pepper,
        Salt = pot.Salt,
        Whiff = false,
        Turned = false,
        Legs = 0,
    }

    if potluck then
        local letter = Larder.MainPool[RollInt(1, #Larder.MainPool)]
        pot.Mains = {}
        pot.MainOrder = {}
        AddCounted(pot.Mains, pot.MainOrder, letter, RollInt(1, 6))
        pot.Hours = RollInt(0, 11)
        pot.HoursWritten = true
        local glazeRoll = Larder.GlazePool[RollInt(1, #Larder.GlazePool)]
        pot.Glazes = {}
        pot.GlazeOrder = {}
        if glazeRoll ~= "" then
            AddCounted(pot.Glazes, pot.GlazeOrder, glazeRoll, RollInt(1, 3))
        end
        table.insert(suffixParts, `E{letter}{pot.Mains[letter]}H{pot.Hours}G{glazeRoll}`)
    end

    local ranked = RankCounted(pot.Mains, pot.MainOrder)
    local winner = ranked[1]

    if not winner then
        record.Prose = "an empty platter, garnished with hope"
        record.Name = "Empty Platter"
        record.DonenessField = "—"
        local taint, whiff, turned = FightTaint(pot.Taint, pot.Hours, pot.HoursWritten, 0, "platter", notes)
        record.Whiff = whiff
        record.Turned = turned
        return record
    end

    record.Present = true
    record.Empty = false
    local entree = Larder.GetEntree(winner.Letter) :: Larder.Entree
    record.Letter = winner.Letter
    record.Count = winner.Count
    record.Kind = entree.Kind

    local isFormat = entree.Kind == "pie" or entree.Kind == "skewer" or entree.Kind == "sausage"
    local losers = {}
    for i = 2, #ranked do
        table.insert(losers, ranked[i])
    end

    if isFormat then
        local bestMeat = nil
        for _, rival in ipairs(losers) do
            local rivalEntree = Larder.GetEntree(rival.Letter) :: Larder.Entree
            if rivalEntree.Fillable and (not bestMeat or rival.Count > (bestMeat :: any).Count) then
                bestMeat = rival
            end
        end
        if bestMeat then
            record.Filling = (bestMeat :: any).Letter
        end
        local benched = {}
        for _, rival in ipairs(losers) do
            if rival ~= bestMeat then
                table.insert(benched, (Larder.GetEntree(rival.Letter) :: Larder.Entree).Name)
            end
        end
        if #benched > 0 then
            table.insert(notes, `One centerpiece per table — the {table.concat(benched, ", ")} goes back to the larder.`)
        end
    else
        local benched = {}
        for _, rival in ipairs(losers) do
            local rivalEntree = Larder.GetEntree(rival.Letter) :: Larder.Entree
            if rivalEntree.Kind == "pie" then
                table.insert(notes, "The pie tins stay on the shelf.")
            elseif rivalEntree.Kind == "skewer" then
                table.insert(notes, "The skewer sticks stay in the drawer.")
            elseif rivalEntree.Kind == "sausage" then
                table.insert(notes, "The sausage press stays on the shelf.")
            else
                table.insert(benched, rivalEntree.Name)
            end
        end
        if #benched > 0 then
            table.insert(notes, `One centerpiece per table — the {table.concat(benched, ", ")} goes back to the larder.`)
        end
    end

    local tier = if winner.Count >= 5 then 3 elseif winner.Count >= 3 then 2 else 1
    record.SizeTier = tier

    local fillingEntree = if record.Filling then Larder.GetEntree(record.Filling :: string) else nil
    if entree.Kind == "pie" then
        record.Name = if fillingEntree then `{(fillingEntree :: Larder.Entree).TitleName} Pie` else "Meat Pie"
        record.Prose = if fillingEntree then `a pie of {(fillingEntree :: Larder.Entree).Name}, no less` else "a pie of honest mystery"
    elseif entree.Kind == "skewer" then
        local sticks = math.min(winner.Count, 4)
        record.Count = winner.Count
        record.Name = if fillingEntree then `{(fillingEntree :: Larder.Entree).TitleName} Skewers` else "Skewers"
        local what = if fillingEntree then `{(fillingEntree :: Larder.Entree).Name} skewers` else "skewers of honest mystery"
        record.Prose = `{Larder.NumberWord(sticks)} {what}, laid crosswise`
    elseif entree.Kind == "sausage" then
        local links = math.min(winner.Count, 6)
        record.Name = if fillingEntree then `{(fillingEntree :: Larder.Entree).TitleName} Links` else "Sausages"
        local what = if fillingEntree then `{(fillingEntree :: Larder.Entree).Name} links` else "links of honest mystery"
        record.Prose = `a coil of {Larder.NumberWord(links)} {what}`
    elseif entree.Kind == "noodle" then
        record.Name = "Piled Noodles"
        record.Prose = "a mounded nest of noodles, fork-twirled at the crown"
    elseif entree.Kind == "broth" then
        record.Name = "Broth Noodles"
        record.Prose = "a deep bowl of broth noodles, strands looped over the rim"
    elseif entree.Kind == "fish" then
        if winner.Count <= 2 then
            record.SizeTier = 1
            record.Name = "Fish Fillet"
            record.Prose = "a fillet of fish"
        else
            record.Name = "Whole Roast Fish"
            record.Prose = "a whole fish, head and tail and all"
        end
    elseif entree.Kind == "bird" then
        if tier == 1 then
            record.Name = "Roast Hen"
            record.Prose = "a roast hen"
        elseif tier == 2 then
            record.Name = "Roast Goose"
            record.Prose = "a roast goose"
        else
            record.Name = "Bird of Unreasonable Size"
            record.Prose = "a roast bird of unreasonable size"
        end
    else
        if tier == 1 then
            record.Name = `{entree.TitleName} Haunch`
            record.Prose = `a modest haunch of {entree.Name}`
        elseif tier == 2 then
            record.Name = `Roast {entree.TitleName}`
            record.Prose = `a full roast of {entree.Name}`
        else
            record.Name = `Whole Roast {entree.TitleName}`
            record.Prose = `a whole roast {entree.Name}`
        end
    end

    local fireEntree = entree
    local hoursWritten = pot.HoursWritten
    local hours = pot.Hours
    record.Hours = if hoursWritten then hours else nil

    local isNoodle = entree.Kind == "noodle" or entree.Kind == "broth"
    local band = Larder.GetDoneness(if hoursWritten then hours else 5)

    if isNoodle then
        if hoursWritten and hours >= 3 then
            record.Mushy = true
            record.DonenessLabel = "mush"
            record.DonenessLine = `left {Larder.NumberWord(hours)} hours over the fire — noodles want minutes, not hours, and these have gone soft past arguing`
        else
            record.DonenessLabel = "just done"
            record.DonenessLine = if hoursWritten
                then "pulled the minute they were done"
                else "tossed and served the moment they were ready"
            record.ProperFire = hoursWritten
        end
        record.Interior = entree.Crust
        record.DonenessField = record.DonenessLabel
    elseif entree.Kind == "phoenix" and hoursWritten and hours >= 12 then
        record.Reignited = true
        record.DonenessLabel = "reignited"
        record.DonenessLine = `and at the {OrdinalWord(hours)} hour the bird reignited — it refuses the insult, and glows the brighter for it`
        record.Interior = {r = 232, g = 120, b = 48}
        record.DonenessField = `reignited ({hours} hours)`
    elseif (entree.Kind == "dragon" or entree.Kind == "phoenix") and hoursWritten and hours >= 9 and hours <= 11 then
        record.ProperFire = true
        record.DonenessLabel = "its proper fire"
        record.DonenessLine = `{Larder.NumberWord(hours)} hours on the fire — what would ruin an ox merely wakes a {entree.Name}, and this one is cooked to its proper fire`
        record.Interior = entree.Flesh or band.Interior
        record.DonenessField = `its proper fire ({hours} hours)`
    else
        record.DonenessLabel = band.Label
        record.Interior = band.Interior
        if not hoursWritten then
            record.DonenessLine = "cooked to the kitchen's judgment, which is medium"
            record.DonenessField = "the kitchen's judgment"
        else
            record.DonenessLine = band.Line
            record.DonenessField = `{band.Label} ({Larder.NumberWord(hours)} {if hours == 1 then "hour" else "hours"})`
            record.ProperFire = hours >= fireEntree.Fire[1] and hours <= fireEntree.Fire[2]
            if entree.Kind == "fish" then
                if hours <= 2 then
                    record.DonenessLine = "done to flaking — it parts at the touch of a fork"
                elseif hours <= 6 then
                    record.DonenessLine = "cooked firm, still moist under the skin"
                elseif hours <= 11 then
                    record.DonenessLine = "dried to argument — it needs the wine more than you do"
                end
            end
            if band.Label == "charred" then
                record.Charred = true
            elseif hours == 0 then
                record.BlueRare = true
            end
            if entree.Kind == "dragon" and (band.Label == "well-done" or band.Label == "charred") then
                record.DulledBands = true
                table.insert(notes, "The long fire dulls the iridescent bands — a mournful sight.")
            end
        end
        if entree.Kind == "dragon" or entree.Kind == "wyvern" then
            record.Interior = if record.Charred then band.Interior else (entree.Flesh or record.Interior)
        end
    end

    local glazeRanked = RankCounted(pot.Glazes, pot.GlazeOrder)
    if #glazeRanked > 0 then
        local first = pot.GlazeOrder[1]
        record.Glaze = first
        record.GlazeDepth = pot.Glazes[first]
        if #pot.GlazeOrder > 1 then
            table.insert(notes, "One glaze coats — the rest arrive in the ewer or not at all.")
        end
    end

    if record.BlueRare and (winner.Letter == "P" or winner.Letter == "X" or winner.Letter == "W") then
        table.insert(notes, "Blue-rare — the physicker is already saddling his horse.")
    end
    if (pot.Craft.T or 0) > 0 and entree.Kind ~= "bird" and entree.Kind ~= "pie" then
        table.insert(notes, "The stuffing finds no cavity — it arrives in a quiet bowl.")
    end
    if record.Spit and isNoodle then
        table.insert(notes, "The carver stares at the noodles, then at the herald.")
    end

    local strength = winner.Count
    local taint, whiff, turned = FightTaint(pot.Taint, pot.Hours, pot.HoursWritten, strength, "entree", notes)
    record.Whiff = whiff
    record.Turned = turned

    local legs = 0
    if winner.Count >= 3 then
        legs += 1
    end
    if record.ProperFire then
        legs += 1
    end
    if record.Glaze then
        legs += 1
    end
    if (pot.Garnish.J or 0) + (pot.Garnish.C or 0) + (pot.Garnish.E or 0) + (pot.Garnish.G or 0) > 0 then
        legs += 1
    end
    if pot.Pepper > 0 or pot.Salt > 0 then
        legs += 1
    end
    local craftAny = (pot.Craft.T or 0) + (pot.Craft.A or 0) + (pot.Craft.H or 0) + (pot.Craft.R or 0) > 0
        or (record.Spit and not isNoodle)
    if craftAny then
        legs += 1
    end
    if record.Charred then
        legs -= 1
    end
    if record.BlueRare and (winner.Letter == "P" or winner.Letter == "X" or winner.Letter == "W") then
        legs -= 1
    end
    if record.Mushy then
        legs -= 1
    end
    if whiff then
        legs -= 2
    end
    record.Legs = legs

    return record
end

local function SolveSide(info, feast, notes, forceRoll: boolean, suffixParts)
    local record = {
        Present = info ~= nil,
        Real = false,
        EmptyPlate = false,
        Letter = nil :: string?,
        Count = 0,
        Vessel = "plate",
        Name = "",
        TitleName = "",
        Prose = "",
        HoursBand = "fresh",
        Butter = false,
        Cream = false,
        Tossed = false,
        Fanned = false,
        Pepper = 0,
        Salt = 0,
        Whiff = false,
        Turned = false,
        Rolled = false,
        Legs = 0,
        Field = "—",
    }
    if not info and not forceRoll then
        return record
    end

    local pot = NewSidePot()
    if info then
        for _, runs in ipairs(info.Clusters) do
            ProcessRuns(runs, feast, MakeSideApply(pot, feast))
        end
        if info.Folded then
            table.insert(notes, "A circle within the circle — the kitchen folds it into the side.")
        end
    end

    local rolled = forceRoll or (info and info.Unstable)
    if rolled then
        local letter = Larder.SidePool[RollInt(1, #Larder.SidePool)]
        pot.Mains = {}
        pot.MainOrder = {}
        AddCounted(pot.Mains, pot.MainOrder, letter, RollInt(1, 4))
        record.Rolled = true
        table.insert(suffixParts, `S{letter}{pot.Mains[letter]}`)
    end

    local ranked = RankCounted(pot.Mains, pot.MainOrder)
    local winner = ranked[1]
    record.Present = true

    if not winner then
        record.EmptyPlate = true
        record.Prose = "an empty side plate — the kitchen's little joke"
        record.Field = "an empty plate"
        return record
    end

    record.Real = true
    local side = Larder.GetSide(winner.Letter) :: Larder.SideDish
    record.Letter = winner.Letter
    record.Count = winner.Count
    record.Vessel = side.Vessel
    record.Name = side.Name
    record.TitleName = side.TitleName
    record.Butter = pot.Butter > 0
    record.Cream = pot.Cream > 0
    record.Tossed = pot.Tossed > 0
    record.Fanned = pot.Fanned > 0
    record.Pepper = pot.Pepper
    record.Salt = pot.Salt

    if #ranked > 1 then
        local benched = {}
        for i = 2, #ranked do
            table.insert(benched, (Larder.GetSide(ranked[i].Letter) :: Larder.SideDish).Name)
        end
        table.insert(notes, `One side to a plate — the {table.concat(benched, ", ")} waits in the kitchen.`)
    end

    local scorched = false
    if pot.HoursWritten then
        if pot.Hours >= 7 then
            record.HoursBand = "scorched"
            scorched = true
        elseif pot.Hours >= 4 then
            record.HoursBand = "burnished"
        elseif pot.Hours >= 1 then
            record.HoursBand = "golden"
        else
            record.HoursBand = "fresh"
        end
    end

    local taint, whiff, turned = FightTaint(pot.Taint, pot.Hours, pot.HoursWritten, winner.Count, "side", notes)
    record.Whiff = whiff
    record.Turned = turned

    local parts = {}
    if winner.Letter == "C" then
        table.insert(parts, if winner.Count >= 2 then "a crowded cheese board, one wedge already cut" else side.Prose)
    elseif winner.Count >= 2 then
        table.insert(parts, `a proper helping of {side.Prose}`)
    else
        table.insert(parts, side.Prose)
    end
    if record.Tossed then
        table.insert(parts, "tossed")
    end
    if record.Fanned then
        table.insert(parts, "knife-fanned on the plate")
    end
    if record.Butter and winner.Letter ~= "P" then
        table.insert(parts, "buttered")
    end
    if record.Cream then
        table.insert(parts, "a dollop of cream on top")
    end
    if record.Pepper > 0 then
        table.insert(parts, "dusted with cracked pepper")
    end
    if record.Salt > 0 then
        table.insert(parts, "finished with flaky salt")
    end
    if record.HoursBand == "golden" then
        table.insert(parts, `roasted {Larder.NumberWord(pot.Hours)} {if pot.Hours == 1 then "hour" else "hours"} to a golden turn`)
    elseif record.HoursBand == "burnished" then
        table.insert(parts, `roasted {Larder.NumberWord(pot.Hours)} hours, burnished at the edges`)
    elseif record.HoursBand == "scorched" then
        table.insert(parts, "scorched — the oven kept it too long")
    end
    record.Prose = table.concat(parts, ", ")

    local dressed = record.Butter or record.Cream or record.Tossed or record.Fanned
    local legs = 0
    if winner.Count >= 2 then
        legs += 1
    end
    if dressed then
        legs += 1
    end
    if record.Pepper > 0 or record.Salt > 0 then
        legs += 1
    end
    if pot.HoursWritten and pot.Hours >= 1 and pot.Hours <= 6 and side.Roastable then
        legs += 1
    end
    if scorched then
        legs -= 1
    end
    if whiff then
        legs -= 2
    end
    record.Legs = legs

    local adjective = if record.Tossed then "Tossed " elseif record.Butter then "Buttered " else ""
    record.Field = `{adjective}{side.TitleName}`
    if side.Letter == "B" and record.Butter then
        record.Field = side.TitleName
    end
    return record
end

local function SolveBread(info, feast, notes, forceRoll: boolean, suffixParts)
    local record = {
        Present = info ~= nil,
        Real = false,
        BareBoard = false,
        Shape = "O",
        ShapeName = "boule",
        RollCount = 0,
        Flour = "",
        CrustHours = nil :: number?,
        CrustBand = "golden",
        Cuts = 0,
        Burst = false,
        Deflated = false,
        Seeds = false,
        Gloss = false,
        SaltCrystals = false,
        Rosemary = false,
        Crock = false,
        Pepper = 0,
        Score = 0,
        Whiff = false,
        Turned = false,
        Rolled = false,
        Legs = 0,
        Prose = "",
        CompanionName = "",
        Field = "—",
    }
    if not info and not forceRoll then
        return record
    end

    local pot = NewBreadPot()
    if info then
        for _, runs in ipairs(info.Clusters) do
            ProcessRuns(runs, feast, MakeBreadApply(pot, feast))
        end
        if info.Folded then
            table.insert(notes, "A circle within the circle — the kitchen folds it into the bread.")
        end
    end

    local rolled = forceRoll or (info and info.Unstable)
    if rolled then
        local shape = Larder.LoafPool[RollInt(1, #Larder.LoafPool)]
        pot.Shapes = {}
        pot.ShapeOrder = {}
        AddCounted(pot.Shapes, pot.ShapeOrder, shape, if shape == "R" then RollInt(2, 5) else RollInt(1, 3))
        local flour = Larder.FlourPool[RollInt(1, #Larder.FlourPool)]
        pot.Flour = if flour == "" then nil else flour
        pot.Hours = RollInt(0, 9)
        pot.HoursWritten = true
        pot.Cuts = RollInt(0, 4)
        record.Rolled = true
        table.insert(suffixParts, `B{shape}{pot.Shapes[shape]}F{flour}H{pot.Hours}C{pot.Cuts}`)
    end

    record.Present = true
    local ranked = RankCounted(pot.Shapes, pot.ShapeOrder)
    local winner = ranked[1]
    local shapeChosen = winner ~= nil
    local flourChosen = pot.Flour ~= nil

    if not shapeChosen and not flourChosen and pot.Cuts == 0 and not pot.HoursWritten
        and pot.Seeds == 0 and pot.Gloss == 0 and pot.Salt == 0 and pot.Rosemary == 0 and pot.Crock == 0 and pot.Taint == 0 then
        record.BareBoard = true
        record.Prose = "a bare board, dusted with flour"
        record.Field = "a bare board"
        return record
    end

    record.Real = true
    local shapeLetter = if winner then winner.Letter else "O"
    local loaf = Larder.GetLoaf(shapeLetter) :: Larder.Loaf
    record.Shape = shapeLetter
    record.ShapeName = loaf.Name
    record.RollCount = if shapeLetter == "R" and winner then math.min(winner.Count, 5) else 0
    record.Flour = pot.Flour or ""
    local flour = Larder.GetFlour(record.Flour)
    record.Seeds = pot.Seeds > 0
    record.Gloss = pot.Gloss > 0
    record.SaltCrystals = pot.Salt > 0
    record.Rosemary = pot.Rosemary > 0
    record.Crock = pot.Crock > 0
    record.Pepper = pot.Pepper

    if pot.FlourExtra then
        table.insert(notes, "One flour to a loaf — the second sack stays tied.")
    end
    if #ranked > 1 then
        local benched = {}
        for i = 2, #ranked do
            table.insert(benched, (Larder.GetLoaf(ranked[i].Letter) :: Larder.Loaf).Name)
        end
        table.insert(notes, `One loaf to a board — the {table.concat(benched, ", ")} stays in the oven.`)
    end

    local pale = false
    local burnt = false
    if pot.HoursWritten then
        record.CrustHours = pot.Hours
        if pot.Hours >= 9 then
            record.CrustBand = "burnt"
            burnt = true
        elseif pot.Hours >= 6 then
            record.CrustBand = "bold"
        elseif pot.Hours >= 4 then
            record.CrustBand = "amber"
        elseif pot.Hours >= 2 then
            record.CrustBand = "golden"
        else
            record.CrustBand = "pale"
            pale = true
        end
    end

    record.Cuts = pot.Cuts
    if pot.Cuts >= 5 then
        record.Deflated = true
    elseif pot.Cuts == 0 and loaf.Bursts then
        record.Burst = true
    end

    local topped = record.Seeds or record.Gloss or record.SaltCrystals or record.Rosemary or record.Crock
    local score = 5
    if shapeChosen then
        score += 1
    end
    if flourChosen then
        score += 1
    end
    if flour.Ambitious then
        score += 1
    end
    if pot.Cuts >= 1 and pot.Cuts <= 4 then
        score += 1
    end
    if pot.Cuts == 4 then
        score += 1
    end
    if pot.HoursWritten and pot.Hours >= 2 and pot.Hours <= 8 then
        score += 1
    end
    if topped then
        score += 1
    end
    if record.Burst then
        score -= 2
    end
    if pale then
        score -= 2
    end
    if burnt then
        score -= 2
    end
    record.Score = math.clamp(score, 0, 10)

    local taint, whiff, turned = FightTaint(pot.Taint, pot.Hours, pot.HoursWritten, if winner then winner.Count else 1, "bread", notes)
    record.Whiff = whiff
    record.Turned = turned

    local legs = 0
    if record.Score >= 8 then
        legs += 2
    elseif record.Score >= 6 then
        legs += 1
    elseif record.Score <= 2 then
        legs -= 1
    end
    if whiff then
        legs -= 2
    end
    record.Legs = legs

    local loafName: string
    if shapeLetter == "R" then
        loafName = `{Larder.NumberWord(math.max(record.RollCount, 1))} {flour.Name} rolls`
    elseif shapeLetter == "F" then
        loafName = `a blistered {flour.Name} flatbread`
    else
        loafName = `a {flour.Name} {loaf.Name}`
    end

    local parts = {loafName}
    if pot.Cuts == 1 then
        table.insert(parts, "cut with a single ear")
    elseif pot.Cuts == 2 then
        table.insert(parts, "cross-scored")
    elseif pot.Cuts == 3 then
        table.insert(parts, "cut three ways")
    elseif pot.Cuts == 4 then
        table.insert(parts, "scored to the wheat-stalk — the baker's showpiece")
    elseif pot.Cuts >= 5 then
        table.insert(parts, "cut half to ribbons — the loaf deflates")
    end
    if record.Seeds then
        table.insert(parts, "seeded")
    end
    if record.Gloss then
        table.insert(parts, "brushed with butter")
    end
    if record.SaltCrystals then
        table.insert(parts, "flaked with salt")
    end
    if record.Rosemary then
        table.insert(parts, "rosemary baked into the crust")
    end
    if pot.HoursWritten then
        if record.CrustBand == "pale" then
            table.insert(parts, "barely baked — dough in disguise")
        elseif record.CrustBand == "burnt" then
            table.insert(parts, `baked {Larder.NumberWord(pot.Hours)} hours to a burnt black blister — the baker looked away`)
        else
            table.insert(parts, `baked {Larder.NumberWord(pot.Hours)} {if pot.Hours == 1 then "hour" else "hours"} to {if record.CrustBand == "bold" then "a bold dark crust" elseif record.CrustBand == "amber" then "an amber crust" else "a golden crust"}`)
        end
    else
        table.insert(parts, "baked golden")
    end
    if record.Crock then
        table.insert(parts, "a crock of whipped butter on the board beside it")
    end
    record.Prose = table.concat(parts, ", ")
    if record.Burst then
        record.Prose ..= ". Unscored, it burst where it pleased — the oven forgives nothing"
    end

    local adjective = if flourChosen then `{flour.Adjective} ` elseif record.Seeds then "Seeded " else ""
    record.CompanionName = `{adjective}{loaf.TitleName}`
    record.Field = `{record.CompanionName} — {record.Score} of 10`
    return record
end

function module.Solve(spell: Parser.Spell)
    local feast = NewFeastPot()
    local entreePot = NewEntreePot()
    local notes = {}
    local lines = {}
    local suffixParts = {}
    local potluck = spell.unstable

    local entreeApply = MakeEntreeApply(entreePot, feast)
    ProcessRuns(spell.rings, feast, entreeApply)
    local circles = {}
    for _, part in ipairs(spell.parts) do
        if part.kind == "spell" then
            table.insert(circles, FlattenCircle(part :: Parser.Spell))
        else
            ProcessRuns((part :: Parser.Group).runs, feast, entreeApply)
        end
    end

    local boatInfo = nil
    local slots = {}
    for _, info in ipairs(circles) do
        if info.GlazeOnly then
            if boatInfo then
                table.insert(notes, "One ewer per table — the second waits its turn.")
            else
                boatInfo = info
            end
        else
            table.insert(slots, info)
        end
    end
    if #slots >= 3 then
        table.insert(notes, "The table seats three courses — the rest wait in the kitchen.")
    end

    local bare = not potluck and not entreePot.Touched and #circles == 0

    local entreeRecord = SolveEntree(entreePot, feast, notes, potluck, suffixParts)
    local sideRecord = SolveSide(slots[1], feast, notes, potluck, suffixParts)
    local breadRecord = SolveBread(slots[2], feast, notes, potluck, suffixParts)

    local boat = {Present = false, Letter = "~", Name = "a honey ewer"}
    if boatInfo then
        local boatPot = {Glazes = {}, GlazeOrder = {}}
        for _, runs in ipairs((boatInfo :: any).Clusters) do
            for _, run in ipairs(runs) do
                AddCounted(boatPot.Glazes, boatPot.GlazeOrder, run.letter, run.count)
            end
        end
        local ranked = RankCounted(boatPot.Glazes, boatPot.GlazeOrder)
        local glaze = Larder.GetGlaze(ranked[1].Letter) :: Larder.Glaze
        boat.Present = true
        boat.Letter = ranked[1].Letter
        boat.Name = glaze.Ewer
        if (boatInfo :: any).Folded then
            table.insert(notes, "A circle within the circle — the kitchen folds it into the ewer.")
        end
    end

    local net = feast.Heat - feast.Chill
    local marks = feast.Heat > 0 or feast.Chill > 0
    local tempKey: string
    local tempLabel: string
    local tempLine: string
    if net >= 3 then
        tempKey = "piping"
        tempLabel = "piping hot"
        tempLine = "piping hot, steam climbing off it in ribbons"
    elseif net >= 1 then
        tempKey = "steaming"
        tempLabel = "steaming"
        tempLine = "steaming"
    elseif net <= -3 then
        tempKey = "vigil"
        tempLabel = "ice-cold — a winter vigil"
        tempLine = "ice-cold — a winter vigil"
    elseif net <= -1 then
        tempKey = "cold"
        tempLabel = "served cold — a traveler's spread"
        tempLine = "cold — a traveler's spread"
    elseif marks then
        tempKey = "lukewarm"
        tempLabel = "lukewarm"
        tempLine = "lukewarm — the kitchen argued about the fire and nobody won"
    else
        tempKey = "warm"
        tempLabel = "table-warm"
        tempLine = "table-warm"
    end

    local candles = math.min(feast.Candles, 3)
    if feast.Candles >= 3 then
        table.insert(notes, "A third candle — someone is courting.")
    elseif candles == 2 then
        table.insert(notes, "Two candles burn for it.")
    end

    local card = feast.Card
    if card then
        if #(card :: string) > 10 then
            card = string.sub(card :: string, 1, 10)
            table.insert(notes, `The chalk ran short — the card reads "{card}".`)
        elseif #(card :: string) == 0 then
            card = nil
            table.insert(notes, "A blank card leans on the salt cellar — the menu stays a secret.")
        else
            table.insert(notes, `The menu card reads, in a proud hand: {card}.`)
        end
    end
    if feast.CardExtra then
        table.insert(notes, "One menu card per table — the rest kindle the fire.")
    end

    local pairingNotes = {}
    if entreeRecord.Present then
        local effectiveLetter = entreeRecord.Filling or entreeRecord.Letter
        for _, pairing in ipairs(Larder.Pairings) do
            local entreeMatch = false
            for token in string.gmatch(pairing.Entree, "[^|]+") do
                if token == entreeRecord.Letter or token == effectiveLetter then
                    entreeMatch = true
                end
            end
            if entreeMatch then
                local hit = false
                if pairing.Garnish then
                    hit = (entreePot.Garnish[pairing.Garnish] or 0) > 0
                elseif pairing.GlazeLetter then
                    hit = entreeRecord.Glaze == pairing.GlazeLetter
                elseif pairing.Side then
                    hit = sideRecord.Real and sideRecord.Letter == pairing.Side
                elseif pairing.Flour then
                    hit = breadRecord.Real and breadRecord.Flour == pairing.Flour
                elseif pairing.Loaf then
                    hit = breadRecord.Real and breadRecord.Shape == pairing.Loaf
                end
                if hit then
                    table.insert(pairingNotes, pairing.Note)
                end
            end
        end
    end
    for _, note in ipairs(pairingNotes) do
        table.insert(notes, note)
    end

    local composition = 0
    if entreeRecord.Present and sideRecord.Real and breadRecord.Real then
        composition += 2
        table.insert(notes, "A balanced table — entree, side, and bread all answer the bell.")
    end
    composition += math.min(#pairingNotes, 2)
    if card then
        composition += 1
    end
    if feast.Candles > 0 then
        composition += 1
    end
    if boat.Present then
        composition += 1
    end
    if net ~= 0 then
        composition += 1
    end

    local total = entreeRecord.Legs + sideRecord.Legs + breadRecord.Legs + composition
    local anyTurned = entreeRecord.Turned or sideRecord.Turned or breadRecord.Turned

    local realCourses = (if entreeRecord.Present then 1 else 0)
        + (if sideRecord.Real then 1 else 0)
        + (if breadRecord.Real then 1 else 0)

    local tier: Larder.Tier
    if anyTurned then
        tier = Larder.Tiers.poisoned
    elseif bare then
        tier = Larder.Tiers.bare
    else
        if total <= 2 then
            tier = Larder.Tiers.beggar
        elseif total <= 5 then
            tier = Larder.Tiers.honest
        elseif total <= 9 then
            tier = Larder.Tiers.hearty
        elseif total <= 13 then
            tier = Larder.Tiers.lord
        else
            tier = Larder.Tiers.ages
        end
        local cap = 5
        if realCourses <= 1 then
            cap = 2
        elseif realCourses == 2 then
            cap = 3
        end
        if entreeRecord.Empty then
            cap = math.min(cap, 2)
        end
        if tier.Rank > cap then
            for _, candidate in pairs(Larder.Tiers) do
                if candidate.Rank == cap then
                    tier = candidate
                end
            end
            table.insert(notes, "A lord's table demands a full table.")
        end
    end

    local goblets = 0
    if tier.Key == "lord" then
        goblets = 1
    elseif tier.Key == "ages" then
        goblets = 2
    end
    local renderCandles = math.max(1, candles)
    if tier.Key == "ages" then
        renderCandles = math.max(renderCandles, 2)
    end

    local seats = 0
    local seatsLabel = "nobody"
    if not bare then
        local additional = (if sideRecord.Real then 1 else 0) + (if breadRecord.Real then 1 else 0)
        seats = math.min(1 + entreeRecord.Count + 2 * additional, 12)
        local word = Larder.NumberWord(seats)
        seatsLabel = if seats >= 8 then `a hall of {word}` else word
    end

    local donenessPrefix = ""
    if entreeRecord.DonenessLabel == "overdone" then
        donenessPrefix = "Overdone "
    elseif entreeRecord.Charred then
        donenessPrefix = "Charred "
    end
    local glazeAdjective = ""
    if entreeRecord.Glaze then
        glazeAdjective = `{(Larder.GetGlaze(entreeRecord.Glaze :: string) :: Larder.Glaze).Adjective} `
    end
    local entreeTitle = `{donenessPrefix}{glazeAdjective}{entreeRecord.Name}`

    local companion = nil :: string?
    if breadRecord.Real then
        companion = breadRecord.CompanionName
    elseif sideRecord.Real then
        local adjective = if sideRecord.Tossed then "Tossed " else ""
        companion = `{adjective}{sideRecord.TitleName}`
    end

    local title: string
    if bare then
        title = "A Bare Table"
    elseif anyTurned then
        title = `A Poisoned Banquet: {entreeTitle}`
    elseif companion then
        title = `{tier.Label}: {entreeTitle} with {companion}`
    else
        title = `{tier.Label}: {entreeTitle}, Alone`
    end
    if potluck and not bare and not anyTurned then
        title = `A Potluck: {entreeTitle}{if companion then ` with {companion}` else ""}`
    end

    if bare then
        table.insert(lines, "Candles lit for nobody; the kitchen sends its regrets.")
        if net > 0 then
            table.insert(notes, "The hall is warm, at least.")
        end
    else
        if potluck then
            table.insert(lines, "The neighbors brought what they brought.")
        end

        local first = {}
        local lone = not sideRecord.Present and not breadRecord.Present
        local opener = if lone and entreeRecord.Present
            then "The first course enters, and it is also the last: "
            else "The first course enters: "
        table.insert(first, entreeRecord.Prose)
        if entreeRecord.Glaze then
            table.insert(first, (Larder.GetGlaze(entreeRecord.Glaze :: string) :: Larder.Glaze).Prose)
        end
        if (entreePot.Craft.H or 0) > 0 then
            table.insert(first, "smoked over orchard wood")
        end
        if (entreePot.Craft.A or 0) > 0 then
            table.insert(first, "studded with cloves and anise")
        end
        if entreeRecord.Spit and entreeRecord.Kind ~= "noodle" and entreeRecord.Kind ~= "broth" then
            table.insert(first, "spit-turned to an even char")
        end
        if entreeRecord.Present then
            table.insert(first, entreeRecord.DonenessLine)
        end
        if (entreePot.Craft.R or 0) > 0 then
            table.insert(first, "resting in its own jus")
        end
        if (entreePot.Craft.T or 0) > 0 and entreeRecord.Kind == "bird" then
            table.insert(first, "stuffing at the cavity")
        end
        local garnishBits = {}
        for _, letter in ipairs({"J", "C", "E", "G"}) do
            if (entreePot.Garnish[letter] or 0) > 0 then
                local bit = Larder.GarnishNames[letter]
                if letter == "E" and entreeRecord.SizeTier == 3 and (entreeRecord.Letter == "P" or entreeRecord.Letter == "X") then
                    bit = "a roast apple set in its mouth"
                end
                table.insert(garnishBits, bit)
            end
        end
        for _, bit in ipairs(garnishBits) do
            table.insert(first, bit)
        end
        if entreeRecord.Pepper > 0 then
            table.insert(first, "dusted with cracked pepper")
        end
        if entreeRecord.Salt > 0 then
            table.insert(first, "finished with flaky salt")
        end
        if entreeRecord.Slices > 0 then
            table.insert(first, if entreeRecord.Slices == 1 then "one slice already carved and fanned" else `{Larder.NumberWord(entreeRecord.Slices)} slices carved and fanned`)
        end
        if boat.Present then
            table.insert(first, `{boat.Name} riding beside it`)
        end
        table.insert(lines, `{opener}{table.concat(first, ", ")}.`)

        if lone then
            if entreeRecord.Present then
                table.insert(lines, "No side, no bread — a hunter's supper.")
            end
        else
            if sideRecord.Real or sideRecord.EmptyPlate then
                table.insert(lines, `Beside it, {sideRecord.Prose}.`)
            elseif not sideRecord.Present and breadRecord.Present then
                table.insert(lines, "No side leaves the kitchen — the platter stands alone on its half of the table.")
            end
            if breadRecord.Real then
                local signed = if breadRecord.Score >= 9 then ", and the baker signs it" else ""
                table.insert(lines, `And from the ovens, {breadRecord.Prose}. The baker's score: {breadRecord.Score} of 10{signed}.`)
            elseif breadRecord.BareBoard then
                table.insert(lines, "And from the ovens, nothing — a bare board, dusted with flour, holds the bread's place.")
            elseif sideRecord.Present then
                table.insert(lines, "No bread came from the ovens — its place at the board stays bare.")
            end
        end

        table.insert(lines, `The table is set {tempLine}, and seats {seatsLabel}.`)
    end
    table.insert(lines, tier.Verdict)

    table.sort(feast.ScrapOrder)
    if #feast.ScrapOrder > 0 then
        table.insert(notes, `The kitchen cannot place {table.concat(feast.ScrapOrder, ", ")} — back to the larder it goes.`)
    end
    if potluck then
        table.insert(notes, "A potluck — every sitting comes up different.")
    end

    local rolledSuffix = if #suffixParts > 0 then `|{table.concat(suffixParts, "|")}` else ""

    return {
        Entree = entreeRecord,
        Side = sideRecord,
        Bread = breadRecord,
        Boat = boat,
        Bare = bare,
        Potluck = potluck,
        Poisoned = anyTurned,
        TempKey = tempKey,
        TempLabel = tempLabel,
        Net = net,
        Candles = renderCandles,
        CandlesWritten = candles,
        Goblets = goblets,
        MenuCard = card,
        Composition = composition,
        Total = total,
        Tier = tier,
        Title = title,
        Lines = lines,
        Notes = notes,
        Scraps = feast.ScrapOrder,
        Seats = seats,
        SeatsLabel = seatsLabel,
        Seed = spell.raw .. rolledSuffix,
        Menu = spell.raw,
        EntreeField = if entreeRecord.Present
            then `{entreeRecord.Name}{if entreeRecord.Glaze then ` — {string.lower((Larder.GetGlaze(entreeRecord.Glaze :: string) :: Larder.Glaze).Adjective)}` else ""}{if entreeRecord.Hours then `, {entreeRecord.Hours} {if entreeRecord.Hours == 1 then "hour" else "hours"}` else ""}`
            else (if bare then "—" else "an empty platter"),
        SideField = sideRecord.Field,
        BreadField = breadRecord.Field,
        DonenessField = entreeRecord.DonenessField,
    }
end

return module
