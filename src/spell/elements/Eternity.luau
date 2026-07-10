local Basic = require("@src/spell/elements/Basic")

local Color = {r = 140, g = 130, b = 220}
local Accent = {r = 200, g = 195, b = 250}

return Basic.Make({
    Name = "Eternity",
    Emoji = "♾️",
    Color = Color,
    Accent = Accent,
    Noun = "Eternity",
    JetVerb = "unfolds",
    SpreadVerb = "expands",
    EvenVerb = "outlasts the circle",
    Sigil = function(cv, x, y, size, power, alpha)
        local color = Basic.Alpha(Color, alpha)
        cv:strokeCircle(x - size * 0.26, y, size * 0.26, color, 3)
        cv:strokeCircle(x + size * 0.26, y, size * 0.26, color, 3)
        cv:circle(x, y, math.max(2, size * 0.06), Basic.Alpha(Accent, alpha))
    end,
})
