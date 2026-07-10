local Basic = require("@src/spell/elements/Basic")

local Color = {r = 255, g = 180, b = 120}
local Accent = {r = 255, g = 225, b = 180}

return Basic.Make({
    Name = "Dawn",
    Emoji = "🌅",
    Color = Color,
    Accent = Accent,
    Noun = "Dawnlight",
    JetVerb = "breaks",
    SpreadVerb = "washes",
    EvenVerb = "rises",
    Sigil = function(cv, x, y, size, power, alpha)
        local color = Basic.Alpha(Color, alpha)
        cv:line(x - size * 0.6, y + size * 0.25, x + size * 0.6, y + size * 0.25, color, 3)
        local steps = 16
        local arc = {}
        for i = 0, steps do
            local a = math.pi + math.pi * i / steps
            table.insert(arc, {x + size * 0.35 * math.cos(a), y + size * 0.25 + size * 0.35 * math.sin(a)})
        end
        cv:polyline(arc, color, 3)
        local accent = Basic.Alpha(Accent, alpha)
        for i = 0, 4 do
            local a = math.pi + math.pi * (i + 0.5) / 5
            cv:line(
                x + size * 0.44 * math.cos(a), y + size * 0.25 + size * 0.44 * math.sin(a),
                x + size * 0.6 * math.cos(a), y + size * 0.25 + size * 0.6 * math.sin(a),
                accent, 2
            )
        end
    end,
})
