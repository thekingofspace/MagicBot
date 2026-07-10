local Basic = require("@src/spell/elements/Basic")

local Color = {r = 140, g = 120, b = 90}
local Accent = {r = 190, g = 170, b = 140}

return Basic.Make({
    Name = "Wither",
    Emoji = "🥀",
    Color = Color,
    Accent = Accent,
    Noun = "Wither",
    JetVerb = "creeps out",
    SpreadVerb = "spreads",
    EvenVerb = "droops",
    Sigil = function(cv, x, y, size, power, alpha)
        local color = Basic.Alpha(Color, alpha)
        cv:polyline({
            {x - size * 0.1, y + size * 0.55},
            {x - size * 0.05, y},
            {x + size * 0.1, y - size * 0.3},
            {x + size * 0.35, y - size * 0.35},
            {x + size * 0.45, y - size * 0.15},
        }, color, 3)
        local accent = Basic.Alpha(Accent, alpha)
        cv:circle(x + size * 0.5, y + size * 0.05, math.max(2, size * 0.06), accent)
        cv:circle(x + size * 0.42, y + size * 0.3, math.max(1, size * 0.05), accent)
    end,
})
