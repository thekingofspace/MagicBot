--#include[canvas]
local Larder = require("@src/feast/Larder")

local module = {}

local W, H = 1200, 900
local TableY = 350
local PX, PY, PRX, PRY = 600, 480, 290, 90
local EX, EY = 585, 430
local BoatX, BoatY = 415, 568
local SideX, SideY, SideRX, SideRY = 265, 690, 150, 47
local BoardX, BoardY, BoardRX, BoardRY = 930, 700, 175, 52
local CandleX, CandleY = 150, 400
local GobletX, GobletY = 1020, 415
local CardX, CardY = 600, 810

local White = {r = 255, g = 255, b = 255}
local Black = {r = 0, g = 0, b = 0}
local CeramicLight = {r = 226, g = 212, b = 194}
local CeramicDark = {r = 118, g = 102, b = 86}
local InnerWall = {r = 146, g = 130, b = 114}
local GlazeBand = {r = 62, g = 80, b = 138}
local Wood = {r = 46, g = 32, b = 24}
local BoardWood = {r = 94, g = 60, b = 34}
local BoardWoodDark = {r = 60, g = 38, b = 22}
local Wheat = {r = 224, g = 196, b = 138}
local WheatLight = {r = 240, g = 218, b = 170}
local JusColor = {r = 74, g = 40, b = 20}
local HerbGreen = {r = 96, g = 136, b = 58}
local HerbDark = {r = 58, g = 88, b = 36}
local BoneColor = {r = 232, g = 222, b = 200}
local Rancid = {r = 112, g = 118, b = 76}

local FontCandidates = {
    "C:/Windows/Fonts/Inkfree.ttf",
    "C:/Windows/Fonts/segoepr.ttf",
    "C:/Windows/Fonts/comic.ttf",
    "C:/Windows/Fonts/georgia.ttf",
    "C:/Windows/Fonts/arial.ttf",
}

local CardFont: CanvasFont? = nil
for _, path in ipairs(FontCandidates) do
    if not CardFont then
        local ok, font = pcall(function()
            return canvas.font(path)
        end)
        if ok and font then
            CardFont = font
        end
    end
end

local function WithAlpha(color, alpha: number)
    return {r = color.r, g = color.g, b = color.b, a = math.floor(alpha)}
end

local function BlendRGB(a, b, t: number)
    return {
        r = math.floor(a.r + (b.r - a.r) * t),
        g = math.floor(a.g + (b.g - a.g) * t),
        b = math.floor(a.b + (b.b - a.b) * t),
    }
end

local function Brighten(color, t: number)
    return BlendRGB(color, White, t)
end

local function Darken(color, t: number)
    return BlendRGB(color, Black, t)
end

local function HashString(text: string): number
    local hash = 5381
    for i = 1, #text do
        hash = (hash * 33 + string.byte(text, i)) % 4294967296
    end
    return hash
end

local function NewRoll(seed: number): () -> number
    local state = seed % 2147483647
    if state <= 0 then
        state += 2147483646
    end
    return function()
        state = (state * 48271) % 2147483647
        return (state - 1) / 2147483646
    end
end

local function EllipseArc(cx: number, cy: number, rx: number, ry: number, a0: number, a1: number, steps: number)
    local points = {}
    for i = 0, steps do
        local t = a0 + (a1 - a0) * i / steps
        table.insert(points, {cx + rx * math.cos(t), cy + ry * math.sin(t)})
    end
    return points
end

local function RotEllipse(cv: Canvas, cx: number, cy: number, rx: number, ry: number, ang: number, color, steps: number?)
    local n = steps or 36
    local points = {}
    local cosA, sinA = math.cos(ang), math.sin(ang)
    for i = 0, n - 1 do
        local t = i / n * math.pi * 2
        local px = rx * math.cos(t)
        local py = ry * math.sin(t)
        table.insert(points, {cx + px * cosA - py * sinA, cy + px * sinA + py * cosA})
    end
    cv:polygon(points, color)
end

local function ContactShadow(cv: Canvas, cx: number, cy: number, rx: number, ry: number)
    cv:ellipse(cx + 10, cy + 14, rx, ry, WithAlpha(Black, 80))
    cv:ellipse(cx + 8, cy + 12, rx * 0.82, ry * 0.75, WithAlpha(Black, 110))
    cv:ellipse(cx + 6, cy + 10, rx * 0.6, ry * 0.5, WithAlpha(Black, 130))
end

local function BuildMound(x: number, y: number, w: number, h: number, Roll: () -> number)
    local top = {}
    local bottom = {}
    local steps = 16
    for i = 0, steps do
        local u = i / steps * 2 - 1
        local lift = math.sqrt(math.max(0, 1 - u * u))
        local jitter = 0.92 + Roll() * 0.14
        table.insert(top, {x + u * w / 2, y - h * math.pow(lift, 0.78) * jitter})
        table.insert(bottom, 1, {x + u * w / 2, y + h * 0.34 * math.pow(lift, 0.55)})
    end
    local polygon = {}
    for _, p in ipairs(top) do
        table.insert(polygon, p)
    end
    for _, p in ipairs(bottom) do
        table.insert(polygon, p)
    end
    return polygon, top
end

local function TopStrip(top, offset: number)
    local strip = {}
    for _, p in ipairs(top) do
        table.insert(strip, {p[1], p[2] + offset})
    end
    return strip
end

local function SubStrip(points, a: number, b: number)
    local n = #points
    local strip = {}
    for i = math.max(1, math.floor(n * a)), math.min(n, math.ceil(n * b)) do
        table.insert(strip, points[i])
    end
    return strip
end

local function Sprig(cv: Canvas, x: number, y: number, s: number, Roll: () -> number)
    local ang = -0.6 - Roll() * 1.6
    local len = 26 * s
    local ex = x + math.cos(ang) * len
    local ey = y + math.sin(ang) * len * 0.55
    cv:line(x, y, ex, ey, WithAlpha(HerbDark, 235), 2.4 * s)
    for i = 1, 5 do
        local t = i / 5
        local px = x + (ex - x) * t
        local py = y + (ey - y) * t
        local side = if i % 2 == 0 then 1 else -1
        cv:line(px, py, px + side * 7 * s, py - 6 * s, WithAlpha(HerbGreen, 225), 2 * s)
    end
end

local function FlyAt(cv: Canvas, fx: number, fy: number, Roll: () -> number)
    local trail = EllipseArc(fx + 8, fy + 5, 13 + Roll() * 7, 7 + Roll() * 4, Roll() * math.pi * 2, Roll() * math.pi * 2 + 2.8, 14)
    cv:polyline(trail, WithAlpha({r = 190, g = 190, b = 178}, 48), 1.6)
    cv:ellipse(fx - 5, fy - 5, 5.5, 2.6, {r = 215, g = 224, b = 232, a = 170})
    cv:ellipse(fx + 5, fy - 5, 5.5, 2.6, {r = 215, g = 224, b = 232, a = 170})
    cv:circle(fx, fy, 4, {r = 22, g = 20, b = 16, a = 255})
    cv:circle(fx + 2, fy - 1, 1.4, {r = 90, g = 96, b = 88, a = 220})
end

local function SteamFrom(cv: Canvas, sx: number, sy: number, span: number, color, Roll: () -> number)
    local drift = (Roll() * 2 - 1) * 30
    local amp = 8 + Roll() * 14
    local phase = Roll() * math.pi * 2
    local points = {}
    for i = 0, 22 do
        local t = i / 22
        table.insert(points, {sx + drift * t + math.sin(phase + t * math.pi * 2.4) * amp * t, sy - 8 - t * span})
    end
    cv:polyline(SubStrip(points, 0, 0.6), WithAlpha(color, 66), 4 + Roll() * 2)
    cv:polyline(SubStrip(points, 0.45, 1), WithAlpha(color, 36), 5 + Roll() * 3)
end

local function BeadsOn(cv: Canvas, cx: number, cy: number, rx: number, ry: number, count: number, Roll: () -> number)
    for _ = 1, count do
        local a = Roll() * math.pi * 2
        local px = cx + math.cos(a) * rx * (0.55 + Roll() * 0.4)
        local py = cy + math.sin(a) * ry * (0.55 + Roll() * 0.4)
        local dr = 2 + Roll() * 2.2
        cv:ellipse(px, py, dr, dr * 1.3, {r = 204, g = 228, b = 244, a = 130})
        cv:circle(px - dr * 0.3, py - dr * 0.4, 1.1, {r = 252, g = 254, b = 255, a = 200})
    end
end

local function TurnedOverlay(cv: Canvas, steam: Canvas, cx: number, cy: number, rx: number, ry: number, Roll: () -> number)
    cv:ellipse(cx, cy, rx, ry, WithAlpha(Rancid, 110))
    for _ = 1, 6 do
        local px = cx + (Roll() * 2 - 1) * rx * 0.7
        local py = cy + (Roll() * 2 - 1) * ry * 0.6
        cv:ellipse(px, py, 10 + Roll() * 14, 4 + Roll() * 4, WithAlpha(Darken(Rancid, 0.25), 150))
        cv:ellipse(px + 3, py - 2, 6 + Roll() * 6, 2 + Roll() * 2, WithAlpha(Brighten(Rancid, 0.3), 90))
    end
    for _ = 1, 3 do
        local sx = cx + (Roll() * 2 - 1) * rx * 0.5
        SteamFrom(steam, sx, cy - ry * 0.4, 90 + Roll() * 60, {r = 150, g = 170, b = 90}, Roll)
    end
    for _ = 1, 3 do
        FlyAt(steam, cx + (Roll() * 2 - 1) * rx * 0.6, cy - ry - 30 - Roll() * 50, Roll)
    end
end

local function TrussStrings(cv: Canvas, x: number, y: number, w: number, h: number, count: number)
    for i = 1, count do
        local u = -0.62 + (i - 1) / math.max(count - 1, 1) * 1.1
        local sx = x + u * w / 2
        local lift = math.sqrt(math.max(0.05, 1 - u * u))
        local topY = y - h * math.pow(lift, 0.78) + 3
        local points = {}
        for j = 0, 9 do
            local t = j / 9
            local px = sx - 5 * math.sin(t * math.pi)
            local py = topY + t * (y + h * 0.3 - topY)
            table.insert(points, {px, py})
        end
        cv:polyline(points, {r = 210, g = 190, b = 150, a = 190}, 2.2)
        cv:polyline(points, {r = 40, g = 24, b = 14, a = 110}, 1)
    end
end

local function CutFace(cv: Canvas, fx: number, fy: number, frx: number, fry: number, interior, crust)
    RotEllipse(cv, fx, fy, frx, fry, 0.12, Darken(crust, 0.2))
    RotEllipse(cv, fx, fy, frx * 0.92, fry * 0.92, 0.12, interior)
    RotEllipse(cv, fx, fy, frx * 0.6, fry * 0.6, 0.12, Darken(interior, 0.16))
    RotEllipse(cv, fx, fy, frx * 0.3, fry * 0.32, 0.12, Brighten(interior, 0.08))
end

local function FannedSlices(cv: Canvas, count: number, interior, crust, tilt: number)
    local sx, sy = 700, 474
    for i = count, 1, -1 do
        local px = sx + (i - 1) * 32
        local py = sy + (i - 1) * 8
        local ang = 0.14 + tilt + (i - 1) * 0.04
        cv:ellipse(px + 5, py + 8, 34, 10, WithAlpha(Black, 100))
        RotEllipse(cv, px, py, 33, 15, ang, Darken(crust, 0.12))
        RotEllipse(cv, px, py - 3, 31, 13, ang, interior)
        RotEllipse(cv, px, py - 3, 19, 7.5, ang, Darken(interior, 0.14))
        RotEllipse(cv, px - 6, py - 5, 8, 3, ang, WithAlpha(Brighten(interior, 0.25), 160))
    end
end

local function GlazeDrips(cv: Canvas, ember: Canvas, top, glaze, depth: number, faceX: number, faceY: number, isEmber: boolean)
    local band = SubStrip(TopStrip(top, 6), 0.12, 0.9)
    cv:polyline(band, WithAlpha(glaze.Color, 200), 7)
    cv:polyline(SubStrip(TopStrip(top, 12), 0.2, 0.75), WithAlpha(Brighten(glaze.Color, 0.35), 130), 4)
    if depth >= 2 then
        cv:polyline(SubStrip(TopStrip(top, 20), 0.25, 0.8), WithAlpha(glaze.Color, 130), 5)
    end
    if depth >= 4 then
        cv:polyline(SubStrip(TopStrip(top, 30), 0.3, 0.7), WithAlpha(glaze.Color, 90), 4)
    end
    for i = 1, math.min(2 + depth, 4) do
        local dx = faceX - 18 + i * 10
        local dy = faceY - 14
        cv:line(dx, dy, dx + 2, dy + 16 + i * 4, WithAlpha(glaze.Color, 190), 4)
        cv:circle(dx + 2, dy + 17 + i * 4, 2.6, WithAlpha(glaze.Color, 210))
    end
    if isEmber then
        for _, p in ipairs(band) do
            if math.floor(p[1]) % 24 < 4 then
                ember:circle(p[1], p[2], 2.2, {r = 255, g = 140, b = 40, a = 220})
            end
        end
    end
