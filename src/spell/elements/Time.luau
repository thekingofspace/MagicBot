local Basic = require("@src/spell/elements/Basic")

local Color = {r = 220, g = 195, b = 145}
local Accent = {r = 245, g = 230, b = 190}

return Basic.Make({
    Name = "Time",
    Emoji = "⏳",
    Color = Color,
    Accent = Accent,
    Noun = "Time",
    JetVerb = "pours out",
    SpreadVerb = "wears",
    EvenVerb = "slows",
    IdleText = "A time rune is drawn, but the moment passes.",
    Sigil = function(cv, x, y, size, power, alpha)
        local color = Basic.Alpha(Color, alpha)
        Basic.Triangle(cv, x, y - size * 0.3, size * 0.62, false, false, color, 3)
        Basic.Triangle(cv, x, y + size * 0.3, size * 0.62, true, false, color, 3)
        cv:line(x - size * 0.36, y - size * 0.62, x + size * 0.36, y - size * 0.62, color, 3)
        cv:line(x - size * 0.36, y + size * 0.62, x + size * 0.36, y + size * 0.62, color, 3)
        local accent = Basic.Alpha(Accent, alpha)
        cv:circle(x, y - size * 0.02, math.max(1, size * 0.05), accent)
        cv:circle(x, y + size * 0.3, math.max(2, size * 0.07), accent)
    end,
})
