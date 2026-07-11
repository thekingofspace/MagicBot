--#include[canvas, fs]
local Resolver = require("@src/coin/Resolver")

-- Draws one large coin face: rim, denticles, legend, stamped emblem, sheen.
-- Everything is deterministic per seed; hammered coins carry a fresh seed
-- from the Resolver each cast.

local module = {}

local Size = 900
local TwoPi = 2 * math.pi

local FontCandidates = {
    "C:/Windows/Fonts/constan.ttf",
    "C:/Windows/Fonts/georgia.ttf",
    "C:/Windows/Fonts/times.ttf",
    "C:/Windows/Fonts/arial.ttf",
}

local RuneFont: CanvasFont? = nil
for _, path in ipairs(FontCandidates) do
    if fs.exists(path) then
        local ok, font = pcall(function()
            return canvas.font(path)
        end)
        if ok then
            RuneFont = font
            break
        end
    end
end

local Background = {r = 25, g = 23, b = 30}
local PatinaTones = {
    {r = 92, g = 150, b = 112},
    {r = 70, g = 132, b = 104},
    {r = 118, g = 162, b = 118},
}
local PitTone = {r = 46, g = 40, b = 34}

local function WithAlpha(color: {r: number, g: number, b: number}, alpha: number): {r: number, g: number, b: number, a: number}
    return {r = color.r, g = color.g, b = color.b, a = math.floor(alpha)}
end

local function LerpColor(a: Resolver.Rgb, b: Resolver.Rgb, t: number): Resolver.Rgb
    return {
        r = math.floor(a.r + (b.r - a.r) * t),
        g = math.floor(a.g + (b.g - a.g) * t),
        b = math.floor(a.b + (b.b - a.b) * t),
    }
end

local function ReliefColor(mat: Resolver.Material): Resolver.Rgb
    return LerpColor(mat.Mid, mat.Dark, 0.5)
end

-- Deterministic minstd generator so every speckle lands in the same place
-- for the same design.
local function NewRng(seed: number): () -> number
    local state = seed % 2147483647
    if state <= 0 then
        state += 2147483646
    end
    return function(): number
        state = (state * 48271) % 2147483647
        return state / 2147483647
    end
end

type Flan = {
    cx: number,
    cy: number,
    R: number,
    shape: string,
    inradius: number,
    wobble: {number}?,
}

type Die = {
    circle: boolean,
    cx: number,
    cy: number,
    r: number,
    flan: Flan,
}

local function ShapeProfile(shape: string, theta: number): number
    if shape == "square" then
        local c = math.abs(math.cos(theta))
        local s = math.abs(math.sin(theta))
        return 0.74 / math.max(c, s)
    elseif shape == "wedge" then
        local apothem = 0.55
        local sector = TwoPi / 3
        local phi = (theta + math.pi / 2) % sector
        return math.min(apothem / math.cos(phi - sector / 2), 1.12)
    elseif shape == "scallop" then
        return 0.955 + 0.045 * math.cos(12 * theta)
    end
    return 1
end

local function MinProfile(shape: string): number
    if shape == "square" then
        return 0.74
    elseif shape == "wedge" then
        return 0.55
    elseif shape == "scallop" then
        return 0.91
    end
    return 1
end

local function WobbleAt(wobble: {number}, theta: number): number
    local count = #wobble
    local pos = ((theta / TwoPi) % 1) * count
    local index = math.floor(pos)
    local fraction = pos - index
    local a = wobble[index % count + 1]
    local b = wobble[(index + 1) % count + 1]
    local t = (1 - math.cos(math.pi * fraction)) / 2
    return a + (b - a) * t
end

local function FlanRadius(flan: Flan, theta: number): number
    local radius = flan.R * ShapeProfile(flan.shape, theta)
    if flan.wobble then
        radius *= WobbleAt(flan.wobble :: {number}, theta)
    end
    return radius
end

