export type Compound = {
    Title: string,
    Persona: boolean?,
    Hue: string,
    Color: {r: number, g: number, b: number},
    Line: string,
}

local module = {}

module.Registry = {
    ["J|W"] = {Title = "Balm", Hue = "rose-water pink", Color = {r = 232, g = 168, b = 180}, Line = "knits and rinses in one kindness"},
    ["B|J"] = {Title = "Hearthblood", Hue = "hearth red", Color = {r = 190, g = 60, b = 54}, Line = "warms the blood and knits it as it goes"},
    ["G|J"] = {Title = "Knitbone", Hue = "fired clay", Color = {r = 186, g = 110, b = 72}, Line = "closes wounds beneath a stone-hard scar"},
    ["A|J"] = {Title = "Second Wind", Hue = "dawn crimson", Color = {r = 220, g = 80, b = 86}, Line = "mends and refills the limbs in one long breath"},
    ["D|J"] = {Title = "Mercy", Hue = "blushed ivory", Color = {r = 238, g = 222, b = 210}, Line = "knits wounds the drinker never feels"},
    [":|J"] = {Title = "Everbalm", Hue = "wine violet", Color = {r = 132, g = 70, b = 124}, Line = "a slow mending that keeps watch for days"},
    ["B|W"] = {Title = "Sweatlodge", Hue = "steam pearl", Color = {r = 222, g = 226, b = 224}, Line = "a purging warmth that sweats the ill humors out"},
    ["N|W"] = {Title = "Stillwater", Hue = "deep slate blue", Color = {r = 70, g = 90, b = 120}, Line = "washes the day away into black, quiet depths"},
    ["F|W"] = {Title = "Clearscent", Hue = "glass green", Color = {r = 152, g = 208, b = 180}, Line = "rinses the senses until the world smells new-washed"},
    ["G|M"] = {Title = "Bulwark", Hue = "granite grey", Color = {r = 130, g = 134, b = 138}, Line = "sets skin and nerve alike to stone"},
    ["B|G"] = {Title = "Kilnhide", Hue = "terracotta", Color = {r = 200, g = 110, b = 70}, Line = "fires the hide hard as kiln-brick, and warm through"},
    ["@|G"] = {Title = "Bedrock", Hue = "deep ochre", Color = {r = 158, g = 112, b = 48}, Line = "roots and armors — the drinker will not be moved"},
    [":|G"] = {Title = "Monument", Hue = "aged sandstone", Color = {r = 196, g = 176, b = 140}, Line = "the body weathers like a monument, slow and grand"},
    ["*|Z"] = {Title = "Gossamer", Hue = "pale opal", Color = {r = 214, g = 222, b = 230}, Line = "each stride a gliding leap, near weightless"},
    ["F|Z"] = {Title = "Prowl", Hue = "dusk amber", Color = {r = 172, g = 120, b = 60}, Line = "the hush and keen tread of a hunting cat"},
    ["Z|^"] = {Title = "Swallowtail", Hue = "sky yellow", Color = {r = 240, g = 214, b = 110}, Line = "swift and turning as a swallow on the wing"},
    ["B|^"] = {Title = "Bellows", Hue = "forge gold", Color = {r = 232, g = 178, b = 72}, Line = "stokes heart and hands like a smith's bellows"},
    ["B|D"] = {Title = "Toddy", Hue = "mulled amber", Color = {r = 196, g = 130, b = 58}, Line = "a deep hearthside comfort that dulls every ache"},
    ["!|F"] = {Title = "Huntsmoon", Hue = "harvest gold", Color = {r = 226, g = 182, b = 80}, Line = "the eyes and ears of the night hunter"},
    ["!|L"] = {Title = "Lodestar", Hue = "gilt green", Color = {r = 158, g = 186, b = 88}, Line = "a kindly inner light that leads toward lucky turns"},
    ["M|^"] = {Title = "the Duelist", Persona = true, Hue = "rapier grey", Color = {r = 156, g = 164, b = 176}, Line = "quick hands under an unshaking eye"},
    ["F|L"] = {Title = "Foxluck", Hue = "lucky russet", Color = {r = 178, g = 104, b = 52}, Line = "the fox's knack for being elsewhere when trouble lands"},
    ["F|N"] = {Title = "Catnap", Hue = "moonlit amber", Color = {r = 216, g = 178, b = 110}, Line = "a sleep that keeps one ear open — the drinker wakes at the first wrong sound"},
    ["A|D"] = {Title = "Mettle", Hue = "oxblood", Color = {r = 128, g = 44, b = 48}, Line = "tireless limbs that shrug off every hurt"},
    [":|A"] = {Title = "Wellspring", Hue = "deep coral", Color = {r = 226, g = 104, b = 92}, Line = "a vigor drawn from a well that does not empty"},
    ["K|Y"] = {Title = "Parley", Hue = "rose gold", Color = {r = 222, g = 158, b = 132}, Line = "speaks and is understood by every ear in the hall"},
    [":|L"] = {Title = "Providence", Hue = "evergreen", Color = {r = 46, g = 110, b = 72}, Line = "luck that leans close and stays the season"},
    ["D|M"] = {Title = "Sawbones", Hue = "bone grey", Color = {r = 208, g = 204, b = 192}, Line = "steady hands that feel no flinch — the chirurgeon's nerve"},
    ["@|M"] = {Title = "the Anvil", Persona = true, Hue = "anvil black", Color = {r = 56, g = 58, b = 64}, Line = "stands to be struck and does not ring"},
    ["D|N"] = {Title = "Twilightsleep", Hue = "deep lilac", Color = {r = 152, g = 122, b = 186}, Line = "a painless, dreamless dark — the chirurgeon's hour"},
    [":|N"] = {Title = "Brumal", Hue = "midwinter blue", Color = {r = 58, g = 76, b = 132}, Line = "a bear's winter sleep — the years pass light as one night"},
    ["*|N"] = {Title = "Cradle", Hue = "night opal", Color = {r = 92, g = 88, b = 132}, Line = "sleeps aloft, light as a babe rocked in air"},
} :: {[string]: Compound}

function module.Key(a: string, b: string): string
    if a < b then
        return `{a}|{b}`
    end
    return `{b}|{a}`
end

function module.Get(a: string, b: string): Compound?
    return module.Registry[module.Key(a, b)]
end

return module
