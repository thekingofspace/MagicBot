local Basic = require("@src/spell/elements/Basic")

local Color = {r = 170, g = 200, b = 220}
local Accent = {r = 225, g = 240, b = 250}
local WaterColor = {r = 60, g = 140, b = 255}
local AirColor = {r = 185, g = 225, b = 240}

return Basic.Make({
    Name = "Mist",
    Emoji = "🌫️",
    Color = Color,
    Accent = Accent,
    Noun = "Mist",
    JetVerb = "streams out",
    SpreadVerb = "drifts",
    EvenVerb = "hangs",
    Sigil = function(cv, x, y, size, power, alpha)
        Basic.Triangle(cv, x, y, size, false, false, Basic.Alpha(WaterColor, alpha), 3)
        Basic.Triangle(cv, x, y, size, true, true, Basic.Alpha(AirColor, alpha), 3)
    end,
})
