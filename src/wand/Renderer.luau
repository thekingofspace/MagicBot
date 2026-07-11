--#include[canvas, fs]
local Resolver = require("@src/wand/Resolver")

local module = {}

local Width = 760
local Height = 1060
local TwoPi = 2 * math.pi

local FontCandidates = {
    "C:/Windows/Fonts/georgia.ttf",
    "C:/Windows/Fonts/constan.ttf",
    "C:/Windows/Fonts/times.ttf",
    "C:/Windows/Fonts/arial.ttf",
}

local WandFont: CanvasFont? = nil
for _, path in ipairs(FontCandidates) do
    if fs.exists(path) then
        local ok, font = pcall(function()
            return canvas.font(path)
        end)
        if ok then
            WandFont = font
            break
        end
    end
end

local VelvetBase = {r = 17, g = 13, b = 23}
local VelvetLight = {r = 34, g = 26, b = 48}
local VelvetDark = {r = 6, g = 4, b = 10}
local PoolTone = {r = 58, g = 46, b = 74}
local OutlineColor = {r = 12, g = 9, b = 18}
local GoldLight = {r = 246, g = 214, b = 120}
local GoldMid = {r = 208, g = 164, b = 72}
local GoldDeep = {r = 104, g = 76, b = 28}
local LeatherColor = {r = 74, g = 48, b = 30}
local LeatherLight = {r = 122, g = 84, b = 54}
local BoneColor = {r = 224, g = 214, b = 190}
local CordColor = {r = 152, g = 34, b = 44}
local CordLight = {r = 214, g = 84, b = 92}
local BurnColor = {r = 38, g = 24, b = 14}
local SparkColor = {r = 255, g = 240, b = 170}
local White = {r = 255, g = 255, b = 255}

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

local function Luminance(color: Resolver.Rgb): number
    return 0.299 * color.r + 0.587 * color.g + 0.114 * color.b
end

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

type Frame = {
    tipX: number,
    tipY: number,
    ux: number,
    uy: number,
    px: number,
    py: number,
    total: number,
    warp: (s: number) -> number,
}

local function At(frame: Frame, s: number, o: number): (number, number)
    local drift = frame.warp(s)
    return frame.tipX + frame.ux * s + frame.px * (o + drift),
        frame.tipY + frame.uy * s + frame.py * (o + drift)
end

