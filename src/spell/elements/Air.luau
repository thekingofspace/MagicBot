local Basic = require("@src/spell/elements/Basic")

local Color = {r = 185, g = 225, b = 240}
local Accent = {r = 235, g = 250, b = 255}

return Basic.Make({
    Name = "Air",
    Emoji = "🌬️",
    Color = Color,
    Accent = Accent,
    Noun = "Wind",
    JetVerb = "cuts out",
    SpreadVerb = "gusts",
    EvenVerb = "swirls",
    IdleText = "An air rune is drawn, but the wind stays still.",
    Sigil = function(cv, x, y, size, power, alpha)
        local color = Basic.Alpha(Color, alpha)
        for i = 1, math.clamp(power, 1, 3) do
            Basic.Triangle(cv, x, y, size * (1 - (i - 1) * 0.28), true, i == 1, color, 3)
        end
    end,
})
