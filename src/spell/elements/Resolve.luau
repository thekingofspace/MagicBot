local Basic = require("@src/spell/elements/Basic")

local Color = {r = 145, g = 150, b = 165}
local Accent = {r = 215, g = 205, b = 190}

return Basic.Make({
    Name = "Resolve",
    Emoji = "🪨",
    Color = Color,
    Accent = Accent,
    Noun = "Resolve",
    JetVerb = "drives out",
    SpreadVerb = "grounds",
    EvenVerb = "holds",
    IdleText = "A will sets like stone, with nothing yet to bear.",
    Sigil = function(cv, x, y, size, power, alpha)
        local color = Basic.Alpha(Color, alpha)
        local accent = Basic.Alpha(Accent, alpha)

        -- the keystone
        cv:strokePolygon({
            {x - size * 0.4, y - size * 0.36},
            {x + size * 0.4, y - size * 0.36},
            {x + size * 0.26, y + size * 0.16},
            {x - size * 0.26, y + size * 0.16},
        }, color, 3)

        -- the unbending line through it
        cv:line(x, y - size * 0.62, x, y + size * 0.5, color, 3)

        -- footing that does not move
        cv:line(x - size * 0.3, y + size * 0.5, x + size * 0.3, y + size * 0.5, color, 3)
        cv:line(x - size * 0.18, y + size * 0.62, x + size * 0.18, y + size * 0.62, color, 2)

        cv:circle(x, y - size * 0.1, math.max(2, size * 0.06), accent)
    end,
})
