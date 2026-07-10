local Basic = require("@src/spell/elements/Basic")

local Color = {r = 160, g = 230, b = 230}
local Accent = {r = 225, g = 255, b = 255}

return Basic.Make({
    Name = "Ion",
    Emoji = "⚛️",
    Color = Color,
    Accent = Accent,
    Noun = "Ionwind",
    JetVerb = "streams out",
    SpreadVerb = "disperses",
    EvenVerb = "charges the air",
    Sigil = function(cv, x, y, size, power, alpha)
        local color = Basic.Alpha(Color, alpha)
        for _, tilt in ipairs({0.5, -0.5}) do
            local points = {}
            local steps = 24
            for i = 0, steps do
                local a = 2 * math.pi * i / steps
                local ox = size * 0.55 * math.cos(a)
                local oy = size * 0.22 * math.sin(a)
                table.insert(points, {
                    x + ox * math.cos(tilt) - oy * math.sin(tilt),
                    y + ox * math.sin(tilt) + oy * math.cos(tilt),
                })
            end
            cv:polyline(points, color, 2)
        end
        cv:circle(x, y, math.max(2, size * 0.1), Basic.Alpha(Accent, alpha))
    end,
})
