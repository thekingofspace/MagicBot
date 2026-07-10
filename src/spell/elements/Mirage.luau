local Basic = require("@src/spell/elements/Basic")

local Color = {r = 235, g = 225, b = 180}
local Accent = {r = 255, g = 250, b = 225}

return Basic.Make({
    Name = "Mirage",
    Emoji = "🏜️",
    Color = Color,
    Accent = Accent,
    Noun = "Mirage",
    JetVerb = "shimmers out",
    SpreadVerb = "ripples",
    EvenVerb = "wavers",
    Sigil = function(cv, x, y, size, power, alpha)
        local color = Basic.Alpha(Color, alpha)
        Basic.Wave(cv, x, y - size * 0.25, size, size * 0.07, color, 2)
        Basic.Wave(cv, x, y, size, size * 0.07, Basic.Alpha(Color, alpha * 0.75), 2)
        Basic.Wave(cv, x, y + size * 0.25, size, size * 0.07, Basic.Alpha(Color, alpha * 0.5), 2)
        cv:circle(x, y - size * 0.5, math.max(2, size * 0.09), Basic.Alpha(Accent, alpha))
    end,
})
