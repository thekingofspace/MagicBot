local Basic = require("@src/spell/elements/Basic")

local Color = {r = 255, g = 250, b = 170}
local Accent = {r = 255, g = 255, b = 225}
local VoltColor = {r = 110, g = 215, b = 255}

return Basic.Make({
    Name = "Flash",
    Emoji = "📸",
    Color = Color,
    Accent = Accent,
    Noun = "The flash",
    JetVerb = "snaps out",
    SpreadVerb = "strobes",
    EvenVerb = "flickers",
    Sigil = function(cv, x, y, size, power, alpha)
        cv:polyline({
            {x + size * 0.12, y - size * 0.45},
            {x - size * 0.12, y},
            {x + size * 0.04, y},
            {x - size * 0.12, y + size * 0.45},
        }, Basic.Alpha(VoltColor, alpha), 2)
        local color = Basic.Alpha(Color, alpha)
        for i = 0, 5 do
            local a = i * math.pi / 3 + 0.3
            cv:line(
                x + size * 0.4 * math.cos(a), y + size * 0.4 * math.sin(a),
                x + size * 0.58 * math.cos(a), y + size * 0.58 * math.sin(a),
                color, 2
            )
        end
    end,
})
