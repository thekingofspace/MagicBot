--#include[canvas]
local Kitchen = require("@src/soup/Kitchen")
local Pantry = require("@src/soup/Pantry")

local module = {}

local Size = 900
local Cx = Size / 2
local RimY = 428
local RimRx = 274
local RimRy = 96
local FootY = 642
local FootHW = 116
local LiquidCy = 434
local LiqRx = 244
local LiqRy = 79
local TableY = 500

local White = {r = 255, g = 255, b = 255}
local Black = {r = 0, g = 0, b = 0}

local CeramicLight = {r = 226, g = 212, b = 194}
local CeramicDark = {r = 118, g = 102, b = 86}
local InnerWall = {r = 146, g = 130, b = 114}
local Glaze = {r = 62, g = 80, b = 138}

local Wheat = {r = 224, g = 196, b = 138}
local WheatLight = {r = 240, g = 218, b = 170}
local Dough = {r = 234, g = 220, b = 192}
local DoughCrease = {r = 186, g = 164, b = 128}
local Salmon = {r = 228, g = 122, b = 78}
local SalmonDark = {r = 176, g = 84, b = 50}
local SalmonStripe = {r = 246, g = 232, b = 216}
local Carrot = {r = 232, g = 134, b = 38}
local CarrotDark = {r = 186, g = 98, b = 22}
local CarrotLight = {r = 248, g = 178, b = 94}
local LeekOuter = {r = 118, g = 164, b = 66}
local LeekPale = {r = 220, g = 232, b = 184}
local LeekCore = {r = 152, g = 192, b = 98}
local Meat = {r = 126, g = 80, b = 52}
local MeatDark = {r = 86, g = 52, b = 32}
local MeatLight = {r = 174, g = 120, b = 84}
local EggWhite = {r = 242, g = 238, b = 226}
local EggEdge = {r = 202, g = 194, b = 176}
local Yolk = {r = 240, g = 178, b = 56}
local YolkEdge = {r = 202, g = 138, b = 34}
local Anise = {r = 98, g = 64, b = 40}
local AniseDark = {r = 60, g = 36, b = 22}
local Tofu = {r = 238, g = 234, b = 220}
local TofuEdge = {r = 200, g = 194, b = 174}
local CreamColor = {r = 246, g = 240, b = 226}
local Silver = {r = 152, g = 156, b = 166}
local SilverDark = {r = 102, g = 106, b = 118}
local SilverLight = {r = 232, g = 236, b = 244}

local FontCandidates = {
    "C:/Windows/Fonts/Inkfree.ttf",
    "C:/Windows/Fonts/segoepr.ttf",
    "C:/Windows/Fonts/comic.ttf",
    "C:/Windows/Fonts/georgia.ttf",
    "C:/Windows/Fonts/arial.ttf",
}

local ChalkFont: CanvasFont? = nil
for _, path in ipairs(FontCandidates) do
    if not ChalkFont then
        local ok, font = pcall(function()
            return canvas.font(path)
        end)
        if ok and font then
            ChalkFont = font
        end
    end
end

local function WithAlpha(color: {r: number, g: number, b: number}, alpha: number): {r: number, g: number, b: number, a: number}
    return {r = color.r, g = color.g, b = color.b, a = math.floor(alpha)}
end

local function BlendRGB(a: {r: number, g: number, b: number}, b: {r: number, g: number, b: number}, t: number): {r: number, g: number, b: number}
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

-- Deterministic per-recipe randomness — the same order always plates the
-- same bowl. Only the chaotic ladle changes the Seed between servings.
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

local function EllipseArc(cx: number, cy: number, rx: number, ry: number, a0: number, a1: number, steps: number): {{number}}
    local points = {}
    for i = 0, steps do
        local t = a0 + (a1 - a0) * i / steps
        table.insert(points, {cx + rx * math.cos(t), cy + ry * math.sin(t)})
    end
    return points
end

local function BodyHW(y: number): number
    local t = math.clamp((y - RimY) / (FootY - RimY), 0, 1)
    return FootHW + (RimRx - FootHW) * math.cos(t * math.pi / 2) ^ 0.85
end

