local Basic = require("@src/spell/elements/Basic")

local Color = {r = 150, g = 135, b = 190}
local Accent = {r = 205, g = 190, b = 240}

return Basic.Make({
    Name = "Gravity",
    Emoji = "🌀",
    Color = Color,
    Accent = Accent,
    Noun = "Gravity",
    JetVerb = "wrenches",
    SpreadVerb = "drags",
    EvenVerb = "presses",
    IdleText = "A gravity rune is drawn, but nothing feels its weight.",
    Sigil = function(cv, x, y, size, power, alpha)
        local color = Basic.Alpha(Color, alpha)
        local points = {}
        local turns = 2.2
        local steps = 40
        for i = 0, steps do
            local t = i / steps
            local a = t * turns * 2 * math.pi
            local r = size * 0.6 * (1 - t)
            table.insert(points, {x + r * math.cos(a), y + r * math.sin(a)})
        end
        cv:polyline(points, color, 3)
        cv:circle(x, y, math.max(3, size * 0.12), Basic.Alpha(Accent, alpha))
    end,
})
