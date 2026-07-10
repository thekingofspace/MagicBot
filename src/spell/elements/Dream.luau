local Basic = require("@src/spell/elements/Basic")

local Color = {r = 190, g = 170, b = 235}
local Accent = {r = 235, g = 225, b = 255}

return Basic.Make({
    Name = "Dream",
    Emoji = "💭",
    Color = Color,
    Accent = Accent,
    Noun = "Dreamstuff",
    JetVerb = "drifts out",
    SpreadVerb = "wanders",
    EvenVerb = "settles",
    Sigil = function(cv, x, y, size, power, alpha)
        local color = Basic.Alpha(Color, alpha)
        cv:strokeCircle(x - size * 0.1, y + size * 0.15, size * 0.35, color, 3)
        local accent = Basic.Alpha(Accent, alpha)
        cv:circle(x + size * 0.28, y - size * 0.15, math.max(2, size * 0.08), accent)
        cv:circle(x + size * 0.42, y - size * 0.35, math.max(1, size * 0.06), accent)
        cv:circle(x + size * 0.52, y - size * 0.52, math.max(1, size * 0.04), accent)
    end,
})
