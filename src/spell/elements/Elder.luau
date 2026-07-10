local Basic = require("@src/spell/elements/Basic")

local Color = {r = 100, g = 140, b = 80}
local Accent = {r = 170, g = 200, b = 140}

return Basic.Make({
    Name = "Elder",
    Emoji = "🌳",
    Color = Color,
    Accent = Accent,
    Noun = "The elder growth",
    JetVerb = "grows out",
    SpreadVerb = "overgrows",
    EvenVerb = "deepens its roots",
    Sigil = function(cv, x, y, size, power, alpha)
        local color = Basic.Alpha(Color, alpha)
        cv:line(x, y + size * 0.55, x, y - size * 0.1, color, 4)
        cv:strokeCircle(x, y - size * 0.3, size * 0.32, color, 3)
        local accent = Basic.Alpha(Accent, alpha)
        cv:line(x, y + size * 0.55, x - size * 0.3, y + size * 0.7, accent, 2)
        cv:line(x, y + size * 0.55, x + size * 0.3, y + size * 0.7, accent, 2)
        cv:line(x, y + size * 0.4, x - size * 0.2, y + size * 0.55, accent, 2)
    end,
})
