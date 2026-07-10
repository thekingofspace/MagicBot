local Basic = require("@src/spell/elements/Basic")

local Color = {r = 255, g = 70, b = 70}
local Accent = {r = 255, g = 165, b = 165}

return Basic.Make({
    Name = "Laser",
    Emoji = "🔦",
    Color = Color,
    Accent = Accent,
    Noun = "The beam",
    JetVerb = "burns a line",
    SpreadVerb = "sweeps",
    EvenVerb = "focuses",
    Sigil = function(cv, x, y, size, power, alpha)
        local color = Basic.Alpha(Color, alpha)
        cv:circle(x - size * 0.45, y, math.max(3, size * 0.12), color)
        cv:line(x - size * 0.3, y, x + size * 0.55, y, color, 3)
        local accent = Basic.Alpha(Accent, alpha)
        cv:line(x - size * 0.3, y - size * 0.06, x + size * 0.4, y - size * 0.06, Basic.Alpha(Accent, alpha * 0.6), 1)
        cv:line(x - size * 0.3, y + size * 0.06, x + size * 0.4, y + size * 0.06, Basic.Alpha(Accent, alpha * 0.6), 1)
        cv:circle(x + size * 0.55, y, math.max(2, size * 0.07), accent)
    end,
})
