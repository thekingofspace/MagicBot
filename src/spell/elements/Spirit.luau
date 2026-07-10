local Basic = require("@src/spell/elements/Basic")

local Color = {r = 200, g = 235, b = 225}
local Accent = {r = 240, g = 255, b = 250}
local AirColor = {r = 185, g = 225, b = 240}
local LifeColor = {r = 110, g = 220, b = 120}

return Basic.Make({
    Name = "Spirit",
    Emoji = "👻",
    Color = Color,
    Accent = Accent,
    Noun = "Spirit",
    JetVerb = "wails out",
    SpreadVerb = "haunts",
    EvenVerb = "lingers",
    Sigil = function(cv, x, y, size, power, alpha)
        cv:strokeCircle(x, y - size * 0.15, size * 0.4, Basic.Alpha(AirColor, alpha), 3)
        Basic.Wave(cv, x, y + size * 0.4, size * 0.9, size * 0.1, Basic.Alpha(LifeColor, alpha), 3)
        cv:circle(x, y - size * 0.15, math.max(2, size * 0.08), Basic.Alpha(Accent, alpha))
    end,
})
