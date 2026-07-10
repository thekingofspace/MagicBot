local Basic = require("@src/spell/elements/Basic")

local Color = {r = 255, g = 110, b = 40}
local Accent = {r = 255, g = 205, b = 110}

return Basic.Make({
    Name = "Fire",
    Emoji = "🔥",
    Color = Color,
    Accent = Accent,
    Noun = "Fire",
    JetVerb = "shoots out",
    SpreadVerb = "washes",
    EvenVerb = "burns",
    IdleText = "A fire rune is drawn, but no heat gathers.",
    Sigil = function(cv, x, y, size, power, alpha)
        local color = Basic.Alpha(Color, alpha)
        for i = 1, math.clamp(power, 1, 3) do
            Basic.Triangle(cv, x, y, size * (1 - (i - 1) * 0.28), true, false, color, 3)
        end
        cv:circle(x, y, math.max(3, size * 0.09), Basic.Alpha(Accent, alpha))
    end,
})
