-- The cellar's stock: brew families and the vessels they pour into.

export type Family = {
    Letter: string,
    Name: string,
    Noun: string,
    Phrase: string,
    Hue: string,
    Color: {r: number, g: number, b: number},
    HeadScale: number,
    HeadColor: {r: number, g: number, b: number},
    BaseProof: number,
    AgesWell: boolean,
}

export type Vessel = {
    Letter: string,
    Key: string,
    Name: string,
    Phrase: string,
    Fits: {[string]: boolean},
}

export type Bottle = {
    Key: string,
    Name: string,
    Phrase: string,
    Intro: string,
    Label: string,
    Fits: {[string]: boolean},
}

export type Cocktail = {
    A: string,
    B: string?,
    Citrus: boolean?,
    Salt: boolean?,
    Bubbles: boolean?,
    Name: string,
    Tag: string,
    Glass: string?,
    Garnish: string?,
    Flashy: boolean?,
    Color: {r: number, g: number, b: number}?,
}

local module = {}

module.Families = {
    B = {
        Letter = "B", Name = "Amber Ale", Noun = "Amber Ale",
        Phrase = "amber ale, bright as lamplit copper",
        Hue = "lamplit amber", Color = {r = 196, g = 118, b = 38},
        HeadScale = 1.0, HeadColor = {r = 240, g = 226, b = 196},
        BaseProof = 9, AgesWell = false,
    },
    G = {
        Letter = "G", Name = "Dark Stout", Noun = "Stout",
        Phrase = "dark stout, black-brown as turned earth",
        Hue = "peat brown", Color = {r = 56, g = 34, b = 22},
        HeadScale = 1.2, HeadColor = {r = 226, g = 202, b = 160},
        BaseProof = 11, AgesWell = true,
    },
    W = {
        Letter = "W", Name = "Pale Lager", Noun = "Lager",
        Phrase = "pale lager, straw-gold and clean",
        Hue = "straw gold", Color = {r = 230, g = 192, b = 84},
        HeadScale = 1.0, HeadColor = {r = 248, g = 246, b = 238},
        BaseProof = 8, AgesWell = false,
    },
    ["!"] = {
        Letter = "!", Name = "Golden Mead", Noun = "Mead",
        Phrase = "golden mead, thick with clover honey",
        Hue = "clover gold", Color = {r = 226, g = 164, b = 48},
        HeadScale = 0.35, HeadColor = {r = 242, g = 228, b = 188},
        BaseProof = 24, AgesWell = true,
    },
    J = {
        Letter = "J", Name = "Herbal Cordial", Noun = "Cordial",
        Phrase = "green herbal cordial, sharp with cut stems",
        Hue = "stillroom green", Color = {r = 92, g = 160, b = 76},
        HeadScale = 0.15, HeadColor = {r = 226, g = 238, b = 214},
        BaseProof = 32, AgesWell = false,
    },
    [":"] = {
        Letter = ":", Name = "Wine-Dark Vintage", Noun = "Vintage",
        Phrase = "a wine-dark vintage, deep as garnet",
        Hue = "wine-dark garnet", Color = {r = 114, g = 26, b = 52},
        HeadScale = 0.05, HeadColor = {r = 224, g = 196, b = 200},
        BaseProof = 26, AgesWell = true,
    },
    ["*"] = {
        Letter = "*", Name = "Void Porter", Noun = "Void Porter",
        Phrase = "void-black porter that drinks the lamplight",
        Hue = "void black", Color = {r = 22, g = 18, b = 32},
        HeadScale = 1.3, HeadColor = {r = 214, g = 196, b = 168},
        BaseProof = 13, AgesWell = true,
    },
    ["^"] = {
        Letter = "^", Name = "Firewater", Noun = "Firewater",
        Phrase = "firewater, pale flame in a glass",
        Hue = "flame amber", Color = {r = 224, g = 144, b = 54},
        HeadScale = 0.0, HeadColor = {r = 240, g = 220, b = 190},
        BaseProof = 78, AgesWell = true,
    },
    ["'"] = {
        Letter = "'", Name = "Dream-Wine", Noun = "Dream-Wine",
        Phrase = "dream-wine, opal-pale and never quite still",
        Hue = "opal sheen", Color = {r = 168, g = 190, b = 212},
        HeadScale = 0.3, HeadColor = {r = 236, g = 240, b = 248},
        BaseProof = 20, AgesWell = true,
    },
    ["%"] = {
        Letter = "%", Name = "Skunked Swill", Noun = "Swill",
        Phrase = "skunked swill, flat and murky as ditchwater",
        Hue = "ditchwater olive", Color = {r = 122, g = 114, b = 56},
        HeadScale = 0.0, HeadColor = {r = 200, g = 194, b = 160},
        BaseProof = 5, AgesWell = false,
    },
} :: {[string]: Family}