local function RotEllipse(cv: Canvas, cx: number, cy: number, rx: number, ry: number, ang: number, color)
    local points = {}
    local cosA, sinA = math.cos(ang), math.sin(ang)
    for i = 0, 19 do
        local t = i / 20 * math.pi * 2
        local px = rx * math.cos(t)
        local py = ry * math.sin(t)
        table.insert(points, {cx + px * cosA - py * sinA, cy + px * sinA + py * cosA})
    end
    cv:polygon(points, color)
end

-- === Ingredient stamps: each letter knows how it floats ===

local function DrawPiece(cv: Canvas, letter: string, x: number, y: number, s: number, Roll: () -> number, surface)
    if letter == "O" then
        local r = 13 * s
        cv:ellipse(x, y, r, r * 0.5, Wheat)
        cv:ellipse(x, y + r * 0.06, r * 0.52, r * 0.24, Darken(surface, 0.12))
        cv:ellipse(x - r * 0.3, y - r * 0.22, r * 0.3, r * 0.11, WithAlpha(WheatLight, 190))
    elseif letter == "I" then
        local len = 62 * s
        local amp = (4 + Roll() * 5) * s
        local phase = Roll() * math.pi * 2
        local tilt = (Roll() - 0.5) * 0.5
        local points = {}
        for i = 0, 16 do
            local t = i / 16
            local px = x - len / 2 + len * t
            local py = y + math.sin(phase + t * math.pi * 2.2) * amp + (px - x) * tilt * 0.2
            table.insert(points, {px, py})
        end
        cv:polyline(points, WithAlpha(Darken(Wheat, 0.3), 220), 5 * s)
        for i, point in ipairs(points) do
            points[i] = {point[1], point[2] - 1.4 * s}
        end
        cv:polyline(points, WheatLight, 3.2 * s)
    elseif letter == "D" then
        local rx, ry = 19 * s, 14 * s
        cv:ellipse(x, y, rx, ry, Dough)
        cv:ellipse(x, y - ry * 0.55, rx * 0.34, ry * 0.3, BlendRGB(Dough, DoughCrease, 0.35))
        for i = -2, 2 do
            cv:line(x + i * rx * 0.1, y - ry * 0.66, x + i * rx * 0.4, y - ry * 0.02, WithAlpha(DoughCrease, 200), 2)
        end
        cv:ellipse(x - rx * 0.38, y + ry * 0.1, rx * 0.3, ry * 0.24, WithAlpha(White, 100))
    elseif letter == "F" then
        local rx, ry = 24 * s, 12 * s
        cv:ellipse(x, y, rx, ry, Salmon)
        cv:strokeEllipse(x, y, rx, ry, SalmonDark)
        for i = -1, 1 do
            local points = {}
            for j = 0, 8 do
                local t = j / 8
                local py = y + (t * 2 - 1) * ry * 0.8
                local px = x + i * rx * 0.42 + math.sin(t * math.pi) * 4 * s
                table.insert(points, {px, py})
            end
            cv:polyline(points, WithAlpha(SalmonStripe, 220), 2.4 * s)
        end
    elseif letter == "C" then
        local r = 11 * s
        cv:ellipse(x, y, r, r * 0.5, CarrotDark)
        cv:ellipse(x, y - 1.4 * s, r * 0.92, r * 0.42, Carrot)
        cv:ellipse(x, y - 1.4 * s, r * 0.46, r * 0.2, CarrotLight)
    elseif letter == "L" then
        local r = 12 * s
        cv:ellipse(x, y, r, r * 0.5, LeekOuter)
        cv:ellipse(x, y, r * 0.72, r * 0.34, LeekPale)
        cv:ellipse(x, y, r * 0.4, r * 0.18, LeekCore)
    elseif letter == "M" then
        local r = (14 + Roll() * 4) * s
        local points = {}
        for i = 0, 6 do
            local a = i / 7 * math.pi * 2 + Roll() * 0.4
            local rr = r * (0.72 + Roll() * 0.42)
            table.insert(points, {x + math.cos(a) * rr, y + math.sin(a) * rr * 0.55})
        end
        cv:polygon(points, Meat)
        cv:strokePolygon(points, WithAlpha(MeatDark, 230), 2)
        cv:ellipse(x - r * 0.2, y - r * 0.22, r * 0.34, r * 0.14, WithAlpha(MeatLight, 170))
    elseif letter == "E" then
        local rx, ry = 19 * s, 12 * s
        cv:ellipse(x, y, rx, ry, EggWhite)
        cv:strokeEllipse(x, y, rx, ry, EggEdge)
        cv:ellipse(x, y, rx * 0.52, ry * 0.55, Yolk)
        cv:strokeEllipse(x, y, rx * 0.52, ry * 0.55, YolkEdge)
        cv:ellipse(x - rx * 0.14, y - ry * 0.18, rx * 0.16, ry * 0.16, WithAlpha(White, 170))
    elseif letter == "A" then
        cv:star(x, y, 8, 12 * s, 4.6 * s, Anise, Roll() * math.pi)
        cv:ellipse(x, y, 3.4 * s, 2.3 * s, AniseDark)
    elseif letter == "T" then
        local r = 12 * s
        local a = (Roll() - 0.5) * 0.6 + math.pi / 4
        local points = {}
        for i = 0, 3 do
            local ang = a + i * math.pi / 2
            table.insert(points, {x + math.cos(ang) * r, y + math.sin(ang) * r * 0.55})
        end
        cv:polygon(points, Tofu)
        cv:strokePolygon(points, WithAlpha(TofuEdge, 220), 2)
        cv:ellipse(x - r * 0.2, y - r * 0.18, r * 0.3, r * 0.12, WithAlpha(White, 130))
    end