local function ShapePoints(flan: Flan, scale: number, ox: number, oy: number, steps: number): {{number}}
    local points = {}
    for i = 0, steps - 1 do
        local theta = TwoPi * i / steps
        local radius = FlanRadius(flan, theta) * scale
        table.insert(points, {flan.cx + ox + radius * math.cos(theta), flan.cy + oy + radius * math.sin(theta)})
    end
    return points
end

local function OnFlan(flan: Flan, x: number, y: number, margin: number): boolean
    local dx, dy = x - flan.cx, y - flan.cy
    local distance = math.sqrt(dx * dx + dy * dy)
    local theta = math.atan2(dy, dx)
    return distance <= FlanRadius(flan, theta) * margin
end

local function DiePos(die: Die, theta: number, inset: number): (number, number)
    if die.circle then
        return die.cx + die.r * inset * math.cos(theta), die.cy + die.r * inset * math.sin(theta)
    end
    local radius = FlanRadius(die.flan, theta) * inset
    return die.flan.cx + radius * math.cos(theta), die.flan.cy + radius * math.sin(theta)
end

-- A ring (or arc) that follows the die, clipped where the strike ran off
-- the flan — hammered coins keep their round die impression.
local function DrawDieArc(cv: Canvas, flan: Flan, die: Die, inset: number, fromAngle: number, toAngle: number, color: any, thickness: number)
    local steps = math.max(12, math.floor(48 * (toAngle - fromAngle) / TwoPi + 0.5))
    local segment = {}
    local function Flush()
        if #segment >= 2 then
            cv:polyline(segment, color, thickness)
        end
        segment = {}
    end
    for i = 0, steps do
        local theta = fromAngle + (toAngle - fromAngle) * i / steps
        local x, y = DiePos(die, theta, inset)
        if OnFlan(flan, x, y, 0.998) then
            table.insert(segment, {x, y})
        else
            Flush()
        end
    end
    Flush()
end

local function DrawDieRing(cv: Canvas, flan: Flan, die: Die, inset: number, color: any, thickness: number)
    DrawDieArc(cv, flan, die, inset, 0, TwoPi, color, thickness)
end

local function DrawMetalFace(cv: Canvas, flan: Flan, mat: Resolver.Material)
    local layers = 34
    local shift = flan.R * 0.15
    for k = layers, 1, -1 do
        local t = k / layers
        local lightT = 1 - t
        local color = LerpColor(mat.Dark, mat.Light, math.min(1, lightT ^ 0.75 * 1.05))
        local off = shift * lightT
        cv:polygon(ShapePoints(flan, t, -off * 0.8, -off, 72), color)
    end
end

local function DrawMetalDisc(cv: Canvas, cx: number, cy: number, radius: number, mat: Resolver.Material)
    local layers = 26
    local shift = radius * 0.18
    for k = layers, 1, -1 do
        local t = k / layers
        local lightT = 1 - t
        local color = LerpColor(mat.Dark, mat.Light, math.min(1, lightT ^ 0.75 * 1.05))
        cv:circle(cx - shift * lightT * 0.8, cy - shift * lightT, radius * t, color)
    end
end

local function DrawDenticles(cv: Canvas, flan: Flan, die: Die, mat: Resolver.Material)
    local count = 64
    local radius = math.max(3, flan.R * 0.013)
    local topColor = LerpColor(mat.Mid, mat.Light, 0.55)
    for i = 0, count - 1 do
        local theta = TwoPi * i / count
        local x, y = DiePos(die, theta, 0.885)
        if OnFlan(flan, x, y, 0.97) then
            cv:circle(x + 1.5, y + 2, radius, WithAlpha(mat.Deep, 210))
            cv:circle(x - 0.5, y - 0.5, radius * 0.9, topColor)
        end
    end
end

