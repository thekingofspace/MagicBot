local Basic = require("@src/spell/elements/Basic")

local Color = {r = 150, g = 240, b = 130}
local Accent = {r = 220, g = 255, b = 200}

return Basic.Make({
    Name = "Nerve",
    Emoji = "🧠",
    Color = Color,
    Accent = Accent,
    Noun = "Nerve-fire",
    JetVerb = "jolts out",
    SpreadVerb = "networks",
    EvenVerb = "tingles",
    Sigil = function(cv, x, y, size, power, alpha)
        local color = Basic.Alpha(Color, alpha)
        cv:line(x, y + size * 0.55, x, y, color, 3)
        cv:line(x, y, x - size * 0.35, y - size * 0.35, color, 2)
        cv:line(x, y, x + size * 0.35, y - size * 0.3, color, 2)
        cv:line(x - size * 0.35, y - size * 0.35, x - size * 0.5, y - size * 0.6, color, 2)
        cv:line(x - size * 0.35, y - size * 0.35, x - size * 0.12, y - size * 0.62, color, 2)
        local accent = Basic.Alpha(Accent, alpha)
        cv:circle(x - size * 0.5, y - size * 0.6, math.max(2, size * 0.06), accent)
        cv:circle(x - size * 0.12, y - size * 0.62, math.max(2, size * 0.06), accent)
        cv:circle(x + size * 0.35, y - size * 0.3, math.max(2, size * 0.06), accent)
    end,
})