module.Vessels = {
    T = {
        Letter = "T", Key = "tankard", Name = "glass tankard",
        Phrase = "a heavy glass tankard",
        Fits = {B = true, G = true, W = true, ["*"] = true},
    },
    V = {
        Letter = "V", Key = "goblet", Name = "stemmed goblet",
        Phrase = "a stemmed goblet",
        Fits = {["!"] = true, [":"] = true, ["'"] = true, J = true},
    },
    I = {
        Letter = "I", Key = "flute", Name = "pilsner flute",
        Phrase = "a tall pilsner flute",
        Fits = {W = true},
    },
    O = {
        Letter = "O", Key = "snifter", Name = "round snifter",
        Phrase = "a round-bellied snifter",
        Fits = {["^"] = true, ["'"] = true},
    },
    U = {
        Letter = "U", Key = "chalice", Name = "wide chalice",
        Phrase = "a wide ceremonial chalice",
        Fits = {["!"] = true, [":"] = true},
    },
    D = {
        Letter = "D", Key = "barrel", Name = "barrel-mug",
        Phrase = "a wooden barrel-mug bound in iron",
        Fits = {B = true, G = true, ["*"] = true},
    },
    Y = {
        Letter = "Y", Key = "wine", Name = "wine glass",
        Phrase = "a tall stemmed wine glass",
        Fits = {[":"] = true, ["'"] = true, ["!"] = true},
    },
    Q = {
        Letter = "Q", Key = "bottle", Name = "wine bottle",
        Phrase = "a corked wine bottle",
        Fits = {[":"] = true},
    },
    X = {
        Letter = "X", Key = "horn", Name = "drinking horn",
        Phrase = "a drinking horn on its stand",
        Fits = {["!"] = true, B = true},
    },
    C = {
        Letter = "C", Key = "clayjug", Name = "clay jug",
        Phrase = "a stoneware jug",
        Fits = {J = true, ["!"] = true},
    },
    A = {
        Letter = "A", Key = "coupe", Name = "margarita coupe",
        Phrase = "a wide-lipped margarita coupe",
        Fits = {},
    },
    M = {
        Letter = "M", Key = "martini", Name = "martini glass",
        Phrase = "a knife-edged martini glass",
        Fits = {},
    },
    K = {
        Letter = "K", Key = "rocks", Name = "rocks glass",
        Phrase = "a squat rocks glass",
        Fits = {},
    },
    L = {
        Letter = "L", Key = "highball", Name = "highball",
        Phrase = "a tall highball",
        Fits = {},
    },
} :: {[string]: Vessel}

-- The bottle rack: the count of Q picks the bottle, not the size.
module.Bottles = {
    {
        Key = "bottle", Name = "wine bottle", Phrase = "a corked wine bottle",
        Intro = "A corked bottle of", Label = "VINTAGE",
        Fits = {[":"] = true},
    },
    {
        Key = "stoutbottle", Name = "stout bottle", Phrase = "a squat stout bottle",
        Intro = "A squat brown bottle of", Label = "STOUT",
        Fits = {G = true, ["*"] = true},
    },
    {
        Key = "spiritsbottle", Name = "spirits bottle", Phrase = "a tall spirits bottle",
        Intro = "A tall slim bottle of", Label = "OLD FLAME",
        Fits = {["^"] = true},
    },
    {
        Key = "swingtop", Name = "swing-top bottle", Phrase = "a swing-top bottle",
        Intro = "A swing-topped bottle of", Label = "BREWHOUSE",
        Fits = {W = true, B = true},
    },
    {
        Key = "demijohn", Name = "wicker demijohn", Phrase = "a wicker demijohn",
        Intro = "A wicker-skirted demijohn of", Label = "MOTHERS BEST",
        Fits = {["!"] = true, J = true},
    },
    {
        Key = "ginbottle", Name = "square gin bottle", Phrase = "a square gin bottle",
        Intro = "A square-shouldered bottle of", Label = "DRY OATH",
        Fits = {["^"] = true, J = true},
    },
} :: {Bottle}