local function DrawMilling(cv: Canvas, flan: Flan, mat: Resolver.Material)
    local count = 110
    for i = 0, count - 1 do
        local theta = TwoPi * i / count
        local r1 = FlanRadius(flan, theta) * 0.972
        local r2 = FlanRadius(flan, theta) * 1.004
        local color = if i % 2 == 0 then WithAlpha(mat.Deep, 200) else WithAlpha(mat.Light, 150)
        cv:line(
            flan.cx + r1 * math.cos(theta), flan.cy + r1 * math.sin(theta),
            flan.cx + r2 * math.cos(theta), flan.cy + r2 * math.sin(theta),
            color, 2
        )
    end
end

local function DrawRim(cv: Canvas, flan: Flan, die: Die, mat: Resolver.Material)
    local outline = ShapePoints(flan, 1, 0, 0, 96)
    table.insert(outline, {outline[1][1], outline[1][2]})
    cv:polyline(outline, WithAlpha(mat.Deep, 235), 3)

    DrawDieRing(cv, flan, die, 0.952, LerpColor(mat.Light, mat.Mid, 0.3), math.max(3, math.floor(flan.R * 0.011)))
    DrawDieRing(cv, flan, die, 0.918, WithAlpha(mat.Dark, 210), 2)
end

local function DrawSwirl(cv: Canvas, flan: Flan, die: Die, sign: number, mat: Resolver.Material)
    for i = 0, 7 do
        local start = TwoPi * i / 8
        local segment = {}
        local function Flush()
            if #segment >= 2 then
                cv:polyline(segment, WithAlpha(mat.Dark, 60), 3)
            end
            segment = {}
        end
        for j = 0, 14 do
            local t = j / 14
            local inset = 0.3 + 0.5 * t
            local theta = start + sign * 1.1 * t
            local x, y = DiePos(die, theta, inset)
            if OnFlan(flan, x, y, 0.95) then
                table.insert(segment, {x, y})
            else
                Flush()
            end
        end
        Flush()
    end
end

-- Emblem art. Each function draws with (cv, x, y, s, color, th); the caller
-- strikes it three times for the embossed relief.
local function Arc(cv: Canvas, cx: number, cy: number, radius: number, fromAngle: number, toAngle: number, color: any, thickness: number)
    local steps = 26
    local points = {}
    for i = 0, steps do
        local t = fromAngle + (toAngle - fromAngle) * i / steps
        table.insert(points, {cx + radius * math.cos(t), cy + radius * math.sin(t)})
    end
    cv:polyline(points, color, thickness)
end

