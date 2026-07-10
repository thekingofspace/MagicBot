local Basic = require("@src/spell/elements/Basic")

local Color = {r = 255, g = 140, b = 20}
local Accent = {r = 255, g = 230, b = 120}
local FireColor = {r = 255, g = 110, b = 40}
local AirColor = {r = 185, g = 225, b = 240}

return Basic.Make({
    Name = "Wildfire",
    Emoji = "☄️",
    Color = Color,
    Accent = Accent,
    Noun = "Wildfire",
    JetVerb = "roars out",
    SpreadVerb = "races",
    EvenVerb = "rages",
    Sigil = function(cv, x, y, size, power, alpha)
        Basic.Triangle(cv, x - size * 0.2, y, size * 0.85, true, false, Basic.Alpha(FireColor, alpha), 3)
        Basic.Triangle(cv, x + size * 0.2, y, size * 0.85, true, true, Basic.Alpha(AirColor, alpha), 3)
    end,
})
