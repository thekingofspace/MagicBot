local Basic = require("@src/spell/elements/Basic")

local Color = {r = 90, g = 175, b = 95}
local Accent = {r = 165, g = 230, b = 155}
local GroundColor = {r = 150, g = 105, b = 60}
local LifeColor = {r = 110, g = 220, b = 120}

return Basic.Make({
    Name = "Verdure",
    Emoji = "🌿",
    Color = Color,
    Accent = Accent,
    Noun = "Verdure",
    JetVerb = "vines out",
    SpreadVerb = "overgrows",
    EvenVerb = "takes root",
    Sigil = function(cv, x, y, size, power, alpha)
        Basic.Triangle(cv, x, y + size * 0.15, size * 0.85, false, true, Basic.Alpha(GroundColor, alpha), 3)
        local green = Basic.Alpha(LifeColor, alpha)
        cv:line(x, y + size * 0.1, x, y - size * 0.5, green, 3)
        cv:polyline({
            {x, y - size * 0.2},
            {x - size * 0.25, y - size * 0.35},
            {x - size * 0.35, y - size * 0.6},
        }, green, 3)
        cv:polyline({
            {x, y - size * 0.35},
            {x + size * 0.22, y - size * 0.5},
            {x + size * 0.32, y - size * 0.72},
        }, green, 3)
    end,
})
