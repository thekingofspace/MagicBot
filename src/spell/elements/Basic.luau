local Types = require("@src/spell/elements/Types")

export type Verbs = {
    Name: string,
    Emoji: string,
    Color: Types.RGB,
    Accent: Types.RGB,
    Noun: string?,
    JetVerb: string?,
    SpreadVerb: string?,
    EvenVerb: string?,
    IdleText: string?,
    Sigil: Types.SigilDrawer?,
}

local module = {}

function module.Alpha(color: Types.RGB, alpha: number): {r: number, g: number, b: number, a: number}
    return {r = color.r, g = color.g, b = color.b, a = math.floor(alpha)}
end

function module.Triangle(cv: Canvas, x: number, y: number, size: number, up: boolean, bar: boolean, color: any, thickness: number?)
    local height = size * 0.866
    local points
    if up then
        points = {
            {x, y - height * 0.6},
            {x - size / 2, y + height * 0.4},
            {x + size / 2, y + height * 0.4},
        }
    else
        points = {
            {x, y + height * 0.6},
            {x - size / 2, y - height * 0.4},
            {x + size / 2, y - height * 0.4},
        }
    end
    cv:strokePolygon(points, color, thickness or 3)
    if bar then
        cv:line(x - size * 0.42, y, x + size * 0.42, y, color, thickness or 3)
    end
end

function module.Wave(cv: Canvas, x: number, y: number, width: number, amplitude: number, color: any, thickness: number?)
    local points = {}
    local segments = 12
    for i = 0, segments do
        local t = i / segments
        table.insert(points, {x - width / 2 + width * t, y + math.sin(t * math.pi * 2) * amplitude})
    end
    cv:polyline(points, color, thickness or 2)
end

function module.Make(verbs: Verbs): Types.ElementModule
    local noun = verbs.Noun or verbs.Name
    local jetVerb = verbs.JetVerb or "shoots out"
    local spreadVerb = verbs.SpreadVerb or "spreads"
    local evenVerb = verbs.EvenVerb or "settles"

    local sigil = verbs.Sigil or function(cv: Canvas, x: number, y: number, size: number, power: number, alpha: number)
        local color = module.Alpha(verbs.Color, alpha)
        for i = 1, math.clamp(power, 1, 3) do
            cv:strokeCircle(x, y, size * (0.55 - (i - 1) * 0.14), color, 3)
        end
        cv:circle(x, y, math.max(2, size * 0.08), module.Alpha(verbs.Accent, alpha))
    end

    return {
        Name = verbs.Name,
        Emoji = verbs.Emoji,
        Color = verbs.Color,
        Accent = verbs.Accent,
        Sigil = sigil,
        Describe = function(ctx: Types.Context): string
            if ctx.Strength <= 0 then
                return verbs.IdleText or `{noun} stirs faintly, but nothing takes hold.`
            end

            if ctx.Directional and ctx.Homing then
                local line = `{noun} {jetVerb}, back at its source, with strength {ctx.Strength}`
                if ctx.Spread > 0 then
                    line ..= `, fanned about {math.floor(ctx.SpreadArcDeg)}° wide`
                end
                return line .. "."
            end

            if ctx.Directional and ctx.AngleDeg then
                local line = `{noun} {jetVerb} at {ctx.AngleDeg}° ({ctx.Compass}) with strength {ctx.Strength}`
                if ctx.Spread > 0 then
                    line ..= `, fanned about {math.floor(ctx.SpreadArcDeg)}° wide`
                end
                return line .. "."
            end

            if ctx.Spread > 0 then
                return `{noun} {spreadVerb} outward on all sides with strength {ctx.Strength}.`
            end

            return `{noun} {evenVerb} evenly around the circle with strength {ctx.Strength}.`
        end,
    }
end

return module
