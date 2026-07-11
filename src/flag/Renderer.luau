--#include[canvas, random]
local Resolver = require("@src/flag/Resolver")

local module = {}

local Width, Height = 960, 640
local PoleX = 116
local PoleTopY = 58
local PoleBottomY = Height - 40
local HoistX = 126
local TopY = 104
local FlagW, FlagH = 690, 400
local Aspect = FlagW / FlagH
local CellSize = 2

local Ripples = 2.4
local WaveAmp = 19

-- Only war-torn banners roll fresh weathering each cast — everything else is deterministic.
local Rng = random.new()

local GoldColor = {r = 224, g = 188, b = 108}
local BrightGold = {r = 250, g = 228, b = 164}
local RimColor = {r = 208, g = 178, b = 108}
local PoleDark = {r = 56, g = 43, b = 32, a = 255}
local PoleLight = {r = 118, g = 92, b = 64, a = 255}
local TieGrey = {r = 176, g = 170, b = 158, a = 220}
local WeatherGrey = {r = 99, g = 92, b = 82}

local function WithAlpha(color: {r: number, g: number, b: number}, alpha: number): {r: number, g: number, b: number, a: number}
    return {r = color.r, g = color.g, b = color.b, a = math.floor(alpha)}
end

local function Lerp(a: number, b: number, t: number): number
    return a + (b - a) * t
end

local function WaveDy(u: number, v: number, droop: number): number
    local phase = 2 * math.pi * Ripples * u - 0.85 * v
    return WaveAmp * math.sin(phase) * u ^ 0.8 + droop * u ^ 1.7
end

-- Light falls from the hoist side: cloth sloping toward it catches highlight,
-- wave troughs fall into shade.
local function WaveShade(u: number): number
    local slope = math.cos(2 * math.pi * Ripples * u) * u ^ 0.8
    local hoist = 0.86 + 0.14 * math.min(u / 0.06, 1)
    return math.clamp((0.88 + 0.16 * slope) * hoist, 0.6, 1.04)
end

local function PointInPolygon(px: number, py: number, points: {{number}}): boolean
    local inside = false
    local j = #points
    for i = 1, #points do
        local xi, yi = points[i][1], points[i][2]
        local xj, yj = points[j][1], points[j][2]
        if (yi > py) ~= (yj > py) then
            local cross = (xj - xi) * (py - yi) / (yj - yi) + xi
            if px < cross then
                inside = not inside
            end
        end
        j = i
    end
    return inside
end

local function BuildStar(cx: number, cy: number, outer: number): {{number}}
    local points = {}
    for j = 0, 9 do
        local angle = -math.pi / 2 + j * math.pi / 5
        local radius = if j % 2 == 0 then outer else outer * 0.42
        table.insert(points, {cx + radius * math.cos(angle), cy + radius * math.sin(angle)})
    end
    return points
end

-- Heater-shield silhouette: sx in [-1,1], sy in [0,1] from the top edge.
local function ShieldInset(sx: number, sy: number): boolean
    if sy < 0 or sy > 1 or math.abs(sx) > 1 then
        return false
    end
    local halfWidth = 1
    if sy > 0.45 then
        halfWidth = math.cos((sy - 0.45) / 0.55 * math.pi / 2) ^ 0.85
    end
    return math.abs(sx) <= halfWidth
end

local function BandCoord(orientation: number, u: number, v: number, x: number, y: number, aspect: number): number
    if orientation == 0 then
        return u
    elseif orientation == 1 then
        return v
    end
    return (x + y) / (aspect + 1)
end

local function SampleField(field: Resolver.FieldPlan, u: number, v: number, x: number, y: number, aspect: number)
    if field.bands <= 1 then
        return field.color
    end
    local w = BandCoord(field.orientation, u, v, x, y, aspect)
    local index = math.min(math.floor(math.clamp(w, 0, 0.999) * field.bands), field.bands - 1)
    return if index % 2 == 0 then field.color else field.altColor
end

