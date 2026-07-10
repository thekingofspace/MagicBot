local Basic = require("@src/spell/elements/Basic")

local Color = {r = 255, g = 200, b = 60}
local Accent = {r = 255, g = 240, b = 170}

return Basic.Make({
    Name = "Solar",
    Emoji = "☀️",
    Color = Color,
    Accent = Accent,
    Noun = "Solar fire",
    JetVerb = "flares out",
    SpreadVerb = "washes",
    EvenVerb = "blazes",
    Sigil = function(cv, x, y, size, power, alpha)
        local color = Basic.Alpha(Color, alpha)
        cv:strokeCircle(x, y, size * 0.3, color, 3)
        for i = 0, 7 do
            local a = i * math.pi / 4
            cv:line(
                x + size * 0.38 * math.cos(a), y + size * 0.38 * math.sin(a),
                x + size * 0.6 * math.cos(a), y + size * 0.6 * math.sin(a),
                color, 2
            )
        end
        cv:circle(x, y, math.max(2, size * 0.1), Basic.Alpha(Accent, alpha))
    end,
})
