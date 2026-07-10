local Basic = require("@src/spell/elements/Basic")

local Color = {r = 200, g = 215, b = 230}
local Accent = {r = 240, g = 248, b = 255}
local FireColor = {r = 255, g = 110, b = 40}
local WaterColor = {r = 60, g = 140, b = 255}

return Basic.Make({
    Name = "Steam",
    Emoji = "♨️",
    Color = Color,
    Accent = Accent,
    Noun = "Steam",
    JetVerb = "blasts out",
    SpreadVerb = "rolls",
    EvenVerb = "billows",
    Sigil = function(cv, x, y, size, power, alpha)
        Basic.Triangle(cv, x, y, size, true, false, Basic.Alpha(FireColor, alpha), 3)
        Basic.Triangle(cv, x, y, size, false, false, Basic.Alpha(WaterColor, alpha), 3)
        cv:circle(x, y, math.max(3, size * 0.08), Basic.Alpha(Accent, alpha))
    end,
})
