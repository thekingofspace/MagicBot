local Basic = require("@src/spell/elements/Basic")

local Color = {r = 210, g = 225, b = 255}
local Accent = {r = 245, g = 250, b = 255}

return Basic.Make({
    Name = "Aether",
    Emoji = "✴️",
    Color = Color,
    Accent = Accent,
    Noun = "Aether",
    JetVerb = "whispers out",
    SpreadVerb = "permeates",
    EvenVerb = "suffuses",
    Sigil = function(cv, x, y, size, power, alpha)
        local color = Basic.Alpha(Color, alpha)
        cv:polygon({
            {x, y - size * 0.5},
            {x + size * 0.08, y - size * 0.08},
            {x + size * 0.5, y},
            {x + size * 0.08, y + size * 0.08},
            {x, y + size * 0.5},
            {x - size * 0.08, y + size * 0.08},
            {x - size * 0.5, y},
            {x - size * 0.08, y - size * 0.08},
        }, color)
        Basic.Wave(cv, x, y, size * 1.1, size * 0.08, Basic.Alpha(Accent, alpha), 2)
    end,
})
