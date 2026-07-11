local Basic = require("@src/spell/elements/Basic")

local Color = {r = 205, g = 198, b = 230}
local Accent = {r = 240, g = 236, b = 252}

return Basic.Make({
    Name = "Whisper",
    Emoji = "🌬️",
    Color = Color,
    Accent = Accent,
    Noun = "Whisper",
    JetVerb = "slips out",
    SpreadVerb = "carries",
    EvenVerb = "hushes",
    IdleText = "A whisper rides the wind, but no ear leans close.",
    Sigil = function(cv, x, y, size, power, alpha)
        local color = Basic.Alpha(Color, alpha)
        local accent = Basic.Alpha(Accent, alpha)

        -- three breaths of wind, the shortest trailing off
        for row, dy in ipairs({-0.3, 0, 0.3}) do
            local yy = y + dy * size
            local len = size * (1 - math.abs(dy) * 1.1)
            local points = {}
            local steps = 12
            for i = 0, steps do
                local t = i / steps
                table.insert(points, {x - size * 0.55 + len * t, yy + math.sin(t * math.pi * 2 + row) * size * 0.05})
            end
            cv:polyline(points, color, 2)
        end

        -- the middle breath curls back on itself: a word kept
        local curl = {}
        for i = 0, 16 do
            local t = i / 16
            local a = -math.pi / 2 + math.pi * 1.7 * t
            local r = size * 0.17 * (1 - t * 0.55)
            table.insert(curl, {x + size * 0.45 + r * math.cos(a), y - size * 0.04 + r * math.sin(a)})
        end
        cv:polyline(curl, color, 2)

        -- syllables scattering
        cv:circle(x + size * 0.5, y - size * 0.38, math.max(1, size * 0.045), accent)
        cv:circle(x + size * 0.62, y - size * 0.2, math.max(1, size * 0.035), accent)
    end,
})