end

local function RoastJoint(cv: Canvas, ember: Canvas, banquet, Roll: () -> number)
    local entree = banquet.Entree
    local sizeTier = entree.SizeTier
    local w = if sizeTier == 3 then 330 elseif sizeTier == 2 then 280 else 215
    local h = if sizeTier == 3 then 78 elseif sizeTier == 2 then 68 else 52
    local spec = Larder.GetEntree(entree.Letter) :: Larder.Entree
    local crust = spec.Crust
    if entree.Charred then
        crust = BlendRGB(crust, {r = 30, g = 26, b = 24}, 0.75)
    end

    if sizeTier == 1 then
        local bx, by = EX - w * 0.38, EY - h * 0.3
        cv:line(bx + 14, by + 8, bx - 58, by - 20, WithAlpha(BoneColor, 255), 12)
        cv:line(bx + 14, by + 10, bx - 58, by - 18, WithAlpha(Darken(BoneColor, 0.3), 130), 4)
        cv:circle(bx - 62, by - 24, 9, BoneColor)
        cv:circle(bx - 68, by - 17, 7, BoneColor)
    end

    local polygon, top = BuildMound(EX, EY, w, h, Roll)
    cv:polygon(polygon, Darken(crust, 0.28))
    local innerPoly, innerTop = BuildMound(EX - 6, EY - 5, w * 0.94, h * 0.94, Roll)
    cv:polygon(innerPoly, crust)
    local lobePoly = BuildMound(EX - w * 0.12, EY - h * 0.42, w * 0.6, h * 0.5, Roll)
    cv:polygon(lobePoly, Brighten(crust, 0.06))

    cv:polyline(SubStrip(TopStrip(innerTop, 5), 0.08, 0.42), WithAlpha(Brighten(crust, 0.4), 120), 6)
    cv:polyline(SubStrip(TopStrip(innerTop, 4), 0.6, 0.95), WithAlpha(Black, 70), 7)

    if entree.Letter == "P" or entree.Letter == "L" then
        cv:polyline(SubStrip(TopStrip(innerTop, 9), 0.15, 0.85), WithAlpha({r = 238, g = 222, b = 196}, 190), 8)
    end
    if entree.Letter == "X" then
        for _ = 1, 26 do
            local u = Roll() * 1.7 - 0.85
            local lift = math.sqrt(math.max(0, 1 - u * u))
            local px = EX + u * w / 2
            local py = EY - h * math.pow(lift, 0.78) * (0.3 + Roll() * 0.6)
            cv:line(px, py, px + (Roll() - 0.5) * 8, py - 4 - Roll() * 6, WithAlpha(Darken(crust, 0.45), 190), 1.6)
        end
    end
    if entree.Spit then
        for i = 1, 4 do
            local u = -0.55 + (i - 1) * 0.36
            local px = EX + u * w / 2
            cv:line(px, EY - h * 0.7, px + 6, EY + h * 0.24, WithAlpha(Darken(crust, 0.5), 140), 5)
        end
    end
    if entree.Charred then
        for _ = 1, 6 do
            local u = Roll() * 1.5 - 0.75
            local px = EX + u * w / 2
            local py = EY - h * (0.2 + Roll() * 0.5)
            local crack = {}
            for j = 0, 4 do
                table.insert(crack, {px + j * 7 + (Roll() - 0.5) * 6, py + (Roll() - 0.5) * 8})
            end
            cv:polyline(crack, {r = 232, g = 110, b = 40, a = 130}, 2)
        end
        for _ = 1, 14 do
            cv:circle(EX + (Roll() * 2 - 1) * w * 0.44, EY - h * Roll() * 0.7, 1.4, {r = 200, g = 196, b = 188, a = 170})
        end
    end

    TrussStrings(cv, EX, EY, w * 0.92, h * 0.94, if sizeTier == 3 then 4 else 3)

    local faceX = EX + w * 0.33
    local faceY = EY - h * 0.02
    CutFace(cv, faceX, faceY, w * 0.095, h * 0.46, entree.Interior, crust)

    if banquet.Entree.Glaze then
        local glaze = Larder.GetGlaze(banquet.Entree.Glaze) :: Larder.Glaze
        GlazeDrips(cv, ember, innerTop, glaze, banquet.Entree.GlazeDepth, faceX, faceY, banquet.Entree.Glaze == ";")
    end

    local slices = math.max(banquet.Entree.Slices, 1)
    FannedSlices(cv, slices, entree.Interior, crust, 0)
end

local function DragonRoast(cv: Canvas, ember: Canvas, banquet, Roll: () -> number)
    local entree = banquet.Entree
    local w = if entree.SizeTier == 3 then 335 elseif entree.SizeTier == 2 then 285 else 220
    local h = if entree.SizeTier == 3 then 80 elseif entree.SizeTier == 2 then 68 else 54
    local spec = Larder.GetEntree(entree.Letter) :: Larder.Entree
    local crust = spec.Crust
    if entree.Charred then
        crust = BlendRGB(crust, {r = 26, g = 24, b = 26}, 0.7)
    end

    local polygon, top = BuildMound(EX, EY, w, h, Roll)
    cv:polygon(polygon, Darken(crust, 0.3))
    local innerPoly, innerTop = BuildMound(EX - 5, EY - 4, w * 0.95, h * 0.95, Roll)
    cv:polygon(innerPoly, crust)

    local wyvern = entree.Kind == "wyvern"
    if wyvern then
        for row = 1, 5 do
            local ry = EY - h * (0.75 - row * 0.16)
            for i = -6, 6 do
                local px = EX + i * w * 0.07 + (row % 2) * w * 0.035
                local u = (px - EX) / (w / 2)
                if math.abs(u) < 0.92 then
                    cv:line(px - 7, ry - 5, px + 7, ry + 5, WithAlpha(Darken(crust, 0.35), 120), 1.6)
                    cv:line(px - 7, ry + 5, px + 7, ry - 5, WithAlpha(Darken(crust, 0.35), 120), 1.6)
                end
            end
        end
    else
        for row = 1, 5 do
            local rowT = row / 5
            local ry = EY - h * (0.85 - rowT * 0.85)
            local scaleR = 11 + row * 2
            for i = -7, 7 do
                local px = EX + i * w * 0.062 + (row % 2) * w * 0.031
                local u = (px - EX) / (w / 2)
                if math.abs(u) < 0.9 then
                    local arc = EllipseArc(px, ry, scaleR, scaleR * 0.6, 0.15, math.pi - 0.15, 10)
                    cv:polyline(arc, WithAlpha(Darken(crust, 0.4), 160), 1.8)
                end
            end
        end
    end

    if not wyvern then
        local alpha = if entree.DulledBands then 26 else 54
        local bandColors = {
            {r = 60, g = 200, b = 190},
            {r = 150, g = 90, b = 220},
            {r = 240, g = 200, b = 90},
        }
        for i, bc in ipairs(bandColors) do
            cv:polyline(SubStrip(TopStrip(innerTop, 7 + (i - 1) * 12), 0.12, 0.88), WithAlpha(bc, alpha), 9)
        end
    end

    for i = 2, 14 do
        local p = innerTop[i]
        local q = innerTop[i + 1]
        if p and q and i % 2 == 0 then
            cv:polygon({{p[1], p[2] + 3}, {(p[1] + q[1]) / 2, p[2] - 13}, {q[1], q[2] + 3}}, WithAlpha(Darken(crust, 0.5), 240))
        end
    end

    cv:polyline(SubStrip(TopStrip(innerTop, 6), 0.08, 0.4), WithAlpha(Brighten(crust, 0.45), 110), 5)

    local faceX = EX + w * 0.33
    local faceY = EY - h * 0.02
    CutFace(cv, faceX, faceY, w * 0.095, h * 0.44, entree.Interior, crust)

    if entree.Glaze then
        local glaze = Larder.GetGlaze(entree.Glaze) :: Larder.Glaze
        GlazeDrips(cv, ember, innerTop, glaze, entree.GlazeDepth, faceX, faceY, entree.Glaze == ";")
    end

    FannedSlices(cv, math.max(entree.Slices, 1), entree.Interior, crust, 0)
end

