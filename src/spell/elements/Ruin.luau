local Basic = require("@src/spell/elements/Basic")

local Color = {r = 150, g = 70, b = 65}
local Accent = {r = 210, g = 140, b = 130}

return Basic.Make({
    Name = "Ruin",
    Emoji = "💀",
    Color = Color,
    Accent = Accent,
    Noun = "Ruin",
    JetVerb = "cleaves out",
    SpreadVerb = "shatters",
    EvenVerb = "gnaws",
    IdleText = "A rend rune is drawn, but nothing breaks.",
    Sigil = function(cv, x, y, size, power, alpha)
        local color = Basic.Alpha(Color, alpha)
        for _, half in ipairs({0.25, math.pi + 0.25}) do
            local points = {}
            local steps = 12
            for s = 0, steps do
                local t = half + math.pi * 0.75 * s / steps
                table.insert(points, {x + size * 0.5 * math.cos(t), y + size * 0.5 * math.sin(t)})
            end
            cv:polyline(points, color, 3)
        end
        cv:line(x - size * 0.45, y + size * 0.45, x + size * 0.45, y - size * 0.45, Basic.Alpha(Accent, alpha), 3)
    end,
})
