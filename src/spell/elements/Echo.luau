local Basic = require("@src/spell/elements/Basic")

local Color = {r = 180, g = 195, b = 210}
local Accent = {r = 225, g = 235, b = 245}

return Basic.Make({
    Name = "Echo",
    Emoji = "🔉",
    Color = Color,
    Accent = Accent,
    Noun = "The echo",
    JetVerb = "rebounds",
    SpreadVerb = "reverberates",
    EvenVerb = "rings",
    Sigil = function(cv, x, y, size, power, alpha)
        local color = Basic.Alpha(Color, alpha)
        cv:circle(x - size * 0.35, y, math.max(2, size * 0.09), Basic.Alpha(Accent, alpha))
        for i = 1, 3 do
            local r = size * (0.2 + i * 0.15)
            local points = {}
            local steps = 12
            for s = 0, steps do
                local a = -math.pi / 3 + (2 * math.pi / 3) * s / steps
                table.insert(points, {x - size * 0.35 + r * math.cos(a), y + r * math.sin(a)})
            end
            cv:polyline(points, Basic.Alpha(Color, alpha * (1.1 - i * 0.25)), 2)
        end
    end,
})
