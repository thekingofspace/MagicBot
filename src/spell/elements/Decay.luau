local Basic = require("@src/spell/elements/Basic")

local Color = {r = 125, g = 135, b = 70}
local Accent = {r = 180, g = 185, b = 120}

return Basic.Make({
    Name = "Decay",
    Emoji = "🍄",
    Color = Color,
    Accent = Accent,
    Noun = "Decay",
    JetVerb = "seeps out",
    SpreadVerb = "creeps",
    EvenVerb = "festers",
    IdleText = "A rot rune is drawn, but nothing spoils.",
    Sigil = function(cv, x, y, size, power, alpha)
        local color = Basic.Alpha(Color, alpha)
        for i = 0, 5 do
            local a = 2 * math.pi * i / 6 + 0.3
            local points = {}
            local steps = 8
            for s = 0, steps do
                local t = a + (2 * math.pi / 6) * 0.6 * s / steps
                table.insert(points, {x + size * 0.5 * math.cos(t), y + size * 0.5 * math.sin(t)})
            end
            cv:polyline(points, color, 2)
        end
        local accent = Basic.Alpha(Accent, alpha)
        cv:line(x - size * 0.15, y + size * 0.1, x - size * 0.15, y + size * 0.35, accent, 2)
        cv:line(x + size * 0.12, y - size * 0.05, x + size * 0.12, y + size * 0.28, accent, 2)
        cv:circle(x - size * 0.15, y + size * 0.42, math.max(1, size * 0.05), accent)
        cv:circle(x + size * 0.12, y + size * 0.35, math.max(1, size * 0.04), accent)
    end,
})
