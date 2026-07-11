--#include[canvas, random]
local Cellar = require("@src/ale/Cellar")

local module = {}

local Size = 900
local Cx = Size / 2
local ShelfY = 780
local Anchor = 776

-- Rowdy pours alone may splash differently every time.
local Rng = random.new()

local GlassColor = {r = 200, g = 216, b = 228}
local White = {r = 255, g = 255, b = 255}
local Black = {r = 0, g = 0, b = 0}

local FontCandidates = {
    "C:/Windows/Fonts/georgia.ttf",
    "C:/Windows/Fonts/times.ttf",
    "C:/Windows/Fonts/arial.ttf",
}

local LabelFont: CanvasFont? = nil
for _, path in ipairs(FontCandidates) do
    if not LabelFont then
        local ok, font = pcall(function()
            return canvas.font(path)
        end)
        if ok and font then
            LabelFont = font
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

local function DrawArc(cv: Canvas, cx: number, cy: number, radius: number, fromAngle: number, toAngle: number, color: any, thickness: number)
    local steps = 24
    local points = {}
    for i = 0, steps do
        local t = fromAngle + (toAngle - fromAngle) * i / steps
        table.insert(points, {cx + radius * math.cos(t), cy + radius * math.sin(t)})
    end
    cv:polyline(points, color, thickness)
end

local function DrawEllipseArc(cv: Canvas, cx: number, cy: number, rx: number, ry: number, fromAngle: number, toAngle: number, color: any, thickness: number)
    local steps = 24
    local points = {}
    for i = 0, steps do
        local t = fromAngle + (toAngle - fromAngle) * i / steps
        table.insert(points, {cx + rx * math.cos(t), cy + ry * math.sin(t)})
    end
    cv:polyline(points, color, thickness)
end

local function RotEllipse(cx: number, cy: number, rx: number, ry: number, rot: number): {{number}}
    local points = {}
    local cosR, sinR = math.cos(rot), math.sin(rot)
    for i = 0, 36 do
        local a = i / 36 * math.pi * 2
        local ex, ey = math.cos(a) * rx, math.sin(a) * ry
        table.insert(points, {cx + ex * cosR - ey * sinR, cy + ex * sinR + ey * cosR})
    end
    return points
end

-- Vessel silhouettes: half-width keypoints down the glass, Catmull-Rom
-- smoothed, with stems, feet, handles, and iron bands per vessel.
type Profile = {top: number, bottom: number, points: {{number}}}

type Art = {
    kind: "glass" | "stem" | "wood" | "bottle" | "clay" | "horn",
    profile: Profile?,
    baseThick: number?,
    stem: {hw: number, toY: number, knop: number?}?,
    foot: {hw: number}?,
    handle: {y1: number, y2: number, out: number}?,
    bands: {number}?,
}

local Arts: {[string]: Art} = {
    pint = {
        kind = "glass", baseThick = 16,
        profile = {top = 300, bottom = 776, points = {{300, 118}, {380, 110}, {560, 96}, {720, 84}, {776, 80}}},
    },
    tankard = {
        kind = "glass", baseThick = 26,
        profile = {top = 390, bottom = 776, points = {{390, 126}, {470, 122}, {600, 118}, {700, 120}, {776, 124}}},
        handle = {y1 = 440, y2 = 706, out = 64},
    },
    flute = {
        kind = "glass", baseThick = 14,
        profile = {top = 190, bottom = 776, points = {{190, 78}, {300, 64}, {470, 48}, {620, 36}, {700, 30}, {744, 36}, {776, 56}}},
    },
    goblet = {
        kind = "stem", baseThick = 8,
        profile = {top = 330, bottom = 566, points = {{330, 112}, {390, 118}, {470, 110}, {530, 82}, {566, 40}}},
        stem = {hw = 13, toY = 736}, foot = {hw = 92},
    },
    wine = {
        kind = "stem", baseThick = 8,
        profile = {top = 280, bottom = 566, points = {{280, 84}, {340, 96}, {440, 98}, {520, 72}, {566, 26}}},
        stem = {hw = 8, toY = 742}, foot = {hw = 82},
    },
    snifter = {
        kind = "stem", baseThick = 8,
        profile = {top = 430, bottom = 700, points = {{430, 64}, {470, 106}, {545, 128}, {620, 116}, {676, 74}, {700, 36}}},
        stem = {hw = 11, toY = 746}, foot = {hw = 86},
    },
    chalice = {
        kind = "stem", baseThick = 8,
        profile = {top = 360, bottom = 548, points = {{360, 150}, {416, 140}, {470, 112}, {516, 64}, {548, 30}}},
        stem = {hw = 17, toY = 728, knop = 644}, foot = {hw = 104},
    },
    coupe = {
        kind = "stem", baseThick = 7,
        profile = {top = 350, bottom = 484, points = {{350, 150}, {384, 128}, {404, 74}, {448, 58}, {484, 26}}},
        stem = {hw = 9, toY = 738}, foot = {hw = 86},
    },
    martini = {
        kind = "stem", baseThick = 5,
        profile = {top = 360, bottom = 520, points = {{360, 148}, {440, 80}, {520, 10}}},
        stem = {hw = 7, toY = 740}, foot = {hw = 82},
    },
    rocks = {
        kind = "glass", baseThick = 30,
        profile = {top = 560, bottom = 776, points = {{560, 106}, {640, 101}, {720, 97}, {776, 94}}},
    },
    highball = {
        kind = "glass", baseThick = 22,
        profile = {top = 330, bottom = 776, points = {{330, 82}, {500, 79}, {680, 75}, {776, 72}}},
    },
    barrel = {
        kind = "wood",
        profile = {top = 330, bottom = 776, points = {{330, 112}, {420, 108}, {560, 102}, {700, 98}, {776, 96}}},
        bands = {356, 730},
        handle = {y1 = 396, y2 = 672, out = 68},
    },
    bottle = {
        kind = "bottle", baseThick = 16,
        profile = {top = 200, bottom = 776, points = {{200, 27}, {320, 28}, {356, 46}, {416, 74}, {600, 78}, {720, 76}, {776, 70}}},
    },
    stoutbottle = {
        kind = "bottle", baseThick = 16,
        profile = {top = 300, bottom = 776, points = {{300, 30}, {356, 32}, {416, 80}, {468, 96}, {620, 98}, {720, 94}, {776, 88}}},
    },
    spiritsbottle = {
        kind = "bottle", baseThick = 14,
        profile = {top = 180, bottom = 776, points = {{180, 25}, {330, 27}, {372, 46}, {424, 60}, {700, 62}, {776, 58}}},
    },
    swingtop = {
        kind = "bottle", baseThick = 16,
        profile = {top = 280, bottom = 776, points = {{280, 28}, {338, 30}, {398, 74}, {456, 90}, {640, 92}, {730, 88}, {776, 82}}},
    },
    demijohn = {
        kind = "bottle", baseThick = 18,
        profile = {top = 290, bottom = 776, points = {{290, 32}, {330, 36}, {390, 100}, {470, 148}, {600, 156}, {700, 138}, {776, 108}}},
    },
    ginbottle = {
        kind = "bottle", baseThick = 14,
        profile = {top = 210, bottom = 776, points = {{210, 26}, {298, 28}, {316, 62}, {330, 84}, {700, 86}, {776, 84}}},
    },
    clayjug = {
        kind = "clay",
        profile = {top = 310, bottom = 776, points = {{310, 36}, {338, 44}, {400, 98}, {470, 122}, {600, 116}, {700, 100}, {776, 78}}},
    },
    horn = {kind = "horn"},
}

local HornLine = {{505, 400}, {492, 470}, {462, 545}, {415, 615}, {358, 668}, {305, 700}, {262, 706}}
local HornRadii = {56, 50, 44, 36, 26, 15, 7}

type BottleStyle = {
    glass: {r: number, g: number, b: number},
    glassA: number,
    outline: {r: number, g: number, b: number},
    cap: "foil" | "crown" | "cork" | "swing",
    labelTop: number,
    labelBot: number,
    default: string,
    wickerY: number?,
}

local BottleStyles: {[string]: BottleStyle} = {
    bottle = {glass = {r = 26, g = 46, b = 32}, glassA = 160, outline = {r = 128, g = 156, b = 132}, cap = "foil", labelTop = 556, labelBot = 672, default = "VINTAGE"},
    stoutbottle = {glass = {r = 52, g = 32, b = 18}, glassA = 170, outline = {r = 150, g = 112, b = 76}, cap = "crown", labelTop = 520, labelBot = 640, default = "STOUT"},
    spiritsbottle = {glass = {r = 44, g = 62, b = 68}, glassA = 95, outline = {r = 150, g = 170, b = 176}, cap = "cork", labelTop = 560, labelBot = 680, default = "OLD FLAME"},
    swingtop = {glass = {r = 30, g = 52, b = 34}, glassA = 150, outline = {r = 126, g = 154, b = 130}, cap = "swing", labelTop = 540, labelBot = 660, default = "BREWHOUSE"},
    demijohn = {glass = {r = 44, g = 66, b = 48}, glassA = 130, outline = {r = 136, g = 160, b = 140}, cap = "cork", labelTop = 500, labelBot = 610, default = "MOTHERS BEST", wickerY = 430},
    ginbottle = {glass = {r = 64, g = 78, b = 82}, glassA = 75, outline = {r = 160, g = 176, b = 180}, cap = "cork", labelTop = 460, labelBot = 670, default = "DRY OATH"},
}

