local Basic = require("@src/spell/elements/Basic")

local Color = {r = 160, g = 170, b = 150}
local Accent = {r = 210, g = 215, b = 200}

return Basic.Make({
    Name = "Erosion",
    Emoji = "🏞️",
    Color = Color,
    Accent = Accent,
    Noun = "Erosion",
    JetVerb = "wears through",
    SpreadVerb = "washes away",
    EvenVerb = "wears all down",
    Sigil = function(cv, x, y, size, power, alpha)
        local color = Basic.Alpha(Color, alpha)
        cv:line(x - size * 0.55, y - size * 0.4, x - size * 0.15, y - size * 0.4, color, 3)
        cv:line(x + size * 0.15, y - size * 0.4, x + size * 0.55, y - size * 0.4, color, 3)
        cv:line(x - size * 0.15, y - size * 0.4, x - size * 0.05, y + size * 0.1, color, 2)
        cv:line(x + size * 0.15, y - size * 0.4, x + size * 0.05, y + size * 0.1, color, 2)
        Basic.Wave(cv, x, y + size * 0.25, size * 0.9, size * 0.06, Basic.Alpha(Accent, alpha), 2)
        Basic.Wave(cv, x, y + size * 0.45, size * 0.7, size * 0.05, Basic.Alpha(Accent, alpha * 0.6), 2)
    end,
})
