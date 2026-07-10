local Basic = require("@src/spell/elements/Basic")

local Color = {r = 255, g = 70, b = 30}
local Accent = {r = 255, g = 160, b = 60}
local FireColor = {r = 255, g = 110, b = 40}
local GroundColor = {r = 150, g = 105, b = 60}

return Basic.Make({
    Name = "Magma",
    Emoji = "🌋",
    Color = Color,
    Accent = Accent,
    Noun = "Magma",
    JetVerb = "erupts",
    SpreadVerb = "oozes",
    EvenVerb = "wells up",
    Sigil = function(cv, x, y, size, power, alpha)
        Basic.Triangle(cv, x, y, size, true, false, Basic.Alpha(FireColor, alpha), 3)
        Basic.Triangle(cv, x, y, size, false, true, Basic.Alpha(GroundColor, alpha), 3)
        cv:circle(x, y, math.max(3, size * 0.08), Basic.Alpha(Accent, alpha))
    end,
})