local function HWAt(profile: Profile, y: number): number
    local points = profile.points
    if y <= points[1][1] then
        return points[1][2]
    end
    for i = 1, #points - 1 do
        local p1, p2 = points[i], points[i + 1]
        if y <= p2[1] then
            local p0 = points[i - 1] or p1
            local p3 = points[i + 2] or p2
            local t = (y - p1[1]) / math.max(p2[1] - p1[1], 1)
            local h0, h1, h2, h3 = p0[2], p1[2], p2[2], p3[2]
            local hw = 0.5 * ((2 * h1)
                + (-h0 + h2) * t
                + (2 * h0 - 5 * h1 + 4 * h2 - h3) * t * t
                + (-h0 + 3 * h1 - 3 * h2 + h3) * t * t * t)
            return math.max(hw, 0)
        end
    end
    return points[#points][2]
end

local function ScaleProfile(profile: Profile, s: number): Profile
    local points = {}
    for _, point in ipairs(profile.points) do
        table.insert(points, {Anchor - (Anchor - point[1]) * s, point[2] * s})
    end
    return {
        top = Anchor - (Anchor - profile.top) * s,
        bottom = Anchor - (Anchor - profile.bottom) * s,
        points = points,
    }
end

local function FitText(font: CanvasFont, text: string, maxW: number, startSize: number, minSize: number): (number, number, number)
    local size = startSize
    local w, h = font:measure(text, size)
    while size > minSize and w > maxW do
        size -= 2
        w, h = font:measure(text, size)
    end
    return size, w, h
end

local function EtchText(cv: Canvas, text: string, cx: number, cy: number, maxW: number, carved: boolean)
    if not LabelFont or #text == 0 then
        return
    end
    local font = LabelFont :: CanvasFont
    local size, w, h = FitText(font, text, maxW, 30, 11)
    if carved then
        cv:text(text, cx - w / 2, cy - h / 2 + 2, size, {r = 230, g = 200, b = 160, a = 70}, font)
        cv:text(text, cx - w / 2, cy - h / 2, size, {r = 36, g = 22, b = 12, a = 225}, font)
    else
        cv:text(text, cx - w / 2, cy - h / 2 + 2, size, {r = 0, g = 0, b = 0, a = 60}, font)
        cv:text(text, cx - w / 2, cy - h / 2, size, {r = 255, g = 255, b = 255, a = 96}, font)
    end
end

local function InkText(cv: Canvas, text: string, cx: number, cy: number, maxW: number, startSize: number, color)
    if not LabelFont or #text == 0 then
        return
    end
    local font = LabelFont :: CanvasFont
    local size, w, h = FitText(font, text, maxW, startSize, 10)
    cv:text(text, cx - w / 2, cy - h / 2, size, color, font)
end

local function DrawWheel(cv: Canvas, x: number, y: number, r: number)
    cv:circle(x, y, r, {r = 214, g = 112, b = 28, a = 255})
    cv:circle(x, y, r - 4, {r = 244, g = 178, b = 72, a = 255})
    cv:strokeCircle(x, y, r - 4, {r = 252, g = 224, b = 156, a = 220}, 2)
    for i = 0, 7 do
        local a = i * math.pi / 4 + 0.35
        cv:line(x, y, x + math.cos(a) * (r - 7), y + math.sin(a) * (r - 7), {r = 250, g = 212, b = 128, a = 205}, 2)
    end
    cv:circle(x, y, 3, {r = 252, g = 224, b = 156, a = 255})
end

local function DrawLime(cv: Canvas, x: number, y: number, r: number)
    cv:pie(x, y, r, math.pi * 1.08, math.pi * 1.92, {r = 196, g = 224, b = 100, a = 255})
    DrawArc(cv, x, y, r - 1, math.pi * 1.08, math.pi * 1.92, {r = 88, g = 146, b = 44, a = 255}, 5)
    for i = 1, 3 do
        local a = math.pi * (1.15 + 0.22 * i)
        cv:line(x, y, x + math.cos(a) * (r - 6), y + math.sin(a) * (r - 6), {r = 234, g = 246, b = 180, a = 210}, 2)
    end
end

local function DrawOlive(cv: Canvas, x: number, y: number)
    cv:line(x - 44, y - 4, x + 40, y - 12, {r = 214, g = 190, b = 146, a = 255}, 3)
    cv:circle(x - 4, y - 9, 9, {r = 116, g = 136, b = 54, a = 255})
    cv:circle(x - 4, y - 9, 3.5, {r = 204, g = 84, b = 48, a = 255})
    cv:circle(x - 7, y - 12, 1.6, {r = 240, g = 246, b = 220, a = 200})
end

local function DrawUmbrella(cv: Canvas, x: number, y: number, bent: boolean)
    local stick = {r = 178, g = 146, b = 100, a = 255}
    local topX, topY
    if bent then
        local midX, midY = x + 12, y - 34
        cv:line(x, y, midX, midY, stick, 3)
        topX, topY = midX + 24, midY - 10
        cv:line(midX, midY, topX, topY, stick, 3)
    else
        topX, topY = x + 18, y - 62
        cv:line(x, y, topX, topY, stick, 3)
    end
    local aC = -math.pi / 2 + (if bent then 0.95 else 0.28)
    cv:pie(topX, topY, 34, aC - 1.35, aC + 1.35, {r = 226, g = 110, b = 138, a = 255})
    cv:pie(topX, topY, 24, aC - 1.35, aC + 1.35, {r = 240, g = 154, b = 176, a = 255})
    cv:pie(topX, topY, 13, aC - 1.35, aC + 1.35, {r = 226, g = 110, b = 138, a = 255})
    DrawArc(cv, topX, topY, 34, aC - 1.35, aC + 1.35, {r = 168, g = 62, b = 88, a = 255}, 2)
    for k = -2, 2 do
        local a = aC + k * 0.55
        cv:line(topX, topY, topX + math.cos(a) * 33, topY + math.sin(a) * 33, {r = 168, g = 62, b = 88, a = 200}, 2)
    end
    for k = -2, 2 do
        local a = aC + k * 0.55
        cv:circle(topX + math.cos(a) * 34, topY + math.sin(a) * 34, 3.5, {r = 226, g = 110, b = 138, a = 255})
    end
    cv:line(topX, topY, topX + math.cos(aC) * 42, topY + math.sin(aC) * 42, stick, 2)
    cv:circle(topX + math.cos(aC) * 43, topY + math.sin(aC) * 43, 2.5, {r = 226, g = 110, b = 138, a = 255})
end

local function DrawIce(cv: Canvas, cx: number, cy: number, sz: number, rot: number)
    local cosR, sinR = math.cos(rot), math.sin(rot)
    local points = {}
    for _, c in ipairs({{-1, -1}, {1, -1}, {1, 1}, {-1, 1}}) do
        table.insert(points, {cx + c[1] * sz * cosR - c[2] * sz * sinR, cy + c[1] * sz * sinR + c[2] * sz * cosR})
    end
    cv:polygon(points, {r = 225, g = 240, b = 248, a = 70})
    cv:strokePolygon(points, {r = 240, g = 250, b = 255, a = 160}, 2)
    cv:line(cx - sz * 0.5, cy - sz * 0.4, cx + sz * 0.2, cy - sz * 0.55, {r = 255, g = 255, b = 255, a = 130}, 2)
end

function module.Render(pour: Cellar.Pour): Canvas
    local art = Arts[pour.Vessel] or Arts.pint
    local s = pour.Scale
    local Roll = NewRoll(HashString(pour.Recipe or "dry"))

    local color = pour.Color
    local headColor = pour.HeadColor
    local inset = 6

    local prof: Profile? = if art.profile then ScaleProfile(art.profile :: Profile, s) else nil
    local maxHW = 0
    if prof then
        for _, point in ipairs((prof :: Profile).points) do
            maxHW = math.max(maxHW, point[2])
        end
    else
        maxHW = 190 * s
    end
    local footHW = if art.foot then (art.foot :: {hw: number}).hw * s else 0
    local span = math.max(maxHW, footHW)

    local function HX(x: number): number
        return Cx + (x - Cx) * s
    end
    local function SY(y: number): number
        return Anchor - (Anchor - y) * s
    end
    local function PHW(y: number): number
        return HWAt(prof :: Profile, y) - inset
    end

    -- === Base: the tavern wall and a lamplit wooden shelf ===
    local base = canvas.new(Size, Size, {r = 16, g = 12, b = 9, a = 255})
    for i = 12, 1, -1 do
        base:circle(Cx, 400, 360 * i / 12, WithAlpha({r = 232, g = 158, b = 82}, 3))
    end
    if not pour.Empty then
        for i = 10, 1, -1 do
            base:circle(Cx, 540, 260 * i / 10, WithAlpha(color, 4))
        end
    end
    base:polygon({{0, ShelfY}, {Size, ShelfY}, {Size, Size}, {0, Size}}, {r = 58, g = 38, b = 23, a = 255})
    base:line(0, ShelfY, Size, ShelfY, {r = 118, g = 78, b = 44, a = 255}, 3)
    for i = 1, 4 do
        local gy = ShelfY + 8 + i * 8
        local points = {}
        for k = 0, 12 do
            table.insert(points, {k * Size / 12, gy + math.sin(k * 1.7 + i * 2.3) * 2})
        end
        base:polyline(points, {r = 40, g = 26, b = 15, a = 140}, 1)
    end
    base:polygon({{0, ShelfY + 44}, {Size, ShelfY + 44}, {Size, Size}, {0, Size}}, {r = 34, g = 22, b = 13, a = 255})
    base:line(0, ShelfY + 44, Size, ShelfY + 44, {r = 20, g = 13, b = 8, a = 255}, 2)
    base:ellipse(Cx + 250, ShelfY + 22, 34, 4, {r = 30, g = 19, b = 11, a = 200})
    if art.kind == "horn" then
        base:ellipse(HX(470), ShelfY + 6, 130 * s, 12, {r = 10, g = 6, b = 4, a = 235})
        base:ellipse(HX(300), ShelfY + 4, 70 * s, 8, {r = 10, g = 6, b = 4, a = 160})
    else
        base:ellipse(Cx, ShelfY + 8, span * 1.3, 13, {r = 10, g = 6, b = 4, a = 255})
    end

    local coaster = pour.Tavern ~= nil and pour.Vessel ~= "barrel" and art.kind ~= "bottle"
    local coasterR = math.max(span * 1.3, 130)
    if coaster then
        base:ellipse(Cx, ShelfY + 6, coasterR, 20, {r = 170, g = 130, b = 82, a = 255})
        base:strokeEllipse(Cx, ShelfY + 6, coasterR, 20, {r = 112, g = 80, b = 46, a = 255})
        base:ellipse(Cx, ShelfY + 4, coasterR - 10, 16, {r = 188, g = 148, b = 96, a = 255})
    end

    if pour.Rowdy and not pour.Empty then
        local dir = if pour.Tilt > 0 then -1 elseif pour.Tilt < 0 then 1 else -1
        local px = Cx + dir * (span + 66 + Rng:NextNumber() * 30)
        base:ellipse(px, ShelfY + 16, 50 + Rng:NextNumber() * 16, 10, WithAlpha(Darken(color, 0.15), 215))
        base:ellipse(px - dir * 10, ShelfY + 14, 22, 5, WithAlpha(Brighten(color, 0.3), 130))
        for _ = 1, 3 do
            base:circle(Cx + dir * (span * 0.6 + Rng:NextNumber() * (px - Cx) * dir * 0.7), ShelfY + 10 + Rng:NextNumber() * 8, 2 + Rng:NextNumber() * 2, WithAlpha(color, 200))
        end
    end

    local under = canvas.new(Size, Size, {r = 0, g = 0, b = 0, a = 0})
    local liquid = canvas.new(Size, Size, {r = 0, g = 0, b = 0, a = 0})
    local glass = canvas.new(Size, Size, {r = 0, g = 0, b = 0, a = 0})

    local transparent = art.kind == "glass" or art.kind == "stem"
    local mouthRef = {x = Cx, y = if prof then (prof :: Profile).top else SY(540)}

    -- === Transparent vessels: the pour itself ===
    local liquidTop = 0
    local headH = 0
    if (transparent or art.kind == "bottle") and not pour.Empty then
        local p = prof :: Profile
        local liquidBottom = p.bottom - (art.baseThick or 12) * s
        local topLimit = p.top + 22 * s
        local fill = pour.Fill
        if pour.FoamOnly then
            fill = 0.2
        end
        liquidTop = topLimit + (1 - fill) * (liquidBottom - topLimit)
        local depth = liquidBottom - liquidTop
        local slope = if transparent then pour.Tilt else 0
        local bodyColor = if pour.FoamOnly then headColor else color
        local liquidAlpha = if art.kind == "bottle" then 240 else 232

        local yStart = math.max(math.floor(liquidTop - math.abs(slope) * (maxHW + 6)), p.top + 4)
        local y = yStart
        while y <= liquidBottom do
            local hw = PHW(y)
            if hw > 2 then
                local xLo, xHi = Cx - hw, Cx + hw
                if slope ~= 0 then
                    local cut = Cx + (y - liquidTop) / slope
                    if slope > 0 then
                        xHi = math.min(xHi, cut)
                    else
                        xLo = math.max(xLo, cut)
                    end
                elseif y < liquidTop then
                    xLo = xHi + 1
                end
                if xHi - xLo > 2 then
                    local t = math.clamp((y - liquidTop) / math.max(depth, 1), 0, 1)
                    local shade = BlendRGB(Brighten(bodyColor, 0.14), Darken(bodyColor, 0.3), t)
                    liquid:line(xLo, y, xHi, y, WithAlpha(shade, liquidAlpha), 4)
                end
            end
            y += 3
        end

        local surfaceHW = math.max(PHW(liquidTop), 4)
        if not pour.FoamOnly then
            local sheen = Brighten(bodyColor, 0.35)
            if slope == 0 then
                liquid:ellipse(Cx, liquidTop, surfaceHW, 5, WithAlpha(sheen, 175))
                liquid:ellipse(Cx, liquidTop, surfaceHW * 0.8, 3, WithAlpha(Brighten(bodyColor, 0.12), 200))
            else
                liquid:line(Cx - surfaceHW, liquidTop - slope * surfaceHW, Cx + surfaceHW, liquidTop + slope * surfaceHW, WithAlpha(sheen, 175), 4)
            end
        end

        -- Body texture: bubbles, nitro cascade, currents, opal sheen, murk.
        if transparent and not pour.FoamOnly then
            if pour.Nitro > 0 then
                local surge = depth * 0.32
                local ny = liquidTop + 2
                while ny < liquidTop + surge do
                    local hw = PHW(ny) - 2
                    local t = (ny - liquidTop) / surge
                    if hw > 2 then
                        liquid:line(Cx - hw, ny, Cx + hw, ny, WithAlpha(BlendRGB(headColor, bodyColor, t), math.floor(120 * (1 - t))), 3)
                    end
                    ny += 3
                end
                for i = 1, 26 do
                    local side = if i % 2 == 0 then 1 else -1
                    local sy = liquidTop + 8 + Roll() * depth * 0.75
                    local hw = PHW(sy)
                    if hw > 8 then
                        local sx = Cx + side * (hw - 5 - Roll() * hw * 0.25)
                        liquid:line(sx, sy, sx, sy + 8 + Roll() * 14, WithAlpha(Brighten(bodyColor, 0.4), 70), 2)
                    end
                end
            end

            if pour.Bubbles > 0 then
                local streams = math.min(2 + pour.Bubbles, 6)
                for i = 1, streams do
                    local frac = (Roll() * 2 - 1) * 0.7
                    local by = liquidBottom - 8
                    while by > liquidTop + 8 do
                        local hw = PHW(by)
                        local sway = math.sin(by * 0.05 + i * 2) * 3
                        liquid:circle(Cx + hw * frac + sway, by, 1.4 + Roll() * 1.2, WithAlpha(Brighten(bodyColor, 0.55), 150))
                        by -= 12 + Roll() * 8
                    end
                end
            end

            for _ = 1, math.min(pour.Swirls, 3) * 2 do
                local yc = liquidTop + depth * (0.25 + Roll() * 0.5)
                local amp = 6 + Roll() * 9
                local phase = Roll() * math.pi * 2
                local hw = math.max(PHW(yc) - 10, 8)
                local points = {}
                for i = 0, 22 do
                    local t = i / 22
                    local px = Cx - hw + t * hw * 2
                    local py = yc + math.sin(phase + t * math.pi * 3) * amp
                    if py > liquidTop + 6 and py < liquidBottom - 4 then
                        table.insert(points, {px, py})
                    end
                end
                if #points > 2 then
                    liquid:polyline(points, WithAlpha(Brighten(bodyColor, 0.32), 95), 3)
                end
            end

            if pour.Family == "'" then
                local pastels = {{r = 236, g = 182, b = 204}, {r = 178, g = 206, b = 238}, {r = 190, g = 232, b = 202}}
                for i = 1, 4 do
                    local oy = liquidTop + depth * (0.14 + 0.18 * i)
                    local hw = PHW(oy) - 8
                    if hw > 10 then
                        local points = {}
                        for k = 0, 24 do
                            local px = Cx - hw + k / 24 * hw * 2
                            table.insert(points, {px, oy + math.sin(k / 24 * math.pi * 2.2 + i * 1.7) * 5})
                        end
                        liquid:polyline(points, WithAlpha(pastels[(i % 3) + 1], 60), 4)
                    end
                end
                for _ = 1, 10 do
                    local py = liquidTop + 10 + Roll() * (depth - 20)
                    local hw = math.max(PHW(py) - 8, 4)
                    liquid:circle(Cx + (Roll() * 2 - 1) * hw * 0.8, py, 1 + Roll() * 1.2, WithAlpha(White, 150))
                end
            end

            if pour.Mulled then
                for i = 1, 18 do
                    local py = liquidTop + 4 + Roll() * depth * 0.55
                    if i > 13 then
                        py = liquidTop + (Roll() - 0.5) * 4
                    end
                    local hw = math.max(PHW(py) - 6, 4)
                    liquid:circle(Cx + (Roll() * 2 - 1) * hw * 0.85, py, 1.2 + Roll() * 1.1, WithAlpha({r = 96, g = 52, b = 26}, 220))
                end
            end

            if pour.Family == "%" then
                for _ = 1, 8 do
                    local py = liquidTop + 12 + Roll() * (depth - 24)
                    local hw = math.max(PHW(py) - 10, 6)
                    liquid:ellipse(Cx + (Roll() * 2 - 1) * hw * 0.7, py, 8 + Roll() * 14, 3 + Roll() * 3, WithAlpha(Darken(bodyColor, 0.3), 40))
                end
            end

            local grains = math.min(pour.Sediment, 26)
            for _ = 1, grains do
                local gy = liquidBottom - 4 - Roll() * math.min(22, depth * 0.25)
                local hw = math.max(PHW(gy) - 4, 4)
                liquid:circle(Cx + (Roll() * 2 - 1) * hw * 0.85, gy, 1.4 + Roll() * 1.6, WithAlpha({r = 92, g = 74, b = 48}, 215))
            end

            if pour.Legs and slope == 0 and not pour.FoamOnly then
                local ringY = liquidTop - 16 * s
                if ringY > p.top + 8 then
                    local hw = PHW(ringY) - 3
                    liquid:line(Cx - hw, ringY, Cx + hw, ringY, WithAlpha(Brighten(bodyColor, 0.35), 55), 2)
                    for _ = 1, 6 do
                        local lx = Cx + (Roll() * 2 - 1) * hw * 0.85
                        local wob = (Roll() - 0.5) * 5
                        liquid:polyline({{lx, ringY}, {lx + wob, ringY + 7}, {lx + wob * 1.5, liquidTop - 2}}, WithAlpha(Brighten(bodyColor, 0.3), 70), 2)
                    end
                end
            end

            if pour.Ice == 1 then
                DrawIce(liquid, Cx - 8 * s, liquidTop + 10 * s, 24 * s, 0.16)
            elseif pour.Ice >= 2 then
                DrawIce(liquid, Cx - 16 * s, liquidTop + 16 * s, 19 * s, 0.2)
                DrawIce(liquid, Cx + 14 * s, liquidTop + 42 * s, 19 * s, -0.12)
            end
        end

        -- Foam head with lace, bumps, and the occasional overflow.
        if transparent then
            headH = pour.Head * 14 * s
            if pour.FoamOnly then
                headH = 0
                local fy = liquidTop
                local bx = -surfaceHW
                while bx <= surfaceHW do
                    liquid:circle(Cx + bx, fy + (Roll() - 0.5) * 4, 4 + Roll() * 5, WithAlpha(headColor, 252))
                    bx += 11 + Roll() * 8
                end
                for _ = 1, 8 do
                    local py = liquidTop + 8 + Roll() * (depth - 12)
                    local hw = math.max(PHW(py) - 6, 4)
                    liquid:strokeCircle(Cx + (Roll() * 2 - 1) * hw * 0.7, py, 2 + Roll() * 3, WithAlpha(Darken(headColor, 0.2), 130), 1)
                end
            end
            local mushroom = false
            if headH > 0 then
                local room = liquidTop - (p.top + 8)
                if headH > room then
                    headH = math.max(room, 0)
                    mushroom = true
                end
                if pour.Overflow then
                    mushroom = true
                end
            end
            if headH > 2 then
                local fy = math.floor(liquidTop - headH - math.abs(slope) * (maxHW + 6))
                local fyEnd = liquidTop + math.abs(slope) * (maxHW + 6) + 3
                while fy <= fyEnd do
                    if fy > p.top - 2 then
                        local hw = PHW(fy) + 2
                        if hw > 2 then
                            local xLo, xHi = Cx - hw, Cx + hw
                            if slope ~= 0 then
                                local cutTop = Cx + (fy - liquidTop + headH) / slope
                                local cutBottom = Cx + (fy - liquidTop - 3) / slope
                                if slope > 0 then
                                    xHi = math.min(xHi, cutTop)
                                    xLo = math.max(xLo, cutBottom)
                                else
                                    xLo = math.max(xLo, cutTop)
                                    xHi = math.min(xHi, cutBottom)
                                end
                            elseif fy < liquidTop - headH or fy > liquidTop + 3 then
                                xLo = xHi + 1
                            end
                            if xHi - xLo > 1 then
                                local ft = math.clamp((liquidTop - fy) / math.max(headH, 1), 0, 1)
                                local c = BlendRGB(BlendRGB(headColor, color, 0.3), headColor, ft)
                                liquid:line(xLo, fy, xHi, fy, WithAlpha(c, 250), 3)
                            end
                        end
                    end
                    fy += 2
                end
                local hwTop = math.max(PHW(math.max(liquidTop - headH, p.top)), 6)
                local bx = -hwTop
                while bx <= hwTop do
                    local topY = liquidTop + slope * bx - headH
                    if topY > p.top - 4 then
                        liquid:circle(Cx + bx, topY - Roll() * 4, 3 + Roll() * 5, WithAlpha(headColor, 250))
                    end
                    bx += 11 + Roll() * 8
                end
            end
            if mushroom and pour.Head > 0 then
                local rimHW = PHW(p.top) + 4
                liquid:ellipse(Cx, p.top + 2, rimHW + 6, 11, WithAlpha(headColor, 252))
                local bx = -rimHW
                while bx <= rimHW do
                    liquid:circle(Cx + bx, p.top - 3 - Roll() * 6, 4 + Roll() * 4, WithAlpha(headColor, 250))
                    bx += 12 + Roll() * 7
                end
                local drips = if pour.Rowdy then 2 else 1
                for _ = 1, drips do
                    local dir = if (Roll() + (if pour.Rowdy then Rng:NextNumber() else 0)) % 1 > 0.5 then 1 else -1
                    local dx = Cx + dir * (rimHW + 2)
                    local dLen = 30 + (if pour.Rowdy then Rng:NextNumber() else Roll()) * 55
                    liquid:polyline({{dx, p.top + 6}, {dx + dir * 2, p.top + 6 + dLen * 0.6}, {dx + dir * 3, p.top + 6 + dLen}}, WithAlpha(headColor, 240), 6)
                    liquid:circle(dx + dir * 3, p.top + 8 + dLen, 4, WithAlpha(headColor, 245))
                end
            end
            if pour.Head >= 2 and headH > 0 then
                for i = 1, 2 do
                    local ly = liquidTop - headH - 8 * s - i * 12 * s
                    if ly > p.top + 10 then
                        local hwL = PHW(ly) - 4
                        local lx = Cx - hwL
                        while lx < Cx + hwL do
                            local len = 7 + Roll() * 10
                            if Roll() > 0.45 then
                                liquid:line(lx, ly + (Roll() - 0.5) * 2, math.min(lx + len, Cx + hwL), ly, WithAlpha(White, 30), 2)
                            end
                            lx += len + 8 + Roll() * 12
                        end
                    end
                end
            end
        end
    end

    -- === Glass shell: stem and foot first, then bowl, rim, highlights ===
    if transparent then
        local p = prof :: Profile

        if art.kind == "stem" then
            local st = art.stem :: {hw: number, toY: number, knop: number?}
            local shw = st.hw * s
            local footY = SY(764)
            local footRy = 12 * s
            local bowlBot = p.bottom - 2

            glass:ellipse(Cx, footY, footHW, footRy, WithAlpha(GlassColor, 120))
            glass:strokeEllipse(Cx, footY, footHW, footRy, WithAlpha(GlassColor, 205))
            glass:ellipse(Cx, footY - 3, footHW * 0.6, footRy * 0.45, WithAlpha(White, 22))

            if st.knop then
                local ky = SY(st.knop :: number)
                glass:circle(Cx, ky, shw * 1.7, WithAlpha(GlassColor, 110))
                DrawArc(glass, Cx, ky, shw * 1.7, -0.7, 0.7, WithAlpha(GlassColor, 185), 2)
                DrawArc(glass, Cx, ky, shw * 1.7, math.pi - 0.7, math.pi + 0.7, WithAlpha(GlassColor, 185), 2)
            end
            glass:polygon({{Cx - shw, bowlBot}, {Cx + shw, bowlBot}, {Cx + shw * 1.6, footY}, {Cx - shw * 1.6, footY}}, WithAlpha(GlassColor, 120))
            glass:line(Cx - shw, bowlBot, Cx - shw * 1.6, footY, WithAlpha(GlassColor, 195), 2)
            glass:line(Cx + shw, bowlBot, Cx + shw * 1.6, footY, WithAlpha(GlassColor, 195), 2)
            glass:line(Cx - shw * 0.35, bowlBot + 6, Cx - shw * 0.5, footY - 5, WithAlpha(White, 55), 2)
        end

        if art.handle then
            local h = art.handle :: {y1: number, y2: number, out: number}
            local points = {}
            for i = 0, 20 do
                local t = i / 20
                local hy = SY(h.y1) + (SY(h.y2) - SY(h.y1)) * t
                table.insert(points, {Cx + HWAt(p, hy) + math.sin(math.pi * t) * h.out * s, hy})
            end
            glass:polyline(points, WithAlpha(GlassColor, 200), 12)
            glass:polyline(points, WithAlpha(White, 38), 4)
        end

        local outline = {}
        local oy = p.top
        while oy <= p.bottom do
            table.insert(outline, {Cx - HWAt(p, oy), oy})
            oy += 4
        end
        oy = p.bottom
        while oy >= p.top do
            table.insert(outline, {Cx + HWAt(p, oy), oy})
            oy -= 4
        end
        glass:polyline(outline, WithAlpha(GlassColor, 215), 4)

        if art.kind == "glass" then
            local baseThick = (art.baseThick or 14) * s
            local by = p.bottom - baseThick
            while by <= p.bottom do
                local hw = HWAt(p, by) - 3
                glass:line(Cx - hw, by, Cx + hw, by, WithAlpha(GlassColor, 24), 3)
                by += 2
            end
            glass:line(Cx - HWAt(p, p.bottom), p.bottom, Cx + HWAt(p, p.bottom), p.bottom, WithAlpha(GlassColor, 190), 4)
        end

        local rimHW = HWAt(p, p.top)
        glass:strokeEllipse(Cx, p.top, rimHW, rimHW * 0.08, WithAlpha(GlassColor, 70))
        glass:line(Cx - rimHW - 4, p.top, Cx + rimHW + 4, p.top, WithAlpha(GlassColor, 210), 3)
        glass:line(Cx - rimHW - 1, p.top + 4, Cx + rimHW + 1, p.top + 4, WithAlpha(GlassColor, 80), 2)

        if pour.Salt then
            local sx = -rimHW - 6
            while sx <= rimHW + 6 do
                glass:circle(Cx + sx, p.top + (Roll() - 0.5) * 5, 1 + Roll() * 1.6, WithAlpha({r = 250, g = 250, b = 246}, 190 + Roll() * 60))
                sx += 3 + Roll() * 3
            end
        end

        local highlight = {}
        local hy = p.top + 24 * s
        while hy <= p.bottom - 26 * s do
            table.insert(highlight, {Cx - (HWAt(p, hy) - inset) * 0.74, hy})
            hy += 4
        end
        if #highlight > 2 then
            glass:polyline(highlight, WithAlpha(White, 20), 10)
            local shortHi = {}
            for i = 1, math.max(math.floor(#highlight * 0.28), 2) do
                table.insert(shortHi, highlight[i])
            end
            glass:polyline(shortHi, WithAlpha(White, 46), 5)
        end
        local echo = {}
        hy = p.top + 60 * s
        while hy <= p.bottom - 60 * s do
            table.insert(echo, {Cx + (HWAt(p, hy) - inset) * 0.78, hy})
            hy += 4
        end
        if #echo > 2 then
            glass:polyline(echo, WithAlpha(White, 14), 6)
        end
    end

    -- === Bottles: tinted glass, a cap to match, a paper label ===
    if art.kind == "bottle" then
        local p = prof :: Profile
        local style = BottleStyles[pour.Vessel] or BottleStyles.bottle
        local pTopU = (art.profile :: Profile).top

        local y = p.top
        while y <= p.bottom do
            local hw = HWAt(p, y)
            glass:line(Cx - hw, y, Cx + hw, y, WithAlpha(style.glass, style.glassA), 3)
            y += 2
        end
        glass:ellipse(Cx, p.bottom - 8 * s, HWAt(p, p.bottom) * 0.6, 6, WithAlpha(Darken(style.glass, 0.5), 200))

        local outline = {}
        local oy = p.top
        while oy <= p.bottom do
            table.insert(outline, {Cx - HWAt(p, oy), oy})
            oy += 4
        end
        oy = p.bottom
        while oy >= p.top do
            table.insert(outline, {Cx + HWAt(p, oy), oy})
            oy -= 4
        end
        glass:polyline(outline, WithAlpha(style.outline, 215), 3)

        local mouthHW = HWAt(p, p.top)
        if style.cap == "foil" then
            local capTop = SY(pTopU - 36)
            local capBot = SY(pTopU + 16)
            local cy = capTop
            while cy <= capBot do
                local hw = HWAt(p, math.max(cy, p.top)) + 3
                glass:line(Cx - hw, cy, Cx + hw, cy, {r = 124, g = 28, b = 40, a = 255}, 3)
                cy += 2
            end
            glass:ellipse(Cx, capTop, mouthHW + 3, 5, {r = 152, g = 46, b = 58, a = 255})
            glass:line(Cx - mouthHW - 4, capBot, Cx + mouthHW + 4, capBot, {r = 70, g = 12, b = 22, a = 230}, 3)
        elseif style.cap == "crown" then
            local capTop = SY(pTopU - 16)
            local capBot = SY(pTopU + 6)
            local cy = capTop
            while cy <= capBot do
                glass:line(Cx - mouthHW - 4, cy, Cx + mouthHW + 4, cy, {r = 186, g = 188, b = 196, a = 255}, 3)
                cy += 2
            end
            glass:ellipse(Cx, capTop, mouthHW + 4, 4, {r = 214, g = 216, b = 224, a = 255})
            local bx = -mouthHW - 2
            while bx <= mouthHW + 2 do
                glass:circle(Cx + bx, capBot + 2, 3, {r = 168, g = 170, b = 178, a = 255})
                bx += 6
            end
        elseif style.cap == "swing" then
            local stopY = SY(pTopU - 22)
            glass:ellipse(Cx, stopY, mouthHW + 7, 11, {r = 226, g = 224, b = 218, a = 255})
            glass:ellipse(Cx, stopY - 7, mouthHW + 3, 6, {r = 240, g = 238, b = 232, a = 255})
            glass:line(Cx - mouthHW - 2, SY(pTopU - 6), Cx + mouthHW + 2, SY(pTopU - 6), {r = 168, g = 66, b = 54, a = 255}, 4)
            for _, dir in ipairs({-1, 1}) do
                glass:polyline({
                    {Cx + dir * (mouthHW + 4), stopY},
                    {Cx + dir * (mouthHW + 11), SY(pTopU + 12)},
                    {Cx + dir * (mouthHW + 4), SY(pTopU + 30)},
                }, {r = 174, g = 176, b = 182, a = 255}, 3)
                glass:circle(Cx + dir * (mouthHW + 4), SY(pTopU + 30), 3, {r = 174, g = 176, b = 182, a = 255})
            end
        else
            local corkTop = SY(pTopU - 32)
            local corkBot = SY(pTopU + 6)
            local cy = corkTop
            while cy <= corkBot do
                glass:line(Cx - mouthHW - 2, cy, Cx + mouthHW + 2, cy, {r = 176, g = 134, b = 86, a = 255}, 3)
                cy += 2
            end
            glass:ellipse(Cx, corkTop, mouthHW + 2, 5, {r = 198, g = 158, b = 108, a = 255})
            glass:line(Cx - mouthHW - 1, SY(pTopU - 14), Cx + mouthHW + 1, SY(pTopU - 14), {r = 138, g = 100, b = 58, a = 170}, 2)
        end

        if style.wickerY then
            local wy = SY(style.wickerY :: number)
            local row = wy
            while row <= p.bottom do
                local hw = HWAt(p, row) + 2
                local band = math.floor((row - wy) / (10 * s))
                local wicker = if band % 2 == 0 then {r = 152, g = 114, b = 64} else {r = 128, g = 92, b = 50}
                glass:line(Cx - hw, row, Cx + hw, row, WithAlpha(wicker, 255), 3)
                row += 2
            end
            for _, frac in ipairs({-0.85, -0.6, -0.35, -0.1, 0.15, 0.4, 0.65, 0.9}) do
                local stake = {}
                local sy2 = wy + 4
                while sy2 <= p.bottom - 2 do
                    table.insert(stake, {Cx + frac * (HWAt(p, sy2) + 1), sy2})
                    sy2 += 6
                end
                glass:polyline(stake, {r = 100, g = 70, b = 38, a = 170}, 2)
            end
            local braidHW = HWAt(p, wy) + 4
            glass:line(Cx - braidHW, wy - 3, Cx + braidHW, wy - 3, {r = 176, g = 136, b = 80, a = 255}, 6)
            glass:line(Cx - braidHW, wy - 7, Cx + braidHW, wy - 7, {r = 110, g = 78, b = 42, a = 255}, 2)
            glass:line(Cx - HWAt(p, p.bottom) - 2, p.bottom, Cx + HWAt(p, p.bottom) + 2, p.bottom, {r = 96, g = 66, b = 34, a = 255}, 4)
        end

        local highlight = {}
        local hy = SY(pTopU + 32)
        local hiEnd = if style.wickerY then SY(style.wickerY :: number) - 10 else p.bottom - 46
        while hy <= hiEnd do
            table.insert(highlight, {Cx - (HWAt(p, hy) - inset) * 0.62, hy})
            hy += 4
        end
        if #highlight > 2 then
            glass:polyline(highlight, WithAlpha(White, 24), 6)
        end

        local labelTop = SY(style.labelTop)
        local labelBot = SY(style.labelBot)
        local labelHW = math.min(HWAt(p, (labelTop + labelBot) / 2) - 8, 70 * s)
        glass:roundedRect(Cx - labelHW, labelTop, labelHW * 2, labelBot - labelTop, 6, {r = 232, g = 222, b = 198, a = 248})
        glass:strokeRoundedRect(Cx - labelHW, labelTop, labelHW * 2, labelBot - labelTop, 6, {r = 152, g = 132, b = 100, a = 255}, 2)
        local mid = (labelTop + labelBot) / 2
        local ink = {r = 74, g = 50, b = 32, a = 240}
        if pour.Tavern and #(pour.Tavern :: string) > 0 then
            InkText(glass, pour.Tavern :: string, Cx, mid - 12, labelHW * 2 - 16, 26, ink)
        else
            InkText(glass, style.default, Cx, mid - 12, labelHW * 2 - 16, 22, ink)
        end
        glass:line(Cx - labelHW + 12, mid + 8, Cx + labelHW - 12, mid + 8, {r = 152, g = 132, b = 100, a = 200}, 1)
        if pour.Age > 0 then
            InkText(glass, `{pour.Age} YEARS`, Cx, mid + 24, labelHW * 2 - 20, 16, {r = 110, g = 80, b = 50, a = 235})
        end
    end

    -- === Wooden tankard: upright staves, slim bands, riveted handle ===
    if art.kind == "wood" then
        local p = prof :: Profile

        if art.handle then
            local h = art.handle :: {y1: number, y2: number, out: number}
            local points = {}
            for i = 0, 20 do
                local t = i / 20
                local hy = SY(h.y1) + (SY(h.y2) - SY(h.y1)) * t
                table.insert(points, {Cx + HWAt(p, hy) + math.sin(math.pi * t) * h.out * s, hy})
            end
            under:polyline(points, {r = 92, g = 60, b = 32, a = 255}, 15)
            under:polyline(points, {r = 146, g = 100, b = 58, a = 170}, 5)
            under:circle(Cx + HWAt(p, SY(h.y1)) + 2, SY(h.y1), 5, {r = 64, g = 66, b = 74, a = 255})
            under:circle(Cx + HWAt(p, SY(h.y1)) + 2, SY(h.y1), 2, {r = 150, g = 154, b = 162, a = 255})
            under:circle(Cx + HWAt(p, SY(h.y2)) + 2, SY(h.y2), 5, {r = 64, g = 66, b = 74, a = 255})
            under:circle(Cx + HWAt(p, SY(h.y2)) + 2, SY(h.y2), 2, {r = 150, g = 154, b = 162, a = 255})
        end

        local y = p.top
        while y <= p.bottom do
            local hw = HWAt(p, y)
            local t = (y - p.top) / math.max(p.bottom - p.top, 1)
            local wood = BlendRGB({r = 134, g = 90, b = 50}, {r = 98, g = 62, b = 34}, t)
            under:line(Cx - hw, y, Cx + hw, y, WithAlpha(wood, 255), 3)
            y += 2
        end
        for _, frac in ipairs({-0.72, -0.44, -0.16, 0.16, 0.44, 0.72}) do
            local stave = {}
            local sy = p.top + 8
            while sy <= p.bottom - 4 do
                table.insert(stave, {Cx + frac * HWAt(p, sy), sy})
                sy += 6
            end
            under:polyline(stave, {r = 62, g = 38, b = 20, a = 120}, 2)
        end
        local edgeL, edgeR = {}, {}
        local ey = p.top
        while ey <= p.bottom do
            table.insert(edgeL, {Cx - HWAt(p, ey), ey})
            table.insert(edgeR, {Cx + HWAt(p, ey), ey})
            ey += 4
        end
        under:polyline(edgeL, {r = 52, g = 32, b = 18, a = 220}, 5)
        under:polyline(edgeR, {r = 52, g = 32, b = 18, a = 220}, 5)
        local gleam = {}
        ey = p.top + 20
        while ey <= p.bottom - 16 do
            table.insert(gleam, {Cx - HWAt(p, ey) * 0.55, ey})
            ey += 6
        end
        under:polyline(gleam, {r = 200, g = 150, b = 92, a = 30}, 7)

        for _, bandY in ipairs(art.bands :: {number}) do
            local by = SY(bandY)
            local row = by - 6 * s
            while row <= by + 6 * s do
                local hw = HWAt(p, row) + 2
                under:line(Cx - hw, row, Cx + hw, row, {r = 76, g = 78, b = 86, a = 255}, 3)
                row += 2
            end
            under:line(Cx - HWAt(p, by) - 2, by - 6 * s, Cx + HWAt(p, by) + 2, by - 6 * s, {r = 44, g = 46, b = 52, a = 255}, 2)
            under:line(Cx - HWAt(p, by) - 2, by + 6 * s, Cx + HWAt(p, by) + 2, by + 6 * s, {r = 44, g = 46, b = 52, a = 255}, 2)
            under:line(Cx - HWAt(p, by), by - 3 * s, Cx + HWAt(p, by), by - 3 * s, {r = 140, g = 144, b = 154, a = 120}, 1)
            for _, frac in ipairs({-0.7, -0.25, 0.25, 0.7}) do
                under:circle(Cx + frac * HWAt(p, by), by + 1, 2.2, {r = 144, g = 148, b = 158, a = 255})
            end
        end

        under:line(Cx - HWAt(p, p.bottom), p.bottom, Cx + HWAt(p, p.bottom), p.bottom, {r = 42, g = 26, b = 14, a = 255}, 4)

        local rimHW = HWAt(p, p.top)
        under:ellipse(Cx, p.top, rimHW, rimHW * 0.2, {r = 96, g = 62, b = 34, a = 255})
        under:ellipse(Cx, p.top, rimHW - 8, (rimHW - 8) * 0.18, {r = 32, g = 20, b = 12, a = 255})
    end

    -- === Clay jug: one warm earthenware body, ear handle at the neck ===
    if art.kind == "clay" then
        local p = prof :: Profile

        local hy1, hy2 = SY(336), SY(432)
        local handlePts = {}
        for i = 0, 16 do
            local t = i / 16
            local hy = hy1 + (hy2 - hy1) * t
            table.insert(handlePts, {Cx + HWAt(p, hy) - 2 + math.sin(math.pi * t) * 38 * s, hy})
        end
        under:polyline(handlePts, {r = 134, g = 88, b = 54, a = 255}, 11)
        under:polyline(handlePts, {r = 176, g = 124, b = 82, a = 150}, 4)
        under:circle(handlePts[1][1], handlePts[1][2] + 2, 5, {r = 110, g = 70, b = 42, a = 255})
        under:circle(handlePts[#handlePts][1], handlePts[#handlePts][2] - 2, 5, {r = 110, g = 70, b = 42, a = 255})

        local y = p.top
        while y <= p.bottom do
            local hw = HWAt(p, y)
            local t = (y - p.top) / math.max(p.bottom - p.top, 1)
            local clay = BlendRGB({r = 186, g = 130, b = 84}, {r = 148, g = 98, b = 60}, t)
            under:line(Cx - hw, y, Cx + hw, y, WithAlpha(clay, 255), 3)
            y += 2
        end
        for _, fy in ipairs({0.42, 0.58, 0.74}) do
            local ty = p.top + (p.bottom - p.top) * fy
            DrawEllipseArc(under, Cx, ty, HWAt(p, ty) - 4, 7 * s, math.pi * 0.12, math.pi * 0.88, {r = 108, g = 68, b = 40, a = 46}, 2)
        end
        local edgeL, edgeR = {}, {}
        local ey = p.top
        while ey <= p.bottom do
            table.insert(edgeL, {Cx - HWAt(p, ey), ey})
            table.insert(edgeR, {Cx + HWAt(p, ey), ey})
            ey += 4
        end
        under:polyline(edgeL, {r = 92, g = 58, b = 34, a = 215}, 4)
        under:polyline(edgeR, {r = 92, g = 58, b = 34, a = 215}, 4)
        local gleam = {}
        ey = p.top + 30
        while ey <= p.bottom - 30 do
            table.insert(gleam, {Cx - HWAt(p, ey) * 0.48, ey})
            ey += 6
        end
        under:polyline(gleam, WithAlpha(White, 22), 8)
        under:line(Cx - HWAt(p, p.bottom), p.bottom, Cx + HWAt(p, p.bottom), p.bottom, {r = 84, g = 52, b = 30, a = 255}, 4)

        local rimHW = HWAt(p, p.top)
        under:ellipse(Cx, p.top, rimHW + 4, rimHW * 0.34 + 2, {r = 158, g = 106, b = 66, a = 255})
        under:strokeEllipse(Cx, p.top, rimHW + 4, rimHW * 0.34 + 2, {r = 100, g = 62, b = 36, a = 255})
        under:ellipse(Cx, p.top + 1, rimHW - 5, (rimHW - 5) * 0.3, {r = 34, g = 20, b = 12, a = 255})
    end

    -- === Drinking horn: upright in an iron ring stand on a wooden block ===
    local hornMouth: {x: number, y: number, r: number, rot: number}? = nil
    if art.kind == "horn" then
        local pts = {}
        for i = 1, #HornLine - 1 do
            local a, b = HornLine[i], HornLine[i + 1]
            local ra, rb = HornRadii[i], HornRadii[i + 1]
            for k = 0, 9 do
                local t = k / 10
                table.insert(pts, {x = a[1] + (b[1] - a[1]) * t, y = a[2] + (b[2] - a[2]) * t, r = ra + (rb - ra) * t})
            end
        end
        table.insert(pts, {x = HornLine[#HornLine][1], y = HornLine[#HornLine][2], r = HornRadii[#HornRadii]})

        local edgeA, edgeB = {}, {}
        for i, pt in ipairs(pts) do
            local nxt = pts[math.min(i + 1, #pts)]
            local prv = pts[math.max(i - 1, 1)]
            local dx, dy = nxt.x - prv.x, nxt.y - prv.y
            local len = math.max(math.sqrt(dx * dx + dy * dy), 0.01)
            local nx, ny = -dy / len, dx / len
            table.insert(edgeA, {HX(pt.x + nx * pt.r), SY(pt.y + ny * pt.r)})
            table.insert(edgeB, {HX(pt.x - nx * pt.r), SY(pt.y - ny * pt.r)})
        end

        local iron = {r = 62, g = 64, b = 72}
        local ironLight = {r = 118, g = 122, b = 132}
        local ringIdx = 21
        local rp = pts[ringIdx]
        local rNxt, rPrv = pts[ringIdx + 1], pts[ringIdx - 1]
        local rdx, rdy = rNxt.x - rPrv.x, rNxt.y - rPrv.y
        local rLen = math.max(math.sqrt(rdx * rdx + rdy * rdy), 0.01)
        local ringRot = math.atan2(rdx / rLen, -rdy / rLen)
        local ringCx, ringCy = HX(rp.x), SY(rp.y)
        local ringRx = rp.r * s + 7
        local ringRy = ringRx * 0.34
        local ring = RotEllipse(ringCx, ringCy, ringRx, ringRy, ringRot)

        local blockW = 112 * s
        local blockH = 30 * s
        local blockX = HX(470)
        under:polygon({{blockX - blockW, Anchor - blockH}, {blockX + blockW, Anchor - blockH}, {blockX + blockW, Anchor + 2}, {blockX - blockW, Anchor + 2}}, {r = 92, g = 60, b = 34, a = 255})
        under:line(blockX - blockW, Anchor - blockH, blockX + blockW, Anchor - blockH, {r = 140, g = 96, b = 56, a = 255}, 3)
        under:line(blockX - blockW, Anchor + 1, blockX + blockW, Anchor + 1, {r = 44, g = 28, b = 16, a = 255}, 3)
        for _, frac in ipairs({-0.6, 0, 0.6}) do
            under:line(blockX + frac * blockW, Anchor - blockH + 5, blockX + frac * blockW * 0.9, Anchor - 3, {r = 60, g = 38, b = 22, a = 130}, 2)
        end

        local postX = ringCx + 10 * s
        local postTop = ringCy + ringRy - 4
        under:line(postX, postTop, postX, Anchor - blockH + 4, WithAlpha(iron, 255), 14)
        under:line(postX - 3, postTop, postX - 3, Anchor - blockH + 4, WithAlpha(ironLight, 110), 3)
        under:line(postX - 30 * s, Anchor - blockH + 2, postX, Anchor - blockH - 34 * s, WithAlpha(iron, 255), 7)
        under:line(postX + 30 * s, Anchor - blockH + 2, postX, Anchor - blockH - 34 * s, WithAlpha(iron, 255), 7)

        under:polyline(ring, WithAlpha(iron, 255), 9)

        local hornLight = {r = 196, g = 156, b = 108}
        local hornDark = {r = 58, g = 42, b = 32}
        for i = 1, #pts - 1 do
            local t = i / #pts
            under:polygon({edgeA[i], edgeA[i + 1], edgeB[i + 1], edgeB[i]}, WithAlpha(BlendRGB(hornLight, hornDark, t), 255))
        end
        under:circle(HX(pts[#pts].x), SY(pts[#pts].y), pts[#pts].r * s + 1, WithAlpha(hornDark, 255))
        under:polyline(edgeA, {r = 44, g = 32, b = 24, a = 235}, 3)
        under:polyline(edgeB, {r = 44, g = 32, b = 24, a = 235}, 3)
        for i = 10, #pts - 8, 9 do
            under:line(edgeA[i][1], edgeA[i][2], edgeB[i][1], edgeB[i][2], {r = 54, g = 38, b = 28, a = 44}, 2)
        end
        local sheen = {}
        for i = 3, math.floor(#pts * 0.72) do
            local pt = pts[i]
            local a = edgeA[i]
            table.insert(sheen, {a[1] * 0.35 + HX(pt.x) * 0.65, a[2] * 0.35 + SY(pt.y) * 0.65})
        end
        under:polyline(sheen, WithAlpha(White, 36), 4)

        local ringFront = {}
        for _, point in ipairs(ring) do
            if point[2] >= ringCy - 2 then
                table.insert(ringFront, point)
            else
                if #ringFront > 1 then
                    under:polyline(ringFront, WithAlpha(iron, 255), 9)
                    under:polyline(ringFront, WithAlpha(ironLight, 130), 3)
                end
                ringFront = {}
            end
        end
        if #ringFront > 1 then
            under:polyline(ringFront, WithAlpha(iron, 255), 9)
            under:polyline(ringFront, WithAlpha(ironLight, 130), 3)
        end

        local m0, m1 = pts[1], pts[3]
        local dxm, dym = m1.x - m0.x, m1.y - m0.y
        local len = math.max(math.sqrt(dxm * dxm + dym * dym), 0.01)
        local nx, ny = -dym / len, dxm / len
        local rot = math.atan2(ny, nx)
        local mx, my = HX(m0.x), SY(m0.y)
        local r0 = m0.r * s
        hornMouth = {x = mx, y = my, r = r0, rot = rot}
        mouthRef = {x = mx, y = my}

        under:polygon(RotEllipse(mx, my, r0 + 4, r0 * 0.46 + 3, rot), {r = 168, g = 166, b = 158, a = 255})
        under:strokePolygon(RotEllipse(mx, my, r0 + 4, r0 * 0.46 + 3, rot), {r = 92, g = 90, b = 84, a = 255}, 2)
        under:polygon(RotEllipse(mx, my, r0 - 2, r0 * 0.38, rot), {r = 38, g = 26, b = 20, a = 255})
    end

    -- === Opaque vessels show their drink at the mouth ===
    if (art.kind == "wood" or art.kind == "clay" or art.kind == "horn") and not pour.Empty then
        if art.kind == "horn" then
            local m = hornMouth :: {x: number, y: number, r: number, rot: number}
            liquid:polygon(RotEllipse(m.x, m.y, m.r - 8, m.r * 0.28, m.rot), WithAlpha(Brighten(color, 0.1), 245))
            local ring = RotEllipse(m.x, m.y, m.r * 0.58, m.r * 0.18, m.rot)
            local sheenPts = {}
            for i = 19, 28 do
                table.insert(sheenPts, ring[i])
            end
            liquid:polyline(sheenPts, WithAlpha(Brighten(color, 0.4), 150), 2)
            if pour.Head > 0 or pour.FoamOnly then
                local blobRing = RotEllipse(m.x, m.y, m.r * 0.5, m.r * 0.2, m.rot)
                for i = 1, #blobRing, 5 do
                    liquid:circle(blobRing[i][1], blobRing[i][2], 4 + Roll() * 4, WithAlpha(headColor, 250))
                end
            end
        else
            local p = prof :: Profile
            local rimHW = HWAt(p, p.top)
            local inner = rimHW - (if art.kind == "clay" then 10 else 14)
            local ry = inner * (if art.kind == "clay" then 0.26 else 0.16)
            liquid:ellipse(Cx, p.top, inner, ry, WithAlpha(Brighten(color, 0.08), 250))
            DrawEllipseArc(liquid, Cx, p.top, inner * 0.66, ry * 0.5, math.pi * 1.15, math.pi * 1.85, WithAlpha(Brighten(color, 0.4), 150), 2)
            local fingers = if pour.FoamOnly then 3 else pour.Head
            if fingers > 0 then
                for layer = 0, math.min(fingers - 1, 2) do
                    liquid:ellipse(Cx, p.top - 4 - layer * 6, inner - 4 - layer * 9, math.max(ry - layer, 3), WithAlpha(headColor, 252))
                end
                local bx = -(inner - 6)
                while bx <= inner - 6 do
                    liquid:circle(Cx + bx, p.top - 6 - math.min(fingers - 1, 2) * 6 - Roll() * 5, 4 + Roll() * 4, WithAlpha(headColor, 250))
                    bx += 12 + Roll() * 8
                end
                if pour.Overflow then
                    local dir = if Roll() > 0.5 then 1 else -1
                    local dx = Cx + dir * (rimHW - 8)
                    liquid:polyline({{dx, p.top + 4}, {dx + dir * 3, p.top + 40}, {dx + dir * 4, p.top + 74}}, WithAlpha(headColor, 240), 6)
                    liquid:circle(dx + dir * 4, p.top + 76, 4, WithAlpha(headColor, 245))
                end
            end
        end
    end

    -- === Dressing: carvings, names, frost, steam, garnish, flies ===
    local carvedKind = art.kind == "wood" or art.kind == "clay" or art.kind == "horn"
    if pour.Toast and #(pour.Toast :: string) > 0 then
        local text = pour.Toast :: string
        if art.kind == "horn" then
            EtchText(glass, text, HX(478), SY(498), 92 * s, true)
        elseif art.kind == "bottle" then
            local style = BottleStyles[pour.Vessel] or BottleStyles.bottle
            EtchText(glass, text, Cx, SY(style.labelTop - 86), 110 * s, false)
        elseif prof then
            local p = prof :: Profile
            local ty = p.top + (p.bottom - p.top) * (if art.kind == "wood" then 0.42 else 0.45)
            EtchText(glass, text, Cx, ty, (HWAt(p, ty) - inset) * 1.5, carvedKind)
        end
    end

    if pour.Tavern and #(pour.Tavern :: string) > 0 then
        local name = pour.Tavern :: string
        if pour.Vessel == "barrel" and prof then
            local p = prof :: Profile
            local ny = p.top + (p.bottom - p.top) * 0.6
            EtchText(glass, name, Cx, ny, (HWAt(p, ny) - inset) * 1.4, true)
        elseif coaster then
            InkText(glass, name, Cx, ShelfY + 16, coasterR * 1.2, 20, {r = 54, g = 34, b = 20, a = 245})
        end
    end

    if pour.Chilled then
        if transparent and prof then
            local p = prof :: Profile
            for _ = 1, 70 do
                local fy = p.top + 8 + Roll() * (p.bottom - p.top - 16)
                local hw = math.max(HWAt(p, fy) - 4, 4)
                glass:circle(Cx + (Roll() * 2 - 1) * hw * 0.92, fy, 1 + Roll() * 1.4, WithAlpha(White, 22))
            end
        end
        if prof then
            local p = prof :: Profile
            for _ = 1, 10 do
                local dy = p.top + 20 + Roll() * (p.bottom - p.top - 50)
                local hw = math.max(HWAt(p, dy) - 6, 4)
                local dx = Cx + (Roll() * 2 - 1) * hw * 0.85
                if Roll() > 0.55 then
                    glass:line(dx, dy - 8 - Roll() * 14, dx, dy, WithAlpha({r = 220, g = 238, b = 248}, 60), 2)
                end
                glass:circle(dx, dy, 2 + Roll() * 1.8, WithAlpha({r = 222, g = 240, b = 250}, 120))
                glass:circle(dx - 1, dy - 1, 0.8, WithAlpha(White, 190))
            end
        end
    end

    if pour.Mulled then
        local hwT = if prof then HWAt(prof :: Profile, mouthRef.y) else 50 * s
        for w = 1, 3 do
            local points = {}
            local wx = mouthRef.x + (Roll() * 2 - 1) * hwT * 0.5
            local drift = (Roll() * 2 - 1) * 16
            local amp = 6 + Roll() * 9
            local phase = Roll() * math.pi * 2
            for i = 0, 20 do
                local t = i / 20
                table.insert(points, {wx + drift * t + math.sin(phase + t * math.pi * 2.4) * amp * t, mouthRef.y - 8 - t * (100 + w * 14)})
            end
            glass:polyline(points, WithAlpha({r = 228, g = 222, b = 214}, 66), 4)
        end
    end

    if pour.Fruit then
        if transparent and prof then
            local p = prof :: Profile
            DrawWheel(glass, Cx + HWAt(p, p.top) - 6, p.top, 30 * s)
        elseif pour.Vessel == "barrel" and prof then
            local p = prof :: Profile
            DrawWheel(glass, Cx + HWAt(p, p.top) - 10, p.top - 4, 28 * s)
        else
            DrawWheel(glass, Cx + span + 64, ShelfY - 20, 26)
            glass:ellipse(Cx + span + 64, ShelfY + 8, 28, 5, {r = 10, g = 6, b = 4, a = 180})
        end
    end

    if pour.Garnish == "lime" then
        if transparent and prof then
            local p = prof :: Profile
            DrawLime(glass, Cx + HWAt(p, p.top) - 8, p.top - 2, 26 * s)
        else
            DrawLime(glass, Cx + span + 58, ShelfY - 8, 24)
            glass:ellipse(Cx + span + 58, ShelfY + 6, 26, 4, {r = 10, g = 6, b = 4, a = 180})
        end
    elseif pour.Garnish == "olive" and transparent and prof then
        local p = prof :: Profile
        DrawOlive(glass, Cx + HWAt(p, p.top) * 0.3, p.top)
    end

    if pour.Umbrella then
        if transparent and prof and liquidTop > 0 then
            local p = prof :: Profile
            DrawUmbrella(glass, Cx - HWAt(p, p.top) * 0.3, liquidTop + 6, pour.UmbrellaBent)
        else
            DrawUmbrella(glass, mouthRef.x - 14, mouthRef.y + 4, pour.UmbrellaBent)
        end
    end

    if pour.Family == "%" then
        local top = if prof then (prof :: Profile).top else SY(540)
        for _ = 1, 3 do
            local fx = Cx + (Roll() * 2 - 1) * 130
            local fy = top - 26 - Roll() * 70
            local a0 = Roll() * math.pi * 2
            DrawArc(glass, fx + 6, fy + 5, 9 + Roll() * 9, a0, a0 + 2.8, {r = 158, g = 148, b = 118, a = 46}, 1)
            glass:circle(fx, fy, 2, {r = 44, g = 40, b = 30, a = 235})
            glass:circle(fx - 2, fy - 2, 1.3, {r = 205, g = 205, b = 195, a = 130})
        end
    end

    -- === Compose: a warm glow off the drink, glass over all ===
    local glowStrength = if pour.Empty then 0.25
        elseif pour.Family == "'" then 1.3
        elseif art.kind == "bottle" then 0.5
        elseif pour.Bite then 1.0
        else 0.7
    local glowed = liquid:clone():glow(6, WithAlpha(color, 110), glowStrength)

    local merged = base:merge(under, "normal"):merge(glowed, "add"):merge(liquid, "normal"):merge(glass, "normal")
    return merged:vignette(0.35)
end

function module.Encode(image: Canvas): string
    return image:encode("png")
end

return module
