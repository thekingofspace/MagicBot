local Basic = require("@src/spell/elements/Basic")

local Color = {r = 255, g = 230, b = 140}
local Accent = {r = 255, g = 255, b = 215}

return Basic.Make({
    Name = "Star",
    Emoji = "⭐",
    Color = Color,
    Accent = Accent,
    Noun = "Starlight",
    JetVerb = "beams out",
    SpreadVerb = "radiates",
    EvenVerb = "shines",
    Sigil = function(cv, x, y, size, power, alpha)
        cv:star(x, y, 5, size * 0.55, size * 0.22, Basic.Alpha(Color, alpha))
        cv:circle(x, y, math.max(2, size * 0.09), Basic.Alpha(Accent, alpha))
    end,
})
