local Basic = require("@src/spell/elements/Basic")

local Color = {r = 226, g = 158, b = 240}
local Accent = {r = 247, g = 210, b = 252}

return Basic.Make({
    Name = "Mind",
    Emoji = "💭",
    Color = Color,
    Accent = Accent,
    Noun = "Thought",
    JetVerb = "lances out",
    SpreadVerb = "washes",
    EvenVerb = "settles",
    IdleText = "A muse rune is drawn, but no thought takes hold.",
    Sigil = function(cv, x, y, size, power, alpha)
        local color = Basic.Alpha(Color, alpha)
        local accent = Basic.Alpha(Accent, alpha)

        local w = size * 0.62
        local h = size * 0.34
        for _, dir in ipairs({-1, 1}) do
            local points = {}
            local steps = 14
            for i = 0, steps do
                local t = i / steps
                table.insert(points, {x - w + 2 * w * t, y + dir * math.sin(math.pi * t) * h})
            end
            cv:polyline(points, color, 3)
        end

        local spiral = {}
        local turns = 2.2
        local steps = 26
        for i = 0, steps do
            local t = i / steps
            local a = -math.pi / 2 + 2 * math.pi * turns * t
            local r = size * 0.24 * (1 - t * 0.85)
            table.insert(spiral, {x + r * math.cos(a), y + r * math.sin(a)})
        end
        cv:polyline(spiral, accent, 2)
        cv:circle(x, y, math.max(1, size * 0.04), accent)
    end,
})
