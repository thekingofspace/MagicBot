local Basic = require("@src/spell/elements/Basic")

local Color = {r = 95, g = 115, b = 215}
local Accent = {r = 165, g = 185, b = 250}

return Basic.Make({
    Name = "Reverie",
    Emoji = "🌙",
    Color = Color,
    Accent = Accent,
    Noun = "Reverie",
    JetVerb = "drifts out",
    SpreadVerb = "pools",
    EvenVerb = "lulls",
    IdleText = "A daydream gathers at the edge of sleep, and slips away.",
    Sigil = function(cv, x, y, size, power, alpha)
        local color = Basic.Alpha(Color, alpha)
        local accent = Basic.Alpha(Accent, alpha)

        -- a closed eyelid
        local w = size * 0.55
        local lid = {}
        local steps = 14
        for i = 0, steps do
            local t = i / steps
            table.insert(lid, {x - w + 2 * w * t, y - size * 0.3 + math.sin(math.pi * t) * size * 0.28})
        end
        cv:polyline(lid, color, 3)

        -- lashes settling
        for _, t in ipairs({0.25, 0.5, 0.75}) do
            local lx = x - w + 2 * w * t
            local ly = y - size * 0.3 + math.sin(math.pi * t) * size * 0.28
            cv:line(lx, ly, lx + (t - 0.5) * size * 0.2, ly + size * 0.14, color, 2)
        end

        -- the dream pooling beneath
        Basic.Wave(cv, x, y + size * 0.34, size * 0.85, size * 0.07, color, 2)
        Basic.Wave(cv, x, y + size * 0.54, size * 0.6, size * 0.05, accent, 2)
        cv:circle(x + size * 0.48, y - size * 0.5, math.max(1, size * 0.05), accent)
    end,
})
