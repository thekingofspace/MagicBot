local Basic = require("@src/spell/elements/Basic")

local Color = {r = 30, g = 80, b = 160}
local Accent = {r = 110, g = 160, b = 220}

return Basic.Make({
    Name = "Abyss",
    Emoji = "🌊",
    Color = Color,
    Accent = Accent,
    Noun = "The deep",
    JetVerb = "surges out",
    SpreadVerb = "floods",
    EvenVerb = "presses in",
    Sigil = function(cv, x, y, size, power, alpha)
        local color = Basic.Alpha(Color, alpha)
        Basic.Triangle(cv, x, y - size * 0.1, size * 0.85, false, false, color, 3)
        cv:line(x - size * 0.45, y + size * 0.4, x + size * 0.45, y + size * 0.4, color, 2)
        cv:line(x - size * 0.32, y + size * 0.55, x + size * 0.32, y + size * 0.55, Basic.Alpha(Color, alpha * 0.6), 2)
        cv:circle(x, y - size * 0.1, math.max(2, size * 0.08), Basic.Alpha(Accent, alpha))
    end,
})
