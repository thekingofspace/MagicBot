local Basic = require("@src/spell/elements/Basic")

local Color = {r = 210, g = 80, b = 90}
local Accent = {r = 255, g = 170, b = 170}

return Basic.Make({
    Name = "Magnet",
    Emoji = "🧲",
    Color = Color,
    Accent = Accent,
    Noun = "The lodestone",
    JetVerb = "pulls",
    SpreadVerb = "polarizes",
    EvenVerb = "clamps",
    Sigil = function(cv, x, y, size, power, alpha)
        local color = Basic.Alpha(Color, alpha)
        local points = {}
        local steps = 20
        for i = 0, steps do
            local a = math.pi - math.pi * i / steps
            table.insert(points, {x + size * 0.4 * math.cos(a), y - size * 0.05 + size * 0.4 * math.sin(a) * -1})
        end
        cv:polyline(points, color, 4)
        local accent = Basic.Alpha(Accent, alpha)
        cv:line(x - size * 0.4, y - size * 0.05, x - size * 0.4, y + size * 0.45, color, 4)
        cv:line(x + size * 0.4, y - size * 0.05, x + size * 0.4, y + size * 0.45, color, 4)
        cv:line(x - size * 0.5, y + size * 0.45, x - size * 0.3, y + size * 0.45, accent, 3)
        cv:line(x + size * 0.3, y + size * 0.45, x + size * 0.5, y + size * 0.45, accent, 3)
    end,
})