local function BirdRoast(cv: Canvas, ember: Canvas, steam: Canvas, banquet, Roll: () -> number, phoenix: boolean)
    local entree = banquet.Entree
    local w = if entree.SizeTier == 3 then 300 elseif entree.SizeTier == 2 then 250 else 200
    local h = w * 0.3
    local spec = Larder.GetEntree(entree.Letter) :: Larder.Entree
    local crust = spec.Crust
    if entree.Charred and not phoenix then
        crust = BlendRGB(crust, {r = 30, g = 26, b = 24}, 0.7)
    end
    local bx, by = EX, EY - 8

    local function Drumstick(dx: number, dy: number, ang: number, len: number, thick: number, shade: number)
        local color = if shade > 0 then Brighten(crust, shade) else Darken(crust, -shade)
        local tipX = dx + math.cos(ang) * len
        local tipY = dy + math.sin(ang) * len
        local midX = dx + math.cos(ang) * len * 0.55
        local midY = dy + math.sin(ang) * len * 0.55
        local points = {}
        local perp = ang + math.pi / 2
        table.insert(points, {dx + math.cos(perp) * thick * 0.85, dy + math.sin(perp) * thick * 0.85})
        table.insert(points, {midX + math.cos(perp) * thick * 0.6, midY + math.sin(perp) * thick * 0.6})
        table.insert(points, {tipX + math.cos(perp) * thick * 0.26, tipY + math.sin(perp) * thick * 0.26})
        table.insert(points, {tipX - math.cos(perp) * thick * 0.26, tipY - math.sin(perp) * thick * 0.26})
        table.insert(points, {midX - math.cos(perp) * thick * 0.6, midY - math.sin(perp) * thick * 0.6})
        table.insert(points, {dx - math.cos(perp) * thick * 0.85, dy - math.sin(perp) * thick * 0.85})
        cv:polygon(points, color)
        cv:polyline({points[2], points[3]}, WithAlpha(Darken(crust, 0.4), 120), 2)
        cv:polyline({points[4], points[5]}, WithAlpha(Darken(crust, 0.4), 120), 2)
        RotEllipse(cv, dx, dy, thick * 1.05, thick * 0.8, ang, color, 16)
        RotEllipse(cv, dx + math.cos(ang) * len * 0.2, dy + math.sin(ang) * len * 0.2, thick * 0.85, thick * 0.62, ang, Brighten(color, 0.08), 14)
        cv:circle(tipX + math.cos(ang) * 6, tipY + math.sin(ang) * 6, thick * 0.4, BoneColor)
        cv:circle(tipX + math.cos(ang) * 10, tipY + math.sin(ang) * 8, thick * 0.28, BoneColor)
    end

    cv:ellipse(bx, by + h * 0.55, w * 0.46, h * 0.3, WithAlpha(JusColor, 200))
    Drumstick(bx + w * 0.3, by - h * 0.28, -0.55, w * 0.24, h * 0.22, -0.22)
    RotEllipse(cv, bx, by, w * 0.46, h * 0.85, -0.06, Darken(crust, 0.22), 48)
    RotEllipse(cv, bx - 4, by - 4, w * 0.44, h * 0.8, -0.06, crust, 48)
    cv:ellipse(bx - w * 0.3, by - h * 0.15, w * 0.13, h * 0.34, Brighten(crust, 0.08))
    cv:ellipse(bx + w * 0.28, by - h * 0.1, w * 0.12, h * 0.3, Brighten(crust, 0.04))
    cv:ellipse(bx - w * 0.16, by - h * 0.42, w * 0.2, h * 0.24, WithAlpha(Brighten(crust, 0.35), 130))
    Drumstick(bx + w * 0.3, by + h * 0.1, -0.34, w * 0.28, h * 0.26, 0.1)
    Drumstick(bx - w * 0.28, by + h * 0.12, math.pi - 0.42, w * 0.26, h * 0.24, 0.06)

    cv:polyline(EllipseArc(bx - 4, by - h * 0.16, w * 0.24, h * 0.34, math.pi * 1.15, math.pi * 1.85, 12), {r = 210, g = 190, b = 150, a = 170}, 2.2)

    if (banquet.Entree.Craft.T or 0) > 0 then
        for i = 1, 8 do
            local px = bx - w * 0.42 + (Roll() - 0.5) * w * 0.1
            local py = by + h * 0.3 + (Roll() - 0.5) * h * 0.16
            local r = 3.5 + Roll() * 3
            cv:circle(px + 1, py + 2, r, WithAlpha(Black, 90))
            cv:circle(px, py, r, {r = 208, g = 168, b = 108, a = 255})
            cv:circle(px - r * 0.3, py - r * 0.3, r * 0.4, {r = 232, g = 196, b = 136, a = 200})
        end
    end

    if phoenix then
        for _ = 1, 7 do
            local u = Roll() * 1.4 - 0.7
            local px = bx + u * w * 0.4
            local py = by - h * (0.1 + Roll() * 0.55)
            local crack = {}
            for j = 0, 5 do
                table.insert(crack, {px + j * 8 + (Roll() - 0.5) * 7, py + (Roll() - 0.5) * 10})
            end
            cv:polyline(crack, {r = 255, g = 120, b = 30, a = 210}, 2.4)
            ember:polyline(crack, {r = 255, g = 140, b = 40, a = 190}, 3)
        end
        local sparkCount = if entree.Reignited then 12 else 8
        for _ = 1, sparkCount do
            local sx = bx + (Roll() * 2 - 1) * w * 0.36
            local sy = by - h * (0.3 + Roll() * 0.5)
            local arc = {}
            for j = 0, 6 do
                local t = j / 6
                table.insert(arc, {sx + t * 12 * (Roll() - 0.4), sy - t * (18 + Roll() * 24)})
            end
            steam:polyline(arc, {r = 250, g = 190, b = 70, a = 150}, 1.4)
            ember:circle(arc[#arc][1], arc[#arc][2], 2.2, {r = 255, g = 200, b = 80, a = 235})
            ember:circle(arc[4][1], arc[4][2], 1.4, {r = 255, g = 180, b = 60, a = 180})
        end
    end

    local faceX = bx + w * 0.4
    local faceY = by
    if entree.Glaze then
        local fakeTop = {}
        for i = 0, 12 do
            local t = i / 12 * math.pi
            table.insert(fakeTop, {bx - math.cos(t) * w * 0.42, by - math.sin(t) * h * 0.72})
        end
        local glaze = Larder.GetGlaze(entree.Glaze) :: Larder.Glaze
        GlazeDrips(cv, ember, fakeTop, glaze, entree.GlazeDepth, faceX, faceY, entree.Glaze == ";")
    end

    if entree.Slices > 0 then
        FannedSlices(cv, entree.Slices, entree.Interior, crust, 0)
    end
end

local function ShadowBeast(cv: Canvas, steam: Canvas, banquet, Roll: () -> number)
    local entree = banquet.Entree
    local w = if entree.SizeTier == 3 then 330 elseif entree.SizeTier == 2 then 280 else 215
    local h = if entree.SizeTier == 3 then 76 elseif entree.SizeTier == 2 then 66 else 52
    local crust = (Larder.GetEntree(entree.Letter) :: Larder.Entree).Crust

    local polygon, top = BuildMound(EX, EY, w, h, Roll)
    cv:polygon(polygon, Darken(crust, 0.25))
    local innerPoly, innerTop = BuildMound(EX - 4, EY - 3, w * 0.96, h * 0.96, Roll)
    cv:polygon(innerPoly, crust)
    cv:polyline(SubStrip(TopStrip(innerTop, 2), 0.05, 0.95), {r = 150, g = 90, b = 220, a = 160}, 2.6)

    local faceX = EX + w * 0.33
    local faceY = EY - h * 0.02
    CutFace(cv, faceX, faceY, w * 0.095, h * 0.44, entree.Interior, crust)

    for _ = 1, 4 do
        local u = Roll() * 1.4 - 0.7
        local sx = EX + u * w * 0.4
        local lift = math.sqrt(math.max(0, 1 - u * u))
        SteamFrom(steam, sx, EY - h * lift * 0.8, 80 + Roll() * 70, {r = 60, g = 44, b = 84}, Roll)
    end

    FannedSlices(cv, math.max(entree.Slices, 1), entree.Interior, crust, 0)
end

local function WholeFish(cv: Canvas, banquet, Roll: () -> number)
    local entree = banquet.Entree
    local fillet = entree.SizeTier == 1
    local w = if fillet then 210 else 330
    local h = if fillet then 44 else 80
    local body = {r = 178, g = 132, b = 74}
    local belly = {r = 226, g = 202, b = 156}
    local bx, by = EX, EY + 6

    if fillet then
        local points = {}
        for i = 0, 20 do
            local t = i / 20
            local px = bx - w / 2 + w * t
            local lift = math.sin(t * math.pi)
            table.insert(points, {px, by - h * 0.5 * lift})
        end
        for i = 20, 0, -1 do
            local t = i / 20
            local px = bx - w / 2 + w * t
            local lift = math.sin(t * math.pi)
            table.insert(points, {px, by + h * 0.42 * lift})
        end
        cv:polygon(points, {r = 228, g = 140, b = 96})
        for i = 1, 5 do
            local fx = bx - w * 0.36 + i * w * 0.13
            local arc = EllipseArc(fx, by, h * 0.36, h * 0.42, math.pi * 0.6, math.pi * 1.4, 10)
            cv:polyline(arc, WithAlpha({r = 248, g = 232, b = 214}, 200), 2.6)
        end
        cv:polyline(EllipseArc(bx - w * 0.1, by - h * 0.24, w * 0.3, h * 0.16, math.pi, math.pi * 2, 12), WithAlpha(White, 90), 3)
        return
    end

    cv:ellipse(bx + 8, by + h * 0.5, w * 0.5, h * 0.3, WithAlpha(Black, 110))

    local tailX = bx + w * 0.5 - 14
    cv:polygon({{tailX, by - 4}, {tailX + 52, by - 30}, {tailX + 42, by + 2}, {tailX + 54, by + 26}}, Darken(body, 0.3))
    cv:line(tailX + 10, by - 6, tailX + 44, by - 22, WithAlpha(Darken(body, 0.5), 180), 2)
    cv:line(tailX + 10, by + 2, tailX + 46, by + 18, WithAlpha(Darken(body, 0.5), 180), 2)

    local points = {}
    for i = 0, 24 do
        local t = i / 24
        local px = bx - w / 2 + w * t
        local lift = math.sin(math.min(t * 1.12, 1) * math.pi) ^ 0.8
        table.insert(points, {px, by - h * 0.55 * lift})
    end
    for i = 24, 0, -1 do
        local t = i / 24
        local px = bx - w / 2 + w * t
        local lift = math.sin(math.min(t * 1.12, 1) * math.pi) ^ 0.8
        table.insert(points, {px, by + h * 0.48 * lift})
    end
    cv:polygon(points, body)
    cv:polyline(points, WithAlpha(Darken(body, 0.55), 220), 2.4)
    cv:ellipse(bx - w * 0.04, by + h * 0.2, w * 0.4, h * 0.22, WithAlpha(belly, 220))
    local back = {}
    for i = 0, 20 do
        local t = i / 20
        local px = bx - w * 0.44 + w * 0.86 * t
        local lift = math.sin(math.min((t * 0.88 + 0.06) * 1.12, 1) * math.pi) ^ 0.8
        table.insert(back, {px, by - h * 0.42 * lift})
    end
    cv:polyline(back, WithAlpha(Darken(body, 0.35), 200), 7)
    cv:polyline(EllipseArc(bx, by - h * 0.02, w * 0.42, h * 0.08, math.pi, math.pi * 2, 20), WithAlpha(Darken(body, 0.45), 180), 2.2)

    local headX = bx - w * 0.5
    local headCap = {}
    for i = 0, 12 do
        local t = i / 12
        local px = headX + w * 0.13 * t
        local lift = math.sin(math.min((t * 0.13) * 1.12, 1) * math.pi) ^ 0.8
        table.insert(headCap, {px, by - h * 0.55 * lift})
    end
    for i = 12, 0, -1 do
        local t = i / 12
        local px = headX + w * 0.13 * t
        local lift = math.sin(math.min((t * 0.13) * 1.12, 1) * math.pi) ^ 0.8
        table.insert(headCap, {px, by + h * 0.48 * lift})
    end
    cv:polygon(headCap, Darken(body, 0.18))
    cv:polyline(EllipseArc(headX + w * 0.15, by - h * 0.02, h * 0.26, h * 0.4, -math.pi * 0.42, math.pi * 0.42, 12), WithAlpha(Darken(body, 0.55), 220), 3)
    cv:circle(headX + w * 0.06, by - h * 0.18, 6.5, {r = 26, g = 22, b = 18, a = 255})
    cv:circle(headX + w * 0.065, by - h * 0.2, 2.2, {r = 244, g = 244, b = 234, a = 230})
    cv:line(headX - 3, by + h * 0.08, headX + w * 0.05, by + h * 0.1, WithAlpha(Darken(body, 0.6), 220), 2.6)

    for i = 1, 5 do
        local gx = bx - w * 0.3 + (i - 1) * w * 0.13
        local grill = {}
        for j = 0, 8 do
            local t = j / 8
            table.insert(grill, {gx + t * 7, by - h * 0.4 + t * h * 0.52})
        end
        cv:polyline(grill, WithAlpha({r = 62, g = 40, b = 22}, 130), 6)
    end
    cv:polyline(EllipseArc(bx - w * 0.08, by - h * 0.32, w * 0.26, h * 0.1, math.pi, math.pi * 2, 14), WithAlpha(White, 90), 3.4)
    Sprig(cv, tailX - 6, by + h * 0.44, 1.2, Roll)
end

local function NoodlePile(cv: Canvas, banquet, Roll: () -> number)
    local w, h = 280, 74
    local polygon = BuildMound(EX, EY, w, h, Roll)
    cv:polygon(polygon, Darken(Wheat, 0.22))
    for band = 1, 4 do
        for _ = 1, 16 do
            local u = Roll() * 1.8 - 0.9
            local lift = math.sqrt(math.max(0, 1 - u * u))
            local sx = EX + u * w / 2
            local sy = EY - h * lift * (1.08 - band * 0.3) + h * 0.1
            local len = 44 + Roll() * 72
            local amp = 4 + Roll() * 7
            local phase = Roll() * math.pi * 2
            local tilt = (Roll() - 0.5) * 0.6
            local dark = {}
            for i = 0, 12 do
                local t = i / 12
                local px = sx - len / 2 + len * t
                local py = sy + math.sin(phase + t * math.pi * 2.4) * amp + (px - sx) * tilt * 0.25
                table.insert(dark, {px, py})
            end
            cv:polyline(dark, WithAlpha(Darken(Wheat, 0.35), 210), 4.6)
            cv:polyline(TopStrip(dark, -1.5), WheatLight, 2.7)
        end
    end
    for i = 1, 3 do
        local arc = EllipseArc(EX - 10, EY - h * 0.72, 30 - i * 7, 13 - i * 3, Roll() * math.pi, Roll() * math.pi + 4.2, 16)
        cv:polyline(arc, WithAlpha(Darken(Wheat, 0.32), 210), 4)
        cv:polyline(TopStrip(arc, -1.4), WheatLight, 2.4)
    end
    for i = 1, 5 do
        local u = -0.8 + (i - 1) * 0.4
        local dir = if u < 0 then -1 else 1
        local sx = EX + u * w * 0.5 + (Roll() - 0.5) * 14
        local baseY = EY + h * 0.3 + 8 + Roll() * 10
        local reach = 34 + Roll() * 30
        local strand = {}
        for j = 0, 6 do
            local t = j / 6
            table.insert(strand, {sx - dir * 14 + dir * 14 * t, EY + h * 0.05 + (baseY - EY - h * 0.05) * t + math.sin(t * 5 + i) * 2})
        end
        for j = 1, 10 do
            local t = j / 10
            table.insert(strand, {sx + dir * reach * t, baseY + math.sin(t * math.pi * 2.6 + i) * 4.4})
        end
        cv:ellipse(sx + dir * reach * 0.5, baseY + 5, reach * 0.6, 4.5, WithAlpha(Black, 80))
        cv:polyline(strand, WithAlpha(Darken(Wheat, 0.35), 225), 4.6)
        cv:polyline(TopStrip(strand, -1.5), WheatLight, 2.7)
        local loop = EllipseArc(sx + dir * (reach + 8), baseY - 2, 11, 5.5, Roll() * math.pi, Roll() * math.pi + 4.4, 12)
        cv:polyline(loop, WithAlpha(Darken(Wheat, 0.35), 215), 4)
        cv:polyline(TopStrip(loop, -1.3), WheatLight, 2.3)
    end
end

local function BrothBowl(cv: Canvas, steam: Canvas, banquet, hot: boolean, Roll: () -> number)
    local bx, by = EX + 10, EY + 16
    local rimRx, rimRy = 150, 48
    local depth = 74
    local y = by
    while y <= by + depth do
        local t = (y - by) / depth
        local hw = rimRx * (0.92 - 0.28 * t * t)
        cv:line(bx - hw, y, bx + hw, y, WithAlpha(BlendRGB(CeramicLight, CeramicDark, 0.2 + t * 0.66), 255), 3)
        y += 2
    end
    cv:ellipse(bx, by + depth, rimRx * 0.62, 9, WithAlpha(Darken(CeramicDark, 0.4), 255))
    cv:ellipse(bx, by, rimRx, rimRy, CeramicLight)
    cv:ellipse(bx, by + 2, rimRx - 12, rimRy - 9, InnerWall)
    cv:ellipse(bx, by + 4, rimRx - 18, rimRy - 13, {r = 116, g = 78, b = 40, a = 255})
    cv:ellipse(bx, by + 5, rimRx * 0.55, rimRy * 0.4, {r = 140, g = 96, b = 50, a = 200})
    for _ = 1, 12 do
        local a = Roll() * math.pi * 2
        local rad = math.sqrt(Roll()) * 0.7
        local sx = bx + math.cos(a) * rad * (rimRx - 26)
        local sy = by + 4 + math.sin(a) * rad * (rimRy - 16)
        local len = 26 + Roll() * 30
        local strand = {}
        for j = 0, 8 do
            local t = j / 8
            table.insert(strand, {sx - len / 2 + len * t, sy + math.sin(t * math.pi * 2 + a) * 4})
        end
        cv:polyline(strand, WithAlpha(Darken(Wheat, 0.2), 220), 3.4)
        cv:polyline(TopStrip(strand, -1), WheatLight, 2)
    end
    for i = 1, 4 do
        local a = Roll() * math.pi * 2
        local sx = bx + math.cos(a) * (rimRx - 30)
        local sy = by + math.sin(a) * (rimRy - 12)
        local loop = {}
        for j = 0, 8 do
            local t = j / 8
            table.insert(loop, {sx + (Roll() - 0.5) * 4 + t * 14, sy - math.sin(t * math.pi) * 14 + t * 10})
        end
        cv:polyline(loop, WithAlpha(Darken(Wheat, 0.25), 220), 3.6)
    end
    local stickY = by - rimRy - 4
    cv:line(bx - rimRx - 26, stickY + 26, bx + rimRx + 6, stickY - 10, {r = 150, g = 104, b = 58, a = 255}, 7)
    cv:line(bx - rimRx - 20, stickY + 34, bx + rimRx + 12, stickY - 2, {r = 128, g = 86, b = 46, a = 255}, 7)
    if hot then
        for _ = 1, 3 do
            SteamFrom(steam, bx + (Roll() * 2 - 1) * rimRx * 0.5, by - 4, 120 + Roll() * 80, Brighten({r = 140, g = 96, b = 50}, 0.6), Roll)
        end
    end
end

local function MeatPie(cv: Canvas, banquet, Roll: () -> number)
    local entree = banquet.Entree
    local w, h = 270, 104
    local bx, by = EX, EY + 2
    local filling = {r = 96, g = 58, b = 30}
    if entree.Filling then
        local fillSpec = Larder.GetEntree(entree.Filling) :: Larder.Entree
        filling = Darken(fillSpec.Flesh or fillSpec.Crust, 0.2)
    end
    local pastry = {r = 214, g = 164, b = 96}

    cv:ellipse(bx, by + h * 0.3, w * 0.52, h * 0.28, Darken(pastry, 0.38))
    cv:ellipse(bx, by + h * 0.02, w * 0.5, h * 0.5, Darken(pastry, 0.18))
    cv:ellipse(bx - 4, by - h * 0.06, w * 0.47, h * 0.44, pastry)
    cv:ellipse(bx - w * 0.14, by - h * 0.26, w * 0.2, h * 0.13, WithAlpha(Brighten(pastry, 0.4), 150))

    for i = 0, 15 do
        local a = math.pi * 0.06 + i / 15 * math.pi * 0.88
        local px = bx - math.cos(a) * w * 0.48
        local py = by + h * 0.2 + math.sin(a) * 4
        cv:polyline(EllipseArc(px, py + math.sin(a) * 2, 11, 8, math.pi, math.pi * 2, 8), WithAlpha(Darken(pastry, 0.3), 210), 2.6)
    end

    local wedgeA0 = 0.35
    local wedgeA1 = 1.0
    local wedge = {{bx + w * 0.06, by - h * 0.14}}
    for i = 0, 8 do
        local a = wedgeA0 + (wedgeA1 - wedgeA0) * i / 8
        table.insert(wedge, {bx + w * 0.06 + math.cos(a) * w * 0.42, by - h * 0.14 + math.sin(a) * h * 0.56})
    end
    cv:polygon(wedge, {r = 46, g = 28, b = 16, a = 255})
    cv:polygon({
        {bx + w * 0.06, by - h * 0.14},
        {bx + w * 0.06 + math.cos(wedgeA0) * w * 0.42, by - h * 0.14 + math.sin(wedgeA0) * h * 0.56},
        {bx + w * 0.06 + math.cos(wedgeA0) * w * 0.40, by - h * 0.14 + math.sin(wedgeA0) * h * 0.5 + 8},
        {bx + w * 0.06, by - h * 0.14 + 9},
    }, BlendRGB(pastry, {r = 240, g = 224, b = 190}, 0.5))
    cv:polygon({
        {bx + w * 0.06, by - h * 0.14},
        {bx + w * 0.06 + math.cos(wedgeA1) * w * 0.42, by - h * 0.14 + math.sin(wedgeA1) * h * 0.56},
        {bx + w * 0.06 + math.cos(wedgeA1) * w * 0.42 - 10, by - h * 0.14 + math.sin(wedgeA1) * h * 0.5},
        {bx + w * 0.06 - 8, by - h * 0.14 + 4},
    }, BlendRGB(pastry, {r = 240, g = 224, b = 190}, 0.35))
    cv:ellipse(bx + w * 0.2, by + h * 0.14, w * 0.11, h * 0.12, filling)
    cv:ellipse(bx + w * 0.17, by + h * 0.1, w * 0.06, h * 0.06, Brighten(filling, 0.15))
    local dripX = bx + w * 0.3
    cv:line(dripX, by + h * 0.3, dripX + 3, by + h * 0.48, WithAlpha(Darken(filling, 0.05), 220), 4)
    cv:ellipse(dripX + 4, by + h * 0.52, 7, 3, WithAlpha(Darken(filling, 0.05), 200))

    cv:line(bx - w * 0.12, by - h * 0.28, bx - w * 0.02, by - h * 0.24, WithAlpha(Darken(pastry, 0.55), 240), 3.6)
    cv:line(bx - w * 0.08, by - h * 0.34, bx - w * 0.06, by - h * 0.18, WithAlpha(Darken(pastry, 0.55), 240), 3.6)
    cv:ellipse(bx - w * 0.07, by - h * 0.26, 5, 3, WithAlpha(filling, 210))
end

local function Skewers(cv: Canvas, banquet, Roll: () -> number)
    local entree = banquet.Entree
    local sticks = math.clamp(entree.Count, 1, 4)
    local cube = if entree.Filling then (Larder.GetEntree(entree.Filling) :: Larder.Entree).Crust else {r = 120, g = 66, b = 38}
    local veg = {{r = 110, g = 150, b = 60}, {r = 226, g = 214, b = 180}}
    for i = 1, sticks do
        local sy = EY - 26 + i * 22
        local sx = EX - 10 + (i % 2) * 24
        local ang = -0.21 + (Roll() - 0.5) * 0.04
        local len = 300
        local x0 = sx - math.cos(ang) * len / 2
        local y0 = sy - math.sin(ang) * len / 2
        local x1 = sx + math.cos(ang) * len / 2
        local y1 = sy + math.sin(ang) * len / 2
        cv:ellipse(sx, sy + 12, len * 0.46, 8, WithAlpha(Black, 80))
        cv:line(x0, y0, x1, y1, {r = 186, g = 156, b = 110, a = 255}, 5)
        cv:circle(x1 + 2, y1, 3.4, {r = 186, g = 156, b = 110, a = 255})
        for c = 1, 5 do
            local t = 0.16 + (c - 1) * 0.155
            local cx = x0 + (x1 - x0) * t
            local cy = y0 + (y1 - y0) * t
            local color = if c % 3 == 0 then veg[(c // 3) % 2 + 1] else cube
            local size = 15 + Roll() * 4
            local points = {}
            local base = Roll() * 0.6 - 0.3 + ang
            for k = 0, 3 do
                local a = base + k * math.pi / 2 + (Roll() - 0.5) * 0.2
                table.insert(points, {cx + math.cos(a) * size, cy + math.sin(a) * size * 0.75})
            end
            cv:polygon(points, color)
            cv:strokePolygon(points, WithAlpha(Darken(color, 0.5), 200), 2)
            cv:ellipse(cx - size * 0.2, cy - size * 0.24, size * 0.3, size * 0.16, WithAlpha(Brighten(color, 0.3), 150))
        end
    end
end

local function Sausages(cv: Canvas, banquet, Roll: () -> number)
    local entree = banquet.Entree
    local links = math.clamp(entree.Count, 3, 6)
    local color = if entree.Filling then Darken((Larder.GetEntree(entree.Filling) :: Larder.Entree).Crust, 0.05) else {r = 152, g = 74, b = 46}
    local rows = {{y = EY - 22, n = math.max(links - 3, 2), shade = -0.18}, {y = EY + 10, n = math.min(links, 4), shade = 0}}
    for _, row in ipairs(rows) do
        local total = row.n
        for i = 1, total do
            local sx = EX - (total - 1) * 34 + (i - 1) * 68
            local sy = row.y + (Roll() - 0.5) * 6
            local phase = Roll() * math.pi
            local body = {}
            for j = 0, 12 do
                local t = j / 12
                table.insert(body, {sx - 34 + t * 68, sy + math.sin(phase + t * math.pi * 1.4) * 7})
            end
            local shade = if row.shade < 0 then Darken(color, -row.shade) else color
            cv:polyline(body, Darken(shade, 0.3), 26)
            cv:polyline(TopStrip(body, -2), shade, 21)
            cv:polyline(SubStrip(TopStrip(body, -8), 0.15, 0.7), WithAlpha(Brighten(shade, 0.35), 130), 5)
            for _ = 1, 3 do
                local t = Roll()
                local px = sx - 30 + t * 60
                cv:line(px, sy + math.sin(phase + t * math.pi * 1.4) * 7 + 4, px + 6, sy + math.sin(phase + t * math.pi * 1.4) * 7 + 5, WithAlpha({r = 40, g = 22, b = 12}, 180), 2.4)
            end
            cv:circle(sx - 34, sy, 5, Darken(shade, 0.35))
            cv:circle(sx + 34, sy + math.sin(phase + math.pi * 1.4) * 7, 5, Darken(shade, 0.35))
        end
    end
end

local function DrawGarnishes(cv: Canvas, banquet, Roll: () -> number)
    local garnish = banquet.Entree.Garnish
    if (garnish.J or 0) > 0 then
        for i = 1, math.min(garnish.J + 1, 4) do
            Sprig(cv, EX - 190 + i * 52 + (Roll() - 0.5) * 20, EY + 62 + (Roll() - 0.5) * 12, 1.5, Roll)
        end
    end
    if (garnish.C or 0) > 0 then
        for i = 1, math.min(garnish.C + 1, 4) do
            local px = PX + 130 + (i - 1) * 34 - i * 8
            local py = PY + 26 + i * 9
            cv:ellipse(px + 3, py + 6, 20, 6, WithAlpha(Black, 90))
            cv:ellipse(px, py, 21, 12, {r = 240, g = 214, b = 92, a = 255})
            cv:ellipse(px, py, 17, 9, {r = 250, g = 236, b = 150, a = 255})
            for k = 0, 5 do
                local a = k / 6 * math.pi * 2 + 0.3
                cv:line(px, py, px + math.cos(a) * 15, py + math.sin(a) * 7.6, {r = 240, g = 214, b = 92, a = 200}, 1.6)
            end
        end
    end
    if (garnish.E or 0) > 0 then
        local inMouth = banquet.Entree.SizeTier == 3 and (banquet.Entree.Letter == "P" or banquet.Entree.Letter == "X")
        local count = math.min(garnish.E, 3)
        for i = 1, count do
            local px = EX - 170 + (i - 1) * 42
            local py = EY + 44 + (i % 2) * 12
            if inMouth and i == 1 then
                px, py = EX - 158, EY - 20
            end
            cv:ellipse(px + 2, py + 8, 16, 5, WithAlpha(Black, 100))
            cv:circle(px, py, 15, {r = 168, g = 58, b = 36, a = 255})
            cv:circle(px - 4, py - 4, 6, {r = 232, g = 130, b = 80, a = 160})
            cv:line(px, py - 13, px + 2, py - 19, {r = 74, g = 48, b = 24, a = 255}, 2.2)
        end
    end
    if (garnish.G or 0) > 0 then
        for i = 1, math.min(garnish.G + 1, 3) do
            local px = EX + 120 + (i - 1) * 30
            local py = EY + 56 + (i % 2) * 10
            cv:ellipse(px + 2, py + 6, 13, 4, WithAlpha(Black, 100))
            cv:ellipse(px, py, 12, 10, {r = 214, g = 186, b = 140, a = 255})
            cv:ellipse(px, py - 2, 9, 7, {r = 230, g = 204, b = 158, a = 255})
            for k = -1, 1 do
                cv:line(px + k * 4, py - 8, px + k * 5, py + 6, WithAlpha({r = 170, g = 140, b = 96}, 160), 1.4)
            end
        end
    end
    if (banquet.Entree.Craft.A or 0) > 0 then
        for _ = 1, 16 do
            local u = Roll() * 1.4 - 0.7
            local lift = math.sqrt(math.max(0, 1 - u * u))
            cv:circle(EX + u * 150, EY - 60 * lift * (0.3 + Roll() * 0.6), 1.8, {r = 44, g = 28, b = 16, a = 235})
        end
    end
    if banquet.Entree.Pepper > 0 then
        for _ = 1, math.min(banquet.Entree.Pepper * 6, 30) do
            cv:circle(EX + (Roll() * 2 - 1) * 150, EY + 20 + Roll() * 40, 1.2, {r = 34, g = 26, b = 18, a = 220})
        end
    end
    if banquet.Entree.Salt > 0 then
        for _ = 1, math.min(banquet.Entree.Salt * 6, 24) do
            cv:circle(EX + (Roll() * 2 - 1) * 140, EY - 10 - Roll() * 30, 1.3, {r = 244, g = 244, b = 238, a = 200})
        end
    end
end

local function GravyBoat(cv: Canvas, banquet, cold: boolean, Roll: () -> number)
    local glaze = Larder.GetGlaze(banquet.Boat.Letter) :: Larder.Glaze
    local bx, by = BoatX, BoatY
    cv:ellipse(bx, by + 26, 66, 12, WithAlpha(Darken(CeramicDark, 0.3), 255))
    cv:ellipse(bx, by + 22, 42, 8, Darken(CeramicDark, 0.15))
    local y = by - 18
    while y <= by + 20 do
        local t = (y - (by - 18)) / 38
        local hw = 70 * (0.72 + 0.4 * math.sin(math.min(t * 1.25, 1) * math.pi * 0.62))
        cv:line(bx - hw, y, bx + hw, y, WithAlpha(BlendRGB(CeramicLight, CeramicDark, 0.12 + t * 0.6), 255), 3)
        y += 2
    end
    cv:polygon({{bx + 58, by - 20}, {bx + 92, by - 34}, {bx + 96, by - 26}, {bx + 64, by - 8}}, BlendRGB(CeramicLight, CeramicDark, 0.2))
    cv:polyline(EllipseArc(bx - 74, by - 8, 18, 16, math.pi * 0.5, math.pi * 1.6, 14), BlendRGB(CeramicLight, CeramicDark, 0.35), 7)
    cv:ellipse(bx, by - 18, 62, 15, CeramicLight)
    cv:ellipse(bx, by - 17, 53, 11, InnerWall)
    cv:ellipse(bx, by - 16, 48, 9, WithAlpha(Darken(glaze.Pool, 0.05), 250))
    cv:ellipse(bx - 10, by - 17, 22, 4, WithAlpha(Brighten(glaze.Color, 0.2), 190))
    cv:polyline(EllipseArc(bx - 20, by + 2, 30, 14, math.pi * 0.7, math.pi * 1.3, 10), WithAlpha(White, 60), 4)
    if cold then
        BeadsOn(cv, bx, by, 60, 22, 6, Roll)
    end
end

local function SideVessel(cv: Canvas, steam: Canvas, banquet, hot: boolean, cold: boolean, tilt: number, Roll: () -> number)
    local side = banquet.Side
    local sx, sy = SideX, SideY
    local vessel = side.Vessel
    local plateColor = CeramicLight
    local wooden = vessel == "wood" or vessel == "board"
    if wooden then
        plateColor = BoardWood
    end

    if vessel == "bowl" or vessel == "wood" then
        local rimY = sy - 24
        local rimRx = SideRX - 32
        local rimRy = SideRY - 10
        local depth = 46
        local y = rimY
        while y <= rimY + depth do
            local t = (y - rimY) / depth
            local hw = rimRx * (0.97 - 0.34 * t * t)
            local shade = if wooden then BlendRGB(BoardWood, BoardWoodDark, 0.15 + t * 0.75) else BlendRGB(CeramicLight, CeramicDark, 0.18 + t * 0.72)
            cv:line(sx - hw, y, sx + hw, y, WithAlpha(shade, 255), 3)
            y += 2
        end
        cv:ellipse(sx, rimY + depth + 2, rimRx * 0.5, 7, WithAlpha(Darken(if wooden then BoardWoodDark else CeramicDark, 0.4), 255))
        local wallHl = {}
        y = rimY + 8
        while y <= rimY + depth - 8 do
            local t = (y - rimY) / depth
            table.insert(wallHl, {sx - rimRx * (0.97 - 0.34 * t * t) * 0.82, y})
            y += 3
        end
        if #wallHl > 2 then
            cv:polyline(wallHl, WithAlpha(White, 36), 6)
        end
        cv:ellipse(sx, rimY, rimRx, rimRy, if wooden then Brighten(BoardWood, 0.12) else CeramicLight)
        cv:ellipse(sx, rimY + 2, rimRx - 10, rimRy - 7, if wooden then BoardWoodDark else InnerWall)
        if not wooden then
            cv:polyline(EllipseArc(sx, rimY, rimRx - 4, rimRy - 3, 0.4, math.pi - 0.5, 24), WithAlpha(GlazeBand, 150), 3)
        end
        sy = rimY + 2
    elseif vessel == "board" then
        RotEllipse(cv, sx, sy + 6, SideRX - 4, SideRY - 6, tilt, BoardWoodDark, 48)
        RotEllipse(cv, sx, sy, SideRX - 4, SideRY - 6, tilt, BoardWood, 48)
        cv:polyline(EllipseArc(sx, sy, SideRX - 24, SideRY - 14, math.pi * 1.15, math.pi * 1.85, 16), WithAlpha(BoardWoodDark, 120), 2)
    else
        RotEllipse(cv, sx, sy, SideRX, SideRY, tilt, CeramicLight, 48)
        RotEllipse(cv, sx, sy + 1, SideRX - 16, SideRY - 10, tilt, BlendRGB(CeramicLight, CeramicDark, 0.35), 48)
        RotEllipse(cv, sx, sy + 1, SideRX - 26, SideRY - 15, tilt, BlendRGB(CeramicLight, CeramicDark, 0.12), 48)
    end

    if side.EmptyPlate then
        Sprig(cv, sx, sy + 2, 1, Roll)
        return
    end

    local letter = side.Letter
    local count = math.clamp(side.Count, 1, 6)
    local burnish = 0
    if side.HoursBand == "burnished" then
        burnish = 0.18
    elseif side.HoursBand == "scorched" then
        burnish = 0.45
    end

    local function FoodShadow(px: number, py: number, r: number)
        cv:ellipse(px + 2, py + 5, r, r * 0.35, WithAlpha(Black, 80))
    end

    if letter == "R" then
        local colors = {{r = 226, g = 122, b = 32}, {r = 234, g = 214, b = 172}, {r = 128, g = 34, b = 52}}
        for i = 1, math.min(4 + count, 9) do
            local px = sx + (Roll() * 2 - 1) * (SideRX - 70)
            local py = sy - 2 + (Roll() * 2 - 1) * (SideRY - 26)
            local color = Darken(colors[(i - 1) % 3 + 1], burnish)
            local ang = (Roll() - 0.5) * 1.4
            FoodShadow(px, py, 24)
            RotEllipse(cv, px, py, 27, 9.5, ang, color)
            cv:circle(px + math.cos(ang) * 24, py + math.sin(ang) * 9, 4.6, Darken(color, 0.55))
            cv:circle(px - math.cos(ang) * 24, py - math.sin(ang) * 9, 3.4, Darken(color, 0.3))
            RotEllipse(cv, px - math.cos(ang) * 5, py - math.sin(ang) * 3 - 3, 12, 3.6, ang, WithAlpha(Brighten(color, 0.32), 160))
        end
    elseif letter == "P" then
        local mash = Darken({r = 234, g = 218, b = 182}, burnish)
        cv:ellipse(sx, sy + 6, 78, 24, Darken(mash, 0.32))
        cv:ellipse(sx, sy - 4, 74, 28, Darken(mash, 0.14))
        cv:ellipse(sx - 3, sy - 14, 62, 24, mash)
        cv:ellipse(sx - 5, sy - 26, 42, 15, Brighten(mash, 0.07))
        for i = 1, 3 do
            local arc = EllipseArc(sx - 3, sy - 10 - i * 6, 56 - i * 11, 18 - i * 4, math.pi * (0.65 + 0.12 * i), math.pi * (1.85 + 0.12 * i), 14)
            cv:polyline(arc, WithAlpha(Darken(mash, 0.26), 170), 3.2)
        end
        cv:polyline(EllipseArc(sx - 22, sy - 22, 20, 8, math.pi * 0.9, math.pi * 1.6, 10), WithAlpha(White, 90), 3)
        cv:ellipse(sx - 4, sy - 24, 14, 6, Darken(mash, 0.22))
        cv:ellipse(sx - 4, sy - 23, 12, 5, {r = 234, g = 174, b = 52, a = 250})
        cv:ellipse(sx - 8, sy - 24, 5, 2, {r = 252, g = 216, b = 108, a = 230})
        local drip = {}
        for i = 0, 7 do
            local t = i / 7
            table.insert(drip, {sx + 6 + t * 10 + t * t * 22, sy - 20 + t * 40})
        end
        cv:polyline(drip, {r = 234, g = 174, b = 52, a = 215}, 3.6)
        cv:circle(sx + 38, sy + 21, 3, {r = 234, g = 174, b = 52, a = 225})
        if hot then
            SteamFrom(steam, sx, sy - 28, 90, Brighten(mash, 0.4), Roll)
        end
    elseif letter == "G" then
        local rice = Darken({r = 240, g = 234, b = 216}, burnish)
        cv:ellipse(sx, sy + 4, 74, 26, Darken(rice, 0.22))
        cv:ellipse(sx, sy - 4, 70, 28, Darken(rice, 0.1))
        cv:ellipse(sx - 3, sy - 12, 58, 22, rice)
        cv:ellipse(sx - 8, sy - 20, 34, 11, Brighten(rice, 0.06))
        for _ = 1, 34 do
            cv:ellipse(sx + (Roll() * 2 - 1) * 52, sy - 10 + (Roll() * 2 - 1) * 16, 3.2, 1.5, WithAlpha(Darken(rice, 0.22), 170))
        end
        for _ = 1, 6 do
            cv:ellipse(sx + (Roll() * 2 - 1) * 78, sy + 22 + Roll() * 8, 3, 1.4, WithAlpha(rice, 230))
        end
        if hot then
            SteamFrom(steam, sx, sy - 18, 84, Brighten(rice, 0.3), Roll)
        end
    elseif letter == "S" then
        local greens = {{r = 92, g = 138, b = 52}, {r = 148, g = 182, b = 78}}
        for i = 1, 16 do
            local px = sx + (Roll() * 2 - 1) * 64
            local py = sy - 8 + (Roll() * 2 - 1) * 18 - (i % 3) * 4
            local color = greens[(i % 2) + 1]
            local points = {}
            for k = 0, 6 do
                local a = k / 7 * math.pi * 2 + Roll()
                local rr = (13 + Roll() * 9)
                table.insert(points, {px + math.cos(a) * rr, py + math.sin(a) * rr * 0.55})
            end
            cv:polygon(points, WithAlpha(color, 240))
            cv:polyline({{px - 8, py + 2}, {px + 2, py - 4}, {px + 9, py + 1}}, WithAlpha(Darken(color, 0.3), 180), 1.8)
            if side.Tossed or side.Butter then
                cv:line(px - 5, py - 4, px + 5, py - 6, WithAlpha(White, 100), 2)
            end
        end
        for i = 1, 4 do
            local px = sx + (Roll() * 2 - 1) * 56
            local py = sy - 6 + (Roll() * 2 - 1) * 14
            cv:circle(px, py, 9, {r = 204, g = 54, b = 40, a = 255})
            cv:circle(px - 3, py - 3, 3.2, {r = 244, g = 130, b = 100, a = 200})
        end
    elseif letter == "C" then
        local wedges = {
            {color = {r = 240, g = 228, b = 190}, w = 40},
            {color = {r = 232, g = 176, b = 70}, w = 46},
            {color = {r = 226, g = 222, b = 204}, w = 36, blue = true},
        }
        for i, wedge in ipairs(wedges) do
            local px = sx - 66 + (i - 1) * 58
            local py = sy - 2 + (i % 2) * 12
            FoodShadow(px, py + 6, wedge.w * 0.6)
            cv:polygon({{px - wedge.w / 2, py + 10}, {px + wedge.w / 2, py + 10}, {px + wedge.w * 0.28, py - 16}, {px - wedge.w * 0.3, py - 14}}, wedge.color)
            cv:polygon({{px - wedge.w / 2, py + 10}, {px + wedge.w / 2, py + 10}, {px + wedge.w / 2, py + 15}, {px - wedge.w / 2, py + 15}}, Darken(wedge.color, 0.22))
            if wedge.blue then
                for _ = 1, 7 do
                    cv:circle(px + (Roll() * 2 - 1) * wedge.w * 0.3, py - 2 + (Roll() * 2 - 1) * 8, 1.8, {r = 88, g = 108, b = 130, a = 200})
                end
            end
        end
        cv:polygon({{sx + 46, sy + 18}, {sx + 78, sy + 14}, {sx + 76, sy + 20}, {sx + 48, sy + 23}}, {r = 240, g = 228, b = 190, a = 255})
    elseif letter == "E" then
        for i = 1, math.min(count + 1, 5) do
            local px = sx - 60 + ((i - 1) % 3) * 56
            local py = sy - 10 + ((i - 1) // 3) * 26
            FoodShadow(px, py + 6, 18)
            cv:ellipse(px, py, 19, 12, {r = 242, g = 238, b = 226, a = 255})
            cv:strokeEllipse(px, py, 19, 12, {r = 202, g = 194, b = 176, a = 255})
            cv:ellipse(px, py, 10, 6.6, {r = 240, g = 178, b = 56, a = 255})
            cv:strokeEllipse(px, py, 10, 6.6, {r = 202, g = 138, b = 34, a = 255})
            cv:ellipse(px - 3, py - 2, 3, 2, WithAlpha(White, 170))
        end
    elseif letter == "F" then
        for i = 1, 9 do
            local px = sx - 20 + ((i - 1) % 3) * 16 - ((i - 1) // 3) * 8
            local py = sy - 14 + ((i - 1) // 3) * 10
            cv:circle(px, py, 8, {r = 96, g = 52, b = 110, a = 255})
            cv:circle(px - 2, py - 2, 2.6, {r = 170, g = 120, b = 190, a = 170})
        end
        for i = 1, 3 do
            cv:circle(sx - 44 + i * 9, sy + 18 + i * 4, 8 - i, {r = 96, g = 52, b = 110, a = 255})
        end
        cv:ellipse(sx + 52, sy - 4, 14, 10, {r = 122, g = 72, b = 48, a = 255})
        cv:ellipse(sx + 52, sy - 2, 9, 6, {r = 196, g = 74, b = 66, a = 255})
        cv:ellipse(sx - 62, sy + 2, 13, 7, {r = 214, g = 190, b = 130, a = 255})
        cv:polyline(EllipseArc(sx - 62, sy + 2, 13, 7, math.pi, math.pi * 2, 10), {r = 160, g = 130, b = 80, a = 200}, 1.6)
    elseif letter == "M" then
        for i = 1, math.min(5 + count, 10) do
            local px = sx + (Roll() * 2 - 1) * (SideRX - 74)
            local py = sy - 2 + (Roll() * 2 - 1) * (SideRY - 26)
            local r = 17 + Roll() * 7
            local color = Darken({r = 168, g = 124, b = 78}, burnish)
            FoodShadow(px, py, r)
            cv:ellipse(px, py, r, r * 0.62, color)
            cv:ellipse(px - r * 0.25, py - r * 0.2, r * 0.4, r * 0.2, WithAlpha(Brighten(color, 0.35), 170))
            cv:polyline(EllipseArc(px, py + r * 0.3, r * 0.8, r * 0.24, 0.2, math.pi - 0.2, 8), WithAlpha(Darken(color, 0.4), 170), 1.6)
        end
    elseif letter == "B" then
        for i = 1, 8 do
            local px = sx + (Roll() * 2 - 1) * (SideRX - 70)
            local py = sy - 2 + (Roll() * 2 - 1) * (SideRY - 28)
            local ribbon = {}
            local phase = Roll() * math.pi
            for k = 0, 8 do
                local t = k / 8
                table.insert(ribbon, {px - 20 + t * 40, py + math.sin(phase + t * math.pi * 1.6) * 7})
            end
            cv:polyline(ribbon, {r = 94, g = 44, b = 26, a = 60}, 9)
            cv:polyline(ribbon, {r = 38, g = 82, b = 40, a = 255}, 7)
            cv:polyline(TopStrip(ribbon, -2), WithAlpha({r = 96, g = 150, b = 74}, 200), 3)
        end
        cv:ellipse(sx - 10, sy - 6, 10, 4, WithAlpha({r = 250, g = 226, b = 130}, 150))
    elseif letter == "O" then
        for i = 1, math.min(3 + count, 7) do
            local px = sx + (Roll() * 2 - 1) * (SideRX - 72)
            local py = sy - 2 + (Roll() * 2 - 1) * (SideRY - 26)
            local r = 15 + Roll() * 5
            local color = Darken({r = 202, g = 138, b = 60}, burnish)
            FoodShadow(px, py, r)
            cv:ellipse(px, py, r, r * 0.6, color)
            for ring = 1, 3 do
                cv:polyline(EllipseArc(px, py, r * (1 - ring * 0.24), r * 0.6 * (1 - ring * 0.24), math.pi * 0.1, math.pi * 1.9, 12), WithAlpha(Darken(color, 0.35), 160), 1.8)
            end
            cv:polyline(EllipseArc(px, py - 1, r * 0.8, r * 0.4, math.pi, math.pi * 2, 10), WithAlpha(Brighten(color, 0.4), 130), 2)
        end
    elseif letter == "L" then
        for i = 1, math.min(3 + count, 7) do
            local px = sx + (Roll() * 2 - 1) * (SideRX - 74)
            local py = sy + (Roll() * 2 - 1) * (SideRY - 26)
            local ang = (Roll() - 0.5) * 1.2
            FoodShadow(px, py, 17)
            RotEllipse(cv, px, py, 20, 8, ang, {r = 92, g = 122, b = 44})
            for _ = 1, 6 do
                cv:circle(px + (Roll() * 2 - 1) * 14, py + (Roll() * 2 - 1) * 5, 1.2, {r = 130, g = 160, b = 70, a = 220})
            end
            RotEllipse(cv, px - 4, py - 3, 8, 2.4, ang, WithAlpha({r = 150, g = 180, b = 90}, 150))
        end
    end

    if side.Cream then
        cv:ellipse(sx + 34, sy - 14, 13, 7, {r = 246, g = 240, b = 226, a = 245})
        cv:ellipse(sx + 31, sy - 17, 7, 4, {r = 255, g = 252, b = 244, a = 220})
    end
    if side.Pepper > 0 then
        for _ = 1, math.min(side.Pepper * 5, 22) do
            cv:circle(sx + (Roll() * 2 - 1) * (SideRX - 60), sy + (Roll() * 2 - 1) * (SideRY - 24), 1.1, {r = 34, g = 26, b = 18, a = 220})
        end
    end
    if side.Salt > 0 then
        for _ = 1, math.min(side.Salt * 5, 18) do
            cv:circle(sx + (Roll() * 2 - 1) * (SideRX - 60), sy + (Roll() * 2 - 1) * (SideRY - 26), 1.2, {r = 246, g = 246, b = 240, a = 210})
        end
    end
    if side.Turned then
        TurnedOverlay(cv, steam, sx, sy, SideRX - 40, SideRY - 14, Roll)
    end
    if cold then
        BeadsOn(cv, SideX, SideY, SideRX - 20, SideRY - 6, 7, Roll)
    end
end

local function ScoreCut(cv: Canvas, x0: number, y0: number, x1: number, y1: number, crumb, deep: boolean)
    local mx, my = (x0 + x1) / 2, (y0 + y1) / 2
    local ang = math.atan2(y1 - y0, x1 - x0)
    local len = math.sqrt((x1 - x0) ^ 2 + (y1 - y0) ^ 2)
    cv:line(x0, y0, x1, y1, {r = 44, g = 28, b = 14, a = 230}, if deep then 6 else 4.4)
    RotEllipse(cv, mx - 1.4, my - 1.6, len * 0.42, if deep then 3.4 else 2.6, ang, WithAlpha(crumb, 245), 14)
    cv:line(x0 + 1, y0 + 1, x1 + 1, y1 + 1, {r = 60, g = 38, b = 20, a = 140}, 1.4)
end

local function BreadBoard(cv: Canvas, steam: Canvas, banquet, hot: boolean, tilt: number, Roll: () -> number)
    local bread = banquet.Bread
    local bx, by = BoardX, BoardY
    local boardTilt = -0.105 + tilt

    RotEllipse(cv, bx, by + 8, BoardRX, BoardRY, boardTilt, BoardWoodDark, 56)
    RotEllipse(cv, bx, by, BoardRX, BoardRY, boardTilt, BoardWood, 56)
    for i = 1, 3 do
        cv:polyline(EllipseArc(bx, by, BoardRX - 20 - i * 26, BoardRY - 8 - i * 7, math.pi * 1.1 + boardTilt, math.pi * 1.9 + boardTilt, 14), WithAlpha(BoardWoodDark, 90), 2)
    end
    local hx = bx + math.cos(boardTilt) * (BoardRX + 14)
    local hy = by + math.sin(boardTilt) * (BoardRX + 14)
    cv:circle(hx, hy + 2, 16, BoardWoodDark)
    cv:circle(hx, hy, 15, BoardWood)
    cv:circle(hx, hy, 5, Darken(BoardWoodDark, 0.3))

    if bread.BareBoard then
        for _ = 1, 16 do
            cv:circle(bx + (Roll() * 2 - 1) * (BoardRX - 50), by + (Roll() * 2 - 1) * (BoardRY - 18), 1.5, {r = 238, g = 226, b = 200, a = 120})
        end
        return
    end
    if not bread.Real then
        return
    end

    local flour = Larder.GetFlour(bread.Flour)
    local crust = flour.Crust
    if bread.CrustBand == "pale" then
        crust = Brighten(crust, 0.3)
    elseif bread.CrustBand == "amber" then
        crust = Darken(crust, 0.12)
    elseif bread.CrustBand == "bold" then
        crust = Darken(crust, 0.3)
    elseif bread.CrustBand == "burnt" then
        crust = {r = 34, g = 28, b = 24}
    end
    local crumb = flour.Crumb
    local shape = bread.Shape
    local flatten = if bread.Deflated then 0.62 else 1

    local function LoafShine(lx: number, ly: number, lrx: number, lry: number)
        cv:polyline(EllipseArc(lx - lrx * 0.2, ly - lry * 0.5, lrx * 0.5, lry * 0.4, math.pi, math.pi * 1.7, 10), WithAlpha(White, if bread.Gloss then 120 else 60), 4)
    end

    if shape == "O" then
        local lrx, lry = 86, 58 * flatten
        cv:ellipse(bx + 4, by + 10, lrx, lry * 0.42, WithAlpha(Black, 100))
        cv:ellipse(bx, by - lry * 0.32, lrx, lry, Darken(crust, 0.18))
        cv:ellipse(bx - 3, by - lry * 0.4, lrx * 0.94, lry * 0.94, crust)
        LoafShine(bx, by - lry * 0.4, lrx, lry)
        for _ = 1, 10 do
            cv:circle(bx - lrx * 0.3 + (Roll() * 2 - 1) * lrx * 0.36, by - lry * 0.8 + Roll() * lry * 0.3, 1.6, WithAlpha(White, 90))
        end
        local topY = by - lry * 0.86
        if bread.Cuts == 1 then
            local ear = {}
            for i = 0, 10 do
                local t = i / 10
                table.insert(ear, {bx - 52 + t * 100, topY + 16 - math.sin(t * math.pi) * 14 - t * 10})
            end
            cv:polyline(ear, {r = 44, g = 28, b = 14, a = 235}, 6.5)
            cv:polyline(TopStrip(ear, -2.2), WithAlpha(crumb, 245), 3.4)
            cv:polyline(TopStrip(ear, 2), {r = 60, g = 38, b = 20, a = 140}, 1.6)
        elseif bread.Cuts == 2 then
            ScoreCut(cv, bx - 40, topY + 8, bx + 40, topY + 12, crumb, true)
            ScoreCut(cv, bx - 4, topY - 12, bx + 6, topY + 34, crumb, false)
        elseif bread.Cuts == 3 then
            for i = -1, 1 do
                ScoreCut(cv, bx - 36 + i * 6, topY + 4 + i * 16, bx + 36 + i * 6, topY + 12 + i * 16, crumb, i == 0)
            end
        elseif bread.Cuts == 4 then
            cv:line(bx - 50, topY + 18, bx + 50, topY + 4, {r = 44, g = 28, b = 14, a = 220}, 3)
            for i = 0, 5 do
                local t = i / 5
                local px = bx - 42 + t * 84
                local py = topY + 16 - t * 12
                local side = if i % 2 == 0 then -1 else 1
                ScoreCut(cv, px, py, px + 16, py + side * 13, crumb, false)
            end
        elseif bread.Cuts >= 5 then
            for i = 1, 6 do
                ScoreCut(cv, bx - 48 + i * 13 + (Roll() - 0.5) * 8, topY + 6 + (Roll() - 0.5) * 18, bx - 34 + i * 13, topY + 18 + (Roll() - 0.5) * 16, crumb, false)
            end
        end
        if bread.Burst then
            local tear = {}
            for i = 0, 7 do
                table.insert(tear, {bx - 40 + i * 12, topY + 14 + (Roll() - 0.5) * 12})
            end
            cv:polyline(tear, {r = 44, g = 28, b = 14, a = 240}, 7)
            cv:polyline(TopStrip(tear, 1), WithAlpha(crumb, 230), 3.4)
        end
    elseif shape == "I" then
        local ang = boardTilt - 0.14
        local lrx, lry = 140, 32 * flatten
        for _ = 1, 14 do
            cv:circle(bx + (Roll() * 2 - 1) * (BoardRX - 30), by + (Roll() * 2 - 1) * (BoardRY - 14), 1.6, {r = 238, g = 226, b = 200, a = 110})
        end
        cv:ellipse(bx + 6, by + 14, lrx * 0.94, 14, WithAlpha(Black, 140))
        RotEllipse(cv, bx + 2, by - 14, lrx, lry + 4, ang, Darken(crust, 0.35), 44)
        RotEllipse(cv, bx - 2, by - 20, lrx * 0.97, lry, ang, crust, 44)
        local topHl = {}
        for i = 0, 12 do
            local t = i / 12 - 0.5
            table.insert(topHl, {bx + math.cos(ang) * lrx * 1.6 * t, by - 20 + math.sin(ang) * lrx * 1.6 * t - lry * 0.72})
        end
        cv:polyline(SubStrip(topHl, 0.1, 0.6), WithAlpha(Brighten(crust, 0.4), 140), 5)
        for _ = 1, 10 do
            cv:circle(bx + (Roll() * 2 - 1) * lrx * 0.6, by - 22 + (Roll() * 2 - 1) * 10, 1.5, WithAlpha(White, 90))
        end
        if bread.Cuts >= 1 then
            local n = if bread.Cuts >= 5 then 6 else math.max(bread.Cuts, 3)
            for i = 1, n do
                local t = (i - 0.5) / n - 0.5
                local px = bx + math.cos(ang) * lrx * 1.6 * t
                local py = by - 22 + math.sin(ang) * lrx * 1.6 * t
                ScoreCut(cv, px - 15, py - 2, px + 11, py - 13, crumb, true)
            end
        elseif bread.Burst then
            local tear = {}
            for i = 0, 6 do
                table.insert(tear, {bx - 60 + i * 20, by - 24 + (Roll() - 0.5) * 10 + i * math.sin(ang) * 18})
            end
            cv:polyline(tear, {r = 44, g = 28, b = 14, a = 240}, 6)
            cv:polyline(TopStrip(tear, 1), WithAlpha(crumb, 230), 3)
        end
    elseif shape == "B" then
        local lobes = 7
        local lrx = 100
        cv:ellipse(bx + 5, by + 12, lrx + 14, 24, WithAlpha(Black, 100))
        RotEllipse(cv, bx, by - 8, lrx + 10, 30 * flatten, boardTilt, Darken(crust, 0.32), 36)
        for i = lobes, 1, -1 do
            local t = (i - 0.5) / lobes - 0.5
            local px = bx + math.cos(boardTilt) * (lrx * 1.8) * t
            local py = by - 12 + math.sin(boardTilt) * (lrx * 1.8) * t
            local side = if i % 2 == 0 then -1 else 1
            local lobeAng = boardTilt + side * 0.5
            RotEllipse(cv, px + side * 2 + 3, py + side * 7 + 5, 33, 22 * flatten, lobeAng, WithAlpha(Darken(crust, 0.4), 180), 24)
            RotEllipse(cv, px + side * 1, py + side * 7 - 4, 34, 23 * flatten, lobeAng, crust, 24)
            RotEllipse(cv, px - 7, py + side * 7 - 12, 13, 7 * flatten, lobeAng, WithAlpha(Brighten(crust, 0.28), 160), 14)
            cv:line(px - 24, py + side * 18, px - 32, py - side * 16, WithAlpha(Darken(crust, 0.55), 200), 3.4)
        end
        if bread.Cuts >= 1 and bread.Cuts <= 4 then
            for i = 1, math.min(bread.Cuts, 4) do
                local t = (i - 0.5) / math.min(bread.Cuts, 4) - 0.5
                local px = bx + math.cos(boardTilt) * (lrx * 1.5) * t
                local py = by - 22 + math.sin(boardTilt) * (lrx * 1.5) * t
                ScoreCut(cv, px - 10, py + 4, px + 10, py - 6, crumb, false)
            end
        end
        LoafShine(bx - 30, by - 30, 50, 16)
    elseif shape == "R" then
        local n = math.clamp(bread.RollCount, 1, 5)
        local spots = {{-52, 6}, {6, 10}, {58, 2}, {-22, -14}, {34, -16}}
        for i = 1, n do
            local px = bx + spots[i][1]
            local py = by + spots[i][2] - 6
            local r = 26
            cv:ellipse(px + 3, py + 12, r, 9, WithAlpha(Black, 100))
            cv:ellipse(px, py, r, r * 0.72 * flatten, Darken(crust, 0.18))
            cv:ellipse(px - 2, py - 3, r * 0.92, r * 0.66 * flatten, crust)
            cv:ellipse(px - 8, py - 9, r * 0.4, r * 0.2, WithAlpha(White, 70))
            if bread.Cuts >= 1 then
                ScoreCut(cv, px - 12, py - 4, px + 10, py - 8, crumb, false)
            end
        end
    elseif shape == "F" then
        local lrx, lry = 96, 34
        cv:ellipse(bx + 4, by + 8, lrx, lry * 0.5, WithAlpha(Black, 90))
        cv:ellipse(bx, by - 4, lrx, lry, Darken(crust, 0.12))
        cv:ellipse(bx - 2, by - 6, lrx * 0.95, lry * 0.92, Brighten(crumb, 0.05))
        for _ = 1, 12 do
            local px = bx + (Roll() * 2 - 1) * lrx * 0.7
            local py = by - 6 + (Roll() * 2 - 1) * lry * 0.6
            cv:ellipse(px, py, 5 + Roll() * 4, 3 + Roll() * 2, WithAlpha(Darken(crust, 0.4), 150))
        end
        for _ = 1, 6 do
            cv:ellipse(bx + (Roll() * 2 - 1) * lrx * 0.6, by - 8 + (Roll() * 2 - 1) * lry * 0.5, 4, 2.4, WithAlpha(Brighten(crust, 0.3), 130))
        end
        local notch = {}
        for i = 0, 5 do
            table.insert(notch, {bx + lrx * 0.66 + (Roll() - 0.5) * 6, by - 18 + i * 6})
        end
        cv:polyline(notch, WithAlpha(Darken(crust, 0.5), 200), 3)
    end

    if bread.Seeds then
        for _ = 1, 26 do
            local px = bx + (Roll() * 2 - 1) * 60
            local py = by - 34 + (Roll() * 2 - 1) * 20
            cv:ellipse(px, py, 2, 1.2, {r = 66, g = 44, b = 22, a = 230})
        end
    end
    if bread.SaltCrystals then
        for _ = 1, 14 do
            cv:circle(bx + (Roll() * 2 - 1) * 56, by - 32 + (Roll() * 2 - 1) * 16, 1.4, {r = 248, g = 248, b = 242, a = 220})
        end
    end
    if bread.Rosemary then
        for _ = 1, 8 do
            local px = bx + (Roll() * 2 - 1) * 52
            local py = by - 32 + (Roll() * 2 - 1) * 16
            cv:line(px, py, px + 6, py - 4, {r = 74, g = 104, b = 52, a = 230}, 1.8)
            cv:line(px + 2, py - 1, px + 3, py - 6, {r = 74, g = 104, b = 52, a = 200}, 1.4)
        end
    end
    if bread.Gloss and hot then
        cv:ellipse(bx - 6, by - 44, 8, 5, {r = 244, g = 206, b = 96, a = 230})
        cv:line(bx - 2, by - 40, bx + 2, by - 28, {r = 244, g = 206, b = 96, a = 160}, 3)
    end
    if bread.Crock then
        local cx, cy = bx - BoardRX + 34, by + 26
        cv:ellipse(cx + 2, cy + 14, 24, 7, WithAlpha(Black, 110))
        local y = cy - 12
        while y <= cy + 10 do
            local t = (y - cy + 12) / 22
            cv:line(cx - 20 + t * 3, y, cx + 20 - t * 3, y, WithAlpha(BlendRGB({r = 190, g = 170, b = 150}, {r = 110, g = 92, b = 76}, t), 255), 2)
            y += 2
        end
        cv:ellipse(cx, cy - 12, 20, 7, {r = 208, g = 190, b = 168, a = 255})
        cv:ellipse(cx, cy - 12, 16, 5, {r = 248, g = 238, b = 210, a = 255})
        cv:polyline(EllipseArc(cx, cy - 13, 9, 3, math.pi * 0.2, math.pi * 1.6, 8), {r = 255, g = 250, b = 230, a = 230}, 2.4)
    end
    if bread.CrustBand == "burnt" then
        SteamFrom(steam, bx, by - 40, 90, {r = 120, g = 116, b = 110}, Roll)
    end
    if bread.Turned then
        TurnedOverlay(cv, steam, bx, by - 10, 90, 34, Roll)
    end
end

local function Candle(cv: Canvas, ember: Canvas, x: number, y: number, height: number, guttering: boolean, Roll: () -> number)
    cv:ellipse(x + 4, y + 8, 34, 9, WithAlpha(Black, 110))
    cv:ellipse(x, y + 2, 30, 9, {r = 132, g = 96, b = 44, a = 255})
    cv:ellipse(x, y, 26, 7, {r = 168, g = 126, b = 58, a = 255})
    local top = y - height
    local w = 9
    local yy = top
    while yy <= y do
        local t = (yy - top) / height
        cv:line(x - w + t, yy, x + w - t * 0.5, yy, WithAlpha(BlendRGB({r = 238, g = 226, b = 196}, {r = 176, g = 158, b = 126}, t * 0.8), 255), 2)
        yy += 1.5
    end
    cv:line(x - w + 2, top + 6, x - w + 3, y - 8, WithAlpha(White, 70), 2.4)
    for i = 1, 3 do
        local dx = x - w + 1 + (i - 1) * 5
        cv:line(dx, top + 8 + i * 6, dx - 1, top + 22 + i * 8, {r = 246, g = 238, b = 214, a = 220}, 3)
        cv:circle(dx - 1, top + 23 + i * 8, 2, {r = 246, g = 238, b = 214, a = 230})
    end
    cv:ellipse(x, top, w - 1, 3, {r = 214, g = 198, b = 164, a = 255})
    cv:line(x, top, x, top - 7, {r = 40, g = 30, b = 20, a = 255}, 2)
    local flameH = if guttering then 12 else 20
    local fy = top - 8
    ember:ellipse(x, fy - flameH / 2, 6, flameH * 0.7, {r = 255, g = 168, b = 40, a = 230})
    ember:ellipse(x, fy - flameH / 2 + 2, 3.4, flameH * 0.42, {r = 255, g = 232, b = 150, a = 250})
    ember:circle(x, fy - flameH / 2, 18, WithAlpha({r = 255, g = 170, b = 60}, 26))
    ember:circle(x, fy - flameH / 2, 30, WithAlpha({r = 255, g = 150, b = 50}, 14))
    ember:circle(x, fy - flameH / 2, 46, WithAlpha({r = 255, g = 140, b = 40}, 8))
end

local function Goblet(cv: Canvas, x: number, y: number, s: number, cold: boolean, Roll: () -> number)
    cv:ellipse(x + 4, y + 66 * s, 30 * s, 8 * s, WithAlpha(Black, 110))
    cv:ellipse(x, y + 62 * s, 26 * s, 7 * s, {r = 96, g = 78, b = 52, a = 255})
    cv:line(x, y + 60 * s, x, y + 24 * s, {r = 120, g = 98, b = 64, a = 255}, 7 * s)
    cv:line(x - 1, y + 56 * s, x - 1, y + 26 * s, WithAlpha(White, 50), 2)
    local cy = y
    local yy = cy - 26 * s
    while yy <= cy + 24 * s do
        local t = (yy - (cy - 26 * s)) / (50 * s)
        local hw = 30 * s * (1 - 0.65 * t * t)
        cv:line(x - hw, yy, x + hw, yy, WithAlpha(BlendRGB({r = 150, g = 122, b = 78}, {r = 74, g = 58, b = 38}, t), 255), 2)
        yy += 1.6
    end
    cv:ellipse(x, cy - 26 * s, 30 * s, 9 * s, {r = 168, g = 140, b = 92, a = 255})
    cv:ellipse(x, cy - 25 * s, 26 * s, 7 * s, {r = 84, g = 22, b = 34, a = 255})
    cv:ellipse(x - 8 * s, cy - 26 * s, 9 * s, 2.6 * s, WithAlpha({r = 220, g = 120, b = 130}, 130))
    cv:line(x - 20 * s, cy - 18 * s, x - 16 * s, cy + 12 * s, WithAlpha(White, 60), 2.4)
    if cold then
        BeadsOn(cv, x, cy, 22 * s, 26 * s, 5, Roll)
    end
end

local function MenuCard(cv: Canvas, text: string, Roll: () -> number)
    local cw, ch = 200, 70
    local x0, y0 = CardX - cw / 2, CardY - ch / 2
    cv:polygon({{x0 + 8, y0 + ch}, {x0 + cw + 12, y0 + ch}, {x0 + cw + 2, y0 + ch + 10}, {x0 - 2, y0 + ch + 10}}, WithAlpha(Black, 90))
    cv:polygon({{x0, y0}, {x0 + cw, y0}, {x0 + cw + 10, y0 + ch}, {x0 - 10, y0 + ch}}, {r = 234, g = 226, b = 204, a = 255})
    cv:polygon({{x0, y0}, {x0 + cw, y0}, {x0 + cw - 6, y0 - 12}, {x0 + 6, y0 - 12}}, {r = 206, g = 196, b = 172, a = 255})
    cv:line(x0, y0, x0 + cw, y0, {r = 150, g = 140, b = 118, a = 200}, 2)
    if CardFont then
        local font = CardFont :: CanvasFont
        local size = 34
        local width, height = font:measure(text, size)
        while size > 12 and width > cw - 24 do
            size -= 2
            width, height = font:measure(text, size)
        end
        cv:text(text, CardX - width / 2, y0 + ch / 2 - height / 2 + 2, size, {r = 62, g = 48, b = 34, a = 235}, font)
    else
        cv:line(x0 + 24, y0 + ch / 2, x0 + cw - 24, y0 + ch / 2, {r = 62, g = 48, b = 34, a = 220}, 4)
    end
end

function module.Render(banquet): Canvas
    local seed = banquet.Seed or "empty"
    local RollE = NewRoll(HashString(`{seed}|E`))
    local RollS = NewRoll(HashString(`{seed}|S`))
    local RollB = NewRoll(HashString(`{seed}|B`))
    local RollT = NewRoll(HashString(`{seed}|T`))

    local hot = banquet.TempKey == "piping" or banquet.TempKey == "steaming"
    local cold = banquet.TempKey == "cold" or banquet.TempKey == "vigil"
    local potluck = banquet.Potluck

    local base = canvas.new(W, H, {r = 13, g = 10, b = 14, a = 255})

    local mood = {r = 110, g = 70, b = 34}
    if banquet.Poisoned then
        mood = {r = 86, g = 110, b = 46}
    elseif cold then
        mood = {r = 52, g = 74, b = 118}
    elseif banquet.TempKey == "piping" or (banquet.Entree and banquet.Entree.Kind == "phoenix") then
        mood = {r = 150, g = 84, b = 30}
    end
    for i = 9, 1, -1 do
        base:circle(PX, 400, 430 * i / 9, WithAlpha(mood, 8))
    end

    base:polygon({{0, TableY}, {W, TableY}, {W, H}, {0, H}}, {r = 46, g = 32, b = 24, a = 255})
    base:line(0, TableY, W, TableY, {r = 86, g = 60, b = 40, a = 255}, 3)
    base:line(0, TableY + 3, W, TableY + 3, {r = 24, g = 16, b = 12, a = 255}, 2)
    local plankGaps = {64, 88, 118, 150}
    local plankY = TableY
    for _, gap in ipairs(plankGaps) do
        plankY += gap
        base:line(0, plankY, W, plankY, {r = 30, g = 20, b = 14, a = 255}, 3)
        base:line(0, plankY + 3, W, plankY + 3, {r = 66, g = 46, b = 32, a = 90}, 2)
    end
    for _ = 1, 9 do
        local gy = TableY + 16 + RollT() * (H - TableY - 30)
        local points = {}
        for i = 0, 14 do
            local t = i / 14
            table.insert(points, {t * W, gy + math.sin(t * math.pi * (1.5 + RollT())) * 3})
        end
        base:polyline(points, {r = 28, g = 19, b = 13, a = 60}, 2)
    end

    for i = 4, 1, -1 do
        base:ellipse(CandleX + 10, 470, 90 * i, 34 * i, WithAlpha({r = 200, g = 140, b = 60}, 7))
    end

    local dishes = canvas.new(W, H, {r = 0, g = 0, b = 0, a = 0})
    local ember = canvas.new(W, H, {r = 0, g = 0, b = 0, a = 0})
    local steam = canvas.new(W, H, {r = 0, g = 0, b = 0, a = 0})

    if banquet.Bare then
        ContactShadow(base, CandleX, 452, 40, 12)
        Candle(dishes, ember, CandleX, 448, 74, true, RollT)
        local glowed = ember:clone():glow(6, WithAlpha({r = 255, g = 170, b = 60}, 90), 0.9)
        local merged = base:merge(glowed, "add"):merge(dishes, "normal"):merge(ember, "normal")
        return merged:vignette(0.33)
    end

    local tilt = if potluck then (RollT() - 0.5) * 0.1 else 0
    local sideTilt = if potluck then (RollT() - 0.5) * 0.12 else 0
    local boardExtra = if potluck then (RollT() - 0.5) * 0.14 else 0

    ContactShadow(base, PX, PY + 8, PRX + 14, PRY + 22)
    base:ellipse(440, 600, 230, 58, WithAlpha(Black, 28))
    base:ellipse(830, 596, 240, 62, WithAlpha(Black, 26))
    if banquet.Side.Present then
        ContactShadow(base, SideX, SideY + 4, SideRX + 8, SideRY + 8)
    end
    if banquet.Bread.Present then
        ContactShadow(base, BoardX, BoardY + 4, BoardRX + 8, BoardRY + 10)
    end
    if banquet.Boat.Present then
        ContactShadow(base, BoatX, BoatY + 22, 84, 18)
    end
    local candleSpots = {{0, 0}, {-58, 22}, {52, 30}}
    for i = 1, banquet.Candles do
        ContactShadow(base, CandleX + candleSpots[i][1], 452 + candleSpots[i][2], 38, 11)
    end
    if banquet.Goblets >= 1 then
        ContactShadow(base, GobletX, GobletY + 66, 32, 10)
    end
    if banquet.Goblets >= 2 then
        ContactShadow(base, GobletX + 64, GobletY + 96, 26, 9)
    end
    if banquet.MenuCard then
        ContactShadow(base, CardX, CardY + 34, 110, 14)
    end

    if banquet.Goblets >= 1 then
        Goblet(dishes, GobletX, GobletY, 1, cold, RollT)
    end
    if banquet.Goblets >= 2 then
        Goblet(dishes, GobletX + 64, GobletY + 34, 0.82, cold, RollT)
    end
    for i = 1, banquet.Candles do
        Candle(dishes, ember, CandleX + candleSpots[i][1], 448 + candleSpots[i][2], 74 - (i - 1) * 12, false, RollT)
    end

    local platterTilt = tilt
    if platterTilt ~= 0 then
        RotEllipse(dishes, PX, PY, PRX, PRY, platterTilt, CeramicLight, 72)
        RotEllipse(dishes, PX, PY + 1, PRX - 14, PRY - 8, platterTilt, BlendRGB(CeramicLight, CeramicDark, 0.34), 72)
        RotEllipse(dishes, PX, PY + 2, PRX - 40, PRY - 18, platterTilt, BlendRGB(CeramicLight, CeramicDark, 0.1), 72)
    else
        dishes:ellipse(PX, PY, PRX, PRY, CeramicLight)
        dishes:polyline(EllipseArc(PX, PY, PRX - 2, PRY - 2, 0, math.pi * 2, 72), WithAlpha(Darken(CeramicLight, 0.35), 190), 2)
        dishes:ellipse(PX, PY + 1, PRX - 14, PRY - 8, BlendRGB(CeramicLight, CeramicDark, 0.34))
        dishes:ellipse(PX, PY + 2, PRX - 40, PRY - 18, BlendRGB(CeramicLight, CeramicDark, 0.1))
        dishes:polyline(EllipseArc(PX, PY + 1, PRX - 26, PRY - 13, 0.3, math.pi - 0.4, 40), WithAlpha(GlazeBand, 140), 5)
        dishes:polyline(EllipseArc(PX, PY + 1, PRX - 26, PRY - 13, math.pi + 0.4, math.pi * 2 - 0.3, 40), WithAlpha(GlazeBand, 190), 5)
    end
    dishes:polyline(EllipseArc(PX, PY, PRX * 0.8, PRY * 0.8, math.pi * 1.05, math.pi * 1.55, 24), WithAlpha(White, 60), 6)

    local entree = banquet.Entree
    if entree.Present then
        if (entree.Craft.R or 0) > 0 then
            dishes:ellipse(EX + 10, EY + 34, 190, 40, WithAlpha(JusColor, 210))
            dishes:ellipse(EX + 4, EY + 32, 150, 30, WithAlpha(Darken(JusColor, 0.2), 220))
            dishes:polyline(EllipseArc(EX - 30, EY + 26, 90, 18, math.pi, math.pi * 2, 16), WithAlpha(White, 40), 3)
        else
            dishes:ellipse(EX + 8, EY + 34, 150, 30, WithAlpha(Darken(JusColor, 0.1), 130))
        end
    end

    if entree.Present then
        local kind = entree.Kind
        if kind == "dragon" or kind == "wyvern" then
            DragonRoast(dishes, ember, banquet, RollE)
        elseif kind == "bird" then
            BirdRoast(dishes, ember, steam, banquet, RollE, false)
        elseif kind == "phoenix" then
            BirdRoast(dishes, ember, steam, banquet, RollE, true)
        elseif kind == "fish" then
            WholeFish(dishes, banquet, RollE)
        elseif kind == "noodle" then
            NoodlePile(dishes, banquet, RollE)
        elseif kind == "broth" then
            BrothBowl(dishes, steam, banquet, hot, RollE)
        elseif kind == "pie" then
            MeatPie(dishes, banquet, RollE)
        elseif kind == "skewer" then
            Skewers(dishes, banquet, RollE)
        elseif kind == "sausage" then
            Sausages(dishes, banquet, RollE)
        elseif kind == "shadow" then
            ShadowBeast(dishes, steam, banquet, RollE)
        else
            RoastJoint(dishes, ember, banquet, RollE)
        end
        DrawGarnishes(dishes, banquet, RollE)
        if (entree.Craft.H or 0) > 0 then
            for _ = 1, 3 do
                local sx = EX + (RollE() * 2 - 1) * 120
                SteamFrom(steam, sx, EY - 40 - RollE() * 20, 70 + RollE() * 40, {r = 168, g = 162, b = 152}, RollE)
            end
        end
        if hot and kind ~= "fish" and kind ~= "broth" then
            local wisps = if banquet.TempKey == "piping" then 4 else 2
            for _ = 1, wisps do
                SteamFrom(steam, EX + (RollE() * 2 - 1) * 110, EY - 50 - RollE() * 16, 120 + RollE() * 90, {r = 235, g = 225, b = 210}, RollE)
            end
        end
        if entree.Turned then
            TurnedOverlay(dishes, steam, EX, EY - 10, 180, 70, RollE)
        end
    elseif entree.Empty then
        Sprig(dishes, EX, EY + 10, 1.3, RollE)
    end
    if cold then
        BeadsOn(dishes, PX, PY, PRX - 30, PRY - 14, 10, RollT)
    end

    if banquet.Boat.Present then
        GravyBoat(dishes, banquet, cold, RollT)
    end

    if banquet.Side.Present then
        SideVessel(dishes, steam, banquet, hot, cold, sideTilt, RollS)
    end

    if banquet.Bread.Present then
        BreadBoard(dishes, steam, banquet, hot, boardExtra, RollB)
    end

    if potluck then
        for _ = 1, 16 do
            local px = 180 + RollT() * 840
            local py = 600 + RollT() * 260
            dishes:circle(px, py, 1.6 + RollT() * 1.4, WithAlpha(Wheat, 140))
        end
        dishes:ellipse(720, 640, 30, 10, WithAlpha(JusColor, 150))
        dishes:ellipse(736, 648, 12, 5, WithAlpha(JusColor, 130))
    end

    if banquet.MenuCard then
        MenuCard(dishes, banquet.MenuCard, RollT)
    end

    local glowColor = if banquet.Poisoned then {r = 130, g = 150, b = 70} else {r = 255, g = 170, b = 60}
    local glowed = ember:clone():glow(7, WithAlpha(glowColor, 100), 0.95)

    local merged = base:merge(glowed, "add"):merge(dishes, "normal"):merge(ember, "normal")
    local hasSteam = true
    if hasSteam then
        merged = merged:merge(steam:clone():glow(5, WithAlpha({r = 220, g = 210, b = 190}, 30), 0.5), "add"):merge(steam, "normal")
    end
    return merged:vignette(0.33)
end

function module.Encode(image: Canvas): string
    return image:encode("png")
end

return module
