local Basic = require("@src/spell/elements/Basic")

local Color = {r = 190, g = 180, b = 255}
local Accent = {r = 235, g = 230, b = 255}

return Basic.Make({
    Name = "Pulsar",
    Emoji = "🌟",
    Color = Color,
    Accent = Accent,
    Noun = "The pulsar",
    JetVerb = "beats out",
    SpreadVerb = "sweeps",
    EvenVerb = "pulses",
    Sigil = function(cv, x, y, size, power, alpha)
        local color = Basic.Alpha(Color, alpha)
        cv:circle(x, y, math.max(3, size * 0.12), Basic.Alpha(Accent, alpha))
        cv:strokeCircle(x, y, size * 0.28, color, 2)
        for _, side in ipairs({-1, 1}) do
            cv:line(
                x + side * size * 0.12, y - side * size * 0.12,
                x + side * size * 0.6, y - side * size * 0.6,
                color, 3
            )
        end
    end,
})