-- Builds a function (u, v) -> color that answers "what does the flat design
-- look like at this point". The wave and weathering are applied afterward, so
-- every emblem follows the ripple of the cloth for free. Depth grows inside
-- inset shields; charges there are drawn bolder so they stay legible small,
-- and each region carries its own aspect so circles stay round inside the
-- narrow shield window.
local function MakeSampler(plan: Resolver.Plan, depth: number?, aspectIn: number?): (number, number) -> any
    local tests = {}
    local boost = math.min(1 + 0.6 * ((depth or 1) - 1), 2.2)
    local aspect = aspectIn or Aspect

    -- Point emblems (roundels, crescents, stars, shields) share the center
    -- line, spaced evenly in written order.
    local pointSlots: {{layer: any, centerU: number}} = {}
    local pointTotal = 0
    for _, layer in ipairs(plan.layers) do
        if layer.kind == "shield" or layer.emblem == "roundel" or layer.emblem == "crescent" or layer.emblem == "star" then
            pointTotal += layer.count
        end
    end
    local pointIndex = 0
    local function NextSlot(): number
        pointIndex += 1
        return pointIndex / (pointTotal + 1)
    end

    for _, layer in ipairs(plan.layers) do
        local power = math.min(layer.power, 5)
        local color = layer.color

        if layer.kind == "bars" then
            local n = layer.count
            local orientation = layer.orientation
            table.insert(tests, function(u, v, x, y)
                local w = BandCoord(orientation, u, v, x, y, aspect)
                local k = math.floor(math.clamp(w, 0, 0.999) * (2 * n + 1))
                return if k % 2 == 1 then color else nil
            end)
        elseif layer.kind == "shield" then
            local scale = if pointTotal > 1 then 0.72 else 1
            local centerX = NextSlot() * aspect
            local halfW = 0.20 * scale
            local halfH = 0.27 * scale
            local subSampler = MakeSampler(layer.shield, (depth or 1) + 1, halfW / halfH)
            local topEdge = 0.52 - halfH
            table.insert(tests, function(u, v, x, y)
                local sxOut = (x - centerX) / (halfW * 1.09)
                local syOut = (y - (topEdge - 0.018)) / (2 * halfH + 0.036)
                if not ShieldInset(sxOut, syOut) then
                    return nil
                end
                local sx = (x - centerX) / halfW
                local sy = (y - topEdge) / (2 * halfH)
                if ShieldInset(sx, sy) then
                    return subSampler((sx + 1) / 2, sy)
                end
                return RimColor
            end)
        elseif layer.emblem == "chevron" then
            local thickness = (0.10 + 0.025 * math.min(power - 1, 4)) * boost
            local apexY = 0.32
            local slope = 0.62 / (0.5 * aspect)
            table.insert(tests, function(u, v, x, y)
                local center = apexY + slope * math.abs(x - 0.5 * aspect)
                return if math.abs(y - center) < thickness / 2 then color else nil
            end)
        elseif layer.emblem == "saltire" then
            local half = (0.05 + 0.015 * math.min(power - 1, 4)) * boost
            local denom = math.sqrt(1 + aspect * aspect)
            table.insert(tests, function(u, v, x, y)
                local d1 = math.abs(x - aspect * y) / denom
                local d2 = math.abs(aspect - x - aspect * y) / denom
                return if d1 < half or d2 < half then color else nil
            end)
        elseif layer.emblem == "cross" then
            local half = (0.05 + 0.015 * math.min(power - 1, 4)) * boost
            table.insert(tests, function(u, v, x, y)
                return if math.abs(x - 0.5 * aspect) < half or math.abs(y - 0.5) < half then color else nil
            end)
        elseif layer.emblem == "pile" then
            local apexX = aspect * math.min(0.42 + 0.05 * math.min(power, 4), 0.72)
            table.insert(tests, function(u, v, x, y)
                return if x <= apexX and math.abs(y - 0.5) < 0.5 * (1 - x / apexX) then color else nil
            end)
        elseif layer.emblem == "wave" then
            local half = (0.05 + 0.015 * math.min(power - 1, 4)) * boost
            table.insert(tests, function(u, v, x, y)
                local center = 0.5 + 0.085 * math.sin(2 * math.pi * 2.5 * u + 0.5)
                return if math.abs(y - center) < half then color else nil
            end)
        elseif layer.emblem == "canton" then
            table.insert(tests, function(u, v, x, y)
                return if u < 0.35 and v < 0.44 then color else nil
            end)
        elseif layer.emblem == "scatter" then
            -- Strewn stars sit on staggered rows, like a mustered company.
            local radius = (0.065 + 0.014 * math.min(power - 1, 3)) * boost
            local total = layer.count
            local rowCount = if total <= 4 then 1 elseif total <= 8 then 2 else 3
            local rowVs = if rowCount == 1 then {0.5} elseif rowCount == 2 then {0.3, 0.7} else {0.22, 0.5, 0.78}
            local stars = {}
            local placed = 0
            for rowIndex = 1, rowCount do
                local inRow = math.floor(total / rowCount) + (if rowIndex <= total % rowCount then 1 else 0)
                for k = 1, inRow do
                    placed += 1
                    local su = 0.08 + 0.84 * (k - 0.5) / inRow
                    local cx, cy = su * aspect, rowVs[rowIndex]
                    table.insert(stars, {cx = cx, cy = cy, polygon = BuildStar(cx, cy, radius)})
                end
            end
            table.insert(tests, function(u, v, x, y)
                for _, star in ipairs(stars) do
                    if math.abs(x - star.cx) < radius and math.abs(y - star.cy) < radius then
                        if PointInPolygon(x, y, star.polygon) then
                            return color
                        end
                    end
                end
                return nil
            end)
        elseif layer.emblem == "roundel" then
            local radius = (0.10 + 0.028 * (power - 1)) * (if layer.count > 2 then 0.8 else 1) * boost
            local centers = {}
            for _ = 1, layer.count do
                table.insert(centers, NextSlot() * aspect)
            end
            table.insert(tests, function(u, v, x, y)
                for _, cx in ipairs(centers) do
                    local dx, dy = x - cx, y - 0.5
                    if dx * dx + dy * dy < radius * radius then
                        return color
                    end
                end
                return nil
            end)
        elseif layer.emblem == "crescent" then
            local radius = (0.12 + 0.028 * (power - 1)) * (if layer.count > 2 then 0.8 else 1) * boost
            local centers = {}
            for _ = 1, layer.count do
                table.insert(centers, NextSlot() * aspect)
            end
            local innerOffset = radius * 0.45
            local innerRadius = radius * 0.85
            table.insert(tests, function(u, v, x, y)
                for _, cx in ipairs(centers) do
                    local dx, dy = x - cx, y - 0.5
                    if dx * dx + dy * dy < radius * radius then
                        local ix = x - (cx + innerOffset)
                        if ix * ix + dy * dy >= innerRadius * innerRadius then
                            return color
                        end
                    end
                end
                return nil
            end)
        elseif layer.emblem == "star" then
            local outer = (0.15 + 0.035 * (power - 1)) * (if layer.count > 2 then 0.8 else 1) * boost
            local polygons = {}
            for _ = 1, layer.count do
                table.insert(polygons, BuildStar(NextSlot() * aspect, 0.52, outer))
            end
            table.insert(tests, function(u, v, x, y)
                for _, polygon in ipairs(polygons) do
                    if PointInPolygon(x, y, polygon) then
                        return color
                    end
                end
                return nil
            end)
        end
    end

    local field = plan.field
    return function(u: number, v: number)
        local x, y = u * aspect, v
        local color = SampleField(field, u, v, x, y, aspect)
        for _, test in ipairs(tests) do
            local hit = test(u, v, x, y)
            if hit then
                color = hit
            end
        end
        return color
    end
