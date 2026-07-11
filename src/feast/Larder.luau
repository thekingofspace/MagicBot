export type RGB = {r: number, g: number, b: number}

export type Entree = {
    Letter: string,
    Name: string,
    TitleName: string,
    Kind: string,
    Fire: {number},
    Fillable: boolean,
    Crust: RGB,
    Flesh: RGB?,
}

export type Glaze = {
    Letter: string,
    Name: string,
    Adjective: string,
    Ewer: string,
    Prose: string,
    Color: RGB,
    Pool: RGB,
}

export type SideDish = {
    Letter: string,
    Name: string,
    TitleName: string,
    Vessel: string,
    Roastable: boolean,
    Prose: string,
}

export type Loaf = {
    Letter: string,
    Name: string,
    TitleName: string,
    Bursts: boolean,
}

export type Flour = {
    Letter: string,
    Name: string,
    Adjective: string,
    Crust: RGB,
    Crumb: RGB,
    Ambitious: boolean,
}

export type Doneness = {
    Min: number,
    Max: number,
    Label: string,
    Interior: RGB,
    Line: string,
}

export type Tier = {
    Key: string,
    Label: string,
    Verdict: string,
    Color: RGB,
    Rank: number,
}

local module = {}

module.Entrees = {
    B = {Letter = "B", Name = "beef", TitleName = "Beef", Kind = "meat", Fire = {3, 4}, Fillable = true, Crust = {r = 96, g = 48, b = 30}},
    P = {Letter = "P", Name = "pork", TitleName = "Pork", Kind = "meat", Fire = {7, 8}, Fillable = true, Crust = {r = 198, g = 140, b = 74}},
    L = {Letter = "L", Name = "lamb", TitleName = "Lamb", Kind = "meat", Fire = {3, 4}, Fillable = true, Crust = {r = 110, g = 62, b = 34}},
    M = {Letter = "M", Name = "mutton", TitleName = "Mutton", Kind = "meat", Fire = {7, 8}, Fillable = true, Crust = {r = 134, g = 104, b = 84}},
    X = {Letter = "X", Name = "boar", TitleName = "Boar", Kind = "meat", Fire = {7, 8}, Fillable = true, Crust = {r = 52, g = 36, b = 28}},
    V = {Letter = "V", Name = "venison", TitleName = "Venison", Kind = "meat", Fire = {1, 2}, Fillable = true, Crust = {r = 76, g = 34, b = 32}},
    U = {Letter = "U", Name = "rabbit", TitleName = "Rabbit", Kind = "meat", Fire = {5, 6}, Fillable = true, Crust = {r = 190, g = 150, b = 104}},
    W = {Letter = "W", Name = "roast bird", TitleName = "Bird", Kind = "bird", Fire = {7, 8}, Fillable = true, Crust = {r = 202, g = 132, b = 54}},
    F = {Letter = "F", Name = "fish", TitleName = "Fish", Kind = "fish", Fire = {1, 2}, Fillable = true, Crust = {r = 196, g = 152, b = 96}},
    D = {Letter = "D", Name = "dragon", TitleName = "Dragon", Kind = "dragon", Fire = {9, 11}, Fillable = true, Crust = {r = 58, g = 72, b = 78}, Flesh = {r = 226, g = 168, b = 176}},
    Y = {Letter = "Y", Name = "wyvern", TitleName = "Wyvern", Kind = "wyvern", Fire = {7, 8}, Fillable = true, Crust = {r = 84, g = 96, b = 58}, Flesh = {r = 198, g = 176, b = 150}},
    ["!"] = {Letter = "!", Name = "phoenix", TitleName = "Phoenix", Kind = "phoenix", Fire = {9, 11}, Fillable = true, Crust = {r = 216, g = 148, b = 44}},
    ["*"] = {Letter = "*", Name = "shadow-beast", TitleName = "Shadow-Beast", Kind = "shadow", Fire = {0, 2}, Fillable = true, Crust = {r = 30, g = 26, b = 36}, Flesh = {r = 52, g = 42, b = 64}},
    O = {Letter = "O", Name = "piled noodles", TitleName = "Piled Noodles", Kind = "noodle", Fire = {0, 2}, Fillable = false, Crust = {r = 224, g = 196, b = 138}},
    I = {Letter = "I", Name = "broth noodles", TitleName = "Broth Noodles", Kind = "broth", Fire = {0, 2}, Fillable = false, Crust = {r = 224, g = 196, b = 138}},
    Q = {Letter = "Q", Name = "meat pie", TitleName = "Pie", Kind = "pie", Fire = {5, 6}, Fillable = false, Crust = {r = 206, g = 156, b = 88}},
    K = {Letter = "K", Name = "skewers", TitleName = "Skewers", Kind = "skewer", Fire = {3, 4}, Fillable = false, Crust = {r = 120, g = 66, b = 38}},
    S = {Letter = "S", Name = "sausages", TitleName = "Sausages", Kind = "sausage", Fire = {5, 6}, Fillable = false, Crust = {r = 152, g = 74, b = 46}},
} :: {[string]: Entree}

