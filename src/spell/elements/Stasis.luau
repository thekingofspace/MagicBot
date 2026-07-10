local Basic = require("@src/spell/elements/Basic")

local Color = {r = 185, g = 225, b = 235}
local Accent = {r = 230, g = 250, b = 255}

return Basic.Make({
    Name = "Stasis",
    Emoji = "🧊",
    Color = Color,
    Accent = Accent,
    Noun = "Stasis",
    JetVerb = "locks",
    SpreadVerb = "stills",
    EvenVerb = "holds all still",
    Sigil = function(cv, x, y, size, power, alpha)
        local color = Basic.Alpha(Color, alpha)
        cv:strokePolygon({
            {x - size * 0.45, y - size * 0.45},
            {x + size * 0.45, y - size * 0.45},
            {x + size * 0.45, y + size * 0.45},
            {x - size * 0.45, y + size * 0.45},
        }, color, 3)
        cv:strokeCircle(x, y, size * 0.26, Basic.Alpha(Accent, alpha), 2)
        cv:circle(x, y, math.max(1, size * 0.06), Basic.Alpha(Accent, alpha))
    end,
})
