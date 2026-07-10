local Basic = require("@src/spell/elements/Basic")

local Color = {r = 120, g = 255, b = 200}
local Accent = {r = 200, g = 255, b = 235}

return Basic.Make({
    Name = "Aurora",
    Emoji = "🎆",
    Color = Color,
    Accent = Accent,
    Noun = "The aurora",
    JetVerb = "ribbons out",
    SpreadVerb = "shimmers",
    EvenVerb = "curtains the sky",
    Sigil = function(cv, x, y, size, power, alpha)
        for i = -1, 1 do
            local points = {}
            local steps = 12
            for s = 0, steps do
                local t = s / steps
                table.insert(points, {
                    x + i * size * 0.3 + math.sin(t * math.pi * 2 + i) * size * 0.08,
                    y + size * 0.5 - t * size,
                })
            end
            cv:polyline(points, Basic.Alpha(Color, alpha * (1 - math.abs(i) * 0.3)), 3)
        end
        cv:circle(x, y - size * 0.62, math.max(1, size * 0.05), Basic.Alpha(Accent, alpha))
    end,
})