local function BuildWarp(plan, rng: () -> number, total: number, scale: number?): (s: number) -> number
    local factor = scale or 1
    local silhouette = plan.silhouette
    local curveAmp = (24 + 8 * plan.curveAmount) * plan.curveSign
    local serpentWaves = 1.5 + 0.5 * math.min(plan.curveAmount + 3, 6)
    local zigSegs = 5
    local zigAmp = 16
    local serpentAmp = 14
    if silhouette == "serpent" then
        serpentAmp = 12 + 3 * math.min(plan.curveAmount + 2, 5)
    end
    local naturalSign = if rng() < 0.5 then -1 else 1
    local naturalPhase = rng() * TwoPi

    local wobble: {number}? = nil
    if plan.wild then
        local built = {}
        for _ = 1, 9 do
            table.insert(built, (rng() - 0.5) * 20)
        end
        wobble = built
    end

    return function(s: number): number
        local t = math.clamp(s / total, 0, 1)
        local envelope = math.sin(math.pi * t)
        local drift = 0
        if silhouette == "curve" then
            drift = curveAmp * envelope
        elseif silhouette == "serpent" then
            drift = serpentAmp * math.sin(TwoPi * serpentWaves * t) * envelope ^ 0.35
        elseif silhouette == "zigzag" then
            local phase = t * zigSegs
            local saw = phase - math.floor(phase)
            local tri = if math.floor(phase) % 2 == 0 then saw * 2 - 1 else 1 - saw * 2
            drift = zigAmp * tri * envelope ^ 0.3
        elseif silhouette == "natural" then
            drift = 8 * naturalSign * envelope + 2.5 * math.sin(TwoPi * t + naturalPhase)
        end
        if wobble then
            local list = wobble :: {number}
            local pos = t * (#list - 1)
            local index = math.floor(pos)
            local fraction = pos - index
            local a = list[index + 1]
            local b = list[math.min(index + 2, #list)]
            local smooth = (1 - math.cos(math.pi * fraction)) / 2
            drift += (a + (b - a) * smooth) * (0.55 + 0.45 * envelope)
        end
        return drift * factor
    end
end

type Knot = {t: number, bump: number, off: number}

local function Bloom(cv: Canvas, x: number, y: number, radius: number, color: Resolver.Rgb, power: number)
    local factor = 0.5 + 0.18 * math.min(power, 5)
    local layers = 12
    for i = layers, 1, -1 do
        local k = i / layers
        local alpha = 3 + 34 * factor * (1 - k) ^ 1.7
        cv:circle(x, y, radius * (0.75 + 2.6 * k), WithAlpha(color, alpha))
    end
end

local function Arc(cv: Canvas, cx: number, cy: number, radius: number, fromAngle: number, toAngle: number, color: any, thickness: number)
    local steps = 30
    local points = {}
    for i = 0, steps do
        local a = fromAngle + (toAngle - fromAngle) * i / steps
        table.insert(points, {cx + radius * math.cos(a), cy + radius * math.sin(a)})
    end
    cv:polyline(points, color, thickness)
end

local function DrawVelvet(cv: Canvas, rng: () -> number, midX: number, midY: number)
    for i = 1, 6 do
        local x0 = -120 + (Width + 240) * (i - 0.5) / 6 + (rng() - 0.5) * 90
        local sway = 26 + rng() * 40
        local phase = rng() * TwoPi
        local points = {}
        for j = 0, 22 do
            local y = -60 + (Height + 120) * j / 22
            table.insert(points, {x0 + math.sin(phase + j * 0.32) * sway + y * 0.22, y})
        end
        local tone = if i % 2 == 0 then WithAlpha(VelvetLight, 16) else WithAlpha(VelvetDark, 24)
        cv:polyline(points, tone, 60 + rng() * 55)
    end
    for i = 8, 1, -1 do
        cv:circle(midX, midY, 60 + i * 62, WithAlpha(PoolTone, 8))
    end
end

local function DrawSkull(cv: Canvas, x: number, y: number, radius: number)
    cv:circle(x, y, radius + 1.5, OutlineColor)
    cv:circle(x, y, radius, BoneColor)
    cv:circle(x - radius * 0.18, y - radius * 0.26, radius * 0.4, WithAlpha({r = 250, g = 246, b = 232}, 130))
    cv:circle(x - radius * 0.36, y - radius * 0.1, radius * 0.24, OutlineColor)
    cv:circle(x + radius * 0.36, y - radius * 0.1, radius * 0.24, OutlineColor)
    cv:circle(x, y + radius * 0.26, radius * 0.12, WithAlpha(OutlineColor, 220))
    for _, o in ipairs({-0.32, 0, 0.32}) do
        cv:line(x + radius * o, y + radius * 0.5, x + radius * o, y + radius * 0.86, WithAlpha({r = 120, g = 110, b = 90}, 230), 1.5)
    end
end

local function DrawTassel(cv: Canvas, x: number, y: number)
    local kx, ky = x + 7, y + 18
    local bx, by = x + 11, y + 34
    cv:line(x, y, kx, ky, WithAlpha(CordColor, 240), 2.5)
    cv:line(kx, ky, bx, by, WithAlpha(CordColor, 240), 2.5)
    cv:circle(bx, by, 3.4, OutlineColor)
    cv:circle(bx, by, 2.4, GoldMid)
    for i = -2, 2 do
        local tone = if i % 2 == 0 then CordColor else CordLight
        cv:line(bx, by, bx + i * 4.5, by + 20 + math.abs(i) * 2.5, WithAlpha(tone, 225), 1.8)
    end
end

local WoodDetail: {[string]: (Canvas, Frame, Resolver.WandPlan, Resolver.Wood, () -> number, (t: number) -> number, number) -> ()} = {
    ebonwood = function(cv, frame, plan, wood, rng, halfWidth, tEnd)
        for _ = 1, 14 do
            local t = 0.05 + (tEnd - 0.1) * rng()
            local o = (rng() - 0.5) * 2 * halfWidth(t) * 0.6
            local x, y = At(frame, t * frame.total, o)
            cv:circle(x, y, 0.8 + rng() * 1.1, WithAlpha({r = 235, g = 225, b = 255}, 90 + rng() * 100))
        end
        local points = {}
        for i = 0, 24 do
            local t = 0.08 + (tEnd - 0.12) * i / 24
            local x, y = At(frame, t * frame.total, -halfWidth(t) + 1)
            table.insert(points, {x, y})
        end
        cv:polyline(points, WithAlpha({r = 150, g = 92, b = 230}, 55), 2)
    end,
    ash = function(cv, frame, plan, wood, rng, halfWidth, tEnd)
        for _ = 1, 7 do
            local t0 = 0.06 + (tEnd - 0.2) * rng()
            local span = 0.04 + rng() * 0.08
            local lane = (rng() - 0.5) * 1.2
            local points = {}
            for i = 0, 6 do
                local t = t0 + span * i / 6
                local x, y = At(frame, t * frame.total, lane * halfWidth(t) * 0.8 + (rng() - 0.5) * 1.5)
                table.insert(points, {x, y})
            end
            cv:polyline(points, WithAlpha({r = 26, g = 22, b = 20}, 150 + rng() * 60), 2 + rng() * 2)
        end
    end,
    dreamwood = function(cv, frame, plan, wood, rng, halfWidth, tEnd)
        local tones = {
            {r = 255, g = 214, b = 240},
            {r = 205, g = 228, b = 255},
            {r = 224, g = 255, b = 232},
        }
        for i = 1, 12 do
            local t0 = 0.06 + (tEnd - 0.14) * rng()
            local lane = (rng() - 0.5) * 1.3
            local x1, y1 = At(frame, t0 * frame.total, lane * halfWidth(t0) * 0.7)
            local x2, y2 = At(frame, (t0 + 0.03) * frame.total, lane * halfWidth(t0 + 0.03) * 0.7)
            cv:line(x1, y1, x2, y2, WithAlpha(tones[i % 3 + 1], 75), 1.6)
        end
    end,
    greenwood = function(cv, frame, plan, wood, rng, halfWidth, tEnd)
        for _ = 1, 4 do
            local t = 0.12 + (tEnd - 0.24) * rng()
            local side = if rng() < 0.5 then -1 else 1
            local s = t * frame.total
            local w = halfWidth(t)
            local x, y = At(frame, s, side * (w - 0.5))
            local nx, ny = frame.px * side, frame.py * side
            local sx, sy = x + nx * 8, y + ny * 8
            cv:line(x, y, sx, sy, WithAlpha({r = 70, g = 110, b = 50}, 230), 2)
            local lx, ly = sx + nx * 5, sy + ny * 5
            local tx, ty = frame.ux, frame.uy
            cv:polygon({
                {sx, sy},
                {lx + tx * 3.2, ly + ty * 3.2},
                {lx + nx * 5.5, ly + ny * 5.5},
                {lx - tx * 3.2, ly - ty * 3.2},
            }, WithAlpha({r = 122, g = 184, b = 82}, 235))
            cv:line(sx, sy, lx + nx * 4.5, ly + ny * 4.5, WithAlpha({r = 56, g = 96, b = 40}, 200), 1)
        end
    end,
    blightwood = function(cv, frame, plan, wood, rng, halfWidth, tEnd)
        for i = 1, 6 do
            local t = 0.08 + (tEnd - 0.16) * rng()
            local s = t * frame.total
            local o = (rng() - 0.5) * halfWidth(t)
            local points = {}
            local cs, co = s, o
            table.insert(points, {At(frame, cs, co)})
            for _ = 1, 3 do
                cs += 6 + rng() * 10
                co += (rng() - 0.5) * halfWidth(t) * 1.1
                table.insert(points, {At(frame, cs, co)})
            end
            cv:polyline(points, WithAlpha({r = 24, g = 20, b = 14}, 210), 1.8)
            if i <= 2 then
                local dx, dy = At(frame, cs, co)
                cv:line(dx, dy, dx + 1, dy + 9 + rng() * 8, WithAlpha({r = 110, g = 130, b = 60}, 110), 2)
                cv:circle(dx + 1, dy + 11 + rng() * 8, 2, WithAlpha({r = 110, g = 130, b = 60}, 130))
            end
        end
    end,
    petrified = function(cv, frame, plan, wood, rng, halfWidth, tEnd)
        for i = 1, 9 do
            local t = 0.06 + (tEnd - 0.12) * (i - 0.5) / 9 + (rng() - 0.5) * 0.02
            local s = t * frame.total
            local w = halfWidth(t) * 0.9
            local tone = if i % 2 == 0 then WithAlpha(wood.Light, 40) else WithAlpha(wood.Deep, 60)
            local x1, y1 = At(frame, s, -w)
            local x2, y2 = At(frame, s + 2, w)
            cv:line(x1, y1, x2, y2, tone, 2.5)
        end
    end,
    goldenwood = function(cv, frame, plan, wood, rng, halfWidth, tEnd)
        local points = {}
        for i = 0, 24 do
            local t = 0.05 + (tEnd - 0.1) * i / 24
            local x, y = At(frame, t * frame.total, -halfWidth(t) * 0.25)
            table.insert(points, {x, y})
        end
        cv:polyline(points, WithAlpha({r = 255, g = 236, b = 160}, 80), 3)
    end,
    cherry = function(cv, frame, plan, wood, rng, halfWidth, tEnd)
        for _ = 1, 3 do
            local t0 = 0.1 + (tEnd - 0.25) * rng()
            local lane = (rng() - 0.5) * 1.1
            local points = {}
            for i = 0, 8 do
                local t = t0 + 0.1 * i / 8
                local x, y = At(frame, t * frame.total, lane * halfWidth(t) * 0.7)
                table.insert(points, {x, y})
            end
            cv:polyline(points, WithAlpha(wood.Deep, 60), 2.5)
        end
    end,
}

local TipDrawers: {[string]: (Canvas, Frame, Resolver.WandPlan, Resolver.Wood, (t: number) -> number) -> ()} = {
    orb = function(cv, frame, plan, wood, halfWidth)
        local power = math.min(plan.tipPower, 5)
        local orbR = 15 + 3 * power
        local cx, cy = At(frame, -orbR - 2, 0)
        Bloom(cv, cx, cy, orbR, wood.Glow, power)
        local mx1, my1 = At(frame, -2, -halfWidth(0) - 1.6)
        local mx2, my2 = At(frame, 4, halfWidth(0) + 1.6)
        cv:line(mx1, my1, mx2, my2, GoldDeep, 8)
        cv:line(mx1, my1, mx2, my2, GoldMid, 5)
        cv:circle(cx, cy, orbR + 1.8, OutlineColor)
        local darkGlass = LerpColor(wood.Glow, {r = 8, g = 6, b = 12}, 0.72)
        local lightGlass = LerpColor(wood.Glow, White, 0.35)
        local layers = 8
        for k = layers, 1, -1 do
            local tt = k / layers
            local lightT = (1 - tt) ^ 0.8
            cv:circle(cx - orbR * 0.28 * (1 - tt), cy - orbR * 0.34 * (1 - tt), orbR * tt, LerpColor(darkGlass, lightGlass, lightT))
        end
        cv:circle(cx, cy, orbR * 0.45, WithAlpha(wood.Glow, 120))
        cv:circle(cx - orbR * 0.35, cy - orbR * 0.4, orbR * 0.2, WithAlpha(White, 200))
    end,
    crystal = function(cv, frame, plan, wood, halfWidth)
        local power = math.min(plan.tipPower, 5)
        local len = 38 + 6 * power
        local halfw = 8 + 1.2 * power
        local mx, my = At(frame, -6 - len * 0.5, 0)
        Bloom(cv, mx, my, len * 0.42, wood.Glow, power)
        local points = {
            {At(frame, 4, -halfw * 0.6)},
            {At(frame, -6, -halfw)},
            {At(frame, -6 - len, 0)},
            {At(frame, -6, halfw)},
            {At(frame, 4, halfw * 0.6)},
        }
        cv:strokePolygon(points, OutlineColor, 3)
        cv:polygon(points, LerpColor(wood.Glow, White, 0.3))
        cv:polygon({
            {At(frame, -6 - len, 0)},
            {At(frame, -6, halfw)},
            {At(frame, 4, halfw * 0.6)},
            {At(frame, 4, 0)},
        }, WithAlpha(LerpColor(wood.Glow, {r = 20, g = 16, b = 30}, 0.45), 230))
        local sx1, sy1 = At(frame, -6 - len + 4, 0)
        local sx2, sy2 = At(frame, 2, 0)
        cv:line(sx1, sy1, sx2, sy2, WithAlpha(White, 130), 1.5)
        local cx1, cy1 = At(frame, 3, -halfWidth(0) - 1)
        local cx2, cy2 = At(frame, 6, halfWidth(0) + 1)
        cv:line(cx1, cy1, cx2, cy2, GoldMid, 4)
    end,
    fork = function(cv, frame, plan, wood, halfWidth)
        local power = math.min(plan.tipPower, 5)
        local reach = 34 + 5 * power
        local spread = 13 + 2.5 * power
        local mx, my = At(frame, -reach * 0.5, 0)
        Bloom(cv, mx, my, 9, wood.Glow, math.max(power - 1, 1))
        for _, side in ipairs({-1, 1}) do
            local points = {
                {At(frame, 6, side * 0.6)},
                {At(frame, -8, side * (4.5 + power * 0.8))},
                {At(frame, -reach, side * spread)},
                {At(frame, -6, side * (7.5 + power))},
                {At(frame, 7, side * 3.6)},
            }
            cv:strokePolygon(points, OutlineColor, 2.5)
            cv:polygon(points, wood.Mid)
            local e1x, e1y = At(frame, -reach + 2, side * (spread - 1))
            local e2x, e2y = At(frame, 2, side * 1.4)
            cv:line(e1x, e1y, e2x, e2y, WithAlpha(wood.Light, 180), 1.5)
        end
    end,
    crescent = function(cv, frame, plan, wood, halfWidth)
        local power = math.min(plan.tipPower, 5)
        local cr = 17 + 3 * power
        local cx, cy = At(frame, -12 - cr * 0.7, 0)
        Bloom(cv, cx, cy, cr * 0.8, wood.Glow, power)
        local inward = math.atan2(frame.uy, frame.ux)
        local tone = LerpColor(wood.Glow, White, 0.2)
        Arc(cv, cx, cy, cr, inward - 2.35, inward + 2.35, OutlineColor, 9)
        Arc(cv, cx, cy, cr, inward - 2.35, inward + 2.35, tone, 6)
        Arc(cv, cx, cy, cr - 3, inward - 1.6, inward + 1.6, WithAlpha(LerpColor(tone, White, 0.4), 200), 2.5)
        for _, side in ipairs({-2.35, 2.35}) do
            local hx = cx + cr * math.cos(inward + side)
            local hy = cy + cr * math.sin(inward + side)
            cv:circle(hx, hy, 3.2, tone)
        end
        local m1x, m1y = At(frame, -4, -halfWidth(0) - 1)
        local m2x, m2y = At(frame, 0, halfWidth(0) + 1)
        cv:line(m1x, m1y, m2x, m2y, GoldMid, 4)
    end,
    gem = function(cv, frame, plan, wood, halfWidth)
        local r = 10
        local cx, cy = At(frame, -8, 0)
        Bloom(cv, cx, cy, r, wood.Glow, 2)
        local points = {
            {At(frame, -8 - r * 1.4, 0)},
            {At(frame, -8, r)},
            {At(frame, -8 + r * 1.1, 0)},
            {At(frame, -8, -r)},
        }
        cv:strokePolygon(points, OutlineColor, 2.5)
        cv:polygon(points, LerpColor(wood.Glow, White, 0.3))
        cv:line(points[1][1], points[1][2], points[3][1], points[3][2], WithAlpha(White, 150), 1)
        cv:line(points[2][1], points[2][2], points[4][1], points[4][2], WithAlpha(White, 150), 1)
        local m1x, m1y = At(frame, 0, -halfWidth(0) - 0.8)
        local m2x, m2y = At(frame, 3, halfWidth(0) + 0.8)
        cv:line(m1x, m1y, m2x, m2y, GoldMid, 3)
    end,
    seal = function(cv, frame, plan, wood, halfWidth)
        local w = halfWidth(0) + 1.4
        local points = {
            {At(frame, 0, -w)},
            {At(frame, 0, w)},
            {At(frame, 6, w)},
            {At(frame, 6, -w)},
        }
        cv:strokePolygon(points, OutlineColor, 2.5)
        cv:polygon(points, wood.Deep)
        local x1, y1 = At(frame, 1.5, -w + 1)
        local x2, y2 = At(frame, 1.5, w - 1)
        cv:line(x1, y1, x2, y2, WithAlpha(wood.Light, 130), 1.5)
    end,
    point = function(cv, frame, plan, wood, halfWidth)
        local points = {}
        for i = 0, 10 do
            local t = 0.02 + 0.12 * i / 10
            table.insert(points, {At(frame, t * frame.total, -halfWidth(t) * 0.4)})
        end
        cv:polyline(points, WithAlpha(wood.Light, 150), 2)
    end,
    bare = function() end,
}

function module.Render(plan: Resolver.WandPlan): Canvas
    local wood = Resolver.Woods[plan.wood]
    local handleWood = if plan.handleWood then Resolver.Woods[plan.handleWood :: string] else wood
    local rng = NewRng(plan.seed)

    local total = math.min(430 + plan.spans * 56, 990)
    local ux, uy = 0.5, 0.866
    local px, py = uy, -ux
    local midX, midY = 380, 532
    local tipX = midX - ux * total / 2
    local tipY = midY - uy * total / 2

    local frame: Frame = {
        tipX = tipX,
        tipY = tipY,
        ux = ux,
        uy = uy,
        px = px,
        py = py,
        total = total,
        warp = function()
            return 0
        end,
    }
    frame.warp = BuildWarp(plan, rng, total)

    local handleLen = if plan.handleSpans > 0 then math.min(plan.handleSpans * 62, total * 0.42) else 0
    local handleT = if handleLen > 0 then 1 - handleLen / total else 1.05
    local handleS = handleT * total

    local knots: {Knot} = {}
    for i = 1, plan.knots do
        table.insert(knots, {
            t = 0.16 + 0.62 * (i - 0.5) / math.max(plan.knots, 1) + (rng() - 0.5) * 0.05,
            bump = 4.5 + rng() * 3,
            off = (rng() - 0.5) * 3,
        })
    end

    local buttW = 12 + plan.spans * 0.55 + (if plan.handleSpans > 0 then 2 else 0)
    local tipW = if plan.taper > 0 then 2.4 else 4.4
    local expo = if plan.taper > 0 then 1.15 + 0.08 * plan.taper else 0.88

    local function HalfWidth(t: number): number
        local w = tipW + (buttW - tipW) * math.clamp(t, 0, 1) ^ expo
        for _, knot in ipairs(knots) do
            local d = (t - knot.t) / 0.045
            w += knot.bump * math.exp(-d * d)
        end
        if handleT <= 1 and t > handleT then
            local rise = math.clamp((t - handleT) / 0.05, 0, 1)
            w += 2.8 * rise
        end
        return w
    end

    local base = canvas.new(Width, Height, WithAlpha(VelvetBase, 255))
    DrawVelvet(base, rng, midX, midY)

    local samples = 90
    local left = {}
    local right = {}
    for i = 0, samples do
        local t = i / samples
        local s = t * total
        local w = HalfWidth(t)
        table.insert(left, {At(frame, s, -w)})
        table.insert(right, {At(frame, s, w)})
    end

    local silhouette = {}
    for i = 1, #left do
        table.insert(silhouette, left[i])
    end
    for i = #right, 1, -1 do
        table.insert(silhouette, right[i])
    end

    local shadow = {}
    for _, point in ipairs(silhouette) do
        table.insert(shadow, {point[1] + 11, point[2] + 16})
    end
    base:polygon(shadow, {r = 0, g = 0, b = 0, a = 85})

    base:strokePolygon(silhouette, OutlineColor, 3.5)
    base:polygon(silhouette, wood.Mid)

    local shade = {}
    for i = 1, #right do
        table.insert(shade, right[i])
    end
    for i = samples + 1, 1, -1 do
        local t = (i - 1) / samples
        table.insert(shade, {At(frame, t * total, HalfWidth(t) * 0.2)})
    end
    base:polygon(shade, WithAlpha(wood.Dark, 150))

    local highlight = {}
    for i = 0, samples do
        local t = i / samples
        table.insert(highlight, {At(frame, t * total, -HalfWidth(t) * 0.55)})
    end
    base:polyline(highlight, WithAlpha(wood.Light, 95), 2.5)

    if handleT <= 1 and plan.handleWood then
        local hLeft = {}
        local hRight = {}
        local hSamples = 24
        for i = 0, hSamples do
            local t = handleT + (1 - handleT) * i / hSamples
            local s = t * total
            local w = HalfWidth(t) - 0.5
            table.insert(hLeft, {At(frame, s, -w)})
            table.insert(hRight, {At(frame, s, w)})
        end
        local handlePoly = {}
        for i = 1, #hLeft do
            table.insert(handlePoly, hLeft[i])
        end
        for i = #hRight, 1, -1 do
            table.insert(handlePoly, hRight[i])
        end
        base:polygon(handlePoly, handleWood.Mid)
        local hShade = {}
        for i = 1, #hRight do
            table.insert(hShade, hRight[i])
        end
        for i = hSamples + 1, 1, -1 do
            local t = handleT + (1 - handleT) * (i - 1) / hSamples
            table.insert(hShade, {At(frame, t * total, HalfWidth(t) * 0.2)})
        end
        base:polygon(hShade, WithAlpha(handleWood.Dark, 150))
        local hl = {}
        for i = 0, hSamples do
            local t = handleT + (1 - handleT) * i / hSamples
            table.insert(hl, {At(frame, t * total, -HalfWidth(t) * 0.55)})
        end
        base:polyline(hl, WithAlpha(handleWood.Light, 95), 2)
    end

    local grainEnd = math.min(handleT, 0.97)
    for laneIndex, lane in ipairs({-0.55, -0.15, 0.3, 0.6}) do
        local points = {}
        for i = 0, 40 do
            local t = 0.03 + (grainEnd - 0.05) * i / 40
            local wobbleO = math.sin(t * 17 + laneIndex * 2.3) * 0.6
            table.insert(points, {At(frame, t * total, lane * HalfWidth(t) * 0.8 + wobbleO)})
        end
        local tone = if laneIndex % 2 == 0 then WithAlpha(wood.Light, 55) else WithAlpha(wood.Deep, 110)
        base:polyline(points, tone, 1.6)
    end
    if handleT <= 1 then
        for laneIndex, lane in ipairs({-0.35, 0.4}) do
            local points = {}
            for i = 0, 10 do
                local t = handleT + 0.02 + (0.96 - handleT) * i / 10
                table.insert(points, {At(frame, t * total, lane * HalfWidth(t) * 0.75)})
            end
            local tone = if laneIndex % 2 == 0 then WithAlpha(handleWood.Light, 55) else WithAlpha(handleWood.Deep, 110)
            base:polyline(points, tone, 1.6)
        end
    end

    local detail = WoodDetail[plan.wood]
    if detail then
        detail(base, frame, plan, wood, rng, HalfWidth, grainEnd)
    end

    if plan.spiral > 0 then
        local pitch = 22 - plan.spiral * 1.5
        local s = total * 0.06
        local sEnd = math.min(handleS - 8, total * 0.96)
        while s < sEnd do
            local t = s / total
            local w = HalfWidth(t) * 0.92
            local x1, y1 = At(frame, s, -w)
            local x2, y2 = At(frame, s + pitch * 0.55, w)
            base:line(x1, y1, x2, y2, WithAlpha(wood.Deep, 180), 2.5)
            base:line(x1 + 1.5, y1 + 1.5, x2 + 1.5, y2 + 1.5, WithAlpha(wood.Light, 65), 1.5)
            s += pitch
        end
    end

    if plan.groove > 0 then
        local glowPts = {}
        for i = 0, 34 do
            local t = 0.06 + (math.min(handleT, 0.94) - 0.09) * i / 34
            table.insert(glowPts, {At(frame, t * total, 0)})
        end
        base:polyline(glowPts, WithAlpha(wood.Glow, 46), 5.5)
        base:polyline(glowPts, WithAlpha(wood.Deep, 220), 2.2)
        local litPts = {}
        for i = 0, 34 do
            local t = 0.06 + (math.min(handleT, 0.94) - 0.09) * i / 34
            table.insert(litPts, {At(frame, t * total, -1)})
        end
        base:polyline(litPts, WithAlpha(wood.Glow, 70), 1)
    end

    for _, knot in ipairs(knots) do
        local x, y = At(frame, knot.t * total, knot.off)
        base:circle(x, y, knot.bump * 1.05, WithAlpha(wood.Deep, 235))
        base:strokeCircle(x, y, knot.bump * 1.6, WithAlpha(wood.Dark, 160), 1.5)
        base:strokeCircle(x, y, knot.bump * 2.3, WithAlpha(wood.Deep, 80), 1.5)
        base:circle(x - knot.bump * 0.4, y - knot.bump * 0.4, knot.bump * 0.3, WithAlpha(wood.Light, 110))
    end

    if plan.bands > 0 then
        local a = 0.16
        local b = math.min(handleT - 0.08, 0.86)
        for i = 1, plan.bands do
            local bt = if plan.bands == 1 then (a + b) / 2 else a + (b - a) * (i - 1) / (plan.bands - 1)
            local s = bt * total
            local w = HalfWidth(bt) + 1.2
            local band = {
                {At(frame, s - 5, -w)},
                {At(frame, s - 5, w)},
                {At(frame, s + 5, w)},
                {At(frame, s + 5, -w)},
            }
            base:strokePolygon(band, WithAlpha(GoldDeep, 235), 1.5)
            base:polygon(band, GoldMid)
            local x1, y1 = At(frame, s - 2, -w * 0.8)
            local x2, y2 = At(frame, s - 2, w * 0.8)
            base:line(x1, y1, x2, y2, WithAlpha(GoldLight, 210), 1.5)
        end
    end

    local darkWood = Luminance(wood.Mid) < 96
    local inkTone = if darkWood then WithAlpha(LerpColor(wood.Glow, White, 0.2), 215) else WithAlpha(BurnColor, 235)
    local underTone = if darkWood then WithAlpha(OutlineColor, 150) else WithAlpha({r = 235, g = 235, b = 245}, 70)

    if plan.inscription and WandFont then
        local text = plan.inscription :: string
        local font = WandFont :: CanvasFont
        local count = #text
        local t0 = 0.28
        local t1 = math.min(handleT - 0.06, 0.66)
        for i = 1, count do
            local char = string.sub(text, i, i)
            local t = t0 + (t1 - t0) * (i - 0.5) / count
            local x, y = At(frame, t * total, 0)
            local size = 15
            local cw, ch = font:measure(char, size)
            base:text(char, x - cw / 2 + 1, y - ch / 2 + 1, size, underTone, font)
            base:text(char, x - cw / 2, y - ch / 2, size, inkTone, font)
        end
    end

    if plan.mark and WandFont then
        local text = plan.mark :: string
        local font = WandFont :: CanvasFont
        for i = 1, #text do
            local char = string.sub(text, i, i)
            local s = (if handleT <= 1 then handleS else total * 0.86) - 14 - (#text - i) * 11
            local x, y = At(frame, s, 0)
            local cw, ch = font:measure(char, 12)
            base:text(char, x - cw / 2 + 1, y - ch / 2 + 1, 12, underTone, font)
            base:text(char, x - cw / 2, y - ch / 2, 12, inkTone, font)
        end
    end

    if plan.wrap > 0 and handleT <= 1 then
        local s = handleS + 8
        while s < total - 10 do
            local t = s / total
            local w = HalfWidth(t) * 0.95
            local x1, y1 = At(frame, s, -w)
            local x2, y2 = At(frame, s + 6, w)
            base:line(x1, y1, x2, y2, WithAlpha(LeatherColor, 225), 3.2)
            local x3, y3 = At(frame, s + 6, -w)
            local x4, y4 = At(frame, s, w)
            base:line(x3, y3, x4, y4, WithAlpha(LeatherColor, 190), 2.4)
            local hx, hy = At(frame, s + 3, -w * 0.5)
            base:circle(hx, hy, 1, WithAlpha(LeatherLight, 120))
            s += 11
        end
    end

    if plan.knuckles > 0 and handleT <= 1 then
        for i = 1, 4 do
            local s = handleS + (total - handleS) * (i - 0.5) / 4
            local t = s / total
            local x, y = At(frame, s, HalfWidth(t) - 0.5)
            base:circle(x, y, 4.5, handleWood.Dark)
            base:circle(x - 1, y - 1, 3, WithAlpha(handleWood.Light, 120))
        end
    end

    if plan.collar > 0 and handleT <= 1 then
        local w = HalfWidth(handleT) + 2
        local collarPoly = {
            {At(frame, handleS - 5, -w)},
            {At(frame, handleS - 5, w)},
            {At(frame, handleS + 5, w)},
            {At(frame, handleS + 5, -w)},
        }
        base:strokePolygon(collarPoly, WithAlpha(GoldDeep, 235), 1.5)
        base:polygon(collarPoly, GoldMid)
        local x1, y1 = At(frame, handleS - 2.5, -w * 0.85)
        local x2, y2 = At(frame, handleS - 2.5, w * 0.85)
        base:line(x1, y1, x2, y2, WithAlpha(GoldLight, 220), 1.5)
        if plan.collar > 1 then
            local x3, y3 = At(frame, handleS + 9, -w + 1)
            local x4, y4 = At(frame, handleS + 9, w - 1)
            base:line(x3, y3, x4, y4, GoldMid, 3)
        end
    end

    if plan.skull > 0 then
        local x, y = At(frame, total - 16, 0)
        DrawSkull(base, x, y, 6.5)
    end

    if plan.pommel > 0 then
        local pr = 7 + math.min(plan.pommel, 4) * 2.5
        local x, y = At(frame, total + pr - 3, 0)
        base:circle(x, y, pr + 2, OutlineColor)
        base:circle(x, y, pr, handleWood.Mid)
        base:circle(x - pr * 0.3, y - pr * 0.3, pr * 0.35, WithAlpha(handleWood.Light, 170))
        base:strokeCircle(x, y, pr * 0.6, WithAlpha(handleWood.Deep, 210), 1.5)
    else
        local heelW = HalfWidth(1) * 0.85
        local heel = {
            {At(frame, total - 2, -heelW)},
            {At(frame, total - 2, heelW)},
            {At(frame, total + 4, heelW * 0.7)},
            {At(frame, total + 4, -heelW * 0.7)},
        }
        base:strokePolygon(heel, OutlineColor, 2)
        base:polygon(heel, handleWood.Dark)
        local hx1, hy1 = At(frame, total + 1, -heelW * 0.55)
        local hx2, hy2 = At(frame, total + 1, heelW * 0.55)
        base:line(hx1, hy1, hx2, hy2, WithAlpha(handleWood.Light, 110), 1.5)
    end

    if plan.tassel > 0 then
        local tx, ty = At(frame, total - 6, HalfWidth(0.99) * 0.5)
        DrawTassel(base, tx, ty)
    end

    local tipDrawer = TipDrawers[plan.tip]
    if tipDrawer then
        tipDrawer(base, frame, plan, wood, HalfWidth)
    end

    if plan.charms > 0 then
        local charmHue = if plan.charmWood then Resolver.Woods[plan.charmWood :: string].Glow else wood.Glow
        local tx, ty = At(frame, -10, 0)
        for i = 1, plan.charms do
            local ang = rng() * TwoPi
            local orbitR = 26 + i * 13
            base:strokeCircle(tx, ty, orbitR, WithAlpha(charmHue, 32), 1.5)
            local mx = tx + math.cos(ang) * orbitR
            local my = ty + math.sin(ang) * orbitR
            Bloom(base, mx, my, 4.5, charmHue, 2)
            base:circle(mx, my, 2.8, LerpColor(charmHue, White, 0.55))
            for trail = 1, 2 do
                local ta = ang - trail * 0.28
                base:circle(tx + math.cos(ta) * orbitR, ty + math.sin(ta) * orbitR, 2 - trail * 0.6, WithAlpha(charmHue, 130 - trail * 55))
            end
        end
    end

    if plan.wild then
        local count = 10 + math.floor(rng() * 5)
        for _ = 1, count do
            local t = 0.05 + 0.85 * rng()
            local o = (rng() - 0.5) * 2 * (HalfWidth(t) + 18)
            local sx, sy = At(frame, t * total, o)
            local len = 5 + rng() * 5
            local ang = rng() * math.pi
            local dx, dy = math.cos(ang) * len, math.sin(ang) * len
            base:circle(sx, sy, 6, WithAlpha(SparkColor, 40))
            base:circle(sx, sy, 3.2, WithAlpha(SparkColor, 80))
            base:line(sx - dx, sy - dy, sx + dx, sy + dy, WithAlpha(SparkColor, 245), 1.8)
            base:line(sx + dy * 0.55, sy - dx * 0.55, sx - dy * 0.55, sy + dx * 0.55, WithAlpha(White, 220), 1.4)
            base:circle(sx, sy, 1.6, WithAlpha(White, 235))
        end
        for _ = 1, 3 do
            local o = (rng() - 0.5) * 44
            local sx, sy = At(frame, -6 - rng() * 18, o)
            local len = 4 + rng() * 4
            local ang = rng() * math.pi
            local dx, dy = math.cos(ang) * len, math.sin(ang) * len
            base:circle(sx, sy, 5, WithAlpha(SparkColor, 50))
            base:line(sx - dx, sy - dy, sx + dx, sy + dy, WithAlpha(White, 235), 1.6)
            base:line(sx + dy * 0.55, sy - dx * 0.55, sx - dy * 0.55, sy + dx * 0.55, WithAlpha(SparkColor, 235), 1.4)
        end
    end

    return base:vignette(0.32)
end

local IronMid = {r = 118, g = 116, b = 128}
local IronLight = {r = 176, g = 174, b = 186}
local IronDeep = {r = 52, g = 50, b = 60}

local function DrawGlassOrb(cv: Canvas, x: number, y: number, orbR: number, glow: Resolver.Rgb)
    cv:circle(x, y, orbR + 1.8, OutlineColor)
    local darkGlass = LerpColor(glow, {r = 8, g = 6, b = 12}, 0.72)
    local lightGlass = LerpColor(glow, White, 0.35)
    for k = 8, 1, -1 do
        local tt = k / 8
        cv:circle(x - orbR * 0.28 * (1 - tt), y - orbR * 0.34 * (1 - tt), orbR * tt, LerpColor(darkGlass, lightGlass, (1 - tt) ^ 0.8))
    end
    cv:circle(x, y, orbR * 0.45, WithAlpha(glow, 120))
    cv:circle(x - orbR * 0.35, y - orbR * 0.4, orbR * 0.2, WithAlpha(White, 200))
end

local StaffHeads: {[string]: (Canvas, Frame, Resolver.StaffPlan, Resolver.Wood, Resolver.Wood, (t: number) -> number, () -> number) -> ()} = {
    crystal = function(cv, frame, plan, wood, crown, halfWidth, rng)
        local power = math.min(plan.headPower, 5)
        local len = 40 + 6 * power
        local halfw = 9 + 1.2 * power
        local mx, my = At(frame, -16 - len * 0.5, 0)
        Bloom(cv, mx, my, len * 0.42, wood.Glow, power)
        local points = {
            {At(frame, -8, -halfw * 0.62)},
            {At(frame, -16, -halfw)},
            {At(frame, -16 - len, 0)},
            {At(frame, -16, halfw)},
            {At(frame, -8, halfw * 0.62)},
        }
        cv:strokePolygon(points, OutlineColor, 3)
        cv:polygon(points, LerpColor(wood.Glow, White, 0.3))
        cv:polygon({
            {At(frame, -16 - len, 0)},
            {At(frame, -16, halfw)},
            {At(frame, -8, halfw * 0.62)},
            {At(frame, -8, 0)},
        }, WithAlpha(LerpColor(wood.Glow, {r = 20, g = 16, b = 30}, 0.45), 230))
        local sx1, sy1 = At(frame, -16 - len + 5, 0)
        local sx2, sy2 = At(frame, -10, 0)
        cv:line(sx1, sy1, sx2, sy2, WithAlpha(White, 130), 1.5)
        for _, side in ipairs({-1, 1}) do
            local claw = {
                {At(frame, 8, side * halfWidth(0.008) * 0.9)},
                {At(frame, -8, side * (halfw + 6))},
                {At(frame, -22, side * (halfw + 3))},
                {At(frame, -32, side * 5)},
            }
            cv:polyline(claw, crown.Deep, 6.5)
            cv:polyline(claw, crown.Mid, 4)
            cv:polyline(claw, WithAlpha(crown.Light, 140), 1.5)
            local tx, ty = At(frame, -32, side * 5)
            cv:circle(tx, ty, 2.6, crown.Dark)
        end
    end,
    orb = function(cv, frame, plan, wood, crown, halfWidth, rng)
        local power = math.min(plan.headPower, 5)
        local orbR = 14 + 2.6 * power
        local cx, cy = At(frame, -26 - orbR * 0.55, 0)
        Bloom(cv, cx, cy, orbR, wood.Glow, power + 1)
        for _, side in ipairs({-1, 1}) do
            local prong = {
                {At(frame, 6, side * halfWidth(0.006) * 0.85)},
                {At(frame, -12, side * (orbR + 9))},
                {At(frame, -30 - orbR * 0.5, side * (orbR + 7))},
                {At(frame, -40 - orbR, side * (orbR * 0.45))},
            }
            cv:polyline(prong, crown.Deep, 7)
            cv:polyline(prong, crown.Mid, 4.5)
            cv:polyline(prong, WithAlpha(crown.Light, 150), 1.5)
            local tx, ty = At(frame, -40 - orbR, side * orbR * 0.45)
            cv:circle(tx, ty, 3, crown.Dark)
            cv:circle(tx - 0.8, ty - 0.8, 1.4, WithAlpha(crown.Light, 160))
        end
        DrawGlassOrb(cv, cx, cy, orbR, wood.Glow)
        for i = 1, 2 do
            local gx, gy = At(frame, -10 - i * 4, (if i % 2 == 0 then 1 else -1) * 3)
            cv:circle(gx, gy, 1.2, WithAlpha(wood.Glow, 200))
        end
    end,
    lantern = function(cv, frame, plan, wood, crown, halfWidth, rng)
        local power = math.min(plan.headPower, 5)
        local cx, cy = At(frame, -42, 0)
        Bloom(cv, cx, cy, 19, wood.Glow, power + 2)
        local mount = {
            {At(frame, 2, -halfWidth(0.002) * 0.85)},
            {At(frame, 2, halfWidth(0.002) * 0.85)},
            {At(frame, -12, 10)},
            {At(frame, -12, -10)},
        }
        cv:strokePolygon(mount, OutlineColor, 2)
        cv:polygon(mount, IronMid)
        cv:circle(cx, cy, 10 + power * 1.4, LerpColor(wood.Glow, White, 0.45))
        cv:circle(cx, cy, (10 + power * 1.4) * 0.5, WithAlpha(White, 220))
        local cage = {
            {At(frame, -14, -13)},
            {At(frame, -42, -19)},
            {At(frame, -70, -13)},
            {At(frame, -70, 13)},
            {At(frame, -42, 19)},
            {At(frame, -14, 13)},
        }
        cv:strokePolygon(cage, IronDeep, 5.5)
        cv:strokePolygon(cage, IronMid, 3)
        for _, lane in ipairs({-7, 7}) do
            local x1, y1 = At(frame, -15, lane)
            local x2, y2 = At(frame, -69, lane)
            cv:line(x1, y1, x2, y2, WithAlpha(IronDeep, 200), 2.4)
        end
        local tx1, ty1 = At(frame, -70, -13)
        local tx2, ty2 = At(frame, -70, 13)
        cv:line(tx1, ty1, tx2, ty2, WithAlpha(IronLight, 150), 2)
        local fx, fy = At(frame, -77, 0)
        cv:circle(fx, fy, 5, IronMid)
        cv:circle(fx, fy, 2.5, IronLight)
        local rx, ry = At(frame, -84, 0)
        cv:strokeCircle(rx, ry, 4.5, IronLight, 2.2)
    end,
    fork = function(cv, frame, plan, wood, crown, halfWidth, rng)
        local power = math.min(plan.headPower, 5)
        local reach = 44 + 5 * power
        local spread = 17 + 2.5 * power
        local prongs = if power >= 3 then {-1, 0, 1} else {-1, 1}
        for _, side in ipairs(prongs) do
            local outS = if side == 0 then -reach - 10 else -reach
            local prong = {
                {At(frame, 8, side * 5)},
                {At(frame, -10, side * spread * 0.5)},
                {At(frame, outS * 0.7, side * spread * 0.85)},
                {At(frame, outS, side * spread)},
            }
            cv:polyline(prong, OutlineColor, 8)
            cv:polyline(prong, crown.Mid, 5.5)
            cv:polyline(prong, WithAlpha(crown.Light, 150), 2)
            local tx, ty = At(frame, outS, side * spread)
            cv:circle(tx, ty, 2.8, crown.Dark)
            cv:circle(tx, ty, 1.6, WithAlpha(White, 150))
        end
    end,
    crescent = function(cv, frame, plan, wood, crown, halfWidth, rng)
        local power = math.min(plan.headPower, 5)
        local cr = 21 + 3 * power
        local cx, cy = At(frame, -16 - cr * 0.75, 0)
        Bloom(cv, cx, cy, cr * 0.8, wood.Glow, power)
        for _, side in ipairs({-1, 1}) do
            local claw = {
                {At(frame, 4, side * halfWidth(0.004) * 0.8)},
                {At(frame, -8, side * 9)},
                {At(frame, -16, side * 6)},
            }
            cv:polyline(claw, crown.Deep, 5.5)
            cv:polyline(claw, crown.Mid, 3.5)
        end
        local inward = math.atan2(frame.uy, frame.ux)
        local tone = LerpColor(wood.Glow, White, 0.2)
        Arc(cv, cx, cy, cr, inward - 2.35, inward + 2.35, OutlineColor, 10)
        Arc(cv, cx, cy, cr, inward - 2.35, inward + 2.35, tone, 7)
        Arc(cv, cx, cy, cr - 3.5, inward - 1.6, inward + 1.6, WithAlpha(LerpColor(tone, White, 0.4), 200), 3)
        for _, side in ipairs({-2.35, 2.35}) do
            local hx = cx + cr * math.cos(inward + side)
            local hy = cy + cr * math.sin(inward + side)
            cv:circle(hx, hy, 3.6, tone)
        end
    end,
    knotgem = function(cv, frame, plan, wood, crown, halfWidth, rng)
        local power = math.min(plan.headPower, 5)
        local kx, ky = At(frame, -20, 0)
        for _ = 1, 6 do
            local ox = (rng() - 0.5) * 16
            local oy = (rng() - 0.5) * 16
            local r = 8 + rng() * 7
            cv:circle(kx + ox, ky + oy, r + 1.5, OutlineColor)
            cv:circle(kx + ox, ky + oy, r, crown.Dark)
            cv:strokeCircle(kx + ox, ky + oy, r * 0.6, WithAlpha(crown.Deep, 180), 1.5)
        end
        cv:circle(kx - 4, ky - 4, 5, WithAlpha(crown.Light, 90))
        local r = 8 + power
        Bloom(cv, kx, ky, r, wood.Glow, power)
        local gem = {
            {kx, ky - r},
            {kx + r * 0.85, ky},
            {kx, ky + r},
            {kx - r * 0.85, ky},
        }
        cv:strokePolygon(gem, OutlineColor, 2.5)
        cv:polygon(gem, LerpColor(wood.Glow, White, 0.3))
        cv:line(kx - r * 0.85, ky, kx + r * 0.85, ky, WithAlpha(White, 150), 1)
        cv:line(kx, ky - r, kx, ky + r, WithAlpha(White, 150), 1)
    end,
    antler = function(cv, frame, plan, wood, crown, halfWidth, rng)
        local power = math.min(plan.headPower, 5)
        local boneTone = LerpColor(crown.Light, BoneColor, 0.55)
        local boneDark = LerpColor(boneTone, OutlineColor, 0.35)
        local reach = 66 + 8 * power
        local mx, my = At(frame, -reach * 0.5, 0)
        Bloom(cv, mx, my, reach * 0.35, wood.Glow, math.max(power - 1, 1))
        for _, side in ipairs({-1, 1}) do
            local beam = {
                {At(frame, 4, side * 3)},
                {At(frame, -16, side * 16)},
                {At(frame, -34, side * reach * 0.42)},
                {At(frame, -reach * 0.78, side * reach * 0.56)},
                {At(frame, -reach, side * reach * 0.5)},
            }
            cv:polyline(beam, OutlineColor, 10)
            cv:polyline(beam, boneTone, 6.5)
            cv:polyline(beam, WithAlpha(boneDark, 140), 2)
            local tines = {
                {{At(frame, -16, side * 16)}, {At(frame, -44, side * 9)}},
                {{At(frame, -34, side * reach * 0.42)}, {At(frame, -reach * 0.86, side * reach * 0.26)}},
                {{At(frame, -reach * 0.62, side * reach * 0.5)}, {At(frame, -reach * 1.02, side * reach * 0.62)}},
            }
            for _, tine in ipairs(tines) do
                cv:line(tine[1][1], tine[1][2], tine[2][1], tine[2][2], OutlineColor, 7)
                cv:line(tine[1][1], tine[1][2], tine[2][1], tine[2][2], boneTone, 4.5)
            end
            for _, tip in ipairs({{-reach, side * reach * 0.5}, {-reach * 0.86, side * reach * 0.26}, {-reach * 1.02, side * reach * 0.62}, {-44, side * 9}}) do
                local txx, tyy = At(frame, tip[1], tip[2])
                Bloom(cv, txx, tyy, 3.5, wood.Glow, 2)
                cv:circle(txx, tyy, 2.2, WithAlpha(wood.Glow, 230))
            end
        end
    end,
    bare = function(cv, frame, plan, wood, crown, halfWidth, rng)
        local w = halfWidth(0)
        local cx, cy = At(frame, 2, 0)
        cv:circle(cx, cy, w * 0.95 + 1.5, OutlineColor)
        cv:circle(cx, cy, w * 0.95, wood.Mid)
        cv:circle(cx - w * 0.3, cy - w * 0.3, w * 0.3, WithAlpha(wood.Light, 130))
    end,
}

local StaffFeet: {[string]: (Canvas, Frame, Resolver.Wood, (t: number) -> number, number) -> ()} = {
    ferrule = function(cv, frame, wood, halfWidth, total)
        local w = halfWidth(0.985) + 1.5
        local cap = {
            {At(frame, total - 26, -w)},
            {At(frame, total - 26, w)},
            {At(frame, total + 3, w * 0.8)},
            {At(frame, total + 3, -w * 0.8)},
        }
        cv:strokePolygon(cap, OutlineColor, 2.5)
        cv:polygon(cap, IronMid)
        local x1, y1 = At(frame, total - 22, -w * 0.85)
        local x2, y2 = At(frame, total, -w * 0.68)
        cv:line(x1, y1, x2, y2, WithAlpha(IronLight, 170), 2)
        local rx, ry = At(frame, total - 13, 0)
        cv:circle(rx, ry, 1.8, IronDeep)
        local bx1, by1 = At(frame, total + 3, -w * 0.8)
        local bx2, by2 = At(frame, total + 3, w * 0.8)
        cv:line(bx1, by1, bx2, by2, WithAlpha(IronDeep, 235), 3)
    end,
    spike = function(cv, frame, wood, halfWidth, total)
        local w = halfWidth(0.99) * 0.8
        local spike = {
            {At(frame, total - 6, -w)},
            {At(frame, total - 6, w)},
            {At(frame, total + 26, 0)},
        }
        cv:strokePolygon(spike, OutlineColor, 2.5)
        cv:polygon(spike, IronMid)
        local x1, y1 = At(frame, total - 4, -w + 1.5)
        local x2, y2 = At(frame, total + 23, 0)
        cv:line(x1, y1, x2, y2, WithAlpha(IronLight, 200), 2)
        local sx1, sy1 = At(frame, total - 6, -w)
        local sx2, sy2 = At(frame, total - 6, w)
        cv:line(sx1, sy1, sx2, sy2, IronDeep, 3)
    end,
    worn = function(cv, frame, wood, halfWidth, total)
        local w = halfWidth(0.995) * 0.9
        local heel = {
            {At(frame, total - 3, -w)},
            {At(frame, total - 3, w)},
            {At(frame, total + 5, w * 0.55)},
            {At(frame, total + 5, -w * 0.55)},
        }
        cv:strokePolygon(heel, OutlineColor, 2)
        cv:polygon(heel, wood.Dark)
        local x1, y1 = At(frame, total + 2, -w * 0.45)
        local x2, y2 = At(frame, total + 2, w * 0.45)
        cv:line(x1, y1, x2, y2, WithAlpha(wood.Light, 100), 1.5)
    end,
}

local function DrawHangings(cv: Canvas, frame: Frame, count: number, rng: () -> number, halfWidth: (t: number) -> number, total: number)
    for i = 1, count do
        local side = if i % 2 == 0 then 1 else -1
        local attachS = 22 + (i - 1) * 5
        local ax, ay = At(frame, attachS, side * (halfWidth(attachS / total) + 1))
        local len = 46 + i * 9 + rng() * 8
        local sway = side * (7 + rng() * 7)
        cv:polyline({{ax, ay}, {ax + sway * 0.55, ay + len * 0.55}, {ax + sway, ay + len}}, WithAlpha(CordColor, 235), 2)
        cv:circle(ax + sway * 0.35, ay + len * 0.35, 2.4, GoldMid)
        cv:circle(ax + sway * 0.75, ay + len * 0.72, 2, WithAlpha(CordLight, 230))
        local ex, ey = ax + sway, ay + len
        local feather = {
            {ex, ey},
            {ex - 3, ey + 7},
            {ex, ey + 18},
            {ex + 3, ey + 7},
        }
        cv:strokePolygon(feather, OutlineColor, 1.5)
        cv:polygon(feather, BoneColor)
        cv:line(ex, ey + 2, ex, ey + 15, WithAlpha({r = 150, g = 142, b = 122}, 200), 1)
    end
end

local function DrawVine(cv: Canvas, frame: Frame, halfWidth: (t: number) -> number, total: number, rng: () -> number)
    local phase = rng() * TwoPi
    local points = {}
    for i = 0, 64 do
        local t = 0.06 + 0.86 * i / 64
        local o = math.sin(t * math.pi * 7 + phase) * halfWidth(t) * 0.82
        table.insert(points, {At(frame, t * total, o)})
    end
    cv:polyline(points, {r = 40, g = 78, b = 36}, 3.4)
    cv:polyline(points, WithAlpha({r = 108, g = 166, b = 78}, 170), 1.5)
    for i = 6, 60, 9 do
        local t = 0.06 + 0.86 * i / 64
        local o = math.sin(t * math.pi * 7 + phase) * halfWidth(t) * 0.82
        local side = if o >= 0 then 1 else -1
        local x, y = At(frame, t * total, o)
        local nx, ny = frame.px * side, frame.py * side
        local sx, sy = x + nx * 6, y + ny * 6
        cv:line(x, y, sx, sy, {r = 56, g = 100, b = 44}, 1.8)
        local lx, ly = sx + nx * 4, sy + ny * 4
        cv:polygon({
            {sx, sy},
            {lx + frame.ux * 3, ly + frame.uy * 3},
            {lx + nx * 4.5, ly + ny * 4.5},
            {lx - frame.ux * 3, ly - frame.uy * 3},
        }, WithAlpha({r = 122, g = 184, b = 82}, 235))
    end
end

local RibbonTones = {
    {r = 176, g = 46, b = 54},
    {r = 226, g = 168, b = 60},
    {r = 62, g = 142, b = 148},
    {r = 128, g = 84, b = 168},
}
local RopeLight = {r = 192, g = 160, b = 110}
local RopeDark = {r = 128, g = 100, b = 62}
local MossTone = {r = 74, g = 116, b = 54}
local MossLight = {r = 108, g = 152, b = 76}
local MushCap = {r = 188, g = 84, b = 62}
local ThreadTone = {r = 222, g = 216, b = 200}
local WaxTone = {r = 232, g = 222, b = 196}

local function DrawBells(cv: Canvas, frame: Frame, count: number, rng: () -> number, halfWidth: (t: number) -> number, total: number)
    for i = 1, count do
        local side = if i % 2 == 0 then 1 else -1
        local attachS = 26 + (i - 1) * 7
        local ax, ay = At(frame, attachS, side * (halfWidth(attachS / total) + 1))
        local len = 13 + i * 4 + rng() * 5
        local sway = side * (4 + rng() * 5)
        local bx, by = ax + sway, ay + len
        cv:line(ax, ay, bx, by, WithAlpha(CordColor, 230), 1.8)
        cv:circle(bx, by, 5.4, WithAlpha(GoldDeep, 235))
        cv:circle(bx, by, 4.2, GoldMid)
        cv:line(bx - 3.4, by + 1.8, bx + 3.4, by + 1.8, WithAlpha(GoldDeep, 220), 1.4)
        cv:circle(bx - 1.3, by - 1.4, 1.2, WithAlpha(GoldLight, 220))
        cv:circle(bx, by + 4.4, 1.3, GoldDeep)
    end
end

local function DrawTeethString(cv: Canvas, frame: Frame, rng: () -> number, halfWidth: (t: number) -> number, total: number)
    local ax, ay = At(frame, 36, -(halfWidth(36 / total) + 1))
    local sway = -(6 + rng() * 5)
    local len = 34 + rng() * 8
    cv:polyline({{ax, ay}, {ax + sway * 0.5, ay + len * 0.5}, {ax + sway, ay + len}}, WithAlpha({r = 150, g = 132, b = 104}, 230), 1.6)
    for k = 1, 4 do
        local tt = k / 5
        local tx = ax + sway * tt
        local ty = ay + len * tt
        local tooth = {
            {tx - 2.2, ty},
            {tx + 2.2, ty},
            {tx + 0.4, ty + 5.5 + rng() * 2},
        }
        cv:strokePolygon(tooth, OutlineColor, 1.2)
        cv:polygon(tooth, BoneColor)
    end
end

local function DrawRibbons(cv: Canvas, frame: Frame, count: number, rng: () -> number, halfWidth: (t: number) -> number, total: number)
    local w = halfWidth(24 / total)
    local k1x, k1y = At(frame, 24, -w - 1)
    local k2x, k2y = At(frame, 24, w + 1)
    cv:line(k1x, k1y, k2x, k2y, WithAlpha(RibbonTones[1], 235), 3.5)
    for i = 1, count do
        local tone = RibbonTones[(i - 1) % #RibbonTones + 1]
        local side = if i % 2 == 0 then 1 else -1
        local ax, ay = At(frame, 26, side * w * 0.7)
        local len = 68 + i * 12 + rng() * 14
        local sway = side * (12 + rng() * 14)
        local phase = rng() * TwoPi
        local points = {}
        for j = 0, 7 do
            local tt = j / 7
            table.insert(points, {
                ax + sway * tt + math.sin(phase + tt * 5.5) * 6 * tt,
                ay + len * tt,
            })
        end
        cv:polyline(points, WithAlpha(tone, 240), 5)
        cv:polyline(points, WithAlpha(LerpColor(tone, White, 0.35), 150), 1.8)
    end
end

local function DrawDreamcatcher(cv: Canvas, frame: Frame, forked: boolean, rng: () -> number, halfWidth: (t: number) -> number, total: number)
    local cx, cy
    local radius
    if forked then
        cx, cy = At(frame, -26, 0)
        radius = 13
    else
        local ax, ay = At(frame, 26, halfWidth(26 / total) + 1)
        cx, cy = ax + 7, ay + 17
        radius = 11
        cv:line(ax, ay, cx, cy - radius, WithAlpha({r = 150, g = 132, b = 104}, 230), 1.6)
        cv:strokeCircle(cx, cy, radius + 1.6, WithAlpha({r = 96, g = 70, b = 44}, 235), 2.5)
    end
    cv:strokeCircle(cx, cy, radius, WithAlpha(ThreadTone, 170), 1.2)
    cv:strokeCircle(cx, cy, radius * 0.55, WithAlpha(ThreadTone, 150), 1.2)
    for k = 0, 7 do
        local ang = TwoPi * k / 8
        cv:line(cx, cy, cx + math.cos(ang) * radius, cy + math.sin(ang) * radius, WithAlpha(ThreadTone, 140), 1)
    end
    local beadAng = rng() * TwoPi
    cv:circle(cx + math.cos(beadAng) * radius * 0.55, cy + math.sin(beadAng) * radius * 0.55, 1.7, WithAlpha(CordLight, 230))
    if not forked then
        for _, o in ipairs({-4, 4}) do
            local fx = cx + o
            local fy = cy + radius + 2
            cv:polygon({
                {fx, fy},
                {fx - 2, fy + 5},
                {fx, fy + 12},
                {fx + 2, fy + 5},
            }, WithAlpha(BoneColor, 235))
        end
    end
end

local function DrawGemClusters(cv: Canvas, frame: Frame, count: number, rng: () -> number, halfWidth: (t: number) -> number, glow: Resolver.Rgb, total: number)
    local fill = LerpColor(glow, White, 0.4)
    for i = 1, count do
        local t = 0.16 + 0.32 * rng()
        local side = if i % 2 == 0 then 1 else -1
        local s = t * total
        local w = halfWidth(t)
        local bx, by = At(frame, s, side * (w - 1))
        local nx, ny = frame.px * side, frame.py * side
        Bloom(cv, bx + nx * 7, by + ny * 7, 6, glow, 2)
        for k = -1, 1 do
            local ang = k * 0.55
            local cosA, sinA = math.cos(ang), math.sin(ang)
            local dx = nx * cosA - ny * sinA
            local dy = nx * sinA + ny * cosA
            local len = (if k == 0 then 13 else 9) + rng() * 4
            local b1x, b1y = At(frame, s + k * 4 - 3.5, side * (w - 1.5))
            local b2x, b2y = At(frame, s + k * 4 + 3.5, side * (w - 1.5))
            local gem = {
                {b1x, b1y},
                {b2x, b2y},
                {bx + dx * len + k * 3, by + dy * len},
            }
            cv:strokePolygon(gem, OutlineColor, 1.6)
            cv:polygon(gem, fill)
            cv:line((b1x + b2x) / 2, (b1y + b2y) / 2, bx + dx * len + k * 3, by + dy * len, WithAlpha(White, 150), 1.2)
        end
    end
end

local function DrawMoss(cv: Canvas, frame: Frame, patches: number, rng: () -> number, halfWidth: (t: number) -> number, total: number)
    for i = 1, patches do
        local t = 0.2 + 0.65 * rng()
        local side = if rng() < 0.5 then -1 else 1
        local s = t * total
        local w = halfWidth(t)
        for _ = 1, 6 do
            local along = (rng() - 0.5) * 16
            local out = rng() * 3.5
            local mx, my = At(frame, s + along, side * (w - 2 + out))
            cv:circle(mx, my, 2.5 + rng() * 3, WithAlpha(MossTone, 210 + rng() * 45))
        end
        for _ = 1, 3 do
            local mx, my = At(frame, s + (rng() - 0.5) * 12, side * (w - 1.5))
            cv:circle(mx, my, 1.6, WithAlpha(MossLight, 200))
        end
        if i <= 2 then
            local nx, ny = frame.px * side, frame.py * side
            local sx, sy = At(frame, s + 9, side * (w - 1))
            cv:line(sx, sy, sx + nx * 6, sy + ny * 6, WithAlpha(BoneColor, 230), 2)
            cv:circle(sx + nx * 7, sy + ny * 7, 3.6, MushCap)
            cv:circle(sx + nx * 7 - 1.2, sy + ny * 7 - 1.2, 1.1, WithAlpha(White, 200))
        end
    end
end

local function DrawWisps(cv: Canvas, frame: Frame, count: number, rng: () -> number, halfWidth: (t: number) -> number, glow: Resolver.Rgb, total: number)
    local tone = LerpColor(glow, White, 0.6)
    for _ = 1, count do
        local t = 0.08 + 0.75 * rng()
        local side = if rng() < 0.5 then -1 else 1
        local o = side * (halfWidth(t) + 10 + rng() * 26)
        local x, y = At(frame, t * total, o)
        cv:circle(x, y, 6.5, WithAlpha(tone, 28))
        cv:circle(x, y, 4, WithAlpha(tone, 55))
        cv:circle(x, y, 2.2, WithAlpha(tone, 195))
        local trail = {}
        local ang = rng() * TwoPi
        for j = 1, 4 do
            table.insert(trail, {x + math.cos(ang + j * 0.5) * j * 3.2, y + math.sin(ang + j * 0.5) * j * 3.2})
        end
        cv:polyline(trail, WithAlpha(tone, 60), 1.2)
    end
end

local function DrawSerpentCarving(cv: Canvas, frame: Frame, rng: () -> number, halfWidth: (t: number) -> number, wood: Resolver.Wood, total: number)
    local darkWood = Luminance(wood.Mid) < 96
    local bodyTone = if darkWood then LerpColor(wood.Light, wood.Mid, 0.25) else wood.Deep
    local innerTone = if darkWood then LerpColor(wood.Light, White, 0.25) else wood.Dark
    local tickTone = if darkWood then wood.Deep else wood.Light
    local phase = rng() * TwoPi
    local points = {}
    for i = 0, 56 do
        local t = 0.16 + 0.7 * i / 56
        local o = math.sin(t * math.pi * 4.2 + phase) * halfWidth(t) * 0.72
        table.insert(points, {At(frame, t * total, o)})
    end
    cv:polyline(points, WithAlpha(bodyTone, 235), 5)
    cv:polyline(points, WithAlpha(innerTone, 235), 2.8)
    for i = 4, 52, 4 do
        local t = 0.16 + 0.7 * i / 56
        local o = math.sin(t * math.pi * 4.2 + phase) * halfWidth(t) * 0.72
        local x, y = At(frame, t * total, o)
        cv:line(x - 1.4, y - 1.4, x + 1.4, y + 1.4, WithAlpha(tickTone, 110), 1)
    end
    local headO = math.sin(0.16 * math.pi * 4.2 + phase) * halfWidth(0.16) * 0.72
    local hx, hy = At(frame, 0.16 * total, headO)
    cv:circle(hx, hy, 4.2, WithAlpha(bodyTone, 245))
    cv:circle(hx, hy, 2.6, WithAlpha(innerTone, 245))
    cv:circle(hx + 1, hy - 1, 0.9, WithAlpha(wood.Glow, 230))
    cv:line(hx - frame.ux * 4, hy - frame.uy * 4, hx - frame.ux * 8 - 1.5, hy - frame.uy * 8, WithAlpha(CordLight, 220), 1)
    cv:line(hx - frame.ux * 4, hy - frame.uy * 4, hx - frame.ux * 8 + 1.5, hy - frame.uy * 8, WithAlpha(CordLight, 220), 1)
end

local function DrawKeyRing(cv: Canvas, frame: Frame, rng: () -> number, halfWidth: (t: number) -> number, total: number)
    local s = total * 0.62
    local w = halfWidth(s / total)
    local ax, ay = At(frame, s, w + 0.5)
    local cx, cy = ax + frame.px * 6, ay + frame.py * 6
    cv:strokeCircle(cx, cy, 5.5, IronDeep, 3.2)
    cv:strokeCircle(cx, cy, 5.5, IronMid, 1.8)
    for k = -1, 1 do
        local ang = math.pi / 2 + k * 0.4 + (rng() - 0.5) * 0.15
        local kx, ky = cx + math.cos(ang) * 5, cy + math.sin(ang) * 5
        local ex, ey = kx + math.cos(ang) * (10 + rng() * 4), ky + math.sin(ang) * (10 + rng() * 4)
        cv:line(kx, ky, ex, ey, IronDeep, 3.4)
        cv:line(kx, ky, ex, ey, IronMid, 1.8)
        cv:strokeCircle(kx, ky, 2.2, IronLight, 1.4)
        cv:line(ex, ey, ex + math.sin(ang) * 3, ey - math.cos(ang) * 3, IronLight, 1.6)
        cv:line(ex - math.cos(ang) * 3, ey - math.sin(ang) * 3, ex - math.cos(ang) * 3 + math.sin(ang) * 2.2, ey - math.sin(ang) * 3 - math.cos(ang) * 2.2, IronLight, 1.4)
    end
end

local function DrawRopeGrip(cv: Canvas, frame: Frame, halfWidth: (t: number) -> number, total: number, rng: () -> number)
    local fromS = total * 0.7
    local toS = total * 0.79
    local s = fromS
    local flip = false
    while s < toS do
        local t = s / total
        local w = halfWidth(t) * 0.98
        local x1, y1 = At(frame, s, -w)
        local x2, y2 = At(frame, s + 2.5, w)
        cv:line(x1, y1, x2, y2, if flip then RopeDark else RopeLight, 3.2)
        flip = not flip
        s += 4.5
    end
    for _, edge in ipairs({fromS - 2, toS + 2}) do
        local t = edge / total
        local w = halfWidth(t)
        for _, side in ipairs({-0.5, 0.5}) do
            local kx, ky = At(frame, edge, side * w)
            cv:circle(kx, ky, 3.2, RopeDark)
            cv:circle(kx - 0.8, ky - 0.8, 1.2, WithAlpha(RopeLight, 200))
        end
    end
    local fx, fy = At(frame, toS + 4, halfWidth((toS + 4) / total) * 0.6)
    cv:line(fx, fy, fx + 3 + rng() * 2, fy + 7, WithAlpha(RopeLight, 200), 1.5)
    cv:line(fx, fy, fx - 1, fy + 8, WithAlpha(RopeDark, 200), 1.5)
end

local function DrawWax(cv: Canvas, frame: Frame, rng: () -> number, halfWidth: (t: number) -> number, total: number)
    local w0 = halfWidth(0.004)
    local rx1, ry1 = At(frame, 4, -w0 * 0.9)
    local rx2, ry2 = At(frame, 4, w0 * 0.9)
    cv:line(rx1, ry1, rx2, ry2, WithAlpha(WaxTone, 225), 3.5)
    for i = 1, 3 do
        local lane = (i - 2) * 0.55 + (rng() - 0.5) * 0.25
        local len = 26 + rng() * 42
        local points = {}
        for j = 0, 6 do
            local s = 4 + len * j / 6
            local t = s / total
            table.insert(points, {At(frame, s, lane * halfWidth(t) * 0.8 + math.sin(j * 1.7) * 0.8)})
        end
        cv:polyline(points, WithAlpha(WaxTone, 210), 2.4 + rng() * 1.2)
        local ex, ey = At(frame, 4 + len, lane * halfWidth((4 + len) / total) * 0.8)
        cv:circle(ex, ey, 2.2, WithAlpha(WaxTone, 225))
        cv:circle(ex, ey + 4, 1.2, WithAlpha(WaxTone, 190))
    end
end

function module.RenderStaff(plan: Resolver.StaffPlan): Canvas
    local wood = Resolver.Woods[plan.wood]
    local crown = if plan.handleWood then Resolver.Woods[plan.handleWood :: string] else wood
    local rng = NewRng(plan.seed)

    local total = 690 + plan.spans * 20
    local ux, uy = 0.14, 0.9902
    local px, py = uy, -ux
    local midX = 380
    local tipY = 96
    local tipX = midX - ux * total / 2

    local frame: Frame = {
        tipX = tipX,
        tipY = tipY,
        ux = ux,
        uy = uy,
        px = px,
        py = py,
        total = total,
        warp = function()
            return 0
        end,
    }
    frame.warp = BuildWarp(plan, rng, total, 0.75)

    local knots: {Knot} = {}
    for i = 1, plan.knots do
        table.insert(knots, {
            t = 0.14 + 0.68 * (i - 0.5) / math.max(plan.knots, 1) + (rng() - 0.5) * 0.05,
            bump = 5 + rng() * 3,
            off = (rng() - 0.5) * 4,
        })
    end

    local buttW = 13 + plan.spans * 0.35
    local topW = buttW * (if plan.taper > 0 then 0.55 else 0.8)

    local function HalfWidth(t: number): number
        local w = topW + (buttW - topW) * math.clamp(t, 0, 1) ^ 1.05
        for _, knot in ipairs(knots) do
            local d = (t - knot.t) / 0.04
            w += knot.bump * math.exp(-d * d)
        end
        return w
    end

    local base = canvas.new(Width, Height, WithAlpha(VelvetBase, 255))
    DrawVelvet(base, rng, midX, tipY + total * uy / 2)

    local samples = 90
    local silhouette = {}
    local right = {}
    for i = 0, samples do
        local t = i / samples
        local s = t * total
        local w = HalfWidth(t)
        table.insert(silhouette, {At(frame, s, -w)})
        table.insert(right, {At(frame, s, w)})
    end
    for i = #right, 1, -1 do
        table.insert(silhouette, right[i])
    end

    local shadow = {}
    for _, point in ipairs(silhouette) do
        table.insert(shadow, {point[1] + 13, point[2] + 15})
    end
    base:polygon(shadow, {r = 0, g = 0, b = 0, a = 85})

    base:strokePolygon(silhouette, OutlineColor, 3.5)
    base:polygon(silhouette, wood.Mid)

    local shade = {}
    for i = 1, #right do
        table.insert(shade, right[i])
    end
    for i = samples + 1, 1, -1 do
        local t = (i - 1) / samples
        table.insert(shade, {At(frame, t * total, HalfWidth(t) * 0.2)})
    end
    base:polygon(shade, WithAlpha(wood.Dark, 150))

    local highlight = {}
    for i = 0, samples do
        local t = i / samples
        table.insert(highlight, {At(frame, t * total, -HalfWidth(t) * 0.55)})
    end
    base:polyline(highlight, WithAlpha(wood.Light, 95), 3)

    for laneIndex, lane in ipairs({-0.6, -0.2, 0.25, 0.62}) do
        local points = {}
        for i = 0, 44 do
            local t = 0.03 + 0.93 * i / 44
            local wobbleO = math.sin(t * 15 + laneIndex * 2.1) * 0.7
            table.insert(points, {At(frame, t * total, lane * HalfWidth(t) * 0.8 + wobbleO)})
        end
        local tone = if laneIndex % 2 == 0 then WithAlpha(wood.Light, 55) else WithAlpha(wood.Deep, 110)
        base:polyline(points, tone, 1.8)
    end

    local detail = WoodDetail[plan.wood]
    if detail then
        detail(base, frame, plan :: any, wood, rng, HalfWidth, 0.94)
    end

    if plan.spiral > 0 then
        local pitch = 24 - plan.spiral * 1.5
        local s = total * 0.05
        while s < total * 0.95 do
            local t = s / total
            local w = HalfWidth(t) * 0.92
            local x1, y1 = At(frame, s, -w)
            local x2, y2 = At(frame, s + pitch * 0.55, w)
            base:line(x1, y1, x2, y2, WithAlpha(wood.Deep, 180), 2.8)
            base:line(x1 + 1.5, y1 + 1.5, x2 + 1.5, y2 + 1.5, WithAlpha(wood.Light, 65), 1.5)
            s += pitch
        end
    end

    if plan.groove > 0 then
        local glowPts = {}
        for i = 0, 38 do
            local t = 0.05 + 0.85 * i / 38
            table.insert(glowPts, {At(frame, t * total, 0)})
        end
        base:polyline(glowPts, WithAlpha(wood.Glow, 46), 6)
        base:polyline(glowPts, WithAlpha(wood.Deep, 220), 2.4)
        base:polyline(glowPts, WithAlpha(wood.Glow, 70), 1)
    end

    for _, knot in ipairs(knots) do
        local x, y = At(frame, knot.t * total, knot.off)
        base:circle(x, y, knot.bump * 1.05, WithAlpha(wood.Deep, 235))
        base:strokeCircle(x, y, knot.bump * 1.6, WithAlpha(wood.Dark, 160), 1.5)
        base:strokeCircle(x, y, knot.bump * 2.3, WithAlpha(wood.Deep, 80), 1.5)
        base:circle(x - knot.bump * 0.4, y - knot.bump * 0.4, knot.bump * 0.3, WithAlpha(wood.Light, 110))
    end

    if plan.collars > 0 then
        for i = 1, plan.collars do
            local ct = 0.2 + 0.6 * (i - 0.5) / plan.collars
            local s = ct * total
            local w = HalfWidth(ct) + 1.8
            local ring = {
                {At(frame, s - 6, -w)},
                {At(frame, s - 6, w)},
                {At(frame, s + 6, w)},
                {At(frame, s + 6, -w)},
            }
            base:strokePolygon(ring, WithAlpha(IronDeep, 235), 2)
            base:polygon(ring, IronMid)
            local x1, y1 = At(frame, s - 3, -w * 0.82)
            local x2, y2 = At(frame, s - 3, w * 0.82)
            base:line(x1, y1, x2, y2, WithAlpha(IronLight, 200), 1.5)
        end
    end

    if plan.bands > 0 then
        for i = 1, plan.bands do
            local bt = if plan.bands == 1 then 0.32 else 0.14 + 0.62 * (i - 1) / (plan.bands - 1)
            local s = bt * total
            local w = HalfWidth(bt) + 1.2
            local band = {
                {At(frame, s - 5, -w)},
                {At(frame, s - 5, w)},
                {At(frame, s + 5, w)},
                {At(frame, s + 5, -w)},
            }
            base:strokePolygon(band, WithAlpha(GoldDeep, 235), 1.5)
            base:polygon(band, GoldMid)
            local x1, y1 = At(frame, s - 2, -w * 0.8)
            local x2, y2 = At(frame, s - 2, w * 0.8)
            base:line(x1, y1, x2, y2, WithAlpha(GoldLight, 210), 1.5)
        end
    end

    if plan.vine then
        DrawVine(base, frame, HalfWidth, total, rng)
    end

    if plan.serpent then
        DrawSerpentCarving(base, frame, rng, HalfWidth, wood, total)
    end
    if plan.gems > 0 then
        DrawGemClusters(base, frame, plan.gems, rng, HalfWidth, wood.Glow, total)
    end
    if plan.moss > 0 then
        DrawMoss(base, frame, plan.moss, rng, HalfWidth, total)
    end

    local darkWood = Luminance(wood.Mid) < 96
    local inkTone = if darkWood then WithAlpha(LerpColor(wood.Glow, White, 0.2), 215) else WithAlpha(BurnColor, 235)
    local underTone = if darkWood then WithAlpha(OutlineColor, 150) else WithAlpha({r = 235, g = 235, b = 245}, 70)

    if plan.inscription and WandFont then
        local text = plan.inscription :: string
        local font = WandFont :: CanvasFont
        local count = #text
        for i = 1, count do
            local char = string.sub(text, i, i)
            local t = 0.2 + 0.42 * (i - 0.5) / count
            local o = math.sin(i * 0.85) * HalfWidth(t) * 0.5
            local x, y = At(frame, t * total, o)
            local cw, ch = font:measure(char, 15)
            base:text(char, x - cw / 2 + 1, y - ch / 2 + 1, 15, underTone, font)
            base:text(char, x - cw / 2, y - ch / 2, 15, inkTone, font)
        end
    end

    if plan.mark and WandFont then
        local text = plan.mark :: string
        local font = WandFont :: CanvasFont
        for i = 1, #text do
            local char = string.sub(text, i, i)
            local s = total * 0.71 - (#text - i) * 11
            local x, y = At(frame, s, 0)
            local cw, ch = font:measure(char, 12)
            base:text(char, x - cw / 2 + 1, y - ch / 2 + 1, 12, underTone, font)
            base:text(char, x - cw / 2, y - ch / 2, 12, inkTone, font)
        end
    end

    if plan.wrap > 0 then
        local gripFrom = total * 0.52
        local gripTo = total * 0.66
        for _, edge in ipairs({gripFrom - 2, gripTo + 2}) do
            local t = edge / total
            local w = HalfWidth(t) + 0.5
            local x1, y1 = At(frame, edge, -w)
            local x2, y2 = At(frame, edge, w)
            base:line(x1, y1, x2, y2, WithAlpha(LeatherColor, 240), 3.5)
        end
        local s = gripFrom
        while s < gripTo do
            local t = s / total
            local w = HalfWidth(t) * 0.97
            local x1, y1 = At(frame, s, -w)
            local x2, y2 = At(frame, s + 6, w)
            base:line(x1, y1, x2, y2, WithAlpha(LeatherColor, 225), 3.4)
            local x3, y3 = At(frame, s + 6, -w)
            local x4, y4 = At(frame, s, w)
            base:line(x3, y3, x4, y4, WithAlpha(LeatherColor, 190), 2.5)
            s += 11
        end
    end

    if plan.knuckles > 0 then
        for i = 1, 4 do
            local s = total * (0.52 + 0.14 * (i - 0.5) / 4)
            local t = s / total
            local x, y = At(frame, s, HalfWidth(t) - 0.5)
            base:circle(x, y, 4.5, wood.Dark)
            base:circle(x - 1, y - 1, 3, WithAlpha(wood.Light, 120))
        end
    end

    if plan.rope then
        DrawRopeGrip(base, frame, HalfWidth, total, rng)
    end
    if plan.keys then
        DrawKeyRing(base, frame, rng, HalfWidth, total)
    end

    if plan.skull > 0 then
        local x, y = At(frame, 38, 0)
        DrawSkull(base, x, y, 7)
    end

    local foot = StaffFeet[plan.foot]
    if foot then
        foot(base, frame, wood, HalfWidth, total)
    end

    local head = StaffHeads[plan.head]
    if head then
        head(base, frame, plan, wood, crown, HalfWidth, rng)
    end

    if plan.waxed then
        DrawWax(base, frame, rng, HalfWidth, total)
    end

    if plan.hangings > 0 then
        DrawHangings(base, frame, plan.hangings, rng, HalfWidth, total)
    end

    if plan.bells > 0 then
        DrawBells(base, frame, plan.bells, rng, HalfWidth, total)
    end
    if plan.teeth then
        DrawTeethString(base, frame, rng, HalfWidth, total)
    end
    if plan.ribbons > 0 then
        DrawRibbons(base, frame, plan.ribbons, rng, HalfWidth, total)
    end
    if plan.dreamcatcher then
        DrawDreamcatcher(base, frame, plan.head == "fork", rng, HalfWidth, total)
    end

    if plan.charms > 0 then
        local charmHue = if plan.charmWood then Resolver.Woods[plan.charmWood :: string].Glow else wood.Glow
        local hx, hy = At(frame, -30, 0)
        for i = 1, plan.charms do
            local ang = rng() * TwoPi
            local orbitR = 34 + i * 14
            base:strokeCircle(hx, hy, orbitR, WithAlpha(charmHue, 32), 1.5)
            local mx = hx + math.cos(ang) * orbitR
            local my = hy + math.sin(ang) * orbitR
            Bloom(base, mx, my, 4.5, charmHue, 2)
            base:circle(mx, my, 2.8, LerpColor(charmHue, White, 0.55))
            for trail = 1, 2 do
                local ta = ang - trail * 0.28
                base:circle(hx + math.cos(ta) * orbitR, hy + math.sin(ta) * orbitR, 2 - trail * 0.6, WithAlpha(charmHue, 130 - trail * 55))
            end
        end
    end

    if plan.wisps > 0 then
        DrawWisps(base, frame, plan.wisps, rng, HalfWidth, wood.Glow, total)
    end

    if plan.wild then
        local count = 11 + math.floor(rng() * 5)
        for _ = 1, count do
            local t = 0.04 + 0.88 * rng()
            local o = (rng() - 0.5) * 2 * (HalfWidth(t) + 20)
            local sx, sy = At(frame, t * total, o)
            local len = 5 + rng() * 5
            local ang = rng() * math.pi
            local dx, dy = math.cos(ang) * len, math.sin(ang) * len
            base:circle(sx, sy, 6, WithAlpha(SparkColor, 40))
            base:circle(sx, sy, 3.2, WithAlpha(SparkColor, 80))
            base:line(sx - dx, sy - dy, sx + dx, sy + dy, WithAlpha(SparkColor, 245), 1.8)
            base:line(sx + dy * 0.55, sy - dx * 0.55, sx - dy * 0.55, sy + dx * 0.55, WithAlpha(White, 220), 1.4)
            base:circle(sx, sy, 1.6, WithAlpha(White, 235))
        end
        for _ = 1, 3 do
            local o = (rng() - 0.5) * 56
            local sx, sy = At(frame, -12 - rng() * 26, o)
            local len = 4 + rng() * 4
            local ang = rng() * math.pi
            local dx, dy = math.cos(ang) * len, math.sin(ang) * len
            base:circle(sx, sy, 5, WithAlpha(SparkColor, 50))
            base:line(sx - dx, sy - dy, sx + dx, sy + dy, WithAlpha(White, 235), 1.6)
            base:line(sx + dy * 0.55, sy - dx * 0.55, sx - dy * 0.55, sy + dx * 0.55, WithAlpha(SparkColor, 235), 1.4)
        end
    end

    return base:vignette(0.32)
end

function module.Encode(image: Canvas): string
    return image:encode("png")
end

return module
