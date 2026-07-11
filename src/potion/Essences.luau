
export type Essence = {
    Letter: string,
    Name: string,
    Title: string,
    Adj: string,
    Hue: string,
    Color: {r: number, g: number, b: number},
    Consume: string,
    Apply: string,
    Inhale: string,
    Clause: string,
    Rot: boolean?,
}

export type MindPair = {
    Title: string,
    Consume: string,
    Apply: string,
    Inhale: string,
}

local module = {}

module.Registry = {
    J = {
        Letter = "J", Name = "Jiva", Title = "Mending", Adj = "Mending",
        Hue = "heartsblood crimson", Color = {r = 198, g = 44, b = 70},
        Consume = "knits wounds closed",
        Apply = "closes the cuts it is poured over",
        Inhale = "knits the breath-deep hurts of lung and heart",
        Clause = ", and mends as it goes",
    },
    W = {
        Letter = "W", Name = "Tide", Title = "Clearwater", Adj = "Cleansing",
        Hue = "clear azure", Color = {r = 64, g = 148, b = 216},
        Consume = "rinses ill humors and addlement away",
        Apply = "washes taint and grime from what it touches",
        Inhale = "clears the head with one cold clean breath",
        Clause = ", washed clean as it works",
    },
    G = {
        Letter = "G", Name = "Stone", Title = "Stoneskin", Adj = "Stonebound",
        Hue = "earthen ochre", Color = {r = 168, g = 126, b = 62},
        Consume = "sets the skin hard as quarried stone",
        Apply = "hardens what it coats to stone",
        Inhale = "sets the skin stone-hard from the breath outward",
        Clause = ", stone-steady all the while",
    },
    Z = {
        Letter = "Z", Name = "Zephyr", Title = "Featherstep", Adj = "Feathered",
        Hue = "pale sky", Color = {r = 166, g = 214, b = 226},
        Consume = "lightens the step to a swift hush",
        Apply = "makes what it coats near light as chaff",
        Inhale = "lifts the step light from a single breath",
        Clause = ", light on its feet",
    },
    B = {
        Letter = "B", Name = "Ember", Title = "Emberwarmth", Adj = "Warming",
        Hue = "ember orange", Color = {r = 224, g = 116, b = 40},
        Consume = "banks a warmth in the blood against flame and frost",
        Apply = "proofs what it coats against flame",
        Inhale = "fills the chest with a banked and lasting warmth",
        Clause = ", warm to the last drop",
    },
    ["!"] = {
        Letter = "!", Name = "Ray", Title = "Owl-light", Adj = "Glowing",
        Hue = "lantern gold", Color = {r = 238, g = 204, b = 94},
        Consume = "opens the eyes to see in the dark",
        Apply = "sets a soft lamplight upon what it coats",
        Inhale = "kindles a lamplight behind the eyes",
        Clause = ", glowing gently all the while",
    },
    ["^"] = {
        Letter = "^", Name = "Spark", Title = "Quickening", Adj = "Hurried",
        Hue = "spark yellow", Color = {r = 222, g = 216, b = 74},
        Consume = "quickens hand and heart",
        Apply = "puts a restless quickness in what it coats",
        Inhale = "sets heart and hands racing on one sharp breath",
        Clause = ", in a hurry",
    },
    [":"] = {
        Letter = ":", Name = "Aeon", Title = "Long-Year", Adj = "Lasting",
        Hue = "dusk violet", Color = {r = 136, g = 90, b = 196},
        Consume = "slows the toll of the years",
        Apply = "keeps what it coats from aging a day",
        Inhale = "slows the toll of the years with every slow breath",
        Clause = ", and lingers well past its hour",
    },
    ["'"] = {
        Letter = "'", Name = "Muse", Title = "Stillmind", Adj = "Quiet",
        Hue = "lake teal", Color = {r = 110, g = 192, b = 176},
        Consume = "stills a racing mind to one clear thought",
        Apply = "settles whatever restless thing it is poured upon",
        Inhale = "stills the mind between one breath and the next",
        Clause = ", with a clear and quiet head",
    },
    ["*"] = {
        Letter = "*", Name = "Astra", Title = "Unburdening", Adj = "Weightless",
        Hue = "midnight blue", Color = {r = 96, g = 110, b = 228},
        Consume = "frees the body of its weight",
        Apply = "lifts the weight from what it coats",
        Inhale = "leaves the body near weightless while the vapor lasts",
        Clause = ", weightless while it lasts",
    },
    ["@"] = {
        Letter = "@", Name = "Vortex", Title = "Grounding", Adj = "Rooted",
        Hue = "iron plum", Color = {r = 122, g = 84, b = 138},
        Consume = "roots the drinker fast to the earth",
        Apply = "anchors what it coats where it stands",
        Inhale = "roots whoever breathes it fast to the earth",
        Clause = ", too heavy to be swept away",
    },

    A = {
        Letter = "A", Name = "Ardor", Title = "Vigor", Adj = "Tireless",
        Hue = "sunrise coral", Color = {r = 236, g = 110, b = 90},
        Consume = "fills the limbs with a tireless vigor",
        Apply = "puts a fresh spring in whatever it is worked into",
        Inhale = "fills the lungs with tireless morning air",
        Clause = ", tireless to the last",
    },
    D = {
        Letter = "D", Name = "Poppy", Title = "Numbing", Adj = "Numbing",
        Hue = "milk white", Color = {r = 228, g = 224, b = 214},
        Consume = "dulls every ache to a far-off murmur",
        Apply = "numbs the flesh it is rubbed into",
        Inhale = "numbs every ache from the first breath",
        Clause = ", felt through a pleasant numbness",
    },
    F = {
        Letter = "F", Name = "Fox", Title = "Foxsense", Adj = "Keen",
        Hue = "russet amber", Color = {r = 196, g = 116, b = 48},
        Consume = "sharpens eye, ear, and nose to a fox's keenness",
        Apply = "tunes what it coats to prick at the faintest stir",
        Inhale = "pricks every sense keen on the instant",
        Clause = ", every sense pricked keen",
    },
    K = {
        Letter = "K", Name = "Kin", Title = "Truetongue", Adj = "Kindred",
        Hue = "honeyed rose", Color = {r = 214, g = 138, b = 148},
        Consume = "opens the ear to every spoken tongue",
        Apply = "makes the writing on what it coats plain to any reader",
        Inhale = "makes every tongue plain to the ear",
        Clause = ", every word understood",
    },
    L = {
        Letter = "L", Name = "Clover", Title = "Fortune", Adj = "Lucky",
        Hue = "clover green", Color = {r = 92, g = 178, b = 84},
        Consume = "tips the small chances of the day kindly",
        Apply = "charms what it coats to be found and never lost",
        Inhale = "draws the day's small chances kindly near",
        Clause = ", with luck leaning close",
    },
    M = {
        Letter = "M", Name = "Iron", Title = "Ironnerve", Adj = "Unflinching",
        Hue = "steel grey", Color = {r = 140, g = 150, b = 164},
        Consume = "steels the nerve until the hand cannot shake",
        Apply = "steadies what it coats against tremor and dread",
        Inhale = "steels the nerve with a single drawn breath",
        Clause = ", with an unflinching nerve",
    },
    N = {
        Letter = "N", Name = "Night", Title = "Dreamless", Adj = "Dreamless",
        Hue = "starless indigo", Color = {r = 52, g = 56, b = 108},
        Consume = "lays the drinker into a deep and dreamless sleep",
        Apply = "stills what it coats to a windless hush",
        Inhale = "drops the breather into deep dreamless sleep",
        Clause = ", then down into dreamless rest",
    },
    Y = {
        Letter = "Y", Name = "Wren", Title = "Clarion", Adj = "Clear-Voiced",
        Hue = "pale primrose", Color = {r = 242, g = 230, b = 168},
        Consume = "rings the voice out clear as a struck bell",
        Apply = "tunes what it coats to ring true when struck",
        Inhale = "rings the voice out clear from the first breath",
        Clause = ", clear as a struck bell",
    },

    ["%"] = {
        Letter = "%", Name = "Rot", Title = "sour rot", Adj = "Soured",
        Hue = "murk green", Color = {r = 106, g = 126, b = 50},
        Consume = "sickens the gut",
        Apply = "spreads a creeping mold across what it touches",
        Inhale = "sours the breath and gripes the lungs",
        Clause = "",
        Rot = true,
    },
    ["/"] = {
        Letter = "/", Name = "Rend", Title = "vitriol", Adj = "Caustic",
        Hue = "bile green", Color = {r = 152, g = 182, b = 44},
        Consume = "burns the throat going down",
        Apply = "eats at flesh, cloth, and lock alike",
        Inhale = "scours the airways raw",
        Clause = "",
        Rot = true,
    },
} :: {[string]: Essence}