module.Glazes = {
    ["~"] = {
        Letter = "~", Name = "honey", Adjective = "Honey-Glazed", Ewer = "a honey ewer",
        Prose = "lacquered in honey", Color = {r = 236, g = 178, b = 64}, Pool = {r = 188, g = 130, b = 36},
    },
    [":"] = {
        Letter = ":", Name = "red-wine reduction", Adjective = "Wine-Glazed", Ewer = "a wine jus",
        Prose = "draped in a red-wine reduction", Color = {r = 106, g = 26, b = 44}, Pool = {r = 74, g = 18, b = 32},
    },
    ["&"] = {
        Letter = "&", Name = "cream sauce", Adjective = "Cream-Sauced", Ewer = "a cream boat",
        Prose = "ribboned with cream sauce", Color = {r = 244, g = 238, b = 222}, Pool = {r = 226, g = 216, b = 194},
    },
    [";"] = {
        Letter = ";", Name = "ember glaze", Adjective = "Ember-Glazed", Ewer = "an ember oil",
        Prose = "lacquered in ember glaze", Color = {r = 198, g = 62, b = 30}, Pool = {r = 140, g = 40, b = 20},
    },
} :: {[string]: Glaze}

module.Sides = {
    R = {Letter = "R", Name = "roasted roots", TitleName = "Roasted Roots", Vessel = "plate", Roastable = true, Prose = "roasted roots — carrot batons, parsnip wedges, and beet halves charred at the tips"},
    P = {Letter = "P", Name = "mashed potatoes", TitleName = "Mashed Potatoes", Vessel = "bowl", Roastable = true, Prose = "mashed potatoes, a pool of butter melting in the crater"},
    G = {Letter = "G", Name = "rice", TitleName = "Rice", Vessel = "bowl", Roastable = true, Prose = "rice, domed smooth in its bowl"},
    S = {Letter = "S", Name = "salad", TitleName = "Salad", Vessel = "wood", Roastable = false, Prose = "torn greens in a wooden bowl"},
    C = {Letter = "C", Name = "a cheese board", TitleName = "Cheese Board", Vessel = "board", Roastable = false, Prose = "a cheese board, one wedge already cut"},
    E = {Letter = "E", Name = "soft-boiled eggs", TitleName = "Eggs", Vessel = "plate", Roastable = true, Prose = "soft-boiled eggs, halved yolk-up"},
    F = {Letter = "F", Name = "seasonal fruits", TitleName = "Seasonal Fruits", Vessel = "bowl", Roastable = false, Prose = "seasonal fruits, grapes draped over the rim"},
    M = {Letter = "M", Name = "buttered mushrooms", TitleName = "Buttered Mushrooms", Vessel = "plate", Roastable = true, Prose = "buttered mushrooms, caps glossy and piled"},
    B = {Letter = "B", Name = "buttered greens", TitleName = "Buttered Greens", Vessel = "plate", Roastable = true, Prose = "buttered greens folded in dark ribbons"},
    O = {Letter = "O", Name = "roasted onions", TitleName = "Roasted Onions", Vessel = "plate", Roastable = true, Prose = "roasted onions, caramelized to the rings"},
    L = {Letter = "L", Name = "pickles", TitleName = "Pickles", Vessel = "plate", Roastable = false, Prose = "bumpy green pickles"},
} :: {[string]: SideDish}

