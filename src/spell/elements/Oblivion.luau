local Basic = require("@src/spell/elements/Basic")

local Color = {r = 60, g = 55, b = 75}
local Accent = {r = 150, g = 140, b = 180}

return Basic.Make({
    Name = "Oblivion",
    Emoji = "🌑",
    Color = Color,
    Accent = Accent,
    Noun = "Oblivion",
    JetVerb = "devours",
    SpreadVerb = "swallows",
    EvenVerb = "hollows the circle",
    Sigil = function(cv, x, y, size, power, alpha)
        cv:circle(x, y, size * 0.3, Basic.Alpha({r = 8, g = 6, b = 14}, alpha))
        cv:strokeCircle(x, y, size * 0.32, Basic.Alpha(Accent, alpha), 2)
        cv:strokeCircle(x, y, size * 0.46, Basic.Alpha(Color, alpha * 0.7), 2)
        cv:strokeCircle(x, y, size * 0.6, Basic.Alpha(Color, alpha * 0.35), 1)
    end,
})
