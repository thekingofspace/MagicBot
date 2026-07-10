local Basic = require("@src/spell/elements/Basic")

local Color = {r = 210, g = 180, b = 110}
local Accent = {r = 245, g = 225, b = 160}
local AirColor = {r = 185, g = 225, b = 240}
local GroundColor = {r = 150, g = 105, b = 60}

return Basic.Make({
    Name = "Sandstorm",
    Emoji = "🌪️",
    Color = Color,
    Accent = Accent,
    Noun = "Sand",
    JetVerb = "blasts out",
    SpreadVerb = "whirls",
    EvenVerb = "churns",
    Sigil = function(cv, x, y, size, power, alpha)
        Basic.Triangle(cv, x, y, size, true, true, Basic.Alpha(AirColor, alpha), 3)
        Basic.Triangle(cv, x, y, size, false, true, Basic.Alpha(GroundColor, alpha), 3)
    end,
})
