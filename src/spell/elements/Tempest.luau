local Basic = require("@src/spell/elements/Basic")

local Color = {r = 130, g = 160, b = 200}
local Accent = {r = 230, g = 240, b = 120}

return Basic.Make({
    Name = "Tempest",
    Emoji = "⛈️",
    Color = Color,
    Accent = Accent,
    Noun = "The tempest",
    JetVerb = "storms out",
    SpreadVerb = "squalls",
    EvenVerb = "rages overhead",
    Sigil = function(cv, x, y, size, power, alpha)
        Basic.Triangle(cv, x, y - size * 0.18, size * 0.8, true, true, Basic.Alpha(Color, alpha), 3)
        cv:polyline({
            {x + size * 0.08, y + size * 0.12},
            {x - size * 0.12, y + size * 0.34},
            {x + size * 0.04, y + size * 0.34},
            {x - size * 0.16, y + size * 0.6},
        }, Basic.Alpha(Accent, alpha), 2)
    end,
})
