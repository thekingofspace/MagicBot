local Basic = require("@src/spell/elements/Basic")

local Color = {r = 110, g = 85, b = 160}
local Accent = {r = 200, g = 180, b = 255}

return Basic.Make({
    Name = "Singularity",
    Emoji = "🕳️",
    Color = Color,
    Accent = Accent,
    Noun = "The singularity",
    JetVerb = "drags all",
    SpreadVerb = "swallows",
    EvenVerb = "collapses inward",
    Sigil = function(cv, x, y, size, power, alpha)
        local color = Basic.Alpha(Color, alpha)
        cv:circle(x, y, size * 0.22, Basic.Alpha({r = 10, g = 6, b = 18}, alpha))
        cv:strokeCircle(x, y, size * 0.24, Basic.Alpha(Accent, alpha), 2)
        cv:strokeCircle(x, y, size * 0.42, color, 2)
        cv:strokeCircle(x, y, size * 0.58, Basic.Alpha(Color, alpha * 0.6), 1)
        for i = 0, 3 do
            local a = math.pi / 4 + i * math.pi / 2
            cv:line(
                x + size * 0.58 * math.cos(a), y + size * 0.58 * math.sin(a),
                x + size * 0.34 * math.cos(a + 0.35), y + size * 0.34 * math.sin(a + 0.35),
                color, 2
            )
        end
    end,
})
