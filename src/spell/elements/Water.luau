local Basic = require("@src/spell/elements/Basic")

local Color = {r = 60, g = 140, b = 255}
local Accent = {r = 150, g = 210, b = 255}

return Basic.Make({
    Name = "Water",
    Emoji = "💧",
    Color = Color,
    Accent = Accent,
    Noun = "Water",
    JetVerb = "jets out",
    SpreadVerb = "washes",
    EvenVerb = "pools",
    IdleText = "A water rune is drawn, but the circle stays dry.",
    Sigil = function(cv, x, y, size, power, alpha)
        local color = Basic.Alpha(Color, alpha)
        for i = 1, math.clamp(power, 1, 3) do
            Basic.Triangle(cv, x, y, size * (1 - (i - 1) * 0.28), false, false, color, 3)
        end
        Basic.Wave(cv, x, y + size * 0.72, size * 0.9, size * 0.07, Basic.Alpha(Accent, alpha), 2)
    end,
})
