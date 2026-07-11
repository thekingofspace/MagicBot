--#include[canvas, fs]
local Resolver = require("@src/grimoire/Resolver")

local module = {}

local Size = 900
local TwoPi = 2 * math.pi

local FontCandidates = {
    "C:/Windows/Fonts/georgia.ttf",
    "C:/Windows/Fonts/constan.ttf",
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
local Paper = {
    Light = {r = 234, g = 223, b = 196},
    Mid = {r = 212, g = 199, b = 168},
    Dark = {r = 162, g = 148, b = 116},
    Deep = {r = 106, g = 94, b = 70},
}
local GiltPaper = {
    Light = {r = 255, g = 233, b = 152},
    Mid = {r = 218, g = 180, b = 88},
    Dark = {r = 152, g = 112, b = 42},
    Deep = {r = 86, g = 60, b = 20},
}
local Brass = {
    Light = {r = 240, g = 210, b = 132},
    Mid = {r = 186, g = 148, b = 74},
    Dark = {r = 118, g = 88, b = 40},
    Deep = {r = 62, g = 44, b = 18},
}
local Iron = {
    Light = {r = 206, g = 210, b = 222},
    Mid = {r = 136, g = 141, b = 156},
    Dark = {r = 80, g = 84, b = 98},
    Deep = {r = 40, g = 42, b = 52},
}
local RibbonColors = {
    {Mid = {r = 168, g = 42, b = 54}, Dark = {r = 104, g = 20, b = 30}},
    {Mid = {r = 46, g = 112, b = 72}, Dark = {r = 22, g = 66, b = 40}},
    {Mid = {r = 56, g = 76, b = 146}, Dark = {r = 28, g = 40, b = 92}},
    {Mid = {r = 204, g = 162, b = 66}, Dark = {r = 130, g = 96, b = 30}},
}
local WoodTop = {r = 92, g = 68, b = 46}
local WoodFace = {r = 56, g = 40, b = 28}
local WoodGrain = {r = 34, g = 24, b = 16}
local ThreadTone = {r = 202, g = 190, b = 166}

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

local function Arc(cv: Canvas, cx: number, cy: number, radius: number, fromAngle: number, toAngle: number, color: any, thickness: number)
    local steps = math.max(10, math.floor(30 * math.abs(toAngle - fromAngle) / TwoPi + 0.5) * 4)
    local points = {}
    for i = 0, steps do
        local t = fromAngle + (toAngle - fromAngle) * i / steps
        table.insert(points, {cx + radius * math.cos(t), cy + radius * math.sin(t)})
    end
    cv:polyline(points, color, thickness)
end

type Book = {
    coverX: number,
    coverW: number,
    coverH: number,
    yb0: number,
    ybSlope: number,
    hBase: number,
    hSlope: number,
    depthX: number,
    depthY: number,
    spineW: number,
}

local function CoverY(book: Book, u: number, v: number): number
    local yb = book.yb0 + book.ybSlope * u
    local yt = yb - book.coverH * (book.hBase + book.hSlope * u)
    return yt + v * (yb - yt)
end

local function P(book: Book, u: number, v: number): (number, number)
    return book.coverX + u * book.coverW, CoverY(book, u, v)
end

local function Off(book: Book, x: number, y: number, k: number): (number, number)
    return x + book.depthX * k, y + book.depthY * k
end

local SigilArt: {[string]: (Canvas, number, number, number, any, number) -> ()} = {
    C = function(cv, x, y, s, color, th)
        Arc(cv, x, y, s * 0.8, 0, TwoPi, color, th * 1.2)
        for i = 0, 11 do
            local a = TwoPi * i / 12
            cv:line(x + s * 0.62 * math.cos(a), y + s * 0.62 * math.sin(a), x + s * 0.74 * math.cos(a), y + s * 0.74 * math.sin(a), color, math.max(2, th * 0.5))
        end
        cv:circle(x, y, math.max(3, s * 0.09), color)
        for i = 0, 3 do
            local a = TwoPi * i / 4 + math.pi / 4
            cv:line(x + s * 0.2 * math.cos(a), y + s * 0.2 * math.sin(a), x + s * 0.42 * math.cos(a), y + s * 0.42 * math.sin(a), color, math.max(2, th * 0.55))
        end
    end,
    D = function(cv, x, y, s, color, th)
        cv:strokePolygon({
            {x, y - s * 0.85}, {x + s * 0.72, y}, {x, y + s * 0.85}, {x - s * 0.72, y},
        }, color, th)
        cv:line(x - s * 0.42, y - s * 0.48, x + s * 0.42, y + s * 0.48, color, th)
        cv:line(x + s * 0.42, y - s * 0.48, x - s * 0.42, y + s * 0.48, color, th)
        cv:circle(x, y, math.max(3, s * 0.08), color)
    end,
    X = function(cv, x, y, s, color, th)
        local r = s * 0.44
        local d = s * 0.34
        Arc(cv, x - d, y, r, 0, TwoPi, color, th)
        Arc(cv, x + d, y, r, 0, TwoPi, color, th)
        Arc(cv, x, y - d, r, 0, TwoPi, color, th)
        Arc(cv, x, y + d, r, 0, TwoPi, color, th)
        cv:strokePolygon({
            {x, y - s * 0.16}, {x + s * 0.16, y}, {x, y + s * 0.16}, {x - s * 0.16, y},
        }, color, math.max(2, th * 0.6))
    end,
    O = function(cv, x, y, s, color, th)
        Arc(cv, x, y, s * 0.82, 0, TwoPi, color, th * 1.25)
        Arc(cv, x, y, s * 0.56, 0, TwoPi, color, th)
        for i = 0, 3 do
            local a = TwoPi * i / 4
            cv:circle(x + s * 0.69 * math.cos(a), y + s * 0.69 * math.sin(a), math.max(2, th * 0.5), color)
        end
    end,
    A = function(cv, x, y, s, color, th)
        cv:polyline({{x - s * 0.62, y + s * 0.55}, {x, y - s * 0.75}, {x + s * 0.62, y + s * 0.55}}, color, th * 1.15)
        cv:polyline({{x - s * 0.4, y + s * 0.55}, {x, y - s * 0.3}, {x + s * 0.4, y + s * 0.55}}, color, math.max(2, th * 0.7))
        cv:line(x, y - s * 0.75, x, y + s * 0.85, color, math.max(2, th * 0.6))
        cv:line(x - s * 0.16, y + s * 0.72, x + s * 0.16, y + s * 0.72, color, math.max(2, th * 0.6))
    end,
    S = function(cv, x, y, s, color, th)
        local points = {}
        for i = 0, 40 do
            local t = i / 40
            local sway = math.sin(TwoPi * 1.1 * t + 1.35)
            table.insert(points, {
                x + s * 0.56 * sway * (0.62 + 0.38 * math.sin(math.pi * t)),
                y - s * 0.82 + s * 1.64 * t,
            })
        end
        cv:polyline(points, color, th * 1.5)
        local body = {}
        for i = 1, 24 do
            table.insert(body, points[i])
        end
        cv:polyline(body, color, th * 1.8)
        local hx, hy = points[1][1], points[1][2]
        cv:circle(hx, hy, math.max(4, s * 0.17), color)
        cv:line(hx - s * 0.04, hy - s * 0.15, hx - s * 0.1, hy - s * 0.32, color, math.max(2, th * 0.45))
        cv:line(hx - s * 0.1, hy - s * 0.32, hx - s * 0.18, hy - s * 0.4, color, math.max(2, th * 0.35))
        cv:line(hx - s * 0.1, hy - s * 0.32, hx - s * 0.02, hy - s * 0.42, color, math.max(2, th * 0.35))
        local tx, ty = points[#points][1], points[#points][2]
        cv:line(tx, ty, tx - s * 0.26, ty + s * 0.1, color, math.max(2, th * 0.6))
        cv:circle(tx - s * 0.3, ty + s * 0.12, math.max(2, th * 0.35), color)
    end,
    Y = function(cv, x, y, s, color, th)
        cv:line(x, y - s * 0.15, x, y + s * 0.62, color, th * 1.2)
        cv:polyline({{x, y - s * 0.1}, {x - s * 0.4, y - s * 0.45}, {x - s * 0.5, y - s * 0.8}}, color, th)
        cv:polyline({{x, y - s * 0.1}, {x + s * 0.4, y - s * 0.45}, {x + s * 0.5, y - s * 0.8}}, color, th)
        cv:polyline({{x, y - s * 0.35}, {x - s * 0.16, y - s * 0.62}, {x - s * 0.2, y - s * 0.85}}, color, math.max(2, th * 0.7))
        cv:polyline({{x, y - s * 0.35}, {x + s * 0.16, y - s * 0.62}, {x + s * 0.2, y - s * 0.85}}, color, math.max(2, th * 0.7))
        cv:polyline({{x - s * 0.42, y + s * 0.78}, {x - s * 0.18, y + s * 0.62}, {x, y + s * 0.62}, {x + s * 0.18, y + s * 0.62}, {x + s * 0.42, y + s * 0.78}}, color, math.max(2, th * 0.7))
    end,
    T = function(cv, x, y, s, color, th)
        cv:strokePolygon({
            {x - s * 0.3, y - s * 0.5}, {x + s * 0.3, y - s * 0.5},
            {x + s * 0.38, y + s * 0.8}, {x - s * 0.38, y + s * 0.8},
        }, color, th)
        for i = 0, 2 do
            local mx = x - s * 0.3 + s * 0.6 * i / 2
            cv:line(mx, y - s * 0.5, mx, y - s * 0.72, color, th)
        end
        cv:line(x - s * 0.34, y - s * 0.72, x + s * 0.34, y - s * 0.72, color, th)
        Arc(cv, x, y + s * 0.8, s * 0.16, math.pi, TwoPi, color, math.max(2, th * 0.8))
        cv:line(x - s * 0.16, y + s * 0.8, x + s * 0.16, y + s * 0.8, color, math.max(2, th * 0.8))
        cv:line(x, y - s * 0.1, x, y + s * 0.14, color, math.max(2, th * 0.7))
    end,
    M = function(cv, x, y, s, color, th)
        cv:polyline({
            {x - s * 0.85, y + s * 0.5}, {x - s * 0.42, y - s * 0.2}, {x - s * 0.16, y + s * 0.14},
            {x, y - s * 0.62}, {x + s * 0.2, y + s * 0.1}, {x + s * 0.46, y - s * 0.28},
            {x + s * 0.85, y + s * 0.5},
        }, color, th * 1.1)
        cv:line(x - s * 0.85, y + s * 0.5, x + s * 0.85, y + s * 0.5, color, math.max(2, th * 0.7))
        cv:polyline({{x - s * 0.08, y - s * 0.34}, {x, y - s * 0.5}, {x + s * 0.08, y - s * 0.34}}, color, math.max(2, th * 0.55))
    end,
    E = function(cv, x, y, s, color, th)
        local w = s * 0.9
        local points = {}
        for i = 0, 24 do
            local t = i / 24
            table.insert(points, {x - w + 2 * w * t, y - s * 0.42 * math.sin(math.pi * t)})
        end
        cv:polyline(points, color, th * 1.1)
        local lower = {}
        for i = 0, 24 do
            local t = i / 24
            table.insert(lower, {x - w + 2 * w * t, y + s * 0.42 * math.sin(math.pi * t)})
        end
        cv:polyline(lower, color, th * 1.1)
        Arc(cv, x, y, s * 0.3, 0, TwoPi, color, th)
        cv:circle(x, y, math.max(3, s * 0.13), color)
        for i = 1, 4 do
            local a = math.pi * (0.28 + 0.15 * (i - 1)) + math.pi
            cv:line(x + s * 0.62 * math.cos(a) * 1.35, y + s * 0.5 * math.sin(a), x + s * 0.78 * math.cos(a) * 1.35, y + s * 0.66 * math.sin(a), color, math.max(2, th * 0.5))
        end
    end,
}

local function Emboss(cv: Canvas, art: (Canvas, number, number, number, any, number) -> (), x: number, y: number, s: number, th: number, tool: Resolver.Rgb, mat: Resolver.Material, power: number)
    local off = math.max(3, s * 0.04 + power * 0.7)
    art(cv, x + off, y + off * 1.2, s, WithAlpha(mat.Deep, 235), th)
    art(cv, x - off * 0.55, y - off * 0.7, s, WithAlpha(mat.Light, 110), th)
    art(cv, x, y, s, tool, th)
end

local function DrawTextTooled(cv: Canvas, text: string, x: number, y: number, size: number, tool: Resolver.Rgb, mat: Resolver.Material, maxWidth: number?)
    if not RuneFont or #text == 0 then
        return
    end
    local font = RuneFont :: CanvasFont
    local width, height = font:measure(text, size)
    if maxWidth and width > maxWidth then
        size = size * maxWidth / width
        width, height = font:measure(text, size)
    end
    local bx, by = x - width / 2, y - height / 2
    local off = math.max(2, size * 0.05)
    cv:text(text, bx + off, by + off * 1.2, size, WithAlpha(mat.Deep, 225), font)
    cv:text(text, bx - off * 0.5, by - off * 0.6, size, WithAlpha(mat.Light, 100), font)
    cv:text(text, bx, by, size, WithAlpha(tool, 255), font)
end

local function Luminance(color: Resolver.Rgb): number
    return 0.299 * color.r + 0.587 * color.g + 0.114 * color.b
end

local function ToolColor(plan: Resolver.GrimoirePlan, mat: Resolver.Material, trim: Resolver.Material?): Resolver.Rgb
    local paleCover = Luminance(mat.Mid) > 150
    if trim then
        if paleCover then
            return LerpColor((trim :: Resolver.Material).Dark, (trim :: Resolver.Material).Deep, 0.45)
        end
        return LerpColor((trim :: Resolver.Material).Mid, (trim :: Resolver.Material).Light, 0.45)
    end
    if paleCover then
        return LerpColor(mat.Deep, {r = 20, g = 16, b = 14}, 0.35)
    end
    if plan.material == "gilt" then
        return LerpColor(mat.Deep, mat.Dark, 0.4)
    end
    return {r = 216, g = 178, b = 100}
end

local Textures: {[string]: (Canvas, Book, () -> number, Resolver.Material) -> ()} = {
    leather = function(cv, book, rng, mat)
        for _ = 1, 240 do
            local u, v = 0.03 + rng() * 0.94, 0.02 + rng() * 0.96
            local x, y = P(book, u, v)
            local a = rng() * TwoPi
            local len = 3 + rng() * 8
            local tone = if rng() < 0.5 then mat.Deep else mat.Light
            cv:line(x, y, x + len * math.cos(a), y + len * math.sin(a), WithAlpha(tone, 14 + rng() * 16), 1)
        end
        for _ = 1, 90 do
            local x, y = P(book, 0.04 + rng() * 0.92, 0.03 + rng() * 0.94)
            cv:circle(x, y, 1 + rng(), WithAlpha(mat.Deep, 18 + rng() * 18), 1)
        end
    end,
    dragonhide = function(cv, book, rng, mat)
        local scale = book.coverW * 0.085
        local rows = math.floor(book.coverH / (scale * 0.72))
        for row = 0, rows do
            local offset = if row % 2 == 0 then 0 else 0.5
            for col = -1, math.floor(book.coverW / scale) + 1 do
                local u = (col + offset) * scale / book.coverW
                local v = row * scale * 0.72 / book.coverH
                if u > 0.02 and u < 0.98 and v > 0.01 and v < 0.99 then
                    local x, y = P(book, u, v)
                    local jitter = (rng() - 0.5) * 2
                    Arc(cv, x + jitter, y, scale * 0.52, math.rad(200), math.rad(340), WithAlpha(mat.Light, 60), 2)
                    Arc(cv, x + jitter, y + 2.5, scale * 0.52, math.rad(200), math.rad(340), WithAlpha(mat.Deep, 120), 3)
                end
            end
        end
    end,
    vellum = function(cv, book, rng, mat)
        for _ = 1, 26 do
            local x, y = P(book, 0.08 + rng() * 0.84, 0.06 + rng() * 0.88)
            cv:ellipse(x, y, 18 + rng() * 46, 10 + rng() * 26, WithAlpha(if rng() < 0.5 then mat.Dark else mat.Light, 9 + rng() * 9))
        end
        for _ = 1, 46 do
            local x, y = P(book, 0.05 + rng() * 0.9, 0.04 + rng() * 0.92)
            cv:circle(x, y, 1 + rng() * 1.4, WithAlpha(mat.Dark, 26 + rng() * 26))
        end
    end,
    gilt = function(cv, book, rng, mat)
        local panels = {{0.1, 0.07, 0.9, 0.3}, {0.1, 0.36, 0.9, 0.64}, {0.1, 0.7, 0.9, 0.93}}
        for _, panel in ipairs(panels) do
            local x0, y0 = P(book, panel[1], panel[2])
            local x1, y1 = P(book, panel[3], panel[2])
            local x2, y2 = P(book, panel[3], panel[4])
            local x3, y3 = P(book, panel[1], panel[4])
            cv:polyline({{x0, y0}, {x1, y1}, {x2, y2}, {x3, y3}, {x0, y0}}, WithAlpha(mat.Deep, 70), 2)
        end
        for _ = 1, 60 do
            local x, y = P(book, 0.04 + rng() * 0.92, 0.03 + rng() * 0.94)
            cv:circle(x, y, 0.8 + rng() * 1.2, WithAlpha(mat.Light, 40 + rng() * 60))
        end
    end,
    void = function(cv, book, rng, mat)
        local cx, cy = P(book, 0.5, 0.48)
        for i = 5, 1, -1 do
            cv:ellipse(cx, cy, book.coverW * 0.09 * i, book.coverH * 0.075 * i, {r = 0, g = 0, b = 0, a = 22})
        end
        for _ = 1, 34 do
            local x, y = P(book, 0.06 + rng() * 0.88, 0.05 + rng() * 0.9)
            cv:circle(x, y, 0.8 + rng() * 1.5, {r = 226, g = 216, b = 255, a = math.floor(60 + rng() * 120)})
        end
        for _ = 1, 5 do
            local x, y = P(book, 0.1 + rng() * 0.8, 0.08 + rng() * 0.84)
            cv:circle(x, y, 2.4, {r = 240, g = 232, b = 255, a = 200})
            cv:circle(x, y, 4.5, {r = 180, g = 150, b = 240, a = 50})
        end
    end,
    ancient = function(cv, book, rng, mat)
        for _ = 1, 14 do
            local u, v = 0.06 + rng() * 0.88, 0.04 + rng() * 0.9
            local points = {}
            local x, y = P(book, u, v)
            table.insert(points, {x, y})
            local a = rng() * TwoPi
            for _ = 1, 4 + math.floor(rng() * 4) do
                a += (rng() - 0.5) * 1.6
                x += math.cos(a) * (8 + rng() * 16)
                y += math.sin(a) * (8 + rng() * 16)
                table.insert(points, {x, y})
            end
            cv:polyline(points, WithAlpha(mat.Deep, 120 + rng() * 80), 1 + rng())
        end
        for _ = 1, 120 do
            local x, y = P(book, 0.03 + rng() * 0.94, 0.02 + rng() * 0.96)
            cv:circle(x, y, 1 + rng() * 2, WithAlpha(if rng() < 0.6 then mat.Deep else mat.Light, 14 + rng() * 20))
        end
    end,
    storm = function(cv, book, rng, mat)
        for _ = 1, 8 do
            local x, y = P(book, 0.1 + rng() * 0.8, 0.06 + rng() * 0.8)
            cv:ellipse(x, y, 30 + rng() * 60, 16 + rng() * 30, WithAlpha(mat.Dark, 16 + rng() * 14))
        end
        for _ = 1, 6 do
            local u = 0.1 + rng() * 0.8
            local v = 0.06 + rng() * 0.7
            local points = {}
            local x, y = P(book, u, v)
            table.insert(points, {x, y})
            for _ = 1, 3 + math.floor(rng() * 3) do
                x += (rng() - 0.5) * 26
                y += 12 + rng() * 22
                table.insert(points, {x, y})
            end
            cv:polyline(points, {r = 190, g = 210, b = 255, a = math.floor(50 + rng() * 60)}, 1.6)
        end
    end,
    dream = function(cv, book, rng, mat)
        local tones = {
            {r = 255, g = 190, b = 216},
            {r = 168, g = 220, b = 228},
            {r = 198, g = 178, b = 240},
            {r = 250, g = 232, b = 190},
        }
        for _ = 1, 22 do
            local x, y = P(book, 0.08 + rng() * 0.84, 0.06 + rng() * 0.88)
            local tone = tones[math.floor(rng() * #tones) + 1]
            cv:ellipse(x, y, 24 + rng() * 52, 16 + rng() * 34, WithAlpha(tone, 12 + rng() * 12))
        end
        for _ = 1, 18 do
            local x, y = P(book, 0.08 + rng() * 0.84, 0.06 + rng() * 0.88)
            cv:circle(x, y, 1 + rng() * 1.4, {r = 255, g = 252, b = 255, a = math.floor(70 + rng() * 90)})
        end
    end,
    flesh = function(cv, book, rng, mat)
        for _ = 1, 9 do
            local points = {}
            local x, y = P(book, 0.1 + rng() * 0.8, 0.05 + rng() * 0.85)
            table.insert(points, {x, y})
            local a = rng() * TwoPi
            for _ = 1, 5 + math.floor(rng() * 4) do
                a += (rng() - 0.5) * 1.1
                x += math.cos(a) * (10 + rng() * 14)
                y += math.sin(a) * (10 + rng() * 14)
                table.insert(points, {x, y})
            end
            cv:polyline(points, {r = 96, g = 62, b = 88, a = math.floor(50 + rng() * 40)}, 2 + rng() * 1.5)
        end
        for _ = 1, 12 do
            local x, y = P(book, 0.1 + rng() * 0.8, 0.06 + rng() * 0.86)
            cv:ellipse(x, y, 10 + rng() * 26, 7 + rng() * 15, {r = 116, g = 122, b = 70, a = math.floor(20 + rng() * 22)})
        end
        local su, sv = 0.2 + rng() * 0.25, 0.15 + rng() * 0.5
        local sx0, sy0 = P(book, su, sv)
        local sx1, sy1 = P(book, su + 0.32, sv + 0.14)
        cv:line(sx0, sy0, sx1, sy1, WithAlpha(mat.Deep, 200), 3)
        for i = 0, 5 do
            local t = i / 5
            local mx = sx0 + (sx1 - sx0) * t
            local my = sy0 + (sy1 - sy0) * t
            cv:line(mx - 5, my - 7, mx + 5, my + 7, WithAlpha(ThreadTone, 170), 2)
        end
    end,
    ruin = function(cv, book, rng, mat)
        for _ = 1, 10 do
            local x, y = P(book, 0.06 + rng() * 0.88, 0.05 + rng() * 0.9)
            cv:ellipse(x, y, 16 + rng() * 40, 10 + rng() * 22, {r = 16, g = 14, b = 14, a = math.floor(24 + rng() * 26)})
        end
        for _ = 1, 16 do
            local x, y = P(book, 0.1 + rng() * 0.8, 0.08 + rng() * 0.84)
            local marks = 2 + math.floor(rng() * 3)
            for _ = 1, marks do
                local a = rng() * TwoPi
                local len = 5 + rng() * 9
                cv:line(x, y, x + math.cos(a) * len, y + math.sin(a) * len, WithAlpha(mat.Light, 44 + rng() * 40), 1.4)
                x += (rng() - 0.5) * 10
                y += (rng() - 0.5) * 10
            end
        end
    end,
}

local function DrawShelf(cv: Canvas)
    local topY = 742
    local faceY = 790
    cv:polygon({{0, topY}, {Size, topY}, {Size, faceY}, {0, faceY}}, WithAlpha(WoodTop, 255))
    cv:polygon({{0, faceY}, {Size, faceY}, {Size, Size}, {0, Size}}, WithAlpha(WoodFace, 255))
    cv:line(0, topY, Size, topY, WithAlpha(LerpColor(WoodTop, {r = 200, g = 170, b = 130}, 0.4), 140), 2)
    cv:line(0, faceY, Size, faceY, WithAlpha(WoodGrain, 220), 3)
    for i = 1, 9 do
        local y = topY + 4 + i * 4.6
        local points = {}
        for x = 0, Size, 60 do
            table.insert(points, {x, y + math.sin(x * 0.02 + i * 2) * 1.5})
        end
        cv:polyline(points, WithAlpha(WoodGrain, 38), 1)
    end
    for i = 1, 9 do
        local y = faceY + 8 + i * 11
        local points = {}
        for x = 0, Size, 50 do
            table.insert(points, {x, y + math.sin(x * 0.014 + i * 1.7) * 2.4})
        end
        cv:polyline(points, WithAlpha(WoodGrain, 46 + (i % 3) * 14), 1 + (i % 2))
    end
    for _, px in ipairs({170, 620}) do
        cv:line(px, faceY, px + 4, Size, WithAlpha(WoodGrain, 130), 3)
    end
end

local function DrawBackCover(cv: Canvas, book: Book, mat: Resolver.Material)
    local corners = {{0, 0}, {1, 0}, {1, 1}, {0, 1}}
    local quad = {}
    for _, c in ipairs(corners) do
        local x, y = P(book, c[1], c[2])
        local ox, oy = Off(book, x, y, 1)
        table.insert(quad, {ox + 5, oy + 4})
    end
    cv:polygon(quad, WithAlpha(LerpColor(mat.Deep, {r = 0, g = 0, b = 0}, 0.35), 255))
    cv:polyline({quad[2], quad[3], quad[4]}, WithAlpha(LerpColor(mat.Deep, {r = 0, g = 0, b = 0}, 0.6), 255), 2)
end

local function DrawPages(cv: Canvas, book: Book, plan: Resolver.GrimoirePlan, rng: () -> number)
    local pal = if plan.gilt then GiltPaper else Paper
    local vTop = 0.022

    local rx, ryTop = P(book, 1, vTop)
    local _, ryBottom = P(book, 1, 1)
    local bx0, by0 = P(book, 0.015, 1)
    local bx1, by1 = P(book, 1, 1)

    local rTx1, rTy1 = Off(book, rx, ryTop, 1)
    local rBx1, rBy1 = Off(book, rx, ryBottom, 1)
    cv:polygon({{rx, ryTop}, {rx, ryBottom}, {rBx1, rBy1}, {rTx1, rTy1}}, WithAlpha(pal.Dark, 255))

    local bBx0, bBy0 = Off(book, bx0, by0, 1)
    local bBx1, bBy1 = Off(book, bx1, by1, 1)
    cv:polygon({{bx0, by0}, {bx1, by1}, {bBx1, bBy1}, {bBx0, bBy0}}, WithAlpha(pal.Dark, 255))

    local steps = math.max(9, math.floor(book.depthX / 2.4))
    for i = 0, steps do
        local k = 0.05 + 0.9 * i / steps
        local t = math.sin(math.pi * (i / steps))
        local jitter = (rng() - 0.5) * 0.16
        local tone = LerpColor(pal.Dark, pal.Light, math.clamp(0.3 + 0.6 * t + jitter, 0, 1))
        local ax, ay = Off(book, rx, ryTop, k)
        local ax2, ay2 = Off(book, rx, ryBottom, k)
        cv:line(ax, ay, ax2, ay2, WithAlpha(tone, 255), 2)
        local hx0, hy0 = Off(book, bx0, by0, k)
        local hx1, hy1 = Off(book, bx1, by1, k)
        cv:line(hx0, hy0, hx1, hy1, WithAlpha(LerpColor(tone, pal.Dark, 0.25), 255), 2)
    end

    local eTx, eTy = Off(book, rx, ryTop, 0.98)
    local eBx, eBy = Off(book, rx, ryBottom, 0.98)
    cv:line(rx, ryTop, eTx, eTy, WithAlpha(pal.Deep, 210), 2)
    cv:line(rx + 1, ryTop + 1, rx + 1, ryBottom, WithAlpha(pal.Deep, 130), 2)
    cv:line(eTx, eTy, eBx, eBy, WithAlpha(pal.Deep, 170), 2)

    if plan.gilt then
        for i = 1, 3 do
            local k = 0.2 + 0.25 * i
            local gx0, gy0 = Off(book, rx, ryTop + 10, k)
            local gx1, gy1 = Off(book, rx, ryBottom - 10, k * 0.94)
            cv:line(gx0, gy0, gx1, gy1, {r = 255, g = 244, b = 190, a = 80}, 2)
        end
    end

    if plan.cursed then
        for _ = 1, 6 do
            local k = 0.1 + rng() * 0.8
            local ux = 0.2 + rng() * 0.75
            local sx, sy = P(book, ux, 1)
            local ox, oy = Off(book, sx, sy, k)
            cv:line(ox, oy, ox + (rng() - 0.5) * 5, oy + 6 + rng() * 10, WithAlpha(pal.Mid, 235), 2)
        end
    end
end

local function DrawSpine(cv: Canvas, book: Book, plan: Resolver.GrimoirePlan, mat: Resolver.Material, tool: Resolver.Rgb)
    local S = book.spineW
    local x0 = book.coverX
    local ytIn = CoverY(book, 0, 0)
    local ybIn = CoverY(book, 0, 1)

    local function EdgeY(t: number, top: boolean): number
        if top then
            return ytIn + 11 * t * t
        end
        return ybIn - 5 * t * t
    end

    local strips = 12
    for i = 0, strips - 1 do
        local t0 = i / strips
        local t1 = (i + 1) / strips
        local mid = (t0 + t1) / 2
        local bright = 0.62 * math.exp(-((mid - 0.24) ^ 2) / 0.09) + 0.05
        local tone = LerpColor(mat.Deep, mat.Light, bright)
        cv:polygon({
            {x0 - S * t0, EdgeY(t0, true)},
            {x0 - S * t1, EdgeY(t1, true)},
            {x0 - S * t1, EdgeY(t1, false)},
            {x0 - S * t0, EdgeY(t0, false)},
        }, WithAlpha(tone, 255))
    end

    local silhouette = {}
    for i = 0, 8 do
        local t = i / 8
        table.insert(silhouette, {x0 - S, EdgeY(1, true) + (EdgeY(1, false) - EdgeY(1, true)) * t})
    end
    cv:polyline(silhouette, WithAlpha(LerpColor(mat.Deep, {r = 0, g = 0, b = 0}, 0.4), 255), 2.5)

    local topEdge = {}
    local bottomEdge = {}
    for i = 0, 10 do
        local t = i / 10
        table.insert(topEdge, {x0 - S * t, EdgeY(t, true)})
        table.insert(bottomEdge, {x0 - S * t, EdgeY(t, false)})
    end
    cv:polyline(topEdge, WithAlpha(mat.Deep, 220), 2.5)
    cv:polyline(bottomEdge, WithAlpha(mat.Deep, 200), 2.5)

    for _, top in ipairs({true, false}) do
        local capBand = {}
        local capEdge = {}
        for i = 0, 8 do
            local t = i / 8
            local y = EdgeY(t, top)
            table.insert(capBand, {x0 - S * t, y + (if top then 5 else -5)})
            table.insert(capEdge, {x0 - S * t, y + (if top then 2 else -2)})
        end
        cv:polyline(capBand, WithAlpha(mat.Deep, 170), 6)
        cv:polyline(capEdge, WithAlpha(ThreadTone, 120), 2)
    end

    if plan.ribs > 0 then
        for i = 1, plan.ribs do
            local v = 0.11 + 0.78 * (i - 0.5) / plan.ribs
            local yIn = ytIn + (ybIn - ytIn) * v
            local yOut = EdgeY(1, true) + (EdgeY(1, false) - EdgeY(1, true)) * v
            cv:polygon({
                {x0, yIn - 8},
                {x0 - S - 3, yOut - 6},
                {x0 - S - 3, yOut + 6},
                {x0, yIn + 8},
            }, WithAlpha(LerpColor(mat.Mid, mat.Light, 0.5), 255))
            cv:ellipse(x0 - S - 2, yOut, 3.4, 7.4, WithAlpha(LerpColor(mat.Mid, mat.Light, 0.3), 255))
            cv:line(x0, yIn + 9.5, x0 - S - 2, yOut + 7.5, WithAlpha(mat.Deep, 235), 4)
            cv:line(x0, yIn - 7.5, x0 - S - 2, yOut - 5.5, WithAlpha(LerpColor(mat.Light, {r = 255, g = 255, b = 255}, 0.3), 190), 2)
        end
    end

    if plan.edition then
        local digits = plan.edition :: string
        local y = ytIn + 30
        for index = 1, #digits do
            DrawTextTooled(cv, string.sub(digits, index, index), x0 - S * 0.46, y, 23, tool, mat, S - 14)
            y += 25
        end
    end

    cv:line(x0, ytIn, x0, ybIn, WithAlpha(mat.Deep, 235), 3)
    cv:line(x0 + 3, ytIn + 2, x0 + 3, ybIn - 2, WithAlpha(mat.Light, 70), 2)
end

local function DrawCoverBase(cv: Canvas, book: Book, mat: Resolver.Material)
    local strips = 36
    for i = 0, strips - 1 do
        local u0 = i / strips
        local u1 = (i + 1) / strips
        local mid = (u0 + u1) / 2
        local t = math.clamp(1 - math.abs(mid - 0.42) ^ 1.15 * 1.5, 0, 1)
        local tone = LerpColor(mat.Dark, mat.Light, 0.12 + 0.6 * t)
        local ax, ay = P(book, u0, 0)
        local bx, by = P(book, u1, 0)
        local cx2, cy2 = P(book, u1, 1)
        local dx, dy = P(book, u0, 1)
        cv:polygon({{ax, ay}, {bx, by}, {cx2, cy2}, {dx, dy}}, WithAlpha(tone, 255))
    end
    local sx0, sy0 = P(book, 0, 0.89)
    local sx1, sy1 = P(book, 1, 0.89)
    local sx2, sy2 = P(book, 1, 1)
    local sx3, sy3 = P(book, 0, 1)
    cv:polygon({{sx0, sy0}, {sx1, sy1}, {sx2, sy2}, {sx3, sy3}}, {r = 0, g = 0, b = 0, a = 26})
end

local function DrawFrame(cv: Canvas, book: Book, plan: Resolver.GrimoirePlan, mat: Resolver.Material, trim: Resolver.Material?, tool: Resolver.Rgb)
    local function Rect(u0: number, v0: number, u1: number, v1: number, color: any, th: number)
        local ax, ay = P(book, u0, v0)
        local bx, by = P(book, u1, v0)
        local cx2, cy2 = P(book, u1, v1)
        local dx, dy = P(book, u0, v1)
        cv:polyline({{ax, ay}, {bx, by}, {cx2, cy2}, {dx, dy}, {ax, ay}}, color, th)
    end
    Rect(0.057, 0.041, 0.943, 0.959, WithAlpha(mat.Deep, 200), 5)
    if trim then
        Rect(0.055, 0.039, 0.941, 0.957, WithAlpha(LerpColor((trim :: Resolver.Material).Mid, (trim :: Resolver.Material).Light, 0.3), 255), 4)
        Rect(0.053, 0.037, 0.939, 0.955, WithAlpha((trim :: Resolver.Material).Light, 150), 1)
    else
        Rect(0.055, 0.039, 0.941, 0.957, WithAlpha(tool, 210), 3)
    end
    Rect(0.088, 0.064, 0.912, 0.936, WithAlpha(mat.Deep, 170), 3)
    Rect(0.086, 0.062, 0.91, 0.934, WithAlpha(tool, 170), 2)
    for _, corner in ipairs({{0.086, 0.062}, {0.91, 0.062}, {0.086, 0.934}, {0.91, 0.934}}) do
        local sx = if corner[1] < 0.5 then 1 else -1
        local sy = if corner[2] < 0.5 then 1 else -1
        local x, y = P(book, corner[1], corner[2])
        cv:line(x + sx * 8, y + sy * 8, x + sx * 26, y + sy * 26, WithAlpha(tool, 170), 2)
        cv:circle(x + sx * 30, y + sy * 30, 2.5, WithAlpha(tool, 170))
    end
end

local function MetalFor(plan: Resolver.GrimoirePlan)
    return if plan.metal == "iron" then Iron else Brass
end

local function DrawStuds(cv: Canvas, book: Book, plan: Resolver.GrimoirePlan, metal)
    local slots = {
        {0.14, 0.105}, {0.86, 0.105}, {0.14, 0.895}, {0.86, 0.895},
        {0.5, 0.085}, {0.5, 0.915}, {0.125, 0.5}, {0.875, 0.5},
    }
    for index = 1, math.min(plan.studs, #slots) do
        local x, y = P(book, slots[index][1], slots[index][2])
        cv:circle(x + 2.5, y + 3, 9, {r = 0, g = 0, b = 0, a = 130})
        cv:circle(x, y, 9, WithAlpha(metal.Mid, 255))
        cv:strokeCircle(x, y, 9, WithAlpha(metal.Deep, 220), 2)
        cv:circle(x - 2.5, y - 3, 3.2, WithAlpha(metal.Light, 235))
    end
end

local function DrawCorners(cv: Canvas, book: Book, metal)
    local L = 0.145
    local Lv = L * book.coverW / book.coverH
    local corners = {
        {0, 0, 1, 1}, {1, 0, -1, 1}, {0, 1, 1, -1}, {1, 1, -1, -1},
    }
    for _, c in ipairs(corners) do
        local u, v, du, dv = c[1], c[2], c[3], c[4]
        local ax, ay = P(book, u, v)
        local bx, by = P(book, u + du * L, v)
        local cx2, cy2 = P(book, u, v + dv * Lv)
        cv:polygon({{ax, ay}, {bx, by}, {cx2, cy2}}, WithAlpha(metal.Mid, 255))
        cv:polygon({{ax, ay}, {bx, by}, {ax + du * 6, ay + (by - ay) * 0.4 + dv * 4}}, WithAlpha(metal.Light, 130))
        cv:polyline({{bx, by}, {cx2, cy2}}, WithAlpha(metal.Deep, 235), 3)
        cv:polyline({{bx, by}, {cx2, cy2}}, WithAlpha(metal.Light, 90), 1)
        local rx = ax + (bx - ax) * 0.3 + (cx2 - ax) * 0.3
        local ry = ay + (by - ay) * 0.3 + (cy2 - ay) * 0.3
        cv:circle(rx, ry, 3.4, WithAlpha(metal.Deep, 220))
        cv:circle(rx - 1, ry - 1, 1.6, WithAlpha(metal.Light, 220))
    end
end

local function DrawStrap(cv: Canvas, book: Book, v: number, metal, cursed: boolean, rng: () -> number)
    local half = 12
    local x0, y0 = P(book, 0.76, v)
    local x1, y1 = P(book, 1, v)
    local reach = if cursed then 0.62 + rng() * 0.3 else 0.82
    local ex, ey = Off(book, x1, y1, reach)
    if cursed then
        ey += (rng() - 0.5) * 14
    end

    cv:polygon({{x1 + 3, y1 - half + 5}, {ex + 3, ey - half + 4}, {ex + 3, ey + half + 2}, {x1 + 3, y1 + half + 5}}, {r = 0, g = 0, b = 0, a = 100})
    cv:polygon({{x1, y1 - half}, {ex, ey - half + 1}, {ex, ey + half - 1}, {x1, y1 + half}}, WithAlpha(LerpColor(metal.Mid, metal.Dark, 0.35), 255))
    cv:line(x1, y1 - half + 1, ex, ey - half + 2, WithAlpha(metal.Light, 150), 2)
    cv:line(x1, y1 + half - 1, ex, ey + half - 2, WithAlpha(metal.Deep, 220), 2)
    cv:polygon({{ex - 2, ey - half + 1}, {ex + 4, ey - half * 0.4}, {ex + 4, ey + half * 0.4}, {ex - 2, ey + half - 1}}, WithAlpha(metal.Dark, 255))
    cv:circle(ex - 4, ey, 2.2, WithAlpha(metal.Deep, 235))

    cv:polygon({{x0 + 2, y0 - half + 4}, {x1 + 2, y1 - half + 4}, {x1 + 2, y1 + half + 4}, {x0 + 2, y0 + half + 4}}, {r = 0, g = 0, b = 0, a = 90})
    cv:polygon({{x0, y0 - half}, {x1, y1 - half}, {x1, y1 + half}, {x0, y0 + half}}, WithAlpha(metal.Mid, 255))
    cv:line(x0, y0 - half + 2, x1, y1 - half + 2, WithAlpha(metal.Light, 200), 2)
    cv:line(x0, y0 + half - 1, x1, y1 + half - 1, WithAlpha(metal.Deep, 220), 3)
    cv:line(x0, y0, x1, y1, WithAlpha(metal.Deep, 60), 1)

    local bx0, by0 = P(book, 0.715, v)
    local bx1, by1 = P(book, 0.795, v)
    cv:polygon({{bx0 + 2, by0 - 17 + 4}, {bx1 + 2, by1 - 17 + 4}, {bx1 + 2, by1 + 17 + 4}, {bx0 + 2, by0 + 17 + 4}}, {r = 0, g = 0, b = 0, a = 110})
    cv:polygon({{bx0, by0 - 17}, {bx1, by1 - 17}, {bx1, by1 + 17}, {bx0, by0 + 17}}, WithAlpha(metal.Dark, 255))
    cv:polyline({{bx0, by0 - 17}, {bx1, by1 - 17}, {bx1, by1 + 17}, {bx0, by0 + 17}, {bx0, by0 - 17}}, WithAlpha(metal.Deep, 235), 2)
    cv:line(bx0 + 3, by0 - 13, bx0 + 3, by0 + 13, WithAlpha(metal.Light, 150), 2)
    local rvx, rvy = P(book, 0.735, v)
    cv:circle(rvx, rvy, 2.6, WithAlpha(metal.Light, 220))
    local pnx, pny = P(book, 0.785, v)
    cv:line(pnx, pny - 9, pnx, pny + 9, WithAlpha(metal.Light, 190), 3)
end

local function DrawLock(cv: Canvas, book: Book, metal, rng: () -> number, cursed: boolean)
    local x1, y1 = P(book, 1, 0.5)
    local hx, hy = Off(book, x1, y1, 0.4)
    local by = hy + 52
    local bx = hx + 2
    local w, h = 30, 26
    if cursed then
        by += (rng() - 0.5) * 10
    end

    cv:line(hx, hy + 10, hx, by - h - 12, WithAlpha(metal.Dark, 230), 5)
    Arc(cv, bx, by - h + 2, 17, math.pi, TwoPi, WithAlpha(metal.Deep, 235), 8)
    Arc(cv, bx, by - h + 2, 17, math.pi, TwoPi, WithAlpha(metal.Light, 160), 3)

    cv:polygon({
        {bx - w + 3, by - h + 5}, {bx + w + 3, by - h + 5},
        {bx + w + 3, by + h + 5}, {bx - w + 3, by + h + 5},
    }, {r = 0, g = 0, b = 0, a = 120})
    cv:polygon({
        {bx - w, by - h}, {bx + w - 8, by - h},
        {bx + w, by - h + 8}, {bx + w, by + h - 6},
        {bx + w - 6, by + h}, {bx - w + 6, by + h},
        {bx - w, by + h - 6}, {bx - w, by - h},
    }, WithAlpha(metal.Mid, 255))
    cv:polygon({{bx - w, by - h}, {bx + w - 8, by - h}, {bx + w - 10, by - h + 7}, {bx - w + 2, by - h + 7}}, WithAlpha(metal.Light, 140))
    cv:polyline({
        {bx - w, by - h}, {bx + w - 8, by - h}, {bx + w, by - h + 8}, {bx + w, by + h - 6},
        {bx + w - 6, by + h}, {bx - w + 6, by + h}, {bx - w, by + h - 6}, {bx - w, by - h},
    }, WithAlpha(metal.Deep, 235), 2)
    cv:circle(bx, by - 2, 6.5, WithAlpha(metal.Deep, 255))
    cv:polygon({{bx - 3.4, by}, {bx + 3.4, by}, {bx + 5.4, by + 16}, {bx - 5.4, by + 16}}, WithAlpha(metal.Deep, 255))
    cv:circle(bx - 2, by - 4, 2, WithAlpha(metal.Light, 200))
end

local function DrawChain(cv: Canvas, book: Book, metal, rng: () -> number)
    local ax, ay = P(book, 0.9, 0.075)
    cv:polygon({{ax - 11, ay - 8}, {ax + 11, ay - 8}, {ax + 11, ay + 8}, {ax - 11, ay + 8}}, WithAlpha(metal.Dark, 255))
    cv:polyline({{ax - 11, ay - 8}, {ax + 11, ay - 8}, {ax + 11, ay + 8}, {ax - 11, ay + 8}, {ax - 11, ay - 8}}, WithAlpha(metal.Deep, 235), 2)
    cv:circle(ax - 5, ay, 2, WithAlpha(metal.Light, 200))
    cv:circle(ax + 5, ay, 2, WithAlpha(metal.Light, 200))

    local backX = book.coverX + book.coverW + book.depthX
    local endX = backX + 52 + rng() * 18
    local endY = 768
    local ctrlX = backX + 62
    local ctrlY = ay + (endY - ay) * 0.44
    local links = 22
    local path = {}
    for i = 0, links do
        local t = i / links
        local ix = (1 - t) ^ 2 * ax + 2 * (1 - t) * t * ctrlX + t ^ 2 * endX
        local iy = (1 - t) ^ 2 * ay + 2 * (1 - t) * t * ctrlY + t ^ 2 * endY
        if i > 0 and i < links then
            ix += (rng() - 0.5) * 3
        end
        table.insert(path, {ix, iy})
    end
    local shadowPath = {}
    for _, pt in ipairs(path) do
        table.insert(shadowPath, {pt[1] + 3, pt[2] + 4})
    end
    cv:polyline(shadowPath, {r = 0, g = 0, b = 0, a = 70}, 8)
    cv:polyline(path, WithAlpha(metal.Deep, 220), 4)
    for i = 2, #path do
        local ix, iy = path[i][1], path[i][2]
        local tone = if i % 2 == 0 then metal.Mid else metal.Dark
        cv:strokeCircle(ix, iy, 6, WithAlpha(metal.Deep, 210), 5)
        cv:strokeCircle(ix - 0.8, iy - 0.8, 5.6, WithAlpha(tone, 255), 3)
    end
    for i = 1, 9 do
        local px = endX - 12 + rng() * 42
        local py = 764 + rng() * 18
        local tone = if i % 2 == 0 then metal.Mid else metal.Dark
        cv:ellipse(px + 1.5, py + 2, 7.5, 5, {r = 0, g = 0, b = 0, a = 110})
        cv:strokeCircle(px, py, 6, WithAlpha(metal.Deep, 210), 5)
        cv:strokeCircle(px - 0.8, py - 0.8, 5.5, WithAlpha(tone, 255), 3)
    end
end

local function DrawRibbons(cv: Canvas, book: Book, plan: Resolver.GrimoirePlan, rng: () -> number)
    for index = 1, plan.ribbons do
        local color = RibbonColors[index]
        local u = 0.3 + 0.55 * index / (plan.ribbons + 1)
        local sx, sy = P(book, u, 1)
        local x0, y0 = Off(book, sx, sy, 0.45)
        local sway = (rng() - 0.5) * 52 + (index - (plan.ribbons + 1) / 2) * 34
        local drop = 88 + rng() * 42
        local points = {}
        for i = 0, 14 do
            local t = i / 14
            local px = x0 + sway * t * t + math.sin(t * 4.6 + index * 2) * 4 * t
            local py = y0 + drop * t
            table.insert(points, {px, py})
        end
        local shadow = {}
        for _, pt in ipairs(points) do
            table.insert(shadow, {pt[1] + 4, pt[2] + 4})
        end
        cv:polyline(shadow, {r = 0, g = 0, b = 0, a = 80}, 15)
        cv:polyline(points, WithAlpha(color.Mid, 255), 13)
        local edge = {}
        for _, pt in ipairs(points) do
            table.insert(edge, {pt[1] + 4.6, pt[2]})
        end
        cv:polyline(edge, WithAlpha(color.Dark, 230), 4)
        local hilite = {}
        for i = 1, 8 do
            table.insert(hilite, {points[i][1] - 3.4, points[i][2]})
        end
        cv:polyline(hilite, WithAlpha(LerpColor(color.Mid, {r = 255, g = 255, b = 255}, 0.45), 150), 2)
        local tx, ty = points[#points][1], points[#points][2]
        local px2, py2 = points[#points - 1][1], points[#points - 1][2]
        local dx, dy = tx - px2, ty - py2
        local len = math.max(math.sqrt(dx * dx + dy * dy), 0.001)
        dx, dy = dx / len, dy / len
        local nx, ny = -dy, dx
        cv:polygon({
            {tx + nx * 7.5, ty + ny * 7.5},
            {tx - nx * 7.5, ty - ny * 7.5},
            {tx - nx * 7.5 + dx * 12, ty - ny * 7.5 + dy * 12},
            {tx + dx * 3, ty + dy * 3},
            {tx + nx * 7.5 + dx * 12, ty + ny * 7.5 + dy * 12},
        }, WithAlpha(color.Mid, 255))
        cv:line(tx - nx * 7.5 + dx * 12, ty - ny * 7.5 + dy * 12, tx + dx * 3, ty + dy * 3, WithAlpha(color.Dark, 200), 2)
        cv:line(tx + dx * 3, ty + dy * 3, tx + nx * 7.5 + dx * 12, ty + ny * 7.5 + dy * 12, WithAlpha(color.Dark, 200), 2)
    end
end

local function DrawCurse(cv: Canvas, book: Book, mat: Resolver.Material, rng: () -> number)
    local edges = {
        {0, 0, 1, 0, 0, 1},
        {0, 1, 1, 1, 0, -1},
        {0, 0, 0, 1, 1, 0},
        {1, 0, 1, 1, -1, 0},
    }
    for _ = 1, 5 + math.floor(rng() * 3) do
        local edge = edges[math.floor(rng() * #edges) + 1]
        local t = 0.08 + rng() * 0.84
        local u = edge[1] + (edge[3] - edge[1]) * t
        local v = edge[2] + (edge[4] - edge[2]) * t
        local x, y = P(book, u, v)
        local depth = 8 + rng() * 18
        local width = 10 + rng() * 20
        local dx, dy = edge[5], edge[6]
        local px = if dx == 0 then 1 else 0
        local py = if dy == 0 then 1 else 0
        cv:polygon({
            {x - px * width / 2, y - py * width / 2},
            {x + px * width / 2, y + py * width / 2},
            {x + dx * depth + (rng() - 0.5) * 6, y + dy * depth + (rng() - 0.5) * 6},
        }, WithAlpha(Background, 255))
        if rng() < 0.55 then
            local tx = x + dx * depth * 0.4
            local ty = y + dy * depth * 0.4
            local points = {{tx, ty}}
            local hang = 20 + rng() * 46
            for i = 1, 6 do
                local ht = i / 6
                table.insert(points, {tx + math.sin(ht * 7 + rng() * 3) * 4, ty + hang * ht})
            end
            cv:polyline(points, WithAlpha(ThreadTone, 190), 1.6)
        end
    end
    for _ = 1, 3 do
        local u0, v0 = 0.12 + rng() * 0.5, 0.1 + rng() * 0.6
        local u1, v1 = u0 + 0.15 + rng() * 0.25, v0 + 0.1 + rng() * 0.25
        local x0, y0 = P(book, u0, v0)
        local x1, y1 = P(book, u1, v1)
        cv:line(x0, y0, x1, y1, WithAlpha(mat.Deep, 190), 2)
        cv:line(x0 + 3, y0 + 2, x1 + 3, y1 + 2, WithAlpha(mat.Light, 60), 1)
    end
end

local function DrawExlibris(cv: Canvas, book: Book, plan: Resolver.GrimoirePlan, mat: Resolver.Material, tool: Resolver.Rgb)
    local x, y = P(book, 0.5, 0.825)
    local r = book.coverW * 0.105
    Emboss(cv, function(cv2, cx, cy, s, color, th)
        Arc(cv2, cx, cy, s, 0, TwoPi, color, th)
        Arc(cv2, cx, cy, s * 0.78, 0, TwoPi, color, math.max(2, th * 0.6))
    end, x, y, r, 3.4, tool, mat, 1)
    local exlibris = plan.exlibris
    if exlibris then
        local art = SigilArt[(exlibris :: Resolver.Sigil).letter]
        if art then
            Emboss(cv, art, x, y, r * 0.52, 2.6, tool, mat, 1)
        end
    else
        Emboss(cv, function(cv2, cx, cy, s, color, th)
            cv2:circle(cx, cy, math.max(2.5, s * 0.12), color)
        end, x, y, r, 3, tool, mat, 1)
    end
end

local function DrawGlowAccents(base: Canvas, book: Book, plan: Resolver.GrimoirePlan, rng: () -> number): Canvas
    if plan.material ~= "void" and plan.material ~= "storm" and plan.material ~= "dream" then
        return base
    end
    local overlay = canvas.new(Size, Size, {r = 0, g = 0, b = 0, a = 0})
    local glowColor
    if plan.material == "void" then
        glowColor = {r = 150, g = 100, b = 235, a = 130}
        local outline = {}
        for _, corner in ipairs({{0, 0}, {1, 0}, {1, 1}, {0, 1}, {0, 0}}) do
            local x, y = P(book, corner[1], corner[2])
            table.insert(outline, {x, y})
        end
        overlay:polyline(outline, {r = 140, g = 90, b = 230, a = 110}, 3)
        for _ = 1, 7 do
            local x, y = P(book, 0.08 + rng() * 0.84, 0.06 + rng() * 0.88)
            overlay:circle(x, y, 1.6, {r = 235, g = 225, b = 255, a = 200})
        end
    elseif plan.material == "storm" then
        glowColor = {r = 120, g = 170, b = 255, a = 120}
        for _ = 1, 4 do
            local points = {}
            local x, y = P(book, 0.14 + rng() * 0.72, 0.08 + rng() * 0.5)
            table.insert(points, {x, y})
            for _ = 1, 4 do
                x += (rng() - 0.5) * 30
                y += 16 + rng() * 26
                table.insert(points, {x, y})
            end
            overlay:polyline(points, {r = 205, g = 225, b = 255, a = 190}, 2)
        end
    else
        glowColor = {r = 235, g = 190, b = 235, a = 90}
        for _ = 1, 12 do
            local x, y = P(book, 0.1 + rng() * 0.8, 0.08 + rng() * 0.84)
            overlay:circle(x, y, 1.4 + rng() * 1.2, {r = 255, g = 245, b = 255, a = 210})
        end
    end
    local glowed = overlay:clone():glow(6, glowColor, 1.2)
    return base:merge(glowed, "add"):merge(overlay, "normal")
end

function module.Render(plan: Resolver.GrimoirePlan): Canvas
    local mat = Resolver.Materials[plan.material]
    local trim: Resolver.Material? = if plan.trim then Resolver.Materials[plan.trim :: string] else nil
    local tool = ToolColor(plan, mat, trim)
    local metal = MetalFor(plan)
    local rng = NewRng(plan.seed)

    local base = canvas.new(Size, Size, WithAlpha(Background, 255))
    for i = 4, 1, -1 do
        base:circle(Size / 2, 390, Size * 0.13 * i + Size * 0.1, {r = 34, g = 32, b = 42, a = 24})
    end

    DrawShelf(base)

    local depth = 22 + 13 * plan.pages
    local spineW = 40
    local coverW = 430
    local coverH = 560
    local totalW = spineW + coverW + depth
    local left = (Size - totalW) / 2 - 12

    local book: Book = {
        coverX = left + spineW,
        coverW = coverW,
        coverH = coverH,
        yb0 = 750,
        ybSlope = 8 + (if plan.cursed then (rng() - 0.5) * 6 else 0),
        hBase = 0.955,
        hSlope = 0.05,
        depthX = depth,
        depthY = depth * 0.3,
        spineW = spineW,
    }

    base:ellipse(left + totalW * 0.52 + book.depthX * 0.4, 774, totalW * 0.6, 22, {r = 0, g = 0, b = 0, a = 120})
    base:ellipse(left + totalW * 0.56 + book.depthX * 0.5, 777, totalW * 0.72, 28, {r = 0, g = 0, b = 0, a = 55})

    DrawBackCover(base, book, mat)
    DrawPages(base, book, plan, rng)

    local ex0, ey0 = P(book, 1, 0)
    local ex1, ey1 = P(book, 1, 1)
    local ebx0, eby0 = Off(book, ex0, ey0, 0.05)
    local ebx1, eby1 = Off(book, ex1, ey1, 0.05)
    base:polygon({{ex0, ey0}, {ebx0, eby0}, {ebx1, eby1}, {ex1, ey1}}, WithAlpha(mat.Dark, 255))
    local bbx0, bby0 = P(book, 0.015, 1)
    local bb1x, bb1y = Off(book, bbx0, bby0, 0.05)
    local bb2x, bb2y = Off(book, ex1, ey1, 0.05)
    base:polygon({{bbx0, bby0}, {ex1, ey1}, {bb2x, bb2y}, {bb1x, bb1y}}, WithAlpha(mat.Dark, 255))

    DrawSpine(base, book, plan, mat, tool)
    DrawCoverBase(base, book, mat)

    local texture = Textures[plan.material]
    if texture then
        texture(base, book, rng, mat)
    end

    DrawFrame(base, book, plan, mat, trim, tool)

    local sigilV = 0.47
    if plan.title then
        sigilV = 0.5
    end
    if plan.exlibrisPlate then
        sigilV -= 0.02
    end

    if plan.title then
        local tx, ty = P(book, 0.5, 0.148)
        DrawTextTooled(base, plan.title :: string, tx, ty, 46, tool, mat, coverW * 0.6)
    end

    local sigil = plan.sigil
    if sigil then
        local built = sigil :: Resolver.Sigil
        local art = SigilArt[built.letter]
        if art then
            local s = coverW * (0.24 + 0.022 * built.power)
            local th = math.max(5, s * 0.075) + built.power * 1.4
            local sx, sy = P(book, 0.5, sigilV)
            Emboss(base, art, sx, sy, s, th, tool, mat, built.power)
        end
    end

    if plan.exlibrisPlate then
        DrawExlibris(base, book, plan, mat, tool)
    end

    DrawStuds(base, book, plan, metal)

    if plan.corners then
        DrawCorners(base, book, metal)
    end

    if plan.clasps > 0 then
        local slots: {number}
        if plan.locked then
            slots = ({{0.28}, {0.26, 0.74}, {0.26, 0.42, 0.84}})[plan.clasps]
        else
            slots = ({{0.5}, {0.3, 0.7}, {0.26, 0.5, 0.74}})[plan.clasps]
        end
        for _, v in ipairs(slots) do
            DrawStrap(base, book, v, metal, plan.cursed, rng)
        end
    end

    if plan.locked then
        DrawStrap(base, book, 0.5, metal, false, rng)
        DrawLock(base, book, metal, rng, plan.cursed)
    end

    if plan.ribbons > 0 then
        DrawRibbons(base, book, plan, rng)
    end

    if plan.chained then
        DrawChain(base, book, metal, rng)
    end

    if plan.cursed then
        DrawCurse(base, book, mat, rng)
    end

    local t0x, t0y = P(book, 0.004, 0.004)
    local t1x, t1y = P(book, 0.996, 0.004)
    base:line(t0x, t0y, t1x, t1y, WithAlpha(LerpColor(mat.Light, {r = 255, g = 255, b = 255}, 0.4), 120), 3)
    local bt0x, bt0y = P(book, 0.004, 0.996)
    local bt1x, bt1y = P(book, 0.996, 0.996)
    base:line(bt0x, bt0y, bt1x, bt1y, WithAlpha(mat.Deep, 200), 3)

    base = DrawGlowAccents(base, book, plan, rng)

    return base:vignette(0.32)
end

function module.Encode(image: Canvas): string
    return image:encode("png")
end

return module
