local Basic = require("@src/spell/elements/Basic")

local Color = {r = 110, g = 215, b = 255}
local Accent = {r = 210, g = 245, b = 255}

return Basic.Make({
    Name = "Volt",
    Emoji = "⚡",
    Color = Color,
    Accent = Accent,
    Noun = "Lightning",
    JetVerb = "arcs out",
    SpreadVerb = "crackles",
    EvenVerb = "hums",
    IdleText = "A spark rune is drawn, but no charge builds.",
    Sigil = function(cv, x, y, size, power, alpha)
        local color = Basic.Alpha(Color, alpha)
        cv:polyline({
            {x + size * 0.18, y - size * 0.6},
            {x - size * 0.18, y - size * 0.05},
            {x + size * 0.06, y - size * 0.05},
            {x - size * 0.18, y + size * 0.6},
        }, color, 3)
        cv:circle(x - size * 0.18, y + size * 0.6, math.max(2, size * 0.07), Basic.Alpha(Accent, alpha))
        for i = 2, math.clamp(power, 1, 3) do
            cv:strokeCircle(x, y, size * (0.5 + (i - 1) * 0.22), Basic.Alpha(Color, alpha * 0.4), 2)
        end
    end,
})