end

local PieceSpacing: {[string]: number} = {
    O = 42, I = 62, D = 58, F = 66, C = 36, L = 40, M = 52, E = 60, A = 42, T = 42,
}

-- === The scene ===

function module.Render(dish: Kitchen.Dish): Canvas
    local Roll = NewRoll(HashString(dish.Seed or "empty"))
    local color = dish.Color
    local hot = dish.Heat >= 1
    local cold = dish.Heat <= -1

    -- Base: a dark kitchen, a wooden table, a mood of light.
    local base = canvas.new(Size, Size, {r = 13, g = 10, b = 14, a = 255})

    local mood = {r = 110, g = 70, b = 34}
    if dish.Spoiled then
        mood = {r = 86, g = 110, b = 46}
    elseif cold then
        mood = {r = 52, g = 74, b = 118}
    elseif hot then
        mood = {r = 150, g = 84, b = 30}
    end
    for i = 8, 1, -1 do
        base:circle(Cx, RimY, 350 * i / 8, WithAlpha(mood, 6))
    end

    base:polygon({{0, TableY}, {Size, TableY}, {Size, Size}, {0, Size}}, {r = 46, g = 32, b = 24, a = 255})
    base:line(0, TableY, Size, TableY, {r = 86, g = 60, b = 40, a = 255}, 3)
    base:line(0, TableY + 3, Size, TableY + 3, {r = 24, g = 16, b = 12, a = 255}, 2)
    local plankGaps = {58, 78, 104, 138}
    local plankY = TableY
    for _, gap in ipairs(plankGaps) do
        plankY += gap
        base:line(0, plankY, Size, plankY, {r = 30, g = 20, b = 14, a = 255}, 3)
        base:line(0, plankY + 3, Size, plankY + 3, {r = 66, g = 46, b = 32, a = 90}, 2)
    end
    for _ = 1, 7 do
        local gy = TableY + 16 + Roll() * (Size - TableY - 30)
        local points = {}
        for i = 0, 12 do
            local t = i / 12
            table.insert(points, {t * Size, gy + math.sin(t * math.pi * (1.5 + Roll())) * 3})
        end
        base:polyline(points, {r = 28, g = 19, b = 13, a = 60}, 2)
    end

    base:ellipse(Cx, FootY + 20, 250, 30, WithAlpha(Black, 90))
    base:ellipse(Cx, FootY + 18, 200, 22, WithAlpha(Black, 120))
    base:ellipse(Cx, FootY + 16, 150, 15, WithAlpha(Black, 140))

    -- Bowl layer: ceramic body, glaze bands, rim, and tableware.
    local bowl = canvas.new(Size, Size, {r = 0, g = 0, b = 0, a = 0})

    local y = RimY
    while y <= FootY do
        local t = (y - RimY) / (FootY - RimY)
        local hw = BodyHW(y)
        local shade = BlendRGB(CeramicLight, CeramicDark, 0.15 + t * 0.72)
        bowl:line(Cx - hw, y, Cx + hw, y, WithAlpha(shade, 255), 4)
        y += 3
    end

    local footTop = FootY
    y = footTop
    while y <= footTop + 15 do
        local hw = FootHW * 0.86 - (y - footTop) * 0.9
        bowl:line(Cx - hw, y, Cx + hw, y, WithAlpha(Darken(CeramicDark, 0.35), 255), 3)
        y += 2
    end
    bowl:ellipse(Cx, footTop + 15, FootHW * 0.78, 8, WithAlpha(Darken(CeramicDark, 0.5), 255))

    for band, spec in ipairs({{0.24, 9}, {0.36, 4}}) do
        local by = RimY + spec[1] * (FootY - RimY)
        local brx = BodyHW(by) - 2
        local bry = (RimRy - 8) * brx / RimRx
        local arc = EllipseArc(Cx, by, brx, bry, 0.1, math.pi - 0.1, 34)
        bowl:polyline(arc, WithAlpha(if band == 1 then Glaze else Brighten(Glaze, 0.25), 235), spec[2])
    end

    local highlight = {}
    y = RimY + 34
    while y <= FootY - 26 do
        table.insert(highlight, {Cx - BodyHW(y) * 0.8, y})
        y += 4
    end
    if #highlight > 2 then
        bowl:polyline(highlight, WithAlpha(White, 26), 13)
        local short = {}
        for i = 1, math.max(math.floor(#highlight * 0.5), 2) do
            table.insert(short, highlight[i])
        end
        bowl:polyline(short, WithAlpha(White, 52), 5)
    end
    local shadowEdge = {}
    y = RimY + 40
    while y <= FootY - 20 do
        table.insert(shadowEdge, {Cx + BodyHW(y) * 0.86, y})
        y += 4
    end
    if #shadowEdge > 2 then
        bowl:polyline(shadowEdge, WithAlpha(Black, 55), 11)
    end

    bowl:ellipse(Cx, RimY, RimRx, RimRy, CeramicLight)
    bowl:polyline(EllipseArc(Cx, RimY, RimRx, RimRy, 0, math.pi * 2, 72), WithAlpha(Darken(CeramicLight, 0.4), 200), 2)
    bowl:ellipse(Cx, RimY + 3, RimRx - 13, RimRy - 9, InnerWall)
    bowl:polyline(EllipseArc(Cx, RimY + 3, RimRx - 13, RimRy - 9, math.pi + 0.3, math.pi * 2 - 0.3, 40), WithAlpha(Darken(InnerWall, 0.35), 160), 4)

    -- Condensation: a chilled bowl sweats.
    if dish.Drops > 0 then
        for _ = 1, dish.Drops do
            local dy = RimY + 30 + Roll() * (FootY - RimY - 72)
            local hw = BodyHW(dy)
            local dx = Cx + (Roll() * 2 - 1) * hw * 0.8
            local dr = 3 + Roll() * 2.6
            bowl:ellipse(dx, dy, dr, dr * 1.35, {r = 204, g = 228, b = 244, a = 140})
            bowl:polyline(EllipseArc(dx, dy, dr, dr * 1.35, 0, math.pi * 2, 14), {r = 150, g = 178, b = 200, a = 90}, 1)
            bowl:circle(dx - dr * 0.35, dy - dr * 0.55, 1.6, {r = 252, g = 254, b = 255, a = 220})
            if Roll() < 0.4 then
                bowl:line(dx, dy + dr, dx + (Roll() - 0.5) * 4, dy + dr + 9 + Roll() * 12, {r = 204, g = 228, b = 244, a = 70}, 2)
            end
        end
        base:ellipse(Cx, FootY + 22, 190, 14, {r = 120, g = 160, b = 190, a = 26})
    end

    -- The spoon, resting where a hand left it.
    local sx, sy = 728, 726
    local ang = -0.55
    bowl:ellipse(sx + 34, sy + 20, 92, 16, WithAlpha(Black, 100))
    local ex = sx + math.cos(ang) * 188
    local ey = sy + math.sin(ang) * 188
    bowl:line(sx + math.cos(ang) * 38, sy + math.sin(ang) * 38, ex, ey, WithAlpha(Silver, 255), 16)
    bowl:line(sx + math.cos(ang) * 44, sy + math.sin(ang) * 44 - 3, ex, ey - 3, WithAlpha(SilverLight, 130), 4)
    RotEllipse(bowl, sx, sy, 48, 31, ang, Silver)
    RotEllipse(bowl, sx - 3, sy, 36, 20, ang, SilverDark)
    RotEllipse(bowl, sx - 12, sy - 8, 14, 6, ang, WithAlpha(SilverLight, 160))

    -- The side dish: one small plate or cup, left of the bowl.
    local side = dish.Side
    if side then
        local px, py = 138, 668
        if side.kind == "cup" then
            bowl:ellipse(px + 4, py + 26, 56, 10, WithAlpha(Black, 110))
            local cy = py - 10
            local yy = cy
            while yy <= cy + 36 do
                local t = (yy - cy) / 36
                local hw = 26 + (47 - 26) * math.cos(t * math.pi / 2) ^ 0.85
                bowl:line(px - hw, yy, px + hw, yy, WithAlpha(BlendRGB(CeramicLight, CeramicDark, 0.2 + t * 0.65), 255), 3)
                yy += 2
            end
            bowl:ellipse(px, cy, 48, 17, CeramicLight)
            bowl:ellipse(px, cy + 2, 40, 13, InnerWall)
            local stock = Pantry.GetStock(side.letter or "W")
            local cupColor = if stock then stock.Color else Pantry.WaterColor
            bowl:ellipse(px, cy + 3, 35, 10, WithAlpha(Darken(cupColor, 0.12), 250))
            bowl:ellipse(px, cy + 3, 20, 5, WithAlpha(Brighten(cupColor, 0.12), 220))
        else
            bowl:ellipse(px + 6, py + 12, 118, 17, WithAlpha(Black, 110))
            bowl:ellipse(px, py, 112, 34, CeramicLight)
            bowl:ellipse(px, py + 2, 88, 25, BlendRGB(CeramicLight, CeramicDark, 0.4))
            bowl:ellipse(px, py + 2, 72, 19, BlendRGB(CeramicLight, CeramicDark, 0.16))
            if side.kind == "plate" and side.letter then
                local spots = {{-38, 2}, {16, -6}, {40, 10}, {-8, 12}, {24, 6}}
                local shown = math.min(side.count, 5)
                for i = 1, shown do
                    local spot = spots[i]
                    local ix = px + spot[1] + (Roll() - 0.5) * 6
                    local iy = py + 2 + spot[2] * 0.6
                    bowl:ellipse(ix, iy + 6, 16, 5, WithAlpha(Black, 80))
                    DrawPiece(bowl, side.letter :: string, ix, iy, 1.05, Roll, BlendRGB(CeramicLight, CeramicDark, 0.16))
                end
            end
        end
    end

    -- The chef's board, chalked and leaning.
    if dish.Chef and #(dish.Chef :: string) > 0 then
        local bw, bh = 236, 84
        local bx, by = Cx - bw / 2, 748
        bowl:ellipse(Cx, by + bh + 4, bw * 0.52, 9, WithAlpha(Black, 100))
        bowl:roundedRect(bx, by, bw, bh, 10, {r = 38, g = 40, b = 44, a = 255})
        bowl:strokeRoundedRect(bx, by, bw, bh, 10, {r = 112, g = 82, b = 50, a = 255}, 5)
        local text = dish.Chef :: string
        if ChalkFont then
            local font = ChalkFont :: CanvasFont
            local size = 40
            local width, height = font:measure(text, size)
            while size > 12 and width > bw - 44 do
                size -= 2
                width, height = font:measure(text, size)
            end
            bowl:text(text, Cx - width / 2, by + bh / 2 - height / 2 - 4, size, {r = 228, g = 230, b = 235, a = 225}, font)
            bowl:line(Cx - width / 2 - 4, by + bh / 2 + height / 2 - 2, Cx + width / 2 + 4, by + bh / 2 + height / 2, {r = 228, g = 230, b = 235, a = 70}, 2)
        else
            bowl:line(bx + 26, by + bh / 2, bx + bw - 26, by + bh / 2, {r = 228, g = 230, b = 235, a = 200}, 4)
        end
    end

    -- Liquid layer: the surface and everything adrift on it. Viscosity is a
    -- dial: thin broths turn translucent, thick stews go matte and opaque.
    local liquid = canvas.new(Size, Size, {r = 0, g = 0, b = 0, a = 0})
    local thickLevel = math.clamp(dish.Body, 0, 3)
    local thinLevel = math.clamp(-dish.Body, 0, 3)
    local surfaceAlpha = 242
    if thickLevel > 0 then
        surfaceAlpha = math.min(248 + thickLevel * 3, 255)
    elseif thinLevel > 0 then
        surfaceAlpha = 232 - thinLevel * 16
    end

    liquid:ellipse(Cx, LiquidCy, LiqRx, LiqRy, WithAlpha(Darken(color, 0.3), surfaceAlpha))
    liquid:ellipse(Cx, LiquidCy, LiqRx - 9, LiqRy - 7, WithAlpha(Darken(color, 0.1), surfaceAlpha))
    liquid:ellipse(Cx, LiquidCy + 3, LiqRx * 0.6, LiqRy * 0.56, WithAlpha(Brighten(color, 0.06), 110))
    if thinLevel > 0 then
        liquid:ellipse(Cx, LiquidCy + 5, LiqRx * (0.4 + 0.07 * thinLevel), LiqRy * (0.38 + 0.07 * thinLevel), WithAlpha(BlendRGB(color, InnerWall, 0.55), 26 + 24 * thinLevel))
    end

    -- Stirred: the spiral the spoon left behind.
    if dish.Stirred > 0 then
        local phase = Roll() * math.pi * 2
        for i = 1, math.min(2 + dish.Stirred, 5) do
            local rr = LiqRx * (0.2 + 0.15 * i)
            local a0 = phase + i * 1.25
            liquid:polyline(EllipseArc(Cx, LiquidCy, rr, rr * LiqRy / LiqRx, a0, a0 + 2.4, 24), WithAlpha(Darken(color, 0.28), 100), 4)
        end
    end

    -- Cream: a drawn spiral, the classic flourish.
    if dish.Cream > 0 then
        local turns = 1.6 + math.min(dish.Cream, 3) * 0.5
        local phase = Roll() * math.pi * 2
        local points = {}
        local steps = 90
        for i = 0, steps do
            local t = i / steps
            local rr = t * LiqRx * 0.58
            local a = phase + t * turns * math.pi * 2
            table.insert(points, {Cx + math.cos(a) * rr, LiquidCy + math.sin(a) * rr * LiqRy / LiqRx})
        end
        liquid:polyline(points, WithAlpha(CreamColor, 235), 7)
        liquid:polyline(points, WithAlpha(White, 120), 3)
    end

    -- Honey: thin gold threads where the spoon drizzled.
    if dish.Sweet > 0 then
        for i = 1, math.min(dish.Sweet + 1, 3) do
            local a0 = Roll() * math.pi * 2
            local rr = LiqRx * (0.18 + Roll() * 0.3)
            liquid:polyline(EllipseArc(Cx + (Roll() - 0.5) * 40, LiquidCy + (Roll() - 0.5) * 16, rr, rr * 0.32, a0, a0 + 3.4, 22), {r = 240, g = 196, b = 88, a = 120}, 3)
        end
    end

    -- Spoilage: scum, film, and a fat lazy bubble or two.
    if dish.Spoiled then
        for _ = 1, 6 + math.min(dish.Taint, 6) do
            local a = Roll() * math.pi * 2
            local rad = math.sqrt(Roll()) * 0.8
            local px = Cx + math.cos(a) * rad * LiqRx
            local py = LiquidCy + math.sin(a) * rad * LiqRy
            liquid:ellipse(px, py, 12 + Roll() * 18, 4 + Roll() * 6, WithAlpha(Darken(color, 0.35), 140))
            liquid:ellipse(px + 4, py - 2, 7 + Roll() * 8, 2.5 + Roll() * 3, WithAlpha(Brighten(color, 0.28), 70))
        end
        for _ = 1, 3 do
            local px = Cx + (Roll() * 2 - 1) * LiqRx * 0.5
            local py = LiquidCy + (Roll() * 2 - 1) * LiqRy * 0.5
            liquid:strokeCircle(px, py, 4 + Roll() * 3, WithAlpha(Brighten(color, 0.4), 150), 1)
        end
    end

    -- Ingredients, plated far-to-near so the close ones overlap.
    local placedPieces: {{letter: string, x: number, y: number, s: number}} = {}
    local placedAt: {{number}} = {}
    local total = 0
    for _, piece in ipairs(dish.Ingredients) do
        local shown = math.min(piece.count, 10)
        for _ = 1, shown do
            if total >= 22 then
                break
            end
            local margin = PieceSpacing[piece.letter] or 46
            local px, py = Cx, LiquidCy
            for attempt = 1, 10 do
                local a = Roll() * math.pi * 2
                local rad = math.sqrt(Roll())
                px = Cx + math.cos(a) * rad * (LiqRx - margin * 0.75)
                py = LiquidCy + math.sin(a) * rad * (LiqRy - margin * 0.28)
                local ok = true
                for _, at in ipairs(placedAt) do
                    local dx, dy = px - at[1], (py - at[2]) * 2.2
                    if dx * dx + dy * dy < (margin + at[3]) * (margin + at[3]) * 0.42 then
                        ok = false
                        break
                    end
                end
                if ok or attempt == 10 then
                    break
                end
            end
            table.insert(placedAt, {px, py, margin})
            local v = (py - LiquidCy) / LiqRy
            table.insert(placedPieces, {letter = piece.letter, x = px, y = py, s = (1.38 + v * 0.28) * (1 - 0.05 * thinLevel)})
            total += 1
        end
    end
    table.sort(placedPieces, function(a, b)
        return a.y < b.y
    end)
    for _, piece in ipairs(placedPieces) do
        liquid:ellipse(piece.x, piece.y + 6 * piece.s, 17 * piece.s, 6 * piece.s, WithAlpha(Darken(color, 0.35), 130))
        DrawPiece(liquid, piece.letter, piece.x, piece.y, piece.s, Roll, color)
        if thickLevel > 0 then
            liquid:ellipse(piece.x, piece.y + (6.5 - thickLevel * 0.5) * piece.s, 19 * piece.s, (2 + 1.8 * thickLevel) * piece.s, WithAlpha(color, 85 + thickLevel * 30))
        end
    end

    -- A thin broth closes back over what floats in it — still plainly visible.
    if thinLevel > 0 then
        liquid:ellipse(Cx, LiquidCy, LiqRx - 9, LiqRy - 7, WithAlpha(color, 12 + 13 * thinLevel))
    end

    -- Pepper: flecks over everything, the way pepper actually lands.
    if dish.Pepper > 0 then
        for _ = 1, math.min(dish.Pepper * 7, 42) do
            local a = Roll() * math.pi * 2
            local rad = math.sqrt(Roll()) * 0.9
            local px = Cx + math.cos(a) * rad * LiqRx
            local py = LiquidCy + math.sin(a) * rad * LiqRy
            liquid:circle(px, py, 1 + Roll() * 1.2, {r = 34, g = 26, b = 18, a = 235})
        end
    end

    -- The gloss: the thinner the broth, the brighter it gleams; a stew sits
    -- matte and dappled, and past spoon-standing the surface turns lumpy.
    if not dish.Spoiled and thickLevel == 0 then
        local glossAlpha = 75 + 15 * thinLevel
        liquid:polyline(EllipseArc(Cx, LiquidCy, LiqRx * 0.68, LiqRy * 0.66, math.pi * 1.06, math.pi * 1.5, 22), WithAlpha(White, glossAlpha), 5)
        liquid:ellipse(Cx - LiqRx * 0.42, LiquidCy - LiqRy * 0.4, 12, 4, WithAlpha(White, glossAlpha))
    end
    if thickLevel > 0 then
        for _ = 1, 4 + thickLevel * 4 do
            local a = Roll() * math.pi * 2
            local rad = math.sqrt(Roll()) * 0.85
            liquid:ellipse(Cx + math.cos(a) * rad * LiqRx, LiquidCy + math.sin(a) * rad * LiqRy, 9 + Roll() * 12, 3 + Roll() * 3, WithAlpha(Darken(color, 0.14), 55 + thickLevel * 8))
        end
    end
    if thickLevel >= 2 then
        for _ = 1, thickLevel * 5 do
            local a = Roll() * math.pi * 2
            local rad = math.sqrt(Roll()) * 0.78
            local lx = Cx + math.cos(a) * rad * LiqRx
            local ly = LiquidCy + math.sin(a) * rad * LiqRy
            liquid:ellipse(lx, ly, 6 + Roll() * 8, 2.2 + Roll() * 2.2, WithAlpha(Brighten(color, 0.12), 85))
            liquid:ellipse(lx + 2, ly + 2.5, 5 + Roll() * 6, 1.8 + Roll() * 1.8, WithAlpha(Darken(color, 0.2), 75))
        end
    end

    -- Steam layer: ribbons for the hot, stink for the spoiled, flies regardless.
    local steam = canvas.new(Size, Size, {r = 0, g = 0, b = 0, a = 0})
    local hasSteam = false

    local wisps = dish.Steam
    local wispColor = Brighten(color, 0.6)
    if dish.Spoiled then
        wisps = 3
        wispColor = {r = 150, g = 170, b = 90}
    end
    if wisps > 0 then
        hasSteam = true
        for _ = 1, wisps do
            local wx = Cx + (Roll() * 2 - 1) * LiqRx * 0.62
            local span = 150 + Roll() * 140
            local drift = (Roll() * 2 - 1) * 34
            local amp = 10 + Roll() * 15
            local phase = Roll() * math.pi * 2
            local points = {}
            for i = 0, 24 do
                local t = i / 24
                table.insert(points, {wx + drift * t + math.sin(phase + t * math.pi * 2.6) * amp * t, LiquidCy - 12 - t * span})
            end
            local lower = {}
            for i = 1, 14 do
                table.insert(lower, points[i])
            end
            local upper = {}
            for i = 12, 25 do
                table.insert(upper, points[i])
            end
            steam:polyline(lower, WithAlpha(wispColor, if dish.Spoiled then 60 else 72), 4 + Roll() * 2)
            steam:polyline(upper, WithAlpha(wispColor, if dish.Spoiled then 36 else 40), 5 + Roll() * 3)
        end
    end

    if dish.Spoiled then
        hasSteam = true
        for _ = 1, 5 do
            local fx = Cx + (Roll() * 2 - 1) * 180
            local fy = RimY - 36 - Roll() * 120
            local trail = EllipseArc(fx + 12, fy + 6, 22 + Roll() * 10, 11 + Roll() * 6, Roll() * math.pi * 2, Roll() * math.pi * 2 + 3.2, 16)
            steam:polyline(trail, WithAlpha({r = 190, g = 190, b = 178}, 70), 2)
            steam:ellipse(fx - 5, fy - 5, 5.5, 2.6, {r = 215, g = 224, b = 232, a = 170})
            steam:ellipse(fx + 5, fy - 5, 5.5, 2.6, {r = 215, g = 224, b = 232, a = 170})
            steam:circle(fx, fy, 4, {r = 22, g = 20, b = 16, a = 255})
            steam:circle(fx + 2, fy - 1, 1.4, {r = 90, g = 96, b = 88, a = 220})
        end
    end

    -- Compose: warm glow off the surface, then the steam over everything.
    local glowStrength = if hot then 1.0 elseif dish.Spoiled then 0.8 else 0.55
    local glowAlpha = if hot then 120 else 85
    local glowed = liquid:clone():glow(6, WithAlpha(Brighten(color, 0.25), glowAlpha), glowStrength)

    local merged = base:merge(bowl, "normal"):merge(glowed, "add"):merge(liquid, "normal")
    if hasSteam then
        merged = merged:merge(steam:clone():glow(5, WithAlpha(wispColor, 40), 0.6), "add"):merge(steam, "normal")
    end
    return merged:vignette(0.33)
end

function module.Encode(image: Canvas): string
    return image:encode("png")
end

return module
