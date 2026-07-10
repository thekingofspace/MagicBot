local Basic = require("@src/spell/elements/Basic")

local Color = {r = 110, g = 220, b = 120}
local Accent = {r = 190, g = 255, b = 190}

return Basic.Make({
    Name = "Life",
    Emoji = "🌱",
    Color = Color,
    Accent = Accent,
    Noun = "Life",
    JetVerb = "surges out",
    SpreadVerb = "flourishes",
    EvenVerb = "blooms",
    IdleText = "A life rune is drawn, but nothing stirs.",
    Sigil = function(cv, x, y, size, power, alpha)
        local color = Basic.Alpha(Color, alpha)
        cv:line(x, y + size * 0.5, x, y - size * 0.3, color, 3)
        cv:polyline({
            {x, y + size * 0.05},
            {x - size * 0.3, y - size * 0.12},
            {x - size * 0.42, y - size * 0.4},
        }, color, 3)
        cv:polyline({
            {x, y - size * 0.12},
            {x + size * 0.28, y - size * 0.3},
            {x + size * 0.4, y - size * 0.58},
        }, color, 3)
        cv:circle(x, y + size * 0.5, math.max(2, size * 0.1), Basic.Alpha(Accent, alpha))
        for i = 2, math.clamp(power, 1, 3) do
            cv:strokeCircle(x, y, size * (0.55 + (i - 1) * 0.2), Basic.Alpha(Color, alpha * 0.45), 2)
        end
    end,
})
