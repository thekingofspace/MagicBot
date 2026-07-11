--#include[canvas, random]
local Brewer = require("@src/potion/Brewer")
local Essences = require("@src/potion/Essences")

local module = {}

local Size = 900
local Cx = Size / 2

local Rng = random.new()

local GlassColor = {r = 198, g = 219, b = 235}
local White = {r = 255, g = 255, b = 255}
local Black = {r = 0, g = 0, b = 0}

local FontCandidates = {
    "C:/Windows/Fonts/Inkfree.ttf",
    "C:/Windows/Fonts/segoepr.ttf",
    "C:/Windows/Fonts/comic.ttf",
    "C:/Windows/Fonts/georgia.ttf",
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
    local steps = 26
    local points = {}
    for i = 0, steps do
        local t = fromAngle + (toAngle - fromAngle) * i / steps
        table.insert(points, {cx + radius * math.cos(t), cy + radius * math.sin(t)})
    end
    cv:polyline(points, color, thickness)
end

type Profile = {
    top: number,
    bottom: number,
    neckBase: number,
    corkHW: number,
    points: {{number}},
}

local Profiles: {[string]: Profile} = {
    vial = {
        top = 258, bottom = 738, neckBase = 320, corkHW = 44,
        points = {{258, 44}, {310, 48}, {560, 55}, {670, 55}, {712, 48}, {738, 26}},
    },
    flask = {
        top = 232, bottom = 748, neckBase = 386, corkHW = 40,
        points = {{232, 40}, {370, 40}, {432, 92}, {498, 164}, {562, 188}, {640, 178}, {700, 132}, {734, 74}, {748, 34}},
    },
    jug = {
        top = 242, bottom = 750, neckBase = 338, corkHW = 68,
        points = {{242, 68}, {330, 66}, {392, 150}, {452, 202}, {560, 212}, {652, 198}, {712, 148}, {740, 86}, {750, 44}},
    },
    heart = {
        top = 268, bottom = 738, neckBase = 356, corkHW = 30,
        points = {{268, 30}, {334, 34}, {382, 104}, {428, 124}, {508, 120}, {612, 94}, {694, 52}, {738, 12}},
    },
    alembic = {
        top = 200, bottom = 748, neckBase = 470, corkHW = 20,
        points = {{200, 20}, {252, 24}, {300, 40}, {348, 24}, {410, 26}, {470, 44}, {540, 104}, {634, 122}, {714, 96}, {748, 50}},
    },
    flute = {
        top = 212, bottom = 748, neckBase = 428, corkHW = 24,
        points = {{212, 24}, {318, 26}, {428, 32}, {498, 58}, {586, 68}, {676, 62}, {726, 44}, {748, 26}},
    },
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

local function LiquidColorAt(brew: Brewer.Brew, t: number, layerT: number): {r: number, g: number, b: number}
    local top = brew.Color
    local bottom = brew.Color
    if brew.SecondColor then
        bottom = brew.SecondColor
    end

    local color
    if brew.SecondColor then
        if t < layerT - 0.08 then
            color = top
        elseif t > layerT + 0.08 then
            color = bottom
        else
            color = BlendRGB(top, bottom, (t - (layerT - 0.08)) / 0.16)
        end
    else
        color = top
    end

    if brew.Kind == "water" then
        color = BlendRGB(Darken(color, 0.55), White, 0.12)
        return BlendRGB(Brighten(color, 0.1), Darken(color, 0.2), t)
    end

    return BlendRGB(Brighten(color, 0.14), Darken(color, 0.3), t)
end

local function RenderShattered(brew: Brewer.Brew): Canvas
    local Roll = NewRoll(HashString(brew.Recipe or "empty"))
    local floorY = 758

    local base = canvas.new(Size, Size, {r = 11, g = 9, b = 20, a = 255})
    base:polygon({{0, floorY}, {Size, floorY}, {Size, Size}, {0, Size}}, {r = 18, g = 15, b = 30, a = 255})
    base:line(0, floorY, Size, floorY, {r = 44, g = 37, b = 66, a = 255}, 2)
    for i = 8, 1, -1 do
        base:circle(Cx, floorY - 60, 300 * i / 8, WithAlpha(brew.Color, 5))
    end

    local spill = canvas.new(Size, Size, {r = 0, g = 0, b = 0, a = 0})
    spill:ellipse(Cx, floorY + 6, 250, 26, WithAlpha(brew.Color, 150))
    spill:ellipse(Cx - 40, floorY + 4, 150, 16, WithAlpha(Brighten(brew.Color, 0.3), 130))
    spill:ellipse(Cx + 120, floorY + 10, 70, 10, WithAlpha(brew.Color, 120))
    spill:ellipse(Cx - 210, floorY + 12, 40, 7, WithAlpha(brew.Color, 110))

    local stumpTop = 660
    local profile = Profiles.flask
    local stump = {}
    local sy = stumpTop
    while sy <= profile.bottom do
        table.insert(stump, {Cx - HWAt(profile, sy), sy})
        sy += 4
    end
    sy = profile.bottom
    while sy >= stumpTop do
        table.insert(stump, {Cx + HWAt(profile, sy), sy})
        sy -= 4
    end
    local rim = {}
    local teeth = 9
    for i = 0, teeth do
        local t = i / teeth
        local rx = Cx + HWAt(profile, stumpTop) * (1 - t * 2)
        local ry = stumpTop + (if i % 2 == 0 then -14 - Roll() * 10 else 6 + Roll() * 8)
        table.insert(rim, {rx, ry})
    end
    spill:polygon({{Cx - HWAt(profile, 700), 700}, {Cx + HWAt(profile, 700), 700}, {Cx + HWAt(profile, profile.bottom), profile.bottom}, {Cx - HWAt(profile, profile.bottom), profile.bottom}}, WithAlpha(brew.Color, 70))
    spill:polyline(stump, WithAlpha(GlassColor, 215), 4)
    spill:polyline(rim, WithAlpha(GlassColor, 200), 3)

    for _ = 1, 11 do
        local sx = Cx + (Roll() * 2 - 1) * 280
        local sw = 8 + Roll() * 16
        local sh = 12 + Roll() * 46
        local lean = (Roll() * 2 - 1) * 14
        spill:polygon({{sx - sw, floorY}, {sx + sw, floorY}, {sx + lean, floorY - sh}}, WithAlpha(GlassColor, 90))
        spill:polyline({{sx - sw, floorY}, {sx + lean, floorY - sh}, {sx + sw, floorY}}, WithAlpha(Brighten(GlassColor, 0.3), 180), 2)
    end

    local corkX = Cx + 224
    spill:polygon({
        {corkX - 30, floorY - 4},
        {corkX + 26, floorY - 16},
        {corkX + 34, floorY + 2},
        {corkX - 22, floorY + 12},
    }, {r = 176, g = 134, b = 86, a = 255})
    spill:line(corkX - 24, floorY - 2, corkX + 26, floorY - 12, {r = 138, g = 100, b = 58, a = 200}, 2)

    local sparkColor = Brighten(brew.Color, 0.6)
    for _ = 1, 14 do
        local px = Cx + (Roll() * 2 - 1) * 240
        local py = floorY - 20 - Roll() * 320
        spill:circle(px, py, 1.4 + Roll() * 1.8, WithAlpha(sparkColor, 60 + math.floor(Roll() * 130)))
    end

    local glowed = spill:clone():glow(7, WithAlpha(brew.Color, 130), 1.2)
    local merged = base:merge(glowed, "add"):merge(spill, "normal")
    return merged:vignette(0.35)
end

function module.Render(brew: Brewer.Brew): Canvas
    if brew.Kind == "shattered" then
        return RenderShattered(brew)
    end

    local profile = Profiles[brew.Vessel] or Profiles.flask
    local Roll = NewRoll(HashString(brew.Recipe or "empty"))
    local function PourRoll(): number
        if brew.PerPour then
            return Rng:NextNumber()
        end
        return Roll()
    end

    local inset = 6
    local maxHW = 0
    for _, point in ipairs(profile.points) do
        maxHW = math.max(maxHW, point[2])
    end

    local bottomY = profile.bottom - 5
    local topLimit = profile.neckBase + 22
    local fillFrac = math.clamp(0.52 + 0.09 * math.min(brew.Doses - 1, 3) + math.min(brew.Potency, 10) * 0.012, 0.45, 0.92)
    if brew.Kind == "water" then
        fillFrac = 0.6
    end
    if brew.Vapor > 0 then
        fillFrac = math.max(fillFrac - 0.08, 0.4)
    end
    local liquidTop = topLimit + (1 - fillFrac) * (bottomY - topLimit)
    local depth = bottomY - liquidTop

    local liquidAlpha = if brew.Thick > 0 then 246 else 228

    local base = canvas.new(Size, Size, {r = 11, g = 9, b = 20, a = 255})
    local floorY = profile.bottom + 10
    base:polygon({{0, floorY}, {Size, floorY}, {Size, Size}, {0, Size}}, {r = 18, g = 15, b = 30, a = 255})
    base:line(0, floorY, Size, floorY, {r = 44, g = 37, b = 66, a = 255}, 2)
    for i = 8, 1, -1 do
        base:circle(Cx, (liquidTop + bottomY) / 2, 340 * i / 8, WithAlpha(brew.Color, 6))
    end
    base:ellipse(Cx, floorY + 8, maxHW * 1.25, 16, {r = 5, g = 4, b = 11, a = 255})

    local liquid = canvas.new(Size, Size, {r = 0, g = 0, b = 0, a = 0})

    local layerT = 0.55
    local step = 3
    local y = liquidTop
    while y <= bottomY do
        local hw = HWAt(profile, y) - inset
        if hw > 2 then
            local t = (y - liquidTop) / math.max(depth, 1)
            local color = LiquidColorAt(brew, t, layerT)
            liquid:line(Cx - hw, y, Cx + hw, y, WithAlpha(color, liquidAlpha), step + 1)
        end
        y += step
    end

    local bands = brew.ElixirBands or brew.CompoundBands
    if bands then
        for index, band in ipairs(bands) do
            local bandT = if #bands == 2 then 0.42 + 0.3 * (index - 1) else 0.34 + 0.26 * (index - 1)
            local by = liquidTop + depth * bandT
            local bhw = math.max(HWAt(profile, by) - inset - 2, 4)
            liquid:line(Cx - bhw, by, Cx + bhw, by, WithAlpha(Brighten(band, 0.35), 170), 5)
            liquid:line(Cx - bhw, by + 5, Cx + bhw, by + 5, WithAlpha(band, 120), 3)
            liquid:ellipse(Cx, by, bhw, 3, WithAlpha(Brighten(band, 0.55), 90))
        end
    end

    if brew.Curdled and brew.CurdColor then
        local curd = brew.CurdColor :: {r: number, g: number, b: number}
        local curdTop = liquidTop + depth * 0.62
        local cy = curdTop
        while cy <= bottomY do
            local chw = math.max(HWAt(profile, cy) - inset, 4)
            local ct = (cy - curdTop) / math.max(bottomY - curdTop, 1)
            liquid:line(Cx - chw, cy, Cx + chw, cy, WithAlpha(Darken(curd, 0.15 + ct * 0.2), 170), 4)
            cy += 3
        end
        local seam = {}
        local shw = math.max(HWAt(profile, curdTop) - inset, 6)
        for i = 0, 16 do
            local t = i / 16
            table.insert(seam, {Cx - shw + t * shw * 2, curdTop + (Roll() - 0.5) * 10})
        end
        liquid:polyline(seam, WithAlpha(Brighten(curd, 0.25), 160), 3)
        for _ = 1, 12 do
            local gy = curdTop - 6 - Roll() * depth * 0.3
            local ghw = math.max(HWAt(profile, gy) - inset - 6, 4)
            local gx = Cx + (Roll() * 2 - 1) * ghw * 0.8
            local r = 2.5 + Roll() * 3.5
            liquid:circle(gx, gy, r, WithAlpha(Brighten(curd, 0.2), 200))
            liquid:circle(gx + r * 0.7, gy + r * 0.5, r * 0.6, WithAlpha(curd, 190))
        end
    end

    local surfaceHW = HWAt(profile, liquidTop) - inset
    if surfaceHW > 4 then
        local sheen = Brighten(brew.Color, 0.4)
        if brew.Kind == "poison" and not brew.Masked then
            sheen = Darken(brew.Color, 0.35)
        end
        liquid:ellipse(Cx, liquidTop, surfaceHW, 6, WithAlpha(sheen, 190))
        liquid:ellipse(Cx, liquidTop, surfaceHW * 0.82, 4, WithAlpha(Brighten(brew.Color, 0.1), 200))
    end

    if brew.Radiant and surfaceHW > 8 then
        local ringColor = Brighten(brew.Color, 0.85)
        local gapColor = Brighten(brew.Color, 0.1)
        local widths = {0.85, 0.7, 0.52, 0.36, 0.2}
        for index, w in ipairs(widths) do
            local rw = surfaceHW * w
            local color = if index % 2 == 1 then WithAlpha(ringColor, 235) else WithAlpha(gapColor, 215)
            liquid:ellipse(Cx, liquidTop, rw, math.max(2, rw * 0.055), color)
        end
        liquid:circle(Cx, liquidTop, 4, WithAlpha(White, 235))
    end

    for index, tint in ipairs(brew.TopTints or {}) do
        local tintColor = Brighten(tint, 0.2)
        for _ = 1, 4 do
            local ty = liquidTop + 8 + Roll() * math.min(depth * 0.2, 30)
            local thw = math.max(HWAt(profile, ty) - inset - 6, 6)
            local tx = Cx + (Roll() * 2 - 1) * thw * 0.7
            local len = 10 + Roll() * 18
            liquid:line(tx - len / 2, ty, tx + len / 2, ty - 2 + index, WithAlpha(tintColor, 150), 2)
        end
    end

    local function PointInLiquid(marginTop: number, marginBottom: number, spread: number): (number, number, number)
        local py = liquidTop + marginTop + Roll() * math.max(depth - marginTop - marginBottom, 1)
        local hw = math.max(HWAt(profile, py) - inset, 4)
        local px = Cx + (Roll() * 2 - 1) * hw * spread
        return px, py, hw
    end

    local bubbleCount = math.min(4 + brew.Bubbles * 7, 36)
    if brew.Kind == "water" then
        bubbleCount = math.max(bubbleCount, 6)
    end
    if brew.Thick > 0 then
        bubbleCount = math.max(2, math.floor(bubbleCount / 2))
    end
    local bubbleColor = Brighten(brew.Color, 0.62)
    for i = 1, bubbleCount do
        local bx, by = PointInLiquid(16, 14, 0.78)
        local radius = 2 + Roll() * 3.4
        if brew.Thick > 0 then
            radius += 1.6
        end
        if i % 3 == 0 then
            liquid:circle(bx, by, math.max(1.5, radius * 0.45), WithAlpha(bubbleColor, 210))
        else
            liquid:strokeCircle(bx, by, radius, WithAlpha(bubbleColor, 165), 1)
        end
    end

    for s = 1, brew.Swirls * 2 do
        local yc = liquidTop + depth * (0.22 + Roll() * 0.55)
        local amp = 7 + Roll() * 11
        local phase = Roll() * math.pi * 2
        local hw = math.max(HWAt(profile, yc) - inset - 10, 8)
        local points = {}
        for i = 0, 22 do
            local t = i / 22
            local px = Cx - hw + t * hw * 2
            local py = yc + math.sin(phase + t * math.pi * 3) * amp
            if py > liquidTop + 8 and py < bottomY - 6 then
                table.insert(points, {px, py})
            end
        end
        if #points > 2 then
            liquid:polyline(points, WithAlpha(Brighten(brew.Color, 0.32), 120), 3)
        end
    end

    if brew.Spirals > 0 then
        local sy = liquidTop + depth * 0.52
        local maxR = math.min((HWAt(profile, sy) - inset) * 0.85, depth * 0.4)
        local rings = math.min(2 + brew.Spirals, 6)
        for i = 1, rings do
            local radius = maxR * i / rings
            local a0 = Roll() * math.pi * 2
            DrawArc(liquid, Cx, sy, radius, a0, a0 + 4.2, WithAlpha(Brighten(brew.Color, 0.3), 110), 2)
        end
    end

    if brew.Uneasy then
        local churnColor = if brew.SecondColor then BlendRGB(brew.Color, brew.SecondColor :: {r: number, g: number, b: number}, 0.5) else brew.Color
        for _ = 1, 6 do
            local cy = liquidTop + depth * (0.2 + Roll() * 0.6)
            local chw = math.max(HWAt(profile, cy) - inset - 8, 8)
            local points = {}
            local px = Cx - chw + Roll() * chw * 0.5
            local reach = chw * (0.9 + Roll() * 0.5)
            local segments = 7
            for i = 0, segments do
                local t = i / segments
                table.insert(points, {math.clamp(px + reach * t, Cx - chw, Cx + chw), cy + (if i % 2 == 0 then -1 else 1) * (5 + Roll() * 9)})
            end
            liquid:polyline(points, WithAlpha(Brighten(churnColor, 0.4), 135), 2)
        end
    end

    if brew.CatalystSeam then
        local seam = {}
        local sy2 = liquidTop + 8
        while sy2 <= bottomY - 6 do
            table.insert(seam, {Cx + math.sin((sy2 - liquidTop) * 0.06) * 5, sy2})
            sy2 += 6
        end
        if #seam > 2 then
            local seamColor = Brighten(brew.Color, 0.55)
            liquid:polyline(seam, WithAlpha(seamColor, 130), 2)
            for i = 1, 4 do
                local node = seam[math.max(1, math.floor(#seam * i / 5))]
                liquid:circle(node[1], node[2], 2.6, WithAlpha(seamColor, 190))
            end
        end
    end

    local grainCount = if brew.Sediment > 0 then math.min(6 + brew.Sediment * 4, 30) else 0
    local grainColor = if brew.Kind == "poison" then Darken(brew.Color, 0.45) else {r = 104, g = 90, b = 66}
    for _ = 1, grainCount do
        local gy = bottomY - 5 - Roll() * math.min(24, depth * 0.3)
        local hw = math.max(HWAt(profile, gy) - inset - 4, 4)
        local gx = Cx + (Roll() * 2 - 1) * hw * 0.85
        liquid:circle(gx, gy, 1.5 + Roll() * 1.8, WithAlpha(grainColor, 215))
    end

    local charmShown = math.min(#brew.Charms, 3)
    for index = 1, charmShown do
        local charm = brew.Charms[index]
        local charmColor = if charm.letter then Essences.Get(charm.letter :: string).Color else {r = 235, g = 205, b = 130}
        local mx = Cx + (index - (charmShown + 1) / 2) * 52
        local my = liquidTop + depth * 0.38 + (index - 1) * 18
        local bright = Brighten(charmColor, 0.55)
        liquid:circle(mx, my, 8, WithAlpha(bright, 255))
        liquid:strokeCircle(mx, my, 14, WithAlpha(bright, 130), 2)
        liquid:strokeCircle(mx, my, 21, WithAlpha(charmColor, 70), 1)
        if charm.unstable then
            for d = 0, 4 do
                local a = math.pi * 2 * d / 5 + (Roll() - 0.5)
                liquid:circle(mx + math.cos(a) * (26 + Roll() * 6), my + math.sin(a) * (26 + Roll() * 6), 2, WithAlpha(bright, 160))
            end
        end
    end

    if brew.Frost > 0 then
        local lozenges = math.clamp(brew.Doses, 1, 4)
        local ice = Brighten(brew.Color, 0.72)
        for index = 1, lozenges do
            local lx = Cx + (index - (lozenges + 1) / 2) * 58
            local ly = liquidTop + depth * (0.42 + 0.14 * ((index - 1) % 2))
            local w, h = 13, 20
            liquid:polygon({{lx, ly - h}, {lx + w, ly}, {lx, ly + h}, {lx - w, ly}}, WithAlpha(ice, 185))
            liquid:polyline({{lx, ly - h}, {lx + w, ly}, {lx, ly + h}, {lx - w, ly}, {lx, ly - h}}, WithAlpha(White, 200), 2)
            liquid:line(lx, ly - h, lx, ly + h, WithAlpha(White, 130), 1)
            liquid:line(lx - w, ly, lx + w, ly, WithAlpha(White, 110), 1)
        end
    end

    local rackShown = math.min(#brew.Rack, 3)
    for index = 1, rackShown do
        local phial = brew.Rack[index]
        local px = Cx + (index - (rackShown + 1) / 2) * 58
        local py = liquidTop + depth * 0.22
        local w, h = 11, 20
        local phialGlass = Brighten(GlassColor, 0.2)
        if not phial.Drawn and phial.Color then
            local fill = phial.Color :: {r: number, g: number, b: number}
            liquid:polygon({{px - w + 2, py - 4}, {px + w - 2, py - 4}, {px + w - 2, py + h - 2}, {px - w + 2, py + h - 2}}, WithAlpha(Brighten(fill, 0.15), 235))
            liquid:ellipse(px, py - 4, w - 2, 2, WithAlpha(Brighten(fill, 0.45), 200))
        end
        liquid:polyline({
            {px - 4, py - h - 4}, {px - 4, py - h + 2}, {px - w, py - h + 8}, {px - w, py + h - 3},
            {px - w + 3, py + h}, {px + w - 3, py + h}, {px + w, py + h - 3}, {px + w, py - h + 8},
            {px + 4, py - h + 2}, {px + 4, py - h - 4}, {px - 4, py - h - 4},
        }, WithAlpha(phialGlass, 210), 2)
        if phial.Drawn then
            liquid:line(px - w + 3, py - h + 9, px + w - 3, py + h - 4, WithAlpha(phialGlass, 120), 1)
        else
            liquid:polygon({{px - 5, py - h - 9}, {px + 5, py - h - 9}, {px + 4, py - h - 1}, {px - 4, py - h - 1}}, {r = 176, g = 134, b = 86, a = 245})
            liquid:line(px - 5, py - h - 8, px + 5, py - h - 8, {r = 198, g = 158, b = 108, a = 220}, 1)
        end
    end

    if brew.Volatile then
        local fizzColor = Brighten(brew.Color, 0.55)
        for _ = 1, 14 do
            local fy = profile.top + 26 + PourRoll() * math.max(liquidTop - profile.top - 40, 10)
            local hw = math.max(HWAt(profile, fy) - inset - 3, 3)
            local fx = Cx + (PourRoll() * 2 - 1) * hw * 0.65
            liquid:circle(fx, fy, 1.4 + PourRoll() * 1.6, WithAlpha(fizzColor, 90 + math.floor(PourRoll() * 100)))
        end
        for _ = 1, 10 do
            local fx = Cx + (PourRoll() * 2 - 1) * surfaceHW * 0.8
            liquid:circle(fx, liquidTop - 3 - PourRoll() * 8, 1.6, WithAlpha(fizzColor, 170))
        end
    end

    if brew.Thunder then
        local boltColor = Brighten(brew.Color, 0.75)
        for _ = 1, 2 do
            local bx = Cx + (PourRoll() * 2 - 1) * surfaceHW * 0.5
            local by = liquidTop + depth * (0.25 + PourRoll() * 0.4)
            liquid:polyline({{bx, by}, {bx + 7, by + 9}, {bx - 2, by + 13}, {bx + 6, by + 24}}, WithAlpha(boltColor, 200), 2)
        end
    end

    if brew.Vapor > 0 then
        local wispColor = Brighten(brew.Color, 0.5)
        local span = math.max(liquidTop - profile.top - 18, 24)
        for _ = 1, 4 do
            local points = {}
            local wx = Cx + (Roll() * 2 - 1) * surfaceHW * 0.5
            local drift = (Roll() * 2 - 1) * 14
            local amp = 6 + Roll() * 9
            local phase = Roll() * math.pi * 2
            local steps = 20
            for i = 0, steps do
                local t = i / steps
                local py = liquidTop - 4 - t * span
                local hw = math.max(HWAt(profile, py) - inset - 4, 4)
                local px = math.clamp(wx + drift * t + math.sin(phase + t * math.pi * 2.4) * amp * t, Cx - hw, Cx + hw)
                table.insert(points, {px, py})
            end
            liquid:polyline(points, WithAlpha(wispColor, 84), 3)
        end
        for _ = 1, 6 do
            local py = liquidTop - 8 - Roll() * span * 0.8
            local hw = math.max(HWAt(profile, py) - inset - 4, 4)
            liquid:circle(Cx + (Roll() * 2 - 1) * hw * 0.7, py, 1.5 + Roll() * 1.8, WithAlpha(wispColor, 70))
        end
    end

    local glass = canvas.new(Size, Size, {r = 0, g = 0, b = 0, a = 0})

    local corkMouthHW = HWAt(profile, profile.top)
    local corkTop = profile.top - 46
    local hwT = corkMouthHW + 11
    local hwB = corkMouthHW + 2
    glass:polygon({
        {Cx - hwT, corkTop + 8},
        {Cx + hwT, corkTop + 8},
        {Cx + hwB, profile.top + 14},
        {Cx - hwB, profile.top + 14},
    }, {r = 176, g = 134, b = 86, a = 255})
    glass:ellipse(Cx, corkTop + 8, hwT, 9, {r = 198, g = 158, b = 108, a = 255})
    glass:line(Cx - hwB - 2, corkTop + 24, Cx + hwB + 2, corkTop + 24, {r = 138, g = 100, b = 58, a = 200}, 2)
    glass:line(Cx - hwB, corkTop + 36, Cx + hwB, corkTop + 36, {r = 138, g = 100, b = 58, a = 150}, 2)
    glass:line(Cx - hwT, corkTop + 9, Cx - hwB, profile.top + 13, {r = 120, g = 86, b = 50, a = 220}, 2)
    glass:line(Cx + hwT, corkTop + 9, Cx + hwB, profile.top + 13, {r = 120, g = 86, b = 50, a = 220}, 2)

    if brew.Hiss then
        local steam = {}
        local sx = Cx + hwB - 4
        local rise = 56
        for i = 0, 14 do
            local t = i / 14
            table.insert(steam, {sx + math.sin(t * math.pi * 3) * 6 * t + 8 * t, corkTop + 4 - t * rise})
        end
        glass:polyline(steam, WithAlpha(White, 132), 2)
        local steam2 = {}
        for i = 0, 12 do
            local t = i / 12
            table.insert(steam2, {sx - 6 + math.sin(0.9 + t * math.pi * 2.6) * 5 * t + 4 * t, corkTop + 2 - t * rise * 0.7})
        end
        glass:polyline(steam2, WithAlpha(White, 84), 2)
    end

    local outline = {}
    local oy = profile.top
    while oy <= profile.bottom do
        table.insert(outline, {Cx - HWAt(profile, oy), oy})
        oy += 4
    end
    oy = profile.bottom
    while oy >= profile.top do
        table.insert(outline, {Cx + HWAt(profile, oy), oy})
        oy -= 4
    end
    glass:polyline(outline, WithAlpha(GlassColor, 215), 4)
    glass:ellipse(Cx, profile.bottom - 2, HWAt(profile, profile.bottom) * 0.85, 4, WithAlpha(GlassColor, 55))

    local mouthHW = HWAt(profile, profile.top)
    glass:line(Cx - mouthHW - 8, profile.top + 1, Cx + mouthHW + 8, profile.top + 1, WithAlpha(GlassColor, 215), 4)
    glass:line(Cx - mouthHW - 5, profile.top + 5, Cx + mouthHW + 5, profile.top + 5, WithAlpha(GlassColor, 110), 2)

    if brew.Rime > 0 or brew.Frost > 0 then
        local ticks = math.min(10 + (brew.Rime + brew.Frost) * 4, 26)
        for _ = 1, ticks do
            local ty = profile.top + 16 + Roll() * (profile.neckBase + 60 - profile.top - 16)
            local side = if Roll() < 0.5 then -1 else 1
            local edge = HWAt(profile, ty)
            local tx = Cx + side * edge
            local len = 4 + Roll() * 5
            glass:line(tx, ty, tx - side * len, ty + (Roll() - 0.5) * 4, WithAlpha(White, 140), 1)
            if Roll() < 0.4 then
                glass:circle(tx - side * (len + 2), ty, 1.2, WithAlpha(White, 120))
            end
        end
    end

    if brew.Thunder then
        for side = -1, 1, 2 do
            local sy3 = profile.neckBase + 30
            local edge = HWAt(profile, sy3)
            for k = 0, 2 do
                local mx = Cx + side * (edge + 12 + k * 8)
                glass:line(mx, sy3 - 16 + k * 6, mx + side * 5, sy3 + 8 + k * 6, WithAlpha(White, 90 - k * 20), 2)
            end
        end
    end

    local highlight = {}
    local hy = math.max(profile.neckBase + 16, liquidTop - 30)
    while hy <= profile.bottom - 60 do
        table.insert(highlight, {Cx - (HWAt(profile, hy) - inset) * 0.66, hy})
        hy += 4
    end
    if #highlight > 2 then
        glass:polyline(highlight, WithAlpha(White, 30), 9)
        local shortHi = {}
        for i = 1, math.max(math.floor(#highlight * 0.45), 2) do
            table.insert(shortHi, highlight[i])
        end
        glass:polyline(shortHi, WithAlpha(White, 62), 4)
    end
    local echo = {}
    hy = liquidTop + 24
    while hy <= profile.bottom - 90 do
        table.insert(echo, {Cx + (HWAt(profile, hy) - inset) * 0.72, hy})
        hy += 4
    end
    if #echo > 2 then
        glass:polyline(echo, WithAlpha(White, 24), 6)
    end

    if brew.Label then
        local ly = profile.bottom - (profile.bottom - profile.neckBase) * 0.42
        local lhw = math.max(HWAt(profile, ly) - inset, 30)
        local halfW = math.min(lhw * 0.72, 96)
        local halfH = 30
        local tilt = -0.055 + (Roll() - 0.5) * 0.05
        local cosT, sinT = math.cos(tilt), math.sin(tilt)
        local function LabelPoint(dx: number, dy: number): {number}
            return {Cx + dx * cosT - dy * sinT, ly + dx * sinT + dy * cosT}
        end
        local paper = {r = 232, g = 221, b = 196}
        glass:polygon({LabelPoint(-halfW, -halfH), LabelPoint(halfW, -halfH), LabelPoint(halfW, halfH), LabelPoint(-halfW, halfH)}, WithAlpha(paper, 246))
        glass:polyline({LabelPoint(-halfW, -halfH), LabelPoint(halfW, -halfH), LabelPoint(halfW, halfH), LabelPoint(-halfW, halfH), LabelPoint(-halfW, -halfH)}, {r = 150, g = 130, b = 98, a = 255}, 2)
        glass:line(LabelPoint(-halfW + 5, -halfH + 5)[1], LabelPoint(-halfW + 5, -halfH + 5)[2], LabelPoint(halfW - 5, -halfH + 5)[1], LabelPoint(halfW - 5, -halfH + 5)[2], WithAlpha({r = 150, g = 130, b = 98}, 90), 1)

        local text = brew.Label :: string
        local ink = {r = 56, g = 40, b = 28, a = 235}
        if LabelFont and #text > 0 then
            local font = LabelFont :: CanvasFont
            local size = 34
            local width = font:measure(text, size)
            while size > 12 and width > halfW * 2 - 16 do
                size -= 2
                width = font:measure(text, size)
            end
            local lx = -width / 2
            for i = 1, #text do
                local char = string.sub(text, i, i)
                local w, h = font:measure(char, size)
                local jitter = (Roll() - 0.5) * 4
                local dx = lx + w / 2
                local px = Cx + dx * cosT - jitter * sinT
                local py = ly + dx * sinT + jitter * cosT
                glass:text(char, px - w / 2, py - h / 2, size, ink, font)
                lx += w
            end
        elseif #text > 0 then
            glass:line(LabelPoint(-halfW + 12, 2)[1], LabelPoint(-halfW + 12, 2)[2], LabelPoint(halfW - 12, 2)[1], LabelPoint(halfW - 12, 2)[2], ink, 3)
        end
    end

    local strong = brew.Potency >= 6 and brew.Kind ~= "water"
    local glowStrength = if strong then 1.5 elseif brew.Kind == "water" then 0.5 else 1.0
    local glowed = liquid:clone():glow(if strong then 9 else 5, WithAlpha(brew.Color, if strong then 160 else 110), glowStrength)

    local merged = base:merge(glowed, "add"):merge(liquid, "normal"):merge(glass, "normal")
    return merged:vignette(0.35)
end

function module.Encode(image: Canvas): string
    return image:encode("png")
end

return module