module.WaterColor = {r = 148, g = 188, b = 212}

module.MindPairs = {
    J = {
        Title = "Cordial of High Heart",
        Consume = "lifts a heavy heart to steady courage",
        Apply = "heartens whoever carries what it anoints",
        Inhale = "puts courage in the chest with every breath",
    },
    [":"] = {
        Title = "Tonic of Remembered Days",
        Consume = "brings lost days back sharp and whole to memory",
        Apply = "wakes in what it coats the memory of every hand that held it",
        Inhale = "returns lost days with every slow breath",
    },
    ["!"] = {
        Title = "Philtre of Clear Sight",
        Consume = "grants a quiet insight that sees through muddle and mask",
        Apply = "shows true whatever is hidden about what it coats",
        Inhale = "clears mask and muddle from the eye at a breath",
    },
    W = {
        Title = "Draught of Untroubled Sleep",
        Consume = "washes the day's troubles away and lays down an untroubled sleep",
        Apply = "grants the bed it is sprinkled over quiet, kindly dreams",
        Inhale = "carries the breather gently into untroubled sleep",
    },
    L = {
        Title = "Philtre of Happenstance",
        Consume = "a quiet knowing of where luck waits, one step ahead",
        Apply = "steers what it anoints toward the kindest of its chances",
        Inhale = "breathes in the knowing of where luck waits next",
    },
    N = {
        Title = "Draught of Deep Dreaming",
        Consume = "vivid, kindly dreams the dreamer steers",
        Apply = "fills the bed it is sprinkled over with dreams worth steering",
        Inhale = "carries the breather down into dreams they steer themselves",
    },
    M = {
        Title = "Tonic of the Even Keel",
        Consume = "fear finds no purchase on a level mind",
        Apply = "settles what it coats too level for any dread to tip",
        Inhale = "levels the mind past fear in a single breath",
    },
    K = {
        Title = "Philtre of the Unspoken",
        Consume = "hears the meaning beneath the words, spoken or not",
        Apply = "lets what it anoints be understood without a word",
        Inhale = "opens the ear to the meaning beneath the words",
    },
} :: {[string]: MindPair}

module.Trance = {
    Consume = "sinks mind and body into a deep meditative trance, far below thought",
    Apply = "settles a temple-hush over whatever it is poured upon",
    Inhale = "drops the breather into deep trance between one breath and the next",
}

module.Forgetting = {Hue = "fog grey", Color = {r = 168, g = 170, b = 182}}
module.HoneyMask = {Hue = "warm honey amber", Color = {r = 224, g = 168, b = 66}}

function module.Get(letter: string): Essence?
    return module.Registry[letter]
end

return module
