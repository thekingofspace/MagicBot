local Basic = require("@src/spell/elements/Basic")

local Color = {r = 255, g = 244, b = 190}
local Accent = {r = 255, g = 255, b = 235}

return Basic.Make({
    Name = "Light",
    Emoji = "✨",
    Color = Color,
    Accent = Accent,
    Noun = "Light",
    JetVerb = "lances out",
    SpreadVerb = "washes",
    EvenVerb = "glows",
    IdleText = "A light rune is drawn, but the circle stays dark.",
    Sigil = function(cv, x, y, size, power, alpha)
        local color = Basic.Alpha(Color, alpha)
        for i = 0, 7 do
            local a = math.pi / 8 + i * math.pi / 4
            local reach = if i % 2 == 0 then size * 0.6 else size * 0.4
            cv:line(
                x + size * 0.16 * math.cos(a), y + size * 0.16 * math.sin(a),
                x + reach * math.cos(a), y + reach * math.sin(a),
                color, 2
            )
        end
        cv:circle(x, y, math.max(3, size * 0.12), Basic.Alpha(Accent, alpha))
    end,
})
