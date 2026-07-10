local Basic = require("@src/spell/elements/Basic")

local Color = {r = 150, g = 105, b = 60}
local Accent = {r = 210, g = 170, b = 110}

return Basic.Make({
    Name = "Ground",
    Emoji = "🪨",
    Color = Color,
    Accent = Accent,
    Noun = "Stone",
    JetVerb = "drives out",
    SpreadVerb = "scatters",
    EvenVerb = "rises",
    IdleText = "A ground rune is drawn, but the earth does not answer.",
    Sigil = function(cv, x, y, size, power, alpha)
        local color = Basic.Alpha(Color, alpha)
        for i = 1, math.clamp(power, 1, 3) do
            Basic.Triangle(cv, x, y, size * (1 - (i - 1) * 0.28), false, i == 1, color, 3)
        end
    end,
})
