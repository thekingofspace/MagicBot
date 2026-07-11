local Basic = require("@src/spell/elements/Basic")

local Color = {r = 240, g = 70, b = 190}
local Accent = {r = 255, g = 230, b = 100}

return Basic.Make({
    Name = "Impulse",
    Emoji = "💥",
    Color = Color,
    Accent = Accent,
    Noun = "Impulse",
    JetVerb = "fires out",
    SpreadVerb = "crackles",
    EvenVerb = "twitches",
    IdleText = "A nerve fires once in the dark, and no muscle answers.",
    Sigil = function(cv, x, y, size, power, alpha)
        local color = Basic.Alpha(Color, alpha)
        local accent = Basic.Alpha(Accent, alpha)

        -- the bolt leaps the gap between two nerve-ends
        local x1, y1 = x - size * 0.48, y + size * 0.46
        local x2, y2 = x + size * 0.48, y - size * 0.46
        cv:polyline({
            {x1, y1},
            {x + size * 0.02, y + size * 0.16},
            {x - size * 0.24, y + size * 0.08},
            {x + size * 0.24, y - size * 0.08},
            {x - size * 0.02, y - size * 0.16},
            {x2, y2},
        }, color, 3)
        cv:circle(x1, y1, math.max(2, size * 0.08), color)

        -- the spark of arrival
        cv:circle(x2, y2, math.max(2, size * 0.07), accent)
        for i = 0, 4 do
            local a = -math.pi * 0.25 + (i - 2) * 0.55
            cv:line(
                x2 + math.cos(a) * size * 0.12, y2 + math.sin(a) * size * 0.12,
                x2 + math.cos(a) * size * 0.26, y2 + math.sin(a) * size * 0.26,
                accent, 2
            )
        end
    end,
})
