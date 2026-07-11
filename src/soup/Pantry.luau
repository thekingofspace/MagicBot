-- The soup pantry: every stock the pot can hold and every ingredient the
-- ladle can lift. Soup is humble magic — it feeds people, nothing more.

export type Stock = {
    Letter: string,
    Name: string,
    Hue: string,
    Prose: string,
    Color: {r: number, g: number, b: number},
}

export type Ingredient = {
    Letter: string,
    Name: string,
    One: string,
    Many: string,
}

export type Tier = {
    Label: string,
    Verdict: string,
}

local module = {}

module.Stocks = {
    B = {
        Letter = "B", Name = "Ember", Hue = "hearth-red tomato",
        Prose = "A hearty tomato stock, fire-warm and hearth-red — it tastes like the last hour of a long winter.",
        Color = {r = 188, g = 54, b = 38},
    },
    W = {
        Letter = "W", Name = "Clear", Hue = "clear as rainwater",
        Prose = "A clear broth, honest all the way to the bottom of the bowl.",
        Color = {r = 174, g = 196, b = 202},
    },
    G = {
        Letter = "G", Name = "Forest Mushroom", Hue = "earthy root-brown",
        Prose = "An earthy mushroom stock, root-deep and forest-dark.",
        Color = {r = 134, g = 100, b = 66},
    },
    J = {
        Letter = "J", Name = "Green Garden", Hue = "garden herb-green",
        Prose = "A green garden stock, bright with herbs torn small over the pot.",
        Color = {r = 106, g = 148, b = 58},
    },
    ["!"] = {
        Letter = "!", Name = "Golden Saffron", Hue = "lantern gold",
        Prose = "A golden chicken stock threaded with saffron — rich as a harvest evening.",
        Color = {r = 228, g = 166, b = 52},
    },
    ["'"] = {
        Letter = "'", Name = "Lavender Dream", Hue = "dreamy lavender-cream",
        Prose = "A lavender-cream stock, dreamy and faintly strange — it hums when nobody is looking.",
        Color = {r = 198, g = 174, b = 212},
    },
    ["%"] = {
        Letter = "%", Name = "Rancid", Hue = "gray-green murk",
        Prose = "Something in this pot turned days ago and has been served anyway.",
        Color = {r = 112, g = 118, b = 76},
    },
    [":"] = {
        Letter = ":", Name = "Deep Miso", Hue = "miso-deep umber",
        Prose = "A fermented stock, miso-deep — aged in the dark until it learned patience.",
        Color = {r = 130, g = 94, b = 46},
    },
    ["*"] = {
        Letter = "*", Name = "Void-Ink", Hue = "squid-ink black",
        Prose = "A void-dark stock of squid ink — light falls in and does not come back out.",
        Color = {r = 34, g = 32, b = 50},
    },
} :: {[string]: Stock}

module.WaterColor = {r = 168, g = 182, b = 188}
module.WaterHue = "plain water"

module.Ingredients = {
    O = {Letter = "O", Name = "noodle rings", One = "a noodle ring", Many = "noodle rings"},
    I = {Letter = "I", Name = "noodle strands", One = "a long noodle strand", Many = "long noodle strands"},
    D = {Letter = "D", Name = "dumplings", One = "a plump dumpling", Many = "plump dumplings"},
    F = {Letter = "F", Name = "fish", One = "a slice of fish", Many = "slices of fish"},
    C = {Letter = "C", Name = "carrot coins", One = "a carrot coin", Many = "carrot coins"},
    L = {Letter = "L", Name = "leek rings", One = "a leek ring", Many = "leek rings"},
    M = {Letter = "M", Name = "meat", One = "a chunk of stewed meat", Many = "chunks of stewed meat"},
    E = {Letter = "E", Name = "egg", One = "a soft-boiled egg half", Many = "soft-boiled egg halves"},
    A = {Letter = "A", Name = "star anise", One = "a star anise pod", Many = "star anise pods"},
    T = {Letter = "T", Name = "tofu", One = "a tofu cube", Many = "tofu cubes"},
} :: {[string]: Ingredient}

module.Tiers = {
    dishwater = {Label = "dishwater", Verdict = "Dishwater — the spoon sinks without hope."},
    poor = {Label = "poor", Verdict = "A poor bowl — it fills a stomach and apologizes the whole way down."},
    honest = {Label = "honest", Verdict = "An honest bowl — plain, warm, and welcome after a long day."},
    hearty = {Label = "hearty", Verdict = "A hearty bowl — the kind that ends arguments and starts naps."},
    exquisite = {Label = "exquisite", Verdict = "An exquisite bowl — the table goes quiet at the first spoonful."},
    legendary = {Label = "legendary", Verdict = "A bowl to remember — they will tell of this soup in winters to come."},
    hazard = {Label = "health hazard", Verdict = "A health hazard — the flies found it first. Send it back and burn the pot."},
} :: {[string]: Tier}

module.MysteryStocks = {"B", "W", "G", "J", "!", "'", ":", "*"}
module.MysteryIngredients = {"O", "I", "D", "F", "C", "L", "M", "E", "A", "T"}

local NumberWords = {"one", "two", "three", "four", "five", "six", "seven", "eight", "nine", "ten", "eleven", "twelve"}

function module.NumberWord(count: number): string
    return NumberWords[count] or tostring(count)
end

function module.GetStock(letter: string): Stock?
    return module.Stocks[letter]
end

function module.GetIngredient(letter: string): Ingredient?
    return module.Ingredients[letter]
end

return module