end

local function DrawPole(cv: Canvas)
    cv:line(PoleX, PoleTopY, PoleX, PoleBottomY, PoleDark, 13)
    cv:line(PoleX - 3, PoleTopY, PoleX - 3, PoleBottomY, PoleLight, 4)
    cv:circle(PoleX, PoleBottomY, 9, PoleDark)
    -- Finial: gold spike on a gold sphere.
    cv:polygon({{PoleX - 7, PoleTopY - 4}, {PoleX + 7, PoleTopY - 4}, {PoleX, PoleTopY - 32}}, WithAlpha(GoldColor, 255))
    cv:circle(PoleX, PoleTopY - 2, 9, WithAlpha(GoldColor, 255))
    cv:circle(PoleX - 3, PoleTopY - 5, 3, WithAlpha(BrightGold, 255))
end

type Weathering = {
    tear: {number},
    holes: {{u: number, v: number, r: number}},
    stains: {{u: number, v: number, rx: number, ry: number, alpha: number}},
}

local function RollWeathering(): Weathering
    local tear = {}
    for i = 0, 12 do
        local depth = 0.02 + Rng:NextNumber() * 0.05
        if Rng:NextNumber() < 0.35 then
            depth += 0.05 + Rng:NextNumber() * 0.12
        end
        tear[i] = depth
    end
    local holes = {}
    for _ = 1, Rng:NextInteger(2, 3) do
        table.insert(holes, {
            u = 0.32 + Rng:NextNumber() * 0.55,
            v = 0.15 + Rng:NextNumber() * 0.7,
            r = 0.018 + Rng:NextNumber() * 0.034,
        })
    end
    local stains = {}
    for _ = 1, Rng:NextInteger(2, 4) do
        table.insert(stains, {
            u = 0.15 + Rng:NextNumber() * 0.72,
            v = 0.2 + Rng:NextNumber() * 0.62,
            rx = 22 + Rng:NextNumber() * 26,
            ry = 12 + Rng:NextNumber() * 18,
            alpha = 34 + Rng:NextNumber() * 26,
        })
    end
    return {tear = tear, holes = holes, stains = stains}
