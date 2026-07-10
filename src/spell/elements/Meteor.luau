local Basic = require("@src/spell/elements/Basic")

local Color = {r = 230, g = 120, b = 70}
local Accent = {r = 255, g = 200, b = 140}

return Basic.Make({
    Name = "Meteor",
    Emoji = "🌠",
    Color = Color,
    Accent = Accent,
    Noun = "Meteor",
    JetVerb = "plunges",
    SpreadVerb = "showers",
    EvenVerb = "rains down",
    Sigil = function(cv, x, y, size, power, alpha)
        local color = Basic.Alpha(Color, alpha)
        cv:circle(x - size * 0.2, y + size * 0.2, size * 0.22, color)
        local accent = Basic.Alpha(Accent, alpha)
        for i = -1, 1 do
            cv:line(
                x - size * 0.05 + i * size * 0.12, y + size * 0.05 - i * size * 0.12,
                x + size * 0.55 + i * size * 0.08, y - size * 0.55 + i * size * 0.08,
                accent, 2
            )
        end
    end,
})