module.Loaves = {
    O = {Letter = "O", Name = "boule", TitleName = "Boule", Bursts = true},
    I = {Letter = "I", Name = "baguette", TitleName = "Baguette", Bursts = true},
    B = {Letter = "B", Name = "plait", TitleName = "Plait", Bursts = true},
    R = {Letter = "R", Name = "rolls", TitleName = "Rolls", Bursts = false},
    F = {Letter = "F", Name = "flatbread", TitleName = "Flatbread", Bursts = false},
} :: {[string]: Loaf}

module.WheatFlour = {
    Letter = "", Name = "wheat", Adjective = "Wheat",
    Crust = {r = 196, g = 158, b = 108}, Crumb = {r = 226, g = 202, b = 160}, Ambitious = false,
} :: Flour

module.Flours = {
    W = {Letter = "W", Name = "white", Adjective = "White", Crust = {r = 222, g = 190, b = 138}, Crumb = {r = 238, g = 228, b = 208}, Ambitious = false},
    Y = {Letter = "Y", Name = "rye", Adjective = "Rye", Crust = {r = 124, g = 90, b = 60}, Crumb = {r = 168, g = 138, b = 104}, Ambitious = false},
    ["*"] = {Letter = "*", Name = "charcoal", Adjective = "Charcoal", Crust = {r = 52, g = 48, b = 50}, Crumb = {r = 92, g = 88, b = 92}, Ambitious = true},
    ["!"] = {Letter = "!", Name = "golden saffron", Adjective = "Saffron", Crust = {r = 232, g = 186, b = 80}, Crumb = {r = 244, g = 214, b = 116}, Ambitious = true},
} :: {[string]: Flour}

module.DonenessBands = {
    {Min = 0, Max = 0, Label = "blue-rare", Interior = {r = 132, g = 36, b = 58}, Line = "shown the fire and taken away again — it remembers the field"},
    {Min = 1, Max = 2, Label = "rare", Interior = {r = 178, g = 42, b = 52}, Line = "cooked rare — the knife blushes"},
    {Min = 3, Max = 4, Label = "medium-rare", Interior = {r = 204, g = 96, b = 102}, Line = "cooked medium-rare — the cook's pride and the carver's mercy"},
    {Min = 5, Max = 6, Label = "medium", Interior = {r = 206, g = 140, b = 120}, Line = "cooked to the middle of the argument"},
    {Min = 7, Max = 8, Label = "well-done", Interior = {r = 150, g = 116, b = 92}, Line = "cooked through, no doubts left in it"},
    {Min = 9, Max = 11, Label = "overdone", Interior = {r = 128, g = 110, b = 96}, Line = "held too long over the fire — it apologizes with every bite"},
    {Min = 12, Max = 999, Label = "charred", Interior = {r = 44, g = 36, b = 30}, Line = "charred — the fire won"},
} :: {Doneness}

