local Basic = require("@src/spell/elements/Basic")

local Color = {r = 125, g = 115, b = 105}
local Accent = {r = 190, g = 180, b = 170}

return Basic.Make({
    Name = "Bedrock",
    Emoji = "🏔️",
    Color = Color,
    Accent = Accent,
    Noun = "Bedrock",
    JetVerb = "grinds out",
    SpreadVerb = "spreads",
    EvenVerb = "stands unmoved",
    Sigil = function(cv, x, y, size, power, alpha)
        local color = Basic.Alpha(Color, alpha)
        Basic.Triangle(cv, x, y - size * 0.08, size * 0.85, false, true, color, 3)
        cv:line(x - size * 0.55, y + size * 0.45, x + size * 0.55, y + size * 0.45, color, 3)
        cv:line(x - size * 0.4, y + size * 0.6, x + size * 0.4, y + size * 0.6, Basic.Alpha(Color, alpha * 0.6), 2)
    end,
})
