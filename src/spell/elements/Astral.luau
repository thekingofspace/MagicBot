local Basic = require("@src/spell/elements/Basic")

local Color = {r = 125, g = 105, b = 220}
local Accent = {r = 195, g = 185, b = 255}

return Basic.Make({
    Name = "Astral",
    Emoji = "🌌",
    Color = Color,
    Accent = Accent,
    Noun = "The astral self",
    JetVerb = "ranges out",
    SpreadVerb = "wanders",
    EvenVerb = "hovers",
    IdleText = "The self steps outward an inch, then thinks better of it.",
    Sigil = function(cv, x, y, size, power, alpha)
        local color = Basic.Alpha(Color, alpha)
        local accent = Basic.Alpha(Accent, alpha)

        -- the sleeping self
        cv:strokeCircle(x - size * 0.36, y + size * 0.42, size * 0.14, color, 2)

        -- the silver cord
        local cord = {}
        local steps = 12
        for i = 0, steps do
            local t = i / steps
            local px = x - size * 0.36 + size * 0.66 * t
            local py = y + size * 0.42 - size * 0.82 * t
            table.insert(cord, {px + math.sin(t * math.pi * 3) * size * 0.06, py})
        end
        cv:polyline(cord, color, 2)

        -- the projected star
        local sx, sy = x + size * 0.3, y - size * 0.4
        cv:line(sx - size * 0.2, sy, sx + size * 0.2, sy, accent, 2)
        cv:line(sx, sy - size * 0.2, sx, sy + size * 0.2, accent, 2)
        cv:line(sx - size * 0.09, sy - size * 0.09, sx + size * 0.09, sy + size * 0.09, accent, 2)
        cv:line(sx - size * 0.09, sy + size * 0.09, sx + size * 0.09, sy - size * 0.09, accent, 2)

        -- distant stars
        cv:circle(x + size * 0.56, y + size * 0.14, math.max(1, size * 0.03), accent)
        cv:circle(x - size * 0.16, y - size * 0.54, math.max(1, size * 0.03), accent)
    end,
})
