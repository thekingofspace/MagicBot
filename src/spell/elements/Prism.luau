local Basic = require("@src/spell/elements/Basic")

local Color = {r = 185, g = 205, b = 255}
local Accent = {r = 235, g = 240, b = 255}
local LightColor = {r = 255, g = 244, b = 190}
local WaterColor = {r = 60, g = 140, b = 255}

return Basic.Make({
    Name = "Prism",
    Emoji = "🌈",
    Color = Color,
    Accent = Accent,
    Noun = "Prismlight",
    JetVerb = "refracts out",
    SpreadVerb = "scatters",
    EvenVerb = "shimmers",
    Sigil = function(cv, x, y, size, power, alpha)
        Basic.Triangle(cv, x - size * 0.12, y, size * 0.8, true, false, Basic.Alpha(WaterColor, alpha), 3)
        local light = Basic.Alpha(LightColor, alpha)
        for i = -1, 1 do
            cv:line(
                x + size * 0.12, y + i * size * 0.08,
                x + size * 0.62, y + i * size * 0.24,
                light, 2
            )
        end
    end,
})