end

local function TearAt(weathering: Weathering, v: number): number
    local scaled = math.clamp(v, 0, 1) * 12
    local index = math.floor(scaled)
    local fraction = scaled - index
    local a = weathering.tear[index]
    local b = weathering.tear[math.min(index + 1, 12)]
    return Lerp(a, b, fraction)
end

function module.Render(plan: Resolver.Plan): Canvas
    local base = canvas.new(Width, Height, {r = 11, g = 9, b = 20, a = 255})
    base:ellipse(Width * 0.53, Height * 0.46, 430, 300, {r = 19, g = 15, b = 31, a = 255})
    base:ellipse(Width * 0.5, Height - 26, 330, 14, {r = 7, g = 6, b = 12, a = 255})

    local overlay = canvas.new(Width, Height, {r = 0, g = 0, b = 0, a = 0})
    DrawPole(overlay)

    local warTorn = plan.warTorn
    local weathering: Weathering? = if warTorn then RollWeathering() else nil
    local droop = if warTorn then 24 else 0

    local sampler = MakeSampler(plan)

    local cols = math.floor(FlagW / CellSize)
    local rows = math.floor(FlagH / CellSize)

    -- Wave offsets at every column boundary so neighboring strips share edges.
    local dyTop, dyBottom = {}, {}
    for i = 0, cols do
        local u = i / cols
        dyTop[i] = WaveDy(u, 0, droop)
        dyBottom[i] = WaveDy(u, 1, droop)
    end

    local topIntact, bottomIntact = {}, {}

    for i = 0, cols - 1 do
        local u = (i + 0.5) / cols
        local shade = WaveShade(u)
        local x0 = HoistX + FlagW * i / cols
        local x1 = HoistX + FlagW * (i + 1) / cols
        local t0, b0 = dyTop[i], dyBottom[i]
        local t1, b1 = dyTop[i + 1], dyBottom[i + 1]

        -- Shaded colors are cached per source table, so identical design
        -- colors merge into long strips instead of one polygon per cell.
        local shadedCache = {}
        local function Shaded(rgb)
            local cached = shadedCache[rgb]
            if cached then
                return cached
            end
            local r, g, b = rgb.r, rgb.g, rgb.b
            if warTorn then
                r = Lerp(r, WeatherGrey.r, 0.14)
                g = Lerp(g, WeatherGrey.g, 0.14)
                b = Lerp(b, WeatherGrey.b, 0.14)
            end
            local shadedColor = {
                r = math.clamp(math.floor(r * shade), 0, 255),
                g = math.clamp(math.floor(g * shade), 0, 255),
                b = math.clamp(math.floor(b * shade), 0, 255),
                a = 255,
            }
            shadedCache[rgb] = shadedColor
            return shadedColor
        end

        local runStart: number? = nil
        local runColor = nil

        local function Flush(vEnd: number)
            if not runStart then
                return
            end
            local v0 = runStart :: number
            local yTopL = TopY + FlagH * v0 + Lerp(t0, b0, v0)
            local yTopR = TopY + FlagH * v0 + Lerp(t1, b1, v0)
            local yBotR = TopY + FlagH * vEnd + Lerp(t1, b1, vEnd)
            local yBotL = TopY + FlagH * vEnd + Lerp(t0, b0, vEnd)
            overlay:polygon({
                {x0, yTopL},
                {x1 + 0.7, yTopR},
                {x1 + 0.7, yBotR + 0.7},
                {x0, yBotL + 0.7},
            }, runColor)
            runStart = nil
            runColor = nil
        end

        for j = 0, rows - 1 do
            local v = (j + 0.5) / rows
            local visible = true
            if weathering then
                if u > 1 - TearAt(weathering, v) then
                    visible = false
                else
                    for _, hole in ipairs(weathering.holes) do
                        local dx = (u - hole.u) * Aspect
                        local dv = v - hole.v
                        if dx * dx + dv * dv < hole.r * hole.r then
                            visible = false
                            break
                        end
                    end
                end
            end

            local color = if visible then Shaded(sampler(u, v)) else nil
            if color ~= runColor then
                Flush(j / rows)
                if color then
                    runStart = j / rows
                    runColor = color
                end
            end

            if j == 0 then
                topIntact[i] = visible
            end
            if j == rows - 1 then
                bottomIntact[i] = visible
            end
        end
        Flush(1)
    end

    -- Ink the top and bottom edges so the cloth reads as a cut shape.
    local edgeColor = {r = 8, g = 6, b = 14, a = 120}
    for i = 1, cols - 1 do
        local uPrev = (i - 0.5) / cols
        local uHere = (i + 0.5) / cols
        local xPrev = HoistX + FlagW * uPrev
        local xHere = HoistX + FlagW * uHere
        if topIntact[i - 1] and topIntact[i] then
            overlay:line(xPrev, TopY + WaveDy(uPrev, 0, droop), xHere, TopY + WaveDy(uHere, 0, droop), edgeColor, 2)
        end
        if bottomIntact[i - 1] and bottomIntact[i] then
            overlay:line(
                xPrev, TopY + FlagH + WaveDy(uPrev, 1, droop),
                xHere, TopY + FlagH + WaveDy(uHere, 1, droop),
                edgeColor, 2
            )
        end
    end

    -- Fringe hangs from the free edges when a dye ring trims the banner.
    if plan.fringe then
        local fringeBase = plan.fringe :: Resolver.RGB
        local tasselCount = 36
        for k = 0, tasselCount - 1 do
            local u = (k + 0.5) / tasselCount
            local column = math.clamp(math.floor(u * cols), 0, cols - 1)
            if bottomIntact[column] then
                local shade = WaveShade(u)
                local color = {
                    r = math.floor(fringeBase.r * shade),
                    g = math.floor(fringeBase.g * shade),
                    b = math.floor(fringeBase.b * shade),
                    a = 255,
                }
                local x = HoistX + FlagW * u
                local y = TopY + FlagH + WaveDy(u, 1, droop) + 1
                overlay:polygon({{x - 8, y}, {x + 8, y}, {x, y + 14}}, color)
            end
        end
        if not warTorn then
            local x = HoistX + FlagW
            local yTop = TopY + WaveDy(1, 0, droop)
            local yBottom = TopY + FlagH + WaveDy(1, 1, droop)
            local flyCount = 18
            for k = 0, flyCount - 1 do
                local y = Lerp(yTop + 8, yBottom - 8, (k + 0.5) / flyCount)
                overlay:polygon({{x - 1, y - 8}, {x - 1, y + 8}, {x + 13, y}}, WithAlpha(fringeBase, 255))
            end
        end
    end

    -- Ties lashing the hoist to the pole.
    overlay:line(PoleX + 2, TopY + 2, HoistX + 4, TopY + 5, TieGrey, 3)
    overlay:line(PoleX + 2, TopY + FlagH - 2, HoistX + 4, TopY + FlagH - 5, TieGrey, 3)

    -- Battle scars: scorch rings around the holes, stains soaked into the weave.
    if weathering then
        for _, hole in ipairs(weathering.holes) do
            local x = HoistX + FlagW * hole.u
            local y = TopY + FlagH * hole.v + Lerp(WaveDy(hole.u, 0, droop), WaveDy(hole.u, 1, droop), hole.v)
            overlay:strokeCircle(x, y, hole.r * FlagH + 4, {r = 26, g = 20, b = 15, a = 150}, 4)
        end
        for _, stain in ipairs(weathering.stains) do
            local x = HoistX + FlagW * stain.u
            local y = TopY + FlagH * stain.v + Lerp(WaveDy(stain.u, 0, droop), WaveDy(stain.u, 1, droop), stain.v)
            overlay:ellipse(x, y, stain.rx, stain.ry, {r = 22, g = 17, b = 12, a = math.floor(stain.alpha)})
        end
    end

    local glowed = overlay:clone():glow(7, WithAlpha(plan.field.color, 85), 1.1)
    local merged = base:merge(glowed, "add"):merge(overlay, "normal")
    return merged:vignette(0.3)
end

return module
