local Basic = require("@src/spell/elements/Basic")

local Color = {r = 200, g = 110, b = 60}
local Accent = {r = 240, g = 170, b = 110}
local FireColor = {r = 255, g = 110, b = 40}

return Basic.Make({
    Name = "Smolder",
    Emoji = "🕯️",
    Color = Color,
    Accent = Accent,
    Noun = "Smolder",
    JetVerb = "creeps out",
    SpreadVerb = "smoulders",
    EvenVerb = "burns low",
    Sigil = function(cv, x, y, size, power, alpha)
        Basic.Triangle(cv, x, y + size * 0.15, size * 0.7, true, false, Basic.Alpha(FireColor, alpha * 0.6), 3)
        Basic.Wave(cv, x, y - size * 0.35, size * 0.7, size * 0.08, Basic.Alpha(Color, alpha), 2)
        Basic.Wave(cv, x, y - size * 0.55, size * 0.5, size * 0.06, Basic.Alpha(Color, alpha * 0.6), 2)
    end,
})
