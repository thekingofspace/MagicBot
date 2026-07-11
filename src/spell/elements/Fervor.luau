local Basic = require("@src/spell/elements/Basic")

local Color = {r = 255, g = 90, b = 85}
local Accent = {r = 255, g = 185, b = 130}

return Basic.Make({
    Name = "Fervor",
    Emoji = "❤️‍🔥",
    Color = Color,
    Accent = Accent,
    Noun = "Fervor",
    JetVerb = "surges out",
    SpreadVerb = "sweeps",
    EvenVerb = "smolders",
    IdleText = "A passion kindles, then finds nothing to burn for.",
    Sigil = function(cv, x, y, size, power, alpha)
        local color = Basic.Alpha(Color, alpha)
        local accent = Basic.Alpha(Accent, alpha)

        -- a heart, drawn hot
        local points = {}
        local steps = 26
        for i = 0, steps do
            local t = i / steps * 2 * math.pi
            local hx = 16 * math.sin(t) ^ 3
            local hy = 13 * math.cos(t) - 5 * math.cos(2 * t) - 2 * math.cos(3 * t) - math.cos(4 * t)
            table.insert(points, {x + hx * size / 36, y - (hy + 5) * size / 36 + size * 0.1})
        end
        cv:polyline(points, color, 3)

        -- flame licking up from the cleft
        cv:polyline({
            {x - size * 0.12, y - size * 0.28},
            {x, y - size * 0.58},
            {x + size * 0.12, y - size * 0.28},
        }, accent, 2)
        cv:line(x, y - size * 0.5, x, y - size * 0.3, accent, 2)
        cv:circle(x, y + size * 0.14, math.max(2, size * 0.06), accent)
    end,
})
