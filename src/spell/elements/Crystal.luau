local Basic = require("@src/spell/elements/Basic")

local Color = {r = 150, g = 220, b = 235}
local Accent = {r = 220, g = 250, b = 255}

return Basic.Make({
    Name = "Crystal",
    Emoji = "💎",
    Color = Color,
    Accent = Accent,
    Noun = "Crystal",
    JetVerb = "lances out",
    SpreadVerb = "facets",
    EvenVerb = "crystallizes",
    Sigil = function(cv, x, y, size, power, alpha)
        local color = Basic.Alpha(Color, alpha)
        cv:strokePolygon({
            {x, y - size * 0.6},
            {x + size * 0.42, y - size * 0.12},
            {x + size * 0.26, y + size * 0.55},
            {x - size * 0.26, y + size * 0.55},
            {x - size * 0.42, y - size * 0.12},
        }, color, 3)
        local accent = Basic.Alpha(Accent, alpha)
        cv:line(x, y - size * 0.6, x - size * 0.1, y + size * 0.55, accent, 1)
        cv:line(x - size * 0.42, y - size * 0.12, x + size * 0.26, y + size * 0.55, accent, 1)
        cv:line(x + size * 0.42, y - size * 0.12, x - size * 0.26, y + size * 0.55, accent, 1)
    end,
})
