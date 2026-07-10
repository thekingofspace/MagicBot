local Types = require("@src/spell/elements/Types")
local Basic = require("@src/spell/elements/Basic")

local Color = {r = 165, g = 125, b = 255}
local Accent = {r = 215, g = 190, b = 255}

local Arcana: Types.ElementModule = {
    Name = "Arcana",
    Emoji = "🔮",
    Color = Color,
    Accent = Accent,
    Sigil = function(cv, x, y, size, power, alpha)
        local color = Basic.Alpha(Color, alpha)
        cv:strokeCircle(x, y, size * 0.5, color, 3)
        cv:strokeCircle(x, y, size * 0.3, color, 2)
        cv:circle(x, y, math.max(2, size * 0.08), Basic.Alpha(Accent, alpha))
    end,
    Describe = function(ctx: Types.Context): string
        if ctx.GlyphCount == 0 and ctx.Layers <= 1 then
            return "An empty circle — nothing resolves."
        end

        if ctx.Directional and ctx.AngleDeg then
            return `Raw force pushes out at {ctx.AngleDeg}° ({ctx.Compass}) with strength {ctx.Strength}.`
        end

        if ctx.Spread > 0 then
            return `Force spreads evenly outward with strength {ctx.Strength}.`
        end

        if ctx.Strength > 0 then
            return `The forces balance inward — the circle holds as a ward with strength {ctx.Strength}.`
        end

        return "The circle holds its shape, but nothing resolves."
    end,
}

return Arcana