local EmblemArt: {[string]: (Canvas, number, number, number, any, number) -> ()} = {
    A = function(cv, x, y, s, color, th)
        cv:polyline({{x - s * 0.1, y + s * 0.28}, {x, y - s * 0.95}, {x + s * 0.1, y + s * 0.28}}, color, th)
        cv:line(x, y - s * 0.78, x, y + s * 0.26, color, math.max(2, th * 0.45))
        cv:line(x - s * 0.4, y + s * 0.3, x + s * 0.4, y + s * 0.3, color, th)
        cv:line(x, y + s * 0.3, x, y + s * 0.7, color, th)
        cv:circle(x, y + s * 0.84, math.max(3, s * 0.11), color)
    end,
    C = function(cv, x, y, s, color, th)
        Arc(cv, x - s * 0.12, y, s * 0.72, math.rad(55), math.rad(305), color, th * 1.4)
        local sx, sy = x + s * 0.52, y
        cv:line(sx - s * 0.15, sy, sx + s * 0.15, sy, color, math.max(2, th * 0.5))
        cv:line(sx, sy - s * 0.15, sx, sy + s * 0.15, color, math.max(2, th * 0.5))
        cv:circle(sx, sy, math.max(2, s * 0.05), color)
    end,
    D = function(cv, x, y, s, color, th)
        cv:strokePolygon({
            {x - s * 0.55, y - s * 0.6}, {x + s * 0.55, y - s * 0.6},
            {x + s * 0.55, y + s * 0.05}, {x + s * 0.3, y + s * 0.45},
            {x, y + s * 0.7}, {x - s * 0.3, y + s * 0.45},
            {x - s * 0.55, y + s * 0.05},
        }, color, th)
        cv:line(x, y - s * 0.6, x, y + s * 0.7, color, math.max(2, th * 0.5))
        cv:line(x - s * 0.55, y - s * 0.05, x + s * 0.55, y - s * 0.05, color, math.max(2, th * 0.5))
    end,
    K = function(cv, x, y, s, color, th)
        cv:polyline({
            {x - s * 0.6, y + s * 0.05}, {x - s * 0.42, y - s * 0.5},
            {x - s * 0.2, y - s * 0.02}, {x, y - s * 0.62},
            {x + s * 0.2, y - s * 0.02}, {x + s * 0.42, y - s * 0.5},
            {x + s * 0.6, y + s * 0.05},
        }, color, th)
        cv:line(x - s * 0.6, y + s * 0.05, x - s * 0.6, y + s * 0.32, color, th)
        cv:line(x + s * 0.6, y + s * 0.05, x + s * 0.6, y + s * 0.32, color, th)
        cv:line(x - s * 0.6, y + s * 0.32, x + s * 0.6, y + s * 0.32, color, th)
        cv:circle(x - s * 0.42, y - s * 0.56, math.max(2, s * 0.07), color)
        cv:circle(x, y - s * 0.7, math.max(2, s * 0.07), color)
        cv:circle(x + s * 0.42, y - s * 0.56, math.max(2, s * 0.07), color)
    end,
    L = function(cv, x, y, s, color, th)
        cv:line(x, y - s * 0.52, x, y + s * 0.8, color, th)
        cv:circle(x, y - s * 0.68, math.max(3, s * 0.16), color)
        cv:line(x - s * 0.22, y - s * 0.4, x + s * 0.22, y - s * 0.4, color, math.max(2, th * 0.6))
        cv:line(x - s * 0.16, y + s * 0.8, x + s * 0.16, y + s * 0.8, color, th)
    end,
    S = function(cv, x, y, s, color, th)
        local points = {}
        for i = 0, 30 do
            local t = i / 30
            local sway = math.sin(TwoPi * 1.5 * t + math.pi * 0.25)
            table.insert(points, {
                x + s * 0.38 * sway * (0.55 + 0.45 * math.sin(math.pi * t)),
                y - s * 0.78 + s * 1.56 * t,
            })
        end
        cv:polyline(points, color, th * 1.25)
        -- head, raised and looking forward
        local hx, hy = points[1][1], points[1][2]
        cv:circle(hx, hy, math.max(3, s * 0.14), color)
        cv:line(hx + s * 0.08, hy - s * 0.08, hx + s * 0.26, hy - s * 0.2, color, math.max(2, th * 0.4))
        -- tail taper
        local tx, ty = points[#points][1], points[#points][2]
        cv:line(tx, ty, tx - s * 0.18, ty + s * 0.1, color, math.max(2, th * 0.5))
    end,
    T = function(cv, x, y, s, color, th)
        cv:polygon({
            {x - s * 0.55, y - s * 0.62}, {x + s * 0.42, y - s * 0.62},
            {x + s * 0.55, y - s * 0.4}, {x + s * 0.42, y - s * 0.18},
            {x - s * 0.55, y - s * 0.18},
        }, color)
        cv:line(x, y - s * 0.18, x, y + s * 0.78, color, th)
        cv:line(x - s * 0.14, y + s * 0.74, x + s * 0.14, y + s * 0.74, color, math.max(2, th * 0.6))
    end,
    U = function(cv, x, y, s, color, th)
        Arc(cv, x, y - s * 0.25, s * 0.5, 0, math.pi, color, th)
        cv:line(x - s * 0.5, y - s * 0.25, x + s * 0.5, y - s * 0.25, color, math.max(2, th * 0.7))
        cv:line(x, y + s * 0.25, x, y + s * 0.55, color, th)
        cv:line(x - s * 0.32, y + s * 0.62, x + s * 0.32, y + s * 0.62, color, th)
    end,
    Y = function(cv, x, y, s, color, th)
        cv:line(x, y - s * 0.62, x, y + s * 0.8, color, th)
        cv:line(x - s * 0.09, y - s * 0.48, x, y - s * 0.66, color, math.max(2, th * 0.6))
        cv:line(x + s * 0.09, y - s * 0.48, x, y - s * 0.66, color, math.max(2, th * 0.6))
        cv:polyline({{x, y + s * 0.05}, {x - s * 0.32, y - s * 0.12}, {x - s * 0.36, y - s * 0.52}}, color, th)
        cv:polyline({{x, y + s * 0.05}, {x + s * 0.32, y - s * 0.12}, {x + s * 0.36, y - s * 0.52}}, color, th)
        cv:line(x - s * 0.44, y - s * 0.42, x - s * 0.36, y - s * 0.52, color, math.max(2, th * 0.6))
        cv:line(x + s * 0.44, y - s * 0.42, x + s * 0.36, y - s * 0.52, color, math.max(2, th * 0.6))
    end,
    Z = function(cv, x, y, s, color, th)
        cv:polyline({
            {x + s * 0.3, y - s * 0.8}, {x - s * 0.12, y - s * 0.05},
            {x + s * 0.1, y - s * 0.05}, {x - s * 0.3, y + s * 0.8},
        }, color, th * 1.1)
        cv:line(x - s * 0.3, y + s * 0.8, x - s * 0.06, y + s * 0.62, color, math.max(2, th * 0.5))
        cv:line(x - s * 0.3, y + s * 0.8, x - s * 0.28, y + s * 0.5, color, math.max(2, th * 0.5))
    end,
}

local function DrawEmblem(cv: Canvas, letter: string, x: number, y: number, s: number, mat: Resolver.Material, power: number)
    local art = EmblemArt[letter]
    if not art then
        return
    end
    local thickness = math.max(4, s * 0.1) + math.min(power, 5)
    local offset = math.max(2, s * 0.04)
    art(cv, x + offset, y + offset * 1.3, s, WithAlpha(mat.Deep, 220), thickness)
    art(cv, x - offset * 0.7, y - offset, s, mat.Light, thickness)
    art(cv, x, y, s, ReliefColor(mat), thickness)
end

local function DrawTextEmbossed(cv: Canvas, text: string, x: number, y: number, size: number, mat: Resolver.Material)
    if not RuneFont then
        return
    end
    local font = RuneFont :: CanvasFont
    local width, height = font:measure(text, size)
    local bx, by = x - width / 2, y - height / 2
    local offset = math.max(2, size * 0.05)
    cv:text(text, bx + offset, by + offset * 1.3, size, WithAlpha(mat.Deep, 220), font)
    cv:text(text, bx - offset * 0.6, by - offset * 0.8, size, mat.Light, font)
    cv:text(text, bx, by, size, ReliefColor(mat), font)
end

local function DrawLegend(cv: Canvas, flan: Flan, die: Die, text: string, top: boolean, size: number, mat: Resolver.Material, tilt: number)
    if not RuneFont or #text == 0 then
        return
    end
    local font = RuneFont :: CanvasFont
    local chars = {}
    for char in string.gmatch(text, utf8.charpattern) do
        table.insert(chars, char)
    end
    local count = #chars
    if count == 0 then
        return
    end
    local step = size * 1.15 / (die.r * 0.8)
    local maxSpan = math.rad(if top then 155 else 120)
    local span = step * math.max(count - 1, 1)
    if span > maxSpan then
        local factor = maxSpan / span
        step *= factor
        size = math.max(11, size * factor)
    end
    local center = (if top then 3 * math.pi / 2 else math.pi / 2) + tilt
    for i = 1, count do
        local k = i - (count + 1) / 2
        local theta = if top then center + k * step else center - k * step
        local x, y = DiePos(die, theta, 0.795)
        if OnFlan(flan, x, y, 0.98) then
            local char = chars[i]
            local width, height = font:measure(char, size)
            local bx, by = x - width / 2, y - height / 2
            cv:text(char, bx + 2, by + 2, size, WithAlpha(mat.Deep, 200), font)
            cv:text(char, bx, by, size, ReliefColor(mat), font)
        end
    end
end

local function DrawHole(cv: Canvas, cx: number, cy: number, half: number, mat: Resolver.Material)
    local rim = half * 1.45
    cv:strokePolygon({
        {cx - rim, cy - rim}, {cx + rim, cy - rim},
        {cx + rim, cy + rim}, {cx - rim, cy + rim},
    }, LerpColor(mat.Light, mat.Mid, 0.35), math.max(3, half * 0.18))
    cv:strokePolygon({
        {cx - half * 1.16, cy - half * 1.16}, {cx + half * 1.16, cy - half * 1.16},
        {cx + half * 1.16, cy + half * 1.16}, {cx - half * 1.16, cy + half * 1.16},
    }, WithAlpha(mat.Dark, 220), 2)
    cv:polygon({
        {cx - half, cy - half}, {cx + half, cy - half},
        {cx + half, cy + half}, {cx - half, cy + half},
    }, WithAlpha(Background, 255))
    cv:line(cx - half, cy - half + 2, cx + half, cy - half + 2, {r = 0, g = 0, b = 0, a = 150}, 3)
    cv:line(cx - half + 2, cy - half, cx - half + 2, cy + half, {r = 0, g = 0, b = 0, a = 120}, 3)
    cv:line(cx - half, cy + half - 1, cx + half, cy + half - 1, WithAlpha(mat.Light, 110), 2)
end

-- Light catches the raised rim from the upper-left; the lower-right rim
-- falls into shade. Runs along the rim die so it follows any flan shape.
local function DrawSheen(cv: Canvas, flan: Flan, die: Die, mat: Resolver.Material, worn: boolean)
    local glint = LerpColor(mat.Light, {r = 255, g = 255, b = 255}, 0.55)
    local brightAlpha = if worn then 90 else 165
    local thickness = math.max(4, flan.R * 0.014)
    DrawDieArc(cv, flan, die, 0.952, math.rad(190), math.rad(258), WithAlpha(glint, brightAlpha), thickness)
    DrawDieArc(cv, flan, die, 0.984, math.rad(198), math.rad(250), WithAlpha(glint, brightAlpha * 0.6), math.max(2, thickness * 0.6))
    DrawDieArc(cv, flan, die, 0.952, math.rad(12), math.rad(78), WithAlpha(mat.Deep, 110), thickness)
end

function module.Render(plan: Resolver.CoinPlan): Canvas
    local mat = Resolver.Materials[plan.material]
    local inlayMat = if plan.inlay then Resolver.Materials[plan.inlay :: string] else nil
    local rng = NewRng(plan.seed)

    local base = canvas.new(Size, Size, WithAlpha(Background, 255))

    -- soft table light behind the coin
    for i = 4, 1, -1 do
        base:circle(Size / 2, Size / 2, Size * 0.14 * i + Size * 0.1, {r = 34, g = 32, b = 42, a = 26})
    end

    local cx, cy = Size / 2, Size / 2
    local R = 292 + 33 * plan.sizeMarks
    if plan.shape == "wedge" then
        R *= 0.94
        cy += R * 0.06
    end

    local wobble: {number}? = nil
    if plan.hammered then
        local built = {}
        for _ = 1, 18 do
            table.insert(built, 0.92 + rng() * 0.13)
        end
        wobble = built
    end

    local flan: Flan = {
        cx = cx,
        cy = cy,
        R = R,
        shape = plan.shape,
        inradius = 0,
        wobble = wobble,
    }
    flan.inradius = R * MinProfile(plan.shape) * (if plan.hammered then 0.92 else 1)

    local strikeOx, strikeOy = 0, 0
    if plan.hammered then
        strikeOx = (rng() - 0.5) * R * 0.15
        strikeOy = (rng() - 0.5) * R * 0.15
    end

    local circleDie: Die = {
        circle = true,
        cx = cx + strikeOx,
        cy = cy + strikeOy,
        r = flan.inradius * 0.965,
        flan = flan,
    }
    local rimDie: Die = if plan.hammered then circleDie else {circle = false, cx = cx, cy = cy, r = flan.inradius, flan = flan}
    local outerMat = inlayMat or mat

    -- drop shadow, then the coin's edge (thickness), then the face
    base:polygon(ShapePoints(flan, 1.02, 12, 18, 96), {r = 0, g = 0, b = 0, a = 110})
    base:polygon(ShapePoints(flan, 1, 5, 9, 96), WithAlpha(mat.Deep, 255))
    DrawMetalFace(base, flan, outerMat)

    -- bimetal insert, or a faint engraved circle on plain coins
    local fieldR: number
    if inlayMat then
        local insertR = flan.inradius * 0.7
        DrawMetalDisc(base, circleDie.cx, circleDie.cy, insertR, mat)
        local groove = insertR / circleDie.r
        DrawDieRing(base, flan, circleDie, groove + 0.012, WithAlpha(outerMat.Deep, 200), 3)
        DrawDieRing(base, flan, circleDie, groove - 0.01, WithAlpha(mat.Light, 130), 2)
        fieldR = insertR * 0.86
    else
        DrawDieRing(base, flan, circleDie, 0.72, WithAlpha(mat.Dark, 120), 2)
        DrawDieRing(base, flan, circleDie, 0.705, WithAlpha(mat.Light, 70), 1)
        fieldR = flan.inradius * 0.62
    end

    if plan.spiral ~= 0 then
        DrawSwirl(base, flan, circleDie, if plan.spiral > 0 then 1 else -1, mat)
    end

    DrawRim(base, flan, rimDie, outerMat)
    DrawDenticles(base, flan, rimDie, outerMat)
    if plan.milled then
        DrawMilling(base, flan, outerMat)
    end

    -- legends: the coin's name above, its worth below
    local tilt = math.clamp(plan.spiral, -3, 3) * math.rad(5)
    local legendSize = math.max(17, R * 0.075)
    DrawLegend(base, flan, circleDie, string.upper(plan.name), true, legendSize, outerMat, tilt)
    DrawLegend(base, flan, circleDie, `· {plan.value} {if plan.value == 1 then "BIT" else "BITS"} ·`, false, legendSize * 0.9, outerMat, tilt)

    -- the field: hole, device, numeral, mint marks
    if plan.holed then
        DrawHole(base, circleDie.cx, circleDie.cy, flan.inradius * 0.17, mat)
    end

    local emblem = plan.emblem
    if emblem then
        local power = (emblem :: Resolver.Emblem).power
        local s = fieldR * (0.62 + 0.05 * math.min(power, 5))
        local ex, ey = circleDie.cx, circleDie.cy
        if plan.holed then
            -- between the hole's rim and the field circle
            s = flan.inradius * 0.18
            ey = circleDie.cy - flan.inradius * 0.42
        elseif plan.numeral then
            s *= 0.76
            ey -= fieldR * 0.3
        end
        DrawEmblem(base, (emblem :: Resolver.Emblem).letter, ex, ey, s, mat, power)
    end

    if plan.numeral then
        local text = plan.numeral :: string
        local size: number
        local ny: number
        if plan.holed then
            -- between the hole's rim and the field circle, clear of the legend
            size = flan.inradius * 0.26
            ny = circleDie.cy + flan.inradius * 0.42
        elseif emblem then
            size = fieldR * 0.52
            ny = circleDie.cy + fieldR * 0.6
        else
            size = fieldR * 1.05
            ny = circleDie.cy
        end
        if RuneFont then
            local width = (RuneFont :: CanvasFont):measure(text, size)
            local maxWidth = if plan.holed then flan.inradius * 0.62 else fieldR * 1.3
            if width > maxWidth then
                size *= maxWidth / width
            end
        end
        DrawTextEmbossed(base, text, circleDie.cx, ny, size, mat)
    end

    for index, mark in ipairs(plan.mintmarks) do
        local side = if index == 1 then -1 else 1
        local mx = circleDie.cx + side * fieldR * 0.62
        local my = circleDie.cy + fieldR * 0.55
        if plan.holed then
            mx = circleDie.cx + side * flan.inradius * 0.52
            my = circleDie.cy
        elseif plan.numeral and emblem then
            -- numeral owns the lower field; the marks flank the device
            mx = circleDie.cx + side * fieldR * 0.74
            my = circleDie.cy + fieldR * 0.02
        elseif plan.numeral then
            mx = circleDie.cx + side * fieldR * 0.74
            my = circleDie.cy
        end
        DrawEmblem(base, mark.letter, mx, my, fieldR * 0.17, mat, 1)
    end

    -- weathering sits over the relief
    if plan.patina > 0 then
        base:polygon(ShapePoints(flan, 0.99, 0, 0, 72), {r = 80, g = 140, b = 100, a = 26})
        local count = 30 + 45 * math.min(plan.patina, 4)
        for _ = 1, count do
            local theta = rng() * TwoPi
            local reach = math.sqrt(rng()) * 0.9
            local radius = FlanRadius(flan, theta) * reach
            local px = cx + radius * math.cos(theta)
            local py = cy + radius * math.sin(theta)
            local tone = PatinaTones[math.floor(rng() * #PatinaTones) + 1]
            local blob = 2 + rng() * 5
            base:circle(px, py, blob, WithAlpha(tone, 80 + rng() * 70))
            if rng() < 0.4 then
                base:circle(px + blob, py + blob * 0.5, blob * 0.7, WithAlpha(tone, 60 + rng() * 50))
            end
        end
    end

    if plan.wear > 0 then
        local count = 25 + 40 * math.min(plan.wear, 4)
        for _ = 1, count do
            local theta = rng() * TwoPi
            local reach = math.sqrt(rng()) * 0.94
            local radius = FlanRadius(flan, theta) * reach
            base:circle(cx + radius * math.cos(theta), cy + radius * math.sin(theta), 1.5 + rng() * 3.5, WithAlpha(PitTone, 130 + rng() * 90))
        end
        -- corrosion bites the edge
        for _ = 1, 3 + math.min(plan.wear, 4) * 2 do
            local theta = rng() * TwoPi
            local radius = FlanRadius(flan, theta)
            base:circle(cx + radius * math.cos(theta), cy + radius * math.sin(theta), 4 + rng() * 7, WithAlpha(Background, 255))
        end
    end

    -- voidmetal holds a night sky
    if plan.material == "voidmetal" then
        for _ = 1, 16 do
            local theta = rng() * TwoPi
            local reach = math.sqrt(rng()) * 0.82
            local radius = FlanRadius(flan, theta) * reach
            local px = cx + radius * math.cos(theta)
            local py = cy + radius * math.sin(theta)
            base:circle(px, py, 1 + rng() * 1.6, {r = 235, g = 225, b = 255, a = math.floor(90 + rng() * 90)})
        end
        for i = 1, 5 do
            local ring = ShapePoints(flan, 1 + i * 0.014, 0, 0, 72)
            table.insert(ring, {ring[1][1], ring[1][2]})
            base:polyline(ring, {r = 150, g = 90, b = 230, a = math.floor(60 / i)}, 4)
        end
    end

    DrawSheen(base, flan, rimDie, mat, plan.patina > 0 or plan.wear > 0)

    return base:vignette(0.32)
end

function module.Encode(image: Canvas): string
    return image:encode("png")
end

return module
