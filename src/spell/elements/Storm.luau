local Basic = require("@src/spell/elements/Basic")

local Color = {r = 70, g = 110, b = 190}
local Accent = {r = 160, g = 200, b = 255}
local VoltColor = {r = 110, g = 215, b = 255}

return Basic.Make({
    Name = "Storm",
    Emoji = "🌩️",
    Color = Color,
    Accent = Accent,
    Noun = "The storm",
    JetVerb = "breaks",
    SpreadVerb = "lashes",
    EvenVerb = "churns overhead",
    Sigil = function(cv, x, y, size, power, alpha)
        Basic.Triangle(cv, x, y - size * 0.15, size * 0.8, false, false, Basic.Alpha(Color, alpha), 3)
        cv:polyline({
            {x + size * 0.1, y + size * 0.05},
            {x - size * 0.1, y + size * 0.35},
            {x + size * 0.02, y + size * 0.35},
            {x - size * 0.12, y + size * 0.62},
        }, Basic.Alpha(VoltColor, alpha), 2)
    end,
})
