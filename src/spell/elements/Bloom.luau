local Basic = require("@src/spell/elements/Basic")

local Color = {r = 245, g = 150, b = 200}
local Accent = {r = 255, g = 215, b = 235}
local WaterColor = {r = 60, g = 140, b = 255}
local LifeColor = {r = 110, g = 220, b = 120}

return Basic.Make({
    Name = "Bloom",
    Emoji = "🌸",
    Color = Color,
    Accent = Accent,
    Noun = "Bloom",
    JetVerb = "blossoms out",
    SpreadVerb = "overgrows",
    EvenVerb = "flowers",
    Sigil = function(cv, x, y, size, power, alpha)
        local petals = 5
        for i = 0, petals - 1 do
            local a = -math.pi / 2 + 2 * math.pi * i / petals
            cv:strokeCircle(
                x + size * 0.3 * math.cos(a),
                y + size * 0.3 * math.sin(a),
                size * 0.24, Basic.Alpha(Color, alpha), 2
            )
        end
        cv:circle(x, y, math.max(3, size * 0.14), Basic.Alpha(WaterColor, alpha))
        cv:strokeCircle(x, y, math.max(4, size * 0.2), Basic.Alpha(LifeColor, alpha), 2)
    end,
})
