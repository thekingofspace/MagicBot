local Basic = require("@src/spell/elements/Basic")

local Color = {r = 125, g = 110, b = 150}
local Accent = {r = 175, g = 160, b = 190}

return Basic.Make({
    Name = "Burden",
    Emoji = "⛓️",
    Color = Color,
    Accent = Accent,
    Noun = "Burden",
    JetVerb = "bears down",
    SpreadVerb = "weighs",
    EvenVerb = "presses",
    IdleText = "A weight settles on the mind, and the mind declines to carry it.",
    Sigil = function(cv, x, y, size, power, alpha)
        local color = Basic.Alpha(Color, alpha)
        local accent = Basic.Alpha(Accent, alpha)

        -- the weight
        cv:strokePolygon({
            {x - size * 0.3, y - size * 0.58},
            {x + size * 0.3, y - size * 0.58},
            {x + size * 0.42, y - size * 0.14},
            {x - size * 0.42, y - size * 0.14},
        }, color, 3)
        cv:line(x - size * 0.34, y - size * 0.36, x + size * 0.34, y - size * 0.36, color, 2)

        -- pressure driving down
        for _, dx in ipairs({-0.22, 0, 0.22}) do
            cv:line(x + dx * size, y - size * 0.06, x + dx * size, y + size * 0.12, accent, 2)
        end

        -- the mind bowed beneath it
        local bow = {}
        local steps = 14
        for i = 0, steps do
            local t = i / steps
            table.insert(bow, {x - size * 0.5 + size * t, y + size * 0.24 + math.sin(math.pi * t) * size * 0.2})
        end
        cv:polyline(bow, color, 3)
        cv:circle(x, y + size * 0.56, math.max(2, size * 0.06), accent)
    end,
})
