local Basic = require("@src/spell/elements/Basic")

local Color = {r = 120, g = 90, b = 55}
local Accent = {r = 170, g = 140, b = 95}
local WaterColor = {r = 60, g = 140, b = 255}
local GroundColor = {r = 150, g = 105, b = 60}

return Basic.Make({
    Name = "Mud",
    Emoji = "🟫",
    Color = Color,
    Accent = Accent,
    Noun = "Mud",
    JetVerb = "sprays out",
    SpreadVerb = "spreads",
    EvenVerb = "pools",
    Sigil = function(cv, x, y, size, power, alpha)
        Basic.Triangle(cv, x - size * 0.2, y, size * 0.85, false, false, Basic.Alpha(WaterColor, alpha), 3)
        Basic.Triangle(cv, x + size * 0.2, y, size * 0.85, false, true, Basic.Alpha(GroundColor, alpha), 3)
    end,
})
