local Basic = require("@src/spell/elements/Basic")

local Color = {r = 150, g = 120, b = 220}
local Accent = {r = 220, g = 200, b = 255}

return Basic.Make({
    Name = "Nebula",
    Emoji = "💫",
    Color = Color,
    Accent = Accent,
    Noun = "Nebula",
    JetVerb = "streams out",
    SpreadVerb = "billows",
    EvenVerb = "wreathes the circle",
    Sigil = function(cv, x, y, size, power, alpha)
        local color = Basic.Alpha(Color, alpha)
        cv:strokeCircle(x - size * 0.22, y + size * 0.08, size * 0.28, color, 2)
        cv:strokeCircle(x + size * 0.15, y - size * 0.1, size * 0.34, color, 2)
        cv:strokeCircle(x + size * 0.3, y + size * 0.22, size * 0.2, color, 2)
        local accent = Basic.Alpha(Accent, alpha)
        cv:circle(x - size * 0.4, y - size * 0.35, math.max(1, size * 0.05), accent)
        cv:circle(x + size * 0.48, y - size * 0.3, math.max(1, size * 0.04), accent)
    end,
})
