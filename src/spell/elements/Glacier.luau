local Basic = require("@src/spell/elements/Basic")

local Color = {r = 170, g = 220, b = 245}
local Accent = {r = 225, g = 245, b = 255}
local WaterColor = {r = 60, g = 140, b = 255}

return Basic.Make({
    Name = "Glacier",
    Emoji = "❄️",
    Color = Color,
    Accent = Accent,
    Noun = "The glacier",
    JetVerb = "grinds out",
    SpreadVerb = "sheets",
    EvenVerb = "freezes over",
    Sigil = function(cv, x, y, size, power, alpha)
        Basic.Triangle(cv, x, y, size * 0.85, false, false, Basic.Alpha(WaterColor, alpha * 0.7), 3)
        local color = Basic.Alpha(Color, alpha)
        cv:line(x - size * 0.35, y - size * 0.15, x + size * 0.35, y - size * 0.15, color, 2)
        cv:line(x - size * 0.25, y + size * 0.05, x + size * 0.25, y + size * 0.05, color, 2)
        cv:line(x - size * 0.12, y + size * 0.28, x + size * 0.12, y + size * 0.28, color, 2)
    end,
})
