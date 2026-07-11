local Basic = require("@src/spell/elements/Basic")

local Color = {r = 175, g = 190, b = 70}
local Accent = {r = 240, g = 215, b = 120}

return Basic.Make({
    Name = "Instinct",
    Emoji = "🐺",
    Color = Color,
    Accent = Accent,
    Noun = "Instinct",
    JetVerb = "pounces out",
    SpreadVerb = "prowls",
    EvenVerb = "circles",
    IdleText = "A hackle rises at nothing — the wild knows better than to stay.",
    Sigil = function(cv, x, y, size, power, alpha)
        local color = Basic.Alpha(Color, alpha)
        local accent = Basic.Alpha(Accent, alpha)

        -- the wild eye
        local w = size * 0.55
        local h = size * 0.3
        for _, dir in ipairs({-1, 1}) do
            local points = {}
            local steps = 12
            for i = 0, steps do
                local t = i / steps
                table.insert(points, {x - w + 2 * w * t, y - size * 0.16 + dir * math.sin(math.pi * t) * h})
            end
            cv:polyline(points, color, 3)
        end

        -- the slit pupil
        cv:ellipse(x, y - size * 0.16, math.max(1, size * 0.05), h * 0.78, accent)

        -- claw marks beneath
        for _, dx in ipairs({-0.26, 0, 0.26}) do
            cv:line(x + dx * size - size * 0.07, y + size * 0.28, x + dx * size + size * 0.07, y + size * 0.6, color, 2)
        end
    end,
})
