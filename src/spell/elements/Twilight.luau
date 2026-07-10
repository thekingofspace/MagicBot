local Basic = require("@src/spell/elements/Basic")

local Color = {r = 225, g = 140, b = 160}
local Accent = {r = 250, g = 200, b = 210}

return Basic.Make({
    Name = "Twilight",
    Emoji = "🌆",
    Color = Color,
    Accent = Accent,
    Noun = "Twilight",
    JetVerb = "stretches out",
    SpreadVerb = "dims",
    EvenVerb = "settles",
    Sigil = function(cv, x, y, size, power, alpha)
        local color = Basic.Alpha(Color, alpha)
        cv:line(x - size * 0.6, y, x + size * 0.6, y, color, 3)
        local steps = 14
        local arc = {}
        for i = 0, steps do
            local a = math.pi + math.pi * i / steps
            table.insert(arc, {x + size * 0.3 * math.cos(a), y + size * 0.42 + size * 0.3 * math.sin(a)})
        end
        cv:polyline(arc, Basic.Alpha(Color, alpha * 0.7), 2)
        local accent = Basic.Alpha(Accent, alpha)
        cv:circle(x - size * 0.35, y - size * 0.3, math.max(1, size * 0.05), accent)
        cv:circle(x + size * 0.4, y - size * 0.22, math.max(1, size * 0.04), accent)
    end,
})
