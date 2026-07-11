local Basic = require("@src/spell/elements/Basic")

local Color = {r = 210, g = 155, b = 140}
local Accent = {r = 240, g = 210, b = 190}

return Basic.Make({
    Name = "Memory",
    Emoji = "🥀",
    Color = Color,
    Accent = Accent,
    Noun = "Memory",
    JetVerb = "wells out",
    SpreadVerb = "lingers",
    EvenVerb = "keeps",
    IdleText = "A moment is pressed like a flower, and forgotten.",
    Sigil = function(cv, x, y, size, power, alpha)
        local color = Basic.Alpha(Color, alpha)
        local accent = Basic.Alpha(Accent, alpha)

        -- the locket and its clasp
        cv:strokeCircle(x, y + size * 0.12, size * 0.42, color, 3)
        cv:strokeCircle(x, y - size * 0.44, size * 0.1, color, 2)
        cv:line(x, y - size * 0.34, x, y - size * 0.3, color, 2)

        -- a thought pressed inside, curled small to keep
        local spiral = {}
        local steps = 22
        for i = 0, steps do
            local t = i / steps
            local a = -math.pi / 2 + math.pi * 2 * 1.8 * t
            local r = size * 0.24 * (1 - t * 0.8)
            table.insert(spiral, {x + r * math.cos(a), y + size * 0.12 + r * math.sin(a)})
        end
        cv:polyline(spiral, accent, 2)
        cv:circle(x, y + size * 0.12, math.max(1, size * 0.04), accent)
    end,
})
