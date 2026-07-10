local Basic = require("@src/spell/elements/Basic")

local Color = {r = 200, g = 205, b = 225}
local Accent = {r = 240, g = 242, b = 255}

return Basic.Make({
    Name = "Moon",
    Emoji = "🌙",
    Color = Color,
    Accent = Accent,
    Noun = "Moonlight",
    JetVerb = "beams out",
    SpreadVerb = "silvers",
    EvenVerb = "waxes",
    Sigil = function(cv, x, y, size, power, alpha)
        local color = Basic.Alpha(Color, alpha)
        local outer = {}
        local inner = {}
        local steps = 20
        for i = 0, steps do
            local a = -math.pi / 2 + math.pi * i / steps
            table.insert(outer, {x + size * 0.5 * math.cos(a), y + size * 0.5 * math.sin(a)})
            local b = math.pi / 2 - math.pi * i / steps
            table.insert(inner, {x + size * 0.12 + size * 0.34 * math.cos(b), y + size * 0.34 * math.sin(b)})
        end
        cv:polyline(outer, color, 3)
        cv:polyline(inner, color, 3)
        cv:circle(x + size * 0.42, y - size * 0.42, math.max(1, size * 0.05), Basic.Alpha(Accent, alpha))
    end,
})
