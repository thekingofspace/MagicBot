local Basic = require("@src/spell/elements/Basic")

local Color = {r = 150, g = 140, b = 135}
local Accent = {r = 210, g = 200, b = 190}
local FireColor = {r = 255, g = 110, b = 40}

return Basic.Make({
    Name = "Ash",
    Emoji = "🍂",
    Color = Color,
    Accent = Accent,
    Noun = "Ash",
    JetVerb = "billows out",
    SpreadVerb = "drifts",
    EvenVerb = "settles",
    Sigil = function(cv, x, y, size, power, alpha)
        Basic.Triangle(cv, x, y - size * 0.12, size * 0.85, true, false, Basic.Alpha(FireColor, alpha * 0.6), 2)
        local grey = Basic.Alpha(Color, alpha)
        cv:circle(x - size * 0.25, y + size * 0.4, math.max(2, size * 0.07), grey)
        cv:circle(x + size * 0.05, y + size * 0.52, math.max(2, size * 0.06), grey)
        cv:circle(x + size * 0.3, y + size * 0.38, math.max(2, size * 0.07), grey)
    end,
})
