local Basic = require("@src/spell/elements/Basic")

local Color = {r = 90, g = 70, b = 120}
local Accent = {r = 200, g = 180, b = 235}

return Basic.Make({
    Name = "Eclipse",
    Emoji = "🌒",
    Color = Color,
    Accent = Accent,
    Noun = "The eclipse",
    JetVerb = "swallows",
    SpreadVerb = "veils",
    EvenVerb = "darkens",
    Sigil = function(cv, x, y, size, power, alpha)
        cv:circle(x, y, size * 0.42, Basic.Alpha({r = 15, g = 10, b = 25}, alpha))
        cv:strokeCircle(x, y, size * 0.44, Basic.Alpha(Accent, alpha), 3)
        cv:strokeCircle(x, y, size * 0.56, Basic.Alpha(Color, alpha * 0.7), 2)
    end,
})
