local Basic = require("@src/spell/elements/Basic")

local Color = {r = 100, g = 85, b = 210}
local Accent = {r = 170, g = 155, b = 255}

return Basic.Make({
    Name = "Space",
    Emoji = "🌌",
    Color = Color,
    Accent = Accent,
    Noun = "The void",
    JetVerb = "tears open",
    SpreadVerb = "unfurls",
    EvenVerb = "yawns",
    IdleText = "A void rune is drawn, but the space between holds still.",
    Sigil = function(cv, x, y, size, power, alpha)
        local color = Basic.Alpha(Color, alpha)
        cv:polygon({
            {x, y - size * 0.6},
            {x + size * 0.1, y - size * 0.1},
            {x + size * 0.6, y},
            {x + size * 0.1, y + size * 0.1},
            {x, y + size * 0.6},
            {x - size * 0.1, y + size * 0.1},
            {x - size * 0.6, y},
            {x - size * 0.1, y - size * 0.1},
        }, color)
        local accent = Basic.Alpha(Accent, alpha)
        cv:circle(x + size * 0.42, y - size * 0.42, math.max(1, size * 0.05), accent)
        cv:circle(x - size * 0.48, y + size * 0.3, math.max(1, size * 0.04), accent)
        cv:circle(x + size * 0.3, y + size * 0.5, math.max(1, size * 0.04), accent)
    end,
})