module.Tiers = {
    poisoned = {Key = "poisoned", Label = "A Poisoned Banquet", Verdict = "A poisoned banquet — the flies were seated first. Burn the tablecloth and start again.", Color = {r = 112, g = 118, b = 76}, Rank = 0},
    bare = {Key = "bare", Label = "A Bare Table", Verdict = "A bare table — candles lit for nobody; the kitchen sends its regrets.", Color = {r = 110, g = 70, b = 34}, Rank = 0},
    beggar = {Key = "beggar", Label = "A Beggar's Plate", Verdict = "A beggar's plate — eaten standing, and quickly, before anyone asks after it.", Color = {r = 110, g = 106, b = 100}, Rank = 1},
    honest = {Key = "honest", Label = "An Honest Supper", Verdict = "An honest supper — no herald needed; the food speaks in a plain voice and tells no lies.", Color = {r = 138, g = 102, b = 62}, Rank = 2},
    hearty = {Key = "hearty", Label = "A Hearty Spread", Verdict = "A hearty spread — elbows on the table, and no one leaves before the last of it.", Color = {r = 184, g = 115, b = 51}, Rank = 3},
    lord = {Key = "lord", Label = "A Lord's Table", Verdict = "A lord's table — the hall falls quiet as the platters pass, and the fires burn taller for it.", Color = {r = 212, g = 164, b = 52}, Rank = 4},
    ages = {Key = "ages", Label = "A Feast for the Ages", Verdict = "A feast for the ages — the bards will argue over this menu for a hundred winters.", Color = {r = 240, g = 196, b = 88}, Rank = 5},
} :: {[string]: Tier}

module.Pairings = {
    {Entree = "F", Garnish = "C", Note = "Fish and citrus — the coast pairing, written in the old menus."},
    {Entree = "P", Garnish = "E", Note = "Pork and roast apples — the orchard pairing, written in the old menus."},
    {Entree = "X", Garnish = "E", Note = "Boar and roast apples — the orchard pairing, written in the old menus."},
    {Entree = "D", GlazeLetter = ";", Note = "Dragon under ember glaze — fighting fire with fire."},
    {Entree = "D", Flour = "*", Note = "Dragon beside charcoal bread — the fireproof supper."},
    {Entree = "*", Flour = "*", Note = "Shadow-beast beside charcoal bread — a table dressed for midnight."},
    {Entree = "!", Flour = "!", Note = "Phoenix beside saffron bread — gold answers fire."},
    {Entree = "B", Side = "P", Note = "Beef and mash — the drover's pairing, written in the old menus."},
    {Entree = "L", Side = "R", Note = "Lamb and roots — the shepherd's pairing, written in the old menus."},
    {Entree = "M", Side = "R", Note = "Mutton and roots — the shepherd's pairing, written in the old menus."},
    {Entree = "I", Side = "E", Note = "Broth noodles and eggs — the night-market pairing, written in the old menus."},
    {Entree = "V", GlazeLetter = ":", Note = "Venison under a wine reduction — the hunt pairing, written in the old menus."},
    {Entree = "S", Loaf = "R", Note = "Sausages and rolls — the fairground pairing, written in the old menus."},
}

module.GarnishNames = {
    J = "herb sprigs tucked close",
    C = "lemon wheels leaned along the platter rim",
    E = "roast apples burnished around it",
    G = "caramelized garlic bulbs at its base",
}

module.MainPool = {"B", "P", "L", "M", "X", "V", "U", "W", "F", "D", "Y", "!", "*", "O", "I", "Q", "K", "S"}
module.SidePool = {"R", "P", "G", "S", "C", "E", "F", "M", "B", "O", "L"}
module.LoafPool = {"O", "I", "B", "R", "F"}
module.FlourPool = {"", "W", "Y", "*", "!"}
module.GlazePool = {"", "~", ":", "&", ";"}

local NumberWords = {"one", "two", "three", "four", "five", "six", "seven", "eight", "nine", "ten", "eleven", "twelve"}

function module.NumberWord(count: number): string
    return NumberWords[count] or tostring(count)
end

function module.GetEntree(letter: string): Entree?
    return module.Entrees[letter]
end

function module.GetGlaze(letter: string): Glaze?
    return module.Glazes[letter]
end

function module.GetSide(letter: string): SideDish?
    return module.Sides[letter]
end

function module.GetLoaf(letter: string): Loaf?
    return module.Loaves[letter]
end

function module.GetFlour(letter: string): Flour
    return module.Flours[letter] or module.WheatFlour
end

function module.GetDoneness(hours: number): Doneness
    for _, band in ipairs(module.DonenessBands) do
        if hours >= band.Min and hours <= band.Max then
            return band
        end
    end
    return module.DonenessBands[#module.DonenessBands]
end

return module
