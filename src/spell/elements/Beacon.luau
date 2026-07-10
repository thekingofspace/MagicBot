local Basic = require("@src/spell/elements/Basic")

local Color = {r = 255, g = 250, b = 200}
local Accent = {r = 255, g = 255, b = 240}

return Basic.Make({
    Name = "Beacon",
    Emoji = "🔆",
    Color = Color,
    Accent = Accent,
    Noun = "Beaconlight",
    JetVerb = "cuts out",
    SpreadVerb = "sweeps",
    EvenVerb = "burns steady",
    Sigil = function(cv, x, y, size, power, alpha)
        local color = Basic.Alpha(Color, alpha)
        cv:line(x, y + size * 0.55, x, y - size * 0.15, color, 3)
        cv:strokeCircle(x, y - size * 0.3, size * 0.18, color, 3)
        local accent = Basic.Alpha(Accent, alpha)
        for _, side in ipairs({-1, 1}) do
            cv:line(
                x + side * size * 0.26, y - size * 0.3,
                x + side * size * 0.55, y - size * 0.38,
                accent, 2
            )
            cv:line(
                x + side * size * 0.22, y - size * 0.45,
                x + side * size * 0.44, y - size * 0.6,
                accent, 2
            )
        end
    end,
})
