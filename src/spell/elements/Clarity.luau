local Basic = require("@src/spell/elements/Basic")

local Color = {r = 250, g = 235, b = 190}
local Accent = {r = 255, g = 252, b = 235}

return Basic.Make({
    Name = "Clarity",
    Emoji = "🔆",
    Color = Color,
    Accent = Accent,
    Noun = "Clarity",
    JetVerb = "cuts out",
    SpreadVerb = "illuminates",
    EvenVerb = "clears",
    IdleText = "A perfect thought forms, too bright to hold.",
    Sigil = function(cv, x, y, size, power, alpha)
        local color = Basic.Alpha(Color, alpha)
        local accent = Basic.Alpha(Accent, alpha)

        -- the lens: a thought ground to a flawless edge
        local r = size * 0.34
        cv:strokePolygon({{x, y - r}, {x + r, y}, {x, y + r}, {x - r, y}}, color, 3)
        cv:strokePolygon({
            {x, y - r * 0.45}, {x + r * 0.45, y}, {x, y + r * 0.45}, {x - r * 0.45, y},
        }, accent, 2)
        cv:circle(x, y, math.max(2, size * 0.05), accent)

        -- lucid rays
        for i = 0, 7 do
            local a = math.pi * 2 * i / 8 + math.pi / 8
            local inner = size * 0.44
            local outer = size * 0.62
            cv:line(
                x + math.cos(a) * inner, y + math.sin(a) * inner,
                x + math.cos(a) * outer, y + math.sin(a) * outer,
                accent, 2
            )
        end
    end,
})
