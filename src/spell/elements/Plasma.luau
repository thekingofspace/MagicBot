local Basic = require("@src/spell/elements/Basic")

local Color = {r = 235, g = 90, b = 220}
local Accent = {r = 255, g = 180, b = 255}
local VoltColor = {r = 110, g = 215, b = 255}

return Basic.Make({
    Name = "Plasma",
    Emoji = "💥",
    Color = Color,
    Accent = Accent,
    Noun = "Plasma",
    JetVerb = "lashes out",
    SpreadVerb = "sheets",
    EvenVerb = "seethes",
    Sigil = function(cv, x, y, size, power, alpha)
        cv:strokeCircle(x, y, size * 0.45, Basic.Alpha(Color, alpha), 3)
        cv:polyline({
            {x + size * 0.12, y - size * 0.35},
            {x - size * 0.12, y},
            {x + size * 0.04, y},
            {x - size * 0.12, y + size * 0.35},
        }, Basic.Alpha(VoltColor, alpha), 2)
    end,
})