module.BottleKeys = {
    bottle = true, stoutbottle = true, spiritsbottle = true,
    swingtop = true, demijohn = true, ginbottle = true,
}

module.CocktailGlasses = {coupe = true, martini = true, rocks = true, highball = true}

-- The mixing book: two-family pours first, then single-family recipes.
module.Cocktails = {
    {A = "^", B = "G", Name = "Boilermaker", Tag = "a shot dropped where it has no business", Glass = "rocks", Color = {r = 74, g = 48, b = 30}},
    {A = "^", B = "!", Name = "The Bee's Sting", Tag = "honey first, then the sting", Glass = "coupe", Color = {r = 230, g = 186, b = 84}},
    {A = "^", B = "J", Name = "The Physicker", Tag = "tastes like medicine because it is", Glass = "martini", Color = {r = 148, g = 188, b = 108}},
    {A = "^", B = "'", Name = "Fey Martini", Tag = "dry as a fairy bargain", Glass = "martini", Garnish = "olive", Color = {r = 198, g = 210, b = 222}},
    {A = "^", B = ":", Name = "Cellar Negroni", Tag = "bitter, garnet, and unhurried", Glass = "rocks", Garnish = "wheel", Color = {r = 170, g = 58, b = 50}},
    {A = "*", B = "^", Name = "Blackpowder", Tag = "drink it before it goes off", Glass = "rocks", Color = {r = 40, g = 32, b = 38}},
    {A = "!", B = "J", Name = "Meadowsweet", Tag = "a meadow pressed into a glass", Glass = "highball", Color = {r = 198, g = 184, b = 88}},
    {A = "'", B = "!", Name = "Moonglow", Tag = "glows faintly and asks the fiddler for something slow", Glass = "coupe", Garnish = "umbrella", Flashy = true, Color = {r = 216, g = 214, b = 186}},
    {A = "'", B = ":", Name = "Violet Hour", Tag = "dusk, decanted", Glass = "martini", Color = {r = 150, g = 110, b = 160}},
    {A = "^", Citrus = true, Salt = true, Name = "Margarita", Tag = "sharp, sour, and sure of itself", Glass = "coupe", Garnish = "lime", Color = {r = 206, g = 224, b = 150}},
    {A = "^", Citrus = true, Name = "Tavern Sour", Tag = "sour enough to wake the dead, politely", Glass = "rocks", Garnish = "wheel", Color = {r = 226, g = 180, b = 90}},
    {A = ":", Bubbles = true, Name = "Garnet Sparkler", Tag = "the vintage taught to laugh", Glass = "flute", Color = {r = 170, g = 54, b = 86}},
    {A = "W", Citrus = true, Name = "Shandy", Tag = "half a lager, twice the afternoon", Glass = "highball", Garnish = "lime", Color = {r = 234, g = 210, b = 118}},
} :: {Cocktail}

module.Regret = {
    A = "%", Name = "The Regret", Tag = "everyone orders it once",
    Garnish = "umbrella", Color = {r = 118, g = 112, b = 62},
} :: Cocktail

module.Pint = {
    Letter = "", Key = "pint", Name = "plain pint",
    Phrase = "a plain pint glass",
    Fits = {W = true, B = true, G = true},
} :: Vessel

module.HeadLabels = {
    [0] = "flat",
    [1] = "a thin collar",
    [2] = "two fingers",
    [3] = "a proud crown",
    [4] = "overflowing",
}

module.Verdicts = {
    swill = "The tapster pulls his cap down and pretends he poured it for someone else.",
    honest = "An honest pour — it does what a drink must and asks no praise for it.",
    fine = "A fine pour — good enough to quiet a table for the first three swallows.",
    prized = "A prized pour — regulars will swear they were there the night it was tapped.",
    legendary = "A pour worth a song — the bard is already clearing his throat.",
}

module.SwillVerdict = "Pour it in the gutter and apologize to the gutter."
module.FoamVerdict = "All head and no heart — the tapster owes you an apology."
module.EmptyVerdict = "Come back when the dray arrives."

module.QualityAdj = {
    fine = "Fine",
    prized = "Prized",
    legendary = "Legendary",
    swill = "Sorry",
}

module.QualityLabels = {
    swill = "Swill",
    honest = "Honest",
    fine = "Fine",
    prized = "Prized",
    legendary = "Legendary",
}

module.MullFits = {["!"] = true, [":"] = true, B = true, J = true}
module.MullClash = {W = true}
module.NitroFits = {G = true, ["*"] = true}

return module
