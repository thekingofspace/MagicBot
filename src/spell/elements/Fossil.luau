local Basic = require("@src/spell/elements/Basic")

local Color = {r = 170, g = 150, b = 115}
local Accent = {r = 215, g = 200, b = 165}

return Basic.Make({
    Name = "Fossil",
    Emoji = "🦴",
    Color = Color,
    Accent = Accent,
    Noun = "Fossil",
    JetVerb = "sets",
    SpreadVerb = "petrifies",
    EvenVerb = "hardens with age",
    Sigil = function(cv, x, y, size, power, alpha)
        local color = Basic.Alpha(Color, alpha)
        local points = {}
        local turns = 2.6
        local steps = 44
        for i = 0, steps do
            local t = i / steps
            local a = t * turns * 2 * math.pi
            local r = size * 0.58 * t
            table.insert(points, {x + r * math.cos(a), y + r * math.sin(a)})
        end
        cv:polyline(points, color, 3)
        cv:circle(x, y, math.max(1, size * 0.05), Basic.Alpha(Accent, alpha))
    end,
})
