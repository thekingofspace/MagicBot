--#include[canvas, fs, random]
-- Draws the forged weapon: large, near-vertical, on the dark ground of the
-- forge. All geometry runs along a tilted axis so warp and curve can bend
-- the silhouette without fighting the canvas.
local Resolver = require("@src/forge/Resolver")

local module = {}

local Width = 760
local Height = 1060

local FontCandidates = {
    "C:/Windows/Fonts/constan.ttf",
    "C:/Windows/Fonts/georgia.ttf",
    "C:/Windows/Fonts/times.ttf",
    "C:/Windows/Fonts/arial.ttf",
}

local ForgeFont: CanvasFont? = nil
for _, path in ipairs(FontCandidates) do
    if fs.exists(path) then
        local ok, font = pcall(function()
            return canvas.font(path)
        end)
        if ok then
            ForgeFont = font
            break
        end
    end
end

local LeatherColor = {r = 88, g = 58, b = 38}
local LeatherDark = {r = 52, g = 34, b = 22}
local WoodColor = {r = 104, g = 72, b = 46}
local WoodDark = {r = 62, g = 42, b = 26}
local OutlineColor = {r = 16, g = 13, b = 24}

local function WithAlpha(color: {r: number, g: number, b: number}, alpha: number): {r: number, g: number, b: number, a: number}
    return {r = color.r, g = color.g, b = color.b, a = math.floor(alpha)}
end

local function Shade(color: {r: number, g: number, b: number}, factor: number): {r: number, g: number, b: number}
    return {
        r = math.clamp(math.floor(color.r * factor), 0, 255),
        g = math.clamp(math.floor(color.g * factor), 0, 255),
        b = math.clamp(math.floor(color.b * factor), 0, 255),
    }
end

type Frame = {
    tipX: number,
    tipY: number,
    ux: number, -- axis unit, tip → butt
    uy: number,
    px: number, -- perpendicular unit (to the weapon's right)
    py: number,
    warp: (s: number, total: number) -> number,
}

-- Point at distance s down the axis, offset o to the side.
local function At(frame: Frame, s: number, o: number, total: number): (number, number)
    local drift = frame.warp(s, total)
    return frame.tipX + frame.ux * s + frame.px * (o + drift),
        frame.tipY + frame.uy * s + frame.py * (o + drift)
end

local function DrawStrip(cv: Canvas, frame: Frame, fromS: number, toS: number, total: number,
    halfWidth: (t: number) -> number, offset: ((t: number) -> number)?, color: any, steps: number?): {{number}}
    local n = steps or 26
    local left = {}
    local right = {}
    for i = 0, n do
        local t = i / n
        local s = fromS + (toS - fromS) * t
        local w = halfWidth(t)
        local o = if offset then offset(t) else 0
        local lx, ly = At(frame, s, o - w, total)
        local rx, ry = At(frame, s, o + w, total)
        table.insert(left, {lx, ly})
        table.insert(right, {rx, ry})
    end
    local points = {}
    for i = 1, #left do
        table.insert(points, left[i])
    end
    for i = #right, 1, -1 do
        table.insert(points, right[i])
    end
    cv:polygon(points, color)
    return points
end

local function DrawEtchings(cv: Canvas, frame: Frame, weapon: Resolver.Weapon, fromS: number, toS: number,
    total: number, maxSize: number, color: any, offset: ((s: number) -> number)?)
    if not ForgeFont then
        return
    end
    local marks = {}
    for _, etching in ipairs(weapon.Etchings) do
        for i = 1, #etching.text do
            table.insert(marks, {letter = string.sub(etching.text, i, i), scale = etching.scale})
        end
    end
    if #marks == 0 then
        return
    end
    local size = math.min(maxSize, (toS - fromS) / (#marks + 1) * 0.9)
    if size < 9 then
        size = 9
    end
    for index, mark in ipairs(marks) do
        local s = fromS + (toS - fromS) * index / (#marks + 1)
        local letterSize = math.min(size * (1 + 0.18 * math.min(mark.scale, 4)), maxSize * 1.4)
        local x, y = At(frame, s, if offset then offset(s) else 0, total)
        local w, h = (ForgeFont :: CanvasFont):measure(mark.letter, letterSize)
        -- Engraved: a light under-stroke below a dark cut.
        cv:text(mark.letter, x - w / 2 + 1, y - h / 2 + 1, letterSize, WithAlpha({r = 235, g = 235, b = 245}, 90), ForgeFont :: CanvasFont)
        cv:text(mark.letter, x - w / 2, y - h / 2, letterSize, color, ForgeFont :: CanvasFont)
    end
end

local function DrawProofMark(cv: Canvas, frame: Frame, weapon: Resolver.Weapon, s: number, total: number, size: number, lateral: number?)
    if not ForgeFont or not weapon.ProofMark then
        return
    end
    local x, y = At(frame, s, lateral or 0, total)
    local w, h = (ForgeFont :: CanvasFont):measure(weapon.ProofMark :: string, size)
    cv:text(weapon.ProofMark :: string, x - w / 2, y - h / 2, size, WithAlpha({r = 24, g = 20, b = 30}, 235), ForgeFont :: CanvasFont)
    cv:strokeCircle(x, y, size * 0.85, WithAlpha({r = 24, g = 20, b = 30}, 160), 2)
end

local function DrawGrip(cv: Canvas, frame: Frame, fromS: number, toS: number, total: number, halfW: number, weapon: Resolver.Weapon)
    DrawStrip(cv, frame, fromS, toS, total, function(_)
        return halfW + 1.5
    end, nil, OutlineColor, 10)
    DrawStrip(cv, frame, fromS, toS, total, function(_)
        return halfW
    end, nil, LeatherColor, 10)

    local length = toS - fromS
    local turns = math.max(4, math.floor(length / 14))
    for i = 1, turns do
        local s = fromS + length * (i - 0.5) / turns
        local x1, y1 = At(frame, s - 3, -halfW, total)
        local x2, y2 = At(frame, s + 3, halfW, total)
        cv:line(x1, y1, x2, y2, WithAlpha(LeatherDark, 220), 3)
    end
    if weapon.Wrap > 0 then
        local wire = WithAlpha({r = 226, g = 218, b = 190}, 200)
        for i = 1, turns do
            local s = fromS + length * (i - 0.5) / turns
            local x1, y1 = At(frame, s + 3, -halfW, total)
            local x2, y2 = At(frame, s - 3, halfW, total)
            cv:line(x1, y1, x2, y2, wire, 2)
        end
    end
    -- Rounded light along the grip's left side
    local hx1, hy1 = At(frame, fromS + 2, -halfW * 0.45, total)
    local hx2, hy2 = At(frame, toS - 2, -halfW * 0.45, total)
    cv:line(hx1, hy1, hx2, hy2, WithAlpha({r = 140, g = 100, b = 70}, 130), 2)
end

local function DrawPommel(cv: Canvas, frame: Frame, s: number, total: number, radius: number, material: Resolver.Material)
    local x, y = At(frame, s, 0, total)
    cv:circle(x, y, radius + 2, OutlineColor)
    cv:circle(x, y, radius, material.Color)
    cv:circle(x - radius * 0.3, y - radius * 0.3, radius * 0.35, WithAlpha(material.Edge, 160))
    cv:strokeCircle(x, y, radius * 0.55, WithAlpha(Shade(material.Color, 0.55), 220), 2)
end

local function DrawGuard(cv: Canvas, frame: Frame, s: number, total: number, halfSpanEach: number, thickness: number, material: Resolver.Material)
    local droop = thickness * 0.5
    local points = {}
    local n = 12
    for i = 0, n do
        local t = i / n
        local o = -halfSpanEach + 2 * halfSpanEach * t
        local sag = droop * (math.abs(o) / halfSpanEach) ^ 2
        local x, y = At(frame, s - thickness / 2 + sag, o, total)
        table.insert(points, {x, y})
    end
    for i = n, 0, -1 do
        local t = i / n
        local o = -halfSpanEach + 2 * halfSpanEach * t
        local sag = droop * (math.abs(o) / halfSpanEach) ^ 2
        local x, y = At(frame, s + thickness / 2 + sag, o, total)
        table.insert(points, {x, y})
    end
    cv:strokePolygon(points, OutlineColor, 3)
    cv:polygon(points, Shade(material.Color, 0.82))
    -- End caps
    for _, side in ipairs({-1, 1}) do
        local x, y = At(frame, s + droop, side * halfSpanEach, total)
        cv:circle(x, y, thickness * 0.62, Shade(material.Color, 0.9))
        cv:circle(x - 2, y - 2, thickness * 0.22, WithAlpha(material.Edge, 150))
    end
    -- Top light
    local lx1, ly1 = At(frame, s - thickness * 0.25, -halfSpanEach * 0.7, total)
    local lx2, ly2 = At(frame, s - thickness * 0.25, halfSpanEach * 0.7, total)
    cv:line(lx1, ly1, lx2, ly2, WithAlpha(material.Edge, 110), 2)
end

local GemColor = {r = 172, g = 30, b = 58}
local GemLight = {r = 255, g = 148, b = 168}
local CordColor = {r = 152, g = 34, b = 44}
local CordLight = {r = 214, g = 84, b = 92}
local BoneColor = {r = 224, g = 214, b = 190}

local function DrawJewel(cv: Canvas, x: number, y: number, radius: number)
    cv:circle(x, y, radius + 2, OutlineColor)
    cv:circle(x, y, radius, GemColor)
    cv:line(x - radius * 0.7, y, x + radius * 0.7, y, WithAlpha(Shade(GemColor, 0.55), 210), 1)
    cv:line(x, y - radius * 0.7, x, y + radius * 0.7, WithAlpha(Shade(GemColor, 0.55), 210), 1)
    cv:circle(x - radius * 0.32, y - radius * 0.36, radius * 0.28, WithAlpha(GemLight, 220))
end

local function DrawSkull(cv: Canvas, x: number, y: number, radius: number)
    cv:circle(x, y, radius + 1.5, OutlineColor)
    cv:circle(x, y, radius, BoneColor)
    cv:circle(x - radius * 0.18, y - radius * 0.26, radius * 0.4, WithAlpha({r = 250, g = 246, b = 232}, 130))
    cv:circle(x - radius * 0.36, y - radius * 0.1, radius * 0.24, OutlineColor)
    cv:circle(x + radius * 0.36, y - radius * 0.1, radius * 0.24, OutlineColor)
    cv:circle(x, y + radius * 0.26, radius * 0.12, WithAlpha(OutlineColor, 220))
    for _, o in ipairs({-0.32, 0, 0.32}) do
        cv:line(x + radius * o, y + radius * 0.5, x + radius * o, y + radius * 0.86, WithAlpha(Shade(BoneColor, 0.4), 230), 2)
    end
end

local function DrawTassel(cv: Canvas, frame: Frame, s: number, o: number, total: number)
    local x0, y0 = At(frame, s, o, total)
    local x1, y1 = At(frame, s + 12, o + 15, total)
    local x2, y2 = At(frame, s + 26, o + 22, total)
    cv:line(x0, y0, x1, y1, WithAlpha(CordColor, 240), 3)
    cv:line(x1, y1, x2, y2, WithAlpha(CordColor, 240), 3)
    for i = -2, 2 do
        local xt, yt = At(frame, s + 48 + math.abs(i) * 3, o + 22 + i * 6, total)
        cv:line(x2, y2, xt, yt, WithAlpha(if i % 2 == 0 then CordColor else CordLight, 230), 2)
    end
    cv:circle(x2, y2, 4.5, OutlineColor)
    cv:circle(x2, y2, 3, Shade(CordColor, 0.85))
end

local function DrawHaftedCharms(cv: Canvas, frame: Frame, weapon: Resolver.Weapon, total: number)
    if weapon.Tassel > 0 then
        DrawTassel(cv, frame, total - 34, 9, total)
    end
    if weapon.Jewel > 0 then
        local x, y = At(frame, total - 10, 0, total)
        DrawJewel(cv, x, y, math.min(4 + weapon.Jewel * 1.5, 8))
    end
end

-- ── Blade weapons: knife / sword / greatsword ───────────────────────────

local function RenderBlade(cv: Canvas, frame: Frame, weapon: Resolver.Weapon, material: Resolver.Material, total: number, jag: Random?)
    local stock = math.min(weapon.Stock, 6)
    local guardGap = if weapon.Guard > 0 then 16 + stock * 4 else 6
    local pommelR = if weapon.Pommel > 0 then 13 + math.min(weapon.Pommel, 4) * 4 else 8
    local gripUnits = math.max(weapon.GripSpans, 1) * 0.62
    local bladeUnits = weapon.BladeSpans + weapon.Stretch * 0.35
    local unitPx = (total - guardGap - pommelR * 2 - 8) / (bladeUnits + gripUnits)

    local bladeLen = bladeUnits * unitPx
    local gripLen = gripUnits * unitPx
    local guardS = bladeLen + guardGap / 2

    local isCutlass = weapon.TypeName == "Cutlass"
    local w0 = if weapon.Category == "greatsword" then 34
        elseif weapon.Category == "knife" then 20
        else 27
    if weapon.Stretch > 0 then
        w0 *= math.max(0.72, 1 - weapon.Stretch * 0.06)
    end
    if isCutlass then
        w0 *= 0.8
    end
    if stock > 0 then
        w0 *= 1 + stock * 0.26
    end

    local tipStart = if weapon.Category == "knife" then 0.5 else 0.66
    tipStart = math.max(0.34, tipStart - weapon.Stretch * 0.05)
    if stock > 0 then
        tipStart = math.min(0.88, tipStart + stock * 0.045)
    end

    local curvePx = math.clamp(weapon.Curve, -6, 6) * 26
    local waveAmp = if weapon.Wave > 0 then math.min(5 + weapon.Wave * 2, 13) else 0
    local waveN = 3 + math.min(weapon.Wave, 4)

    local function Bend(k: number): number
        return curvePx * k ^ 1.6
    end

    -- A curved knife (the kukri) bells out toward the tip.
    local belly = if weapon.Category == "knife" and weapon.Curve ~= 0 then 0.4 else 0

    -- t runs 0 at tip → 1 at guard for the strip; flip for shaping so
    -- profile(k) with k = 0 at guard, 1 at tip.
    local function Profile(k: number): number
        local w
        if k < tipStart then
            w = w0 * (1 - 0.22 * (k / tipStart))
        else
            w = w0 * 0.78 * (1 - (k - tipStart) / (1 - tipStart)) ^ 0.92
        end
        if belly > 0 then
            w *= 1 + belly * math.sin(math.pi * math.min(k / math.max(tipStart + 0.15, 0.1), 1))
        end
        return math.max(w, 0.8)
    end

    local function EdgeNoise(k: number): number
        if not jag then
            return 0
        end
        return (jag:NextNumber() - 0.5) * 5
    end

    local moonAmp = if weapon.MoonTip > 0 then w0 * (0.7 + 0.22 * math.min(weapon.MoonTip, 3)) else 0

    local function MoonFlare(k: number): number
        if moonAmp <= 0 or k <= 0.76 then
            return 0
        end
        local m = (k - 0.76) / 0.24
        if m < 0.4 then
            return moonAmp * (m / 0.4) ^ 1.3
        end
        return moonAmp * math.max(1 - (m - 0.4) / 0.6, 0) ^ 2.2
    end

    -- A clip point cuts the spine straight (slightly concave) to the tip.
    local function ClipCut(k: number, w: number): number
        if weapon.Clip == 0 or k <= 0.68 then
            return w
        end
        local m = (k - 0.68) / 0.32
        local target = Profile(0.68) * (1 - m) ^ 1.1 * (1 - 0.28 * math.sin(math.pi * m))
        return math.min(w, math.max(target, 0.6))
    end

    local function SpineWidth(k: number): number
        local w = Profile(k)
        if waveAmp > 0 and k < tipStart then
            w += math.sin(k * math.pi * 2 * waveN) * waveAmp * 0.5 + waveAmp * 0.5
        end
        return ClipCut(k, w + MoonFlare(k))
    end

    -- Samples run t = 0 at the tip (s = 0) → t = 1 at the guard; the
    -- shaping parameter k = 1 - t runs 0 at the guard → 1 at the tip.
    local samples = 44
    local left = {}
    local right = {}
    for i = 0, samples do
        local t = i / samples -- 0 tip → 1 guard
        local k = 1 - t -- 0 guard → 1 tip
        local s = bladeLen * t
        local w = Profile(k)
        if waveAmp > 0 and k < tipStart then
            w += math.sin(k * math.pi * 2 * waveN) * waveAmp * 0.5 + waveAmp * 0.5
        end
        local wR = w
        if weapon.Serration > 0 and k < tipStart + 0.1 then
            local teeth = 9 + weapon.Serration * 3
            wR += ((k * teeth) % 1) * 8
        end
        wR += MoonFlare(k)
        wR = ClipCut(k, wR)
        if jag then
            w += EdgeNoise(k)
            wR += EdgeNoise(k)
            w = math.max(w, 0.8)
            wR = math.max(wR, 0.8)
        end
        local bend = Bend(k)
        local lx, ly = At(frame, s, bend - w, total)
        local rx, ry = At(frame, s, bend + wR, total)
        table.insert(left, {lx, ly})
        table.insert(right, {rx, ry})
    end

    local silhouette = {}
    for i = #left, 1, -1 do
        table.insert(silhouette, left[i])
    end
    for i = 1, #right do
        table.insert(silhouette, right[i])
    end

    cv:strokePolygon(silhouette, OutlineColor, 4)
    cv:polygon(silhouette, material.Color)

    -- Flat shading: darker toward the right edge
    local shadePoints = {}
    for i = 1, #right do
        table.insert(shadePoints, right[i])
    end
    for i = #left, 1, -1 do
        local t = (i - 1) / samples
        local k = 1 - t
        local s = bladeLen * t
        local bend = Bend(k)
        local x, y = At(frame, s, bend + Profile(k) * 0.15, total)
        table.insert(shadePoints, {x, y})
    end
    cv:polygon(shadePoints, WithAlpha(Shade(material.Color, 0.72), 200))

    -- Pattern-welded grain: wavy watered layers along the flat
    if weapon.Folds >= 5 then
        local lanes = math.min(weapon.Folds + 4, 12)
        for lane = 1, lanes do
            local lo = -0.66 + 1.32 * (lane - 0.5) / lanes
            local pts = {}
            for i = 0, 40 do
                local k = 0.03 + 0.87 * i / 40
                local wobble = math.sin(k * math.pi * (5 + lane % 3) + lane * 2.1) * 0.2
                    + math.sin(k * math.pi * 11 + lane * 0.7) * 0.08
                local s = bladeLen * (1 - k)
                local x, y = At(frame, s, Bend(k) + (lo + wobble) * Profile(k) * 0.78, total)
                table.insert(pts, {x, y})
            end
            if lane % 2 == 0 then
                cv:polyline(pts, WithAlpha(Shade(material.Color, 0.52), 165), 2.5)
            else
                cv:polyline(pts, WithAlpha(material.Edge, 95), 1.5)
            end
        end
    end

    -- Fuller groove(s)
    if weapon.Fuller > 0 then
        local grooves = if weapon.Fuller >= 2 then {-0.28, 0.28} else {0}
        for _, lane in ipairs(grooves) do
            local points = {}
            for i = 0, 30 do
                local k = 0.04 + (tipStart - 0.1) * i / 30
                local s = bladeLen * (1 - k)
                local bend = Bend(k)
                local x, y = At(frame, s, bend + lane * w0 * 0.8, total)
                table.insert(points, {x, y})
            end
            cv:polyline(points, WithAlpha(Shade(material.Color, 0.5), 230), math.max(3, w0 * 0.18))
            cv:polyline(points, WithAlpha(material.Edge, 60), 1)
        end
    end

    -- Hollow grind: scooped flats either side of a bright median ridge
    if weapon.Hollow > 0 then
        for _, lane in ipairs({-0.5, 0.5}) do
            local points = {}
            for i = 0, 26 do
                local k = 0.04 + (tipStart + 0.04) * i / 26
                local s = bladeLen * (1 - k)
                local x, y = At(frame, s, Bend(k) + lane * Profile(k) * 0.6, total)
                table.insert(points, {x, y})
            end
            cv:polyline(points, WithAlpha(Shade(material.Color, 0.62), 140), math.max(3, w0 * 0.22))
        end
        local ridge = {}
        for i = 0, 20 do
            local k = 0.06 + tipStart * i / 20
            local s = bladeLen * (1 - k)
            local x, y = At(frame, s, Bend(k), total)
            table.insert(ridge, {x, y})
        end
        cv:polyline(ridge, WithAlpha(material.Edge, 80), 2)
    end

    -- Blood channel: a narrow groove cut hard against the true edge
    if weapon.Channel > 0 then
        local points = {}
        for i = 0, 30 do
            local k = 0.05 + (tipStart + 0.1) * i / 30
            local s = bladeLen * (1 - k)
            local x, y = At(frame, s, Bend(k) - Profile(k) * 0.62, total)
            table.insert(points, {x, y})
        end
        cv:polyline(points, WithAlpha(Shade(material.Color, 0.42), 235), math.max(2, w0 * 0.1))
        cv:polyline(points, WithAlpha(material.Edge, 80), 1)
    end

    -- Reinforced spine: a heavy stripe riding the back edge
    if weapon.Spine > 0 then
        local points = {}
        for i = 0, 30 do
            local k = 0.03 + 0.9 * i / 30
            local s = bladeLen * (1 - k)
            local x, y = At(frame, s, Bend(k) + SpineWidth(k) - math.max(2.5, w0 * 0.1), total)
            table.insert(points, {x, y})
        end
        cv:polyline(points, WithAlpha(Shade(material.Color, 0.5), 220), math.max(4, w0 * 0.16))
        cv:polyline(points, WithAlpha(material.Edge, 70), 1)
    end

    -- Edge sheen along the left (true) edge
    local sheen = {}
    for i = 0, samples do
        local t = i / samples
        local k = 1 - t
        local s = bladeLen * t
        local w = Profile(k)
        if waveAmp > 0 and k < tipStart then
            w += math.sin(k * math.pi * 2 * waveN) * waveAmp * 0.5 + waveAmp * 0.5
        end
        local bend = Bend(k)
        local x, y = At(frame, s, bend - w + 2, total)
        table.insert(sheen, {x, y})
    end
    cv:polyline(sheen, WithAlpha(material.Edge, 235), 3)

    -- A twin-edged blade wears the sheen on both sides
    if weapon.TwinEdge > 0 then
        local sheenR = {}
        for i = 0, samples do
            local t = i / samples
            local k = 1 - t
            local s = bladeLen * t
            local x, y = At(frame, s, Bend(k) + SpineWidth(k) - 2, total)
            table.insert(sheenR, {x, y})
        end
        cv:polyline(sheenR, WithAlpha(material.Edge, 220), 3)
    end

    if weapon.MoonTip > 0 then
        local clip = {}
        for i = 0, 16 do
            local k = 0.76 + 0.24 * i / 16
            local s = bladeLen * (1 - k)
            local bend = Bend(k)
            local x, y = At(frame, s, bend + Profile(k) + MoonFlare(k) - 1.5, total)
            table.insert(clip, {x, y})
        end
        cv:polyline(clip, WithAlpha(material.Edge, 220), 3)
    end

    -- Clip point: a false-edge glint along the cut spine
    if weapon.Clip > 0 then
        local clipLine = {}
        for i = 0, 14 do
            local k = 0.68 + 0.32 * i / 14
            local s = bladeLen * (1 - k)
            local x, y = At(frame, s, Bend(k) + SpineWidth(k) - 1.5, total)
            table.insert(clipLine, {x, y})
        end
        cv:polyline(clipLine, WithAlpha(material.Edge, 210), 2)
    end

    -- A catching hook worked into the spine near the point
    if weapon.Hook > 0 then
        local hookPts = {
            {At(frame, bladeLen * (1 - 0.7), Bend(0.7) + SpineWidth(0.7) - 1, total)},
            {At(frame, bladeLen * (1 - 0.73), Bend(0.78) + SpineWidth(0.78) + w0 * 0.62, total)},
            {At(frame, bladeLen * (1 - 0.84), Bend(0.84) + SpineWidth(0.84) - 1, total)},
        }
        cv:strokePolygon(hookPts, OutlineColor, 3)
        cv:polygon(hookPts, material.Color)
    end

    -- A bright working highlight down the mid-blade
    if not isCutlass then
        local streak = {}
        for i = 0, 12 do
            local k = 0.35 + 0.45 * i / 12
            local s = bladeLen * (1 - k)
            local bend = Bend(k)
            local x, y = At(frame, s, bend - Profile(k) * 0.35, total)
            table.insert(streak, {x, y})
        end
        cv:polyline(streak, WithAlpha(material.Edge, 90), math.max(2, w0 * 0.14))
    end

    local function CenterlineAt(s: number): number
        return Bend(1 - s / bladeLen)
    end
    DrawEtchings(cv, frame, weapon, bladeLen * 0.32, bladeLen * 0.9, total, math.min(w0 * 1.15, 26), WithAlpha({r = 26, g = 22, b = 32}, 235), CenterlineAt)
    if weapon.ProofMark then
        DrawProofMark(cv, frame, weapon, bladeLen * 0.95, total, math.min(w0 * 0.7, 15), CenterlineAt(bladeLen * 0.95))
    end

    -- Furniture
    if weapon.Guard > 0 then
        DrawGuard(cv, frame, guardS, total, 40 + math.min(weapon.Guard, 5) * 16 + stock * 4, 13 + stock * 4.5, material)
    end
    local gripFrom = bladeLen + guardGap
    local gripHalf = math.max(8, w0 * 0.34)
    DrawGrip(cv, frame, gripFrom, gripFrom + gripLen, total, gripHalf, weapon)
    local pommelS = gripFrom + gripLen + pommelR - 2
    if weapon.Pommel > 0 then
        DrawPommel(cv, frame, pommelS, total, pommelR, material)
        if weapon.Skull > 0 then
            local x, y = At(frame, pommelS, 0, total)
            DrawSkull(cv, x, y, pommelR * 0.8)
        end
    else
        -- bare tang button
        local x, y = At(frame, gripFrom + gripLen + 4, 0, total)
        cv:circle(x, y, 5, Shade(material.Color, 0.8))
    end
    if weapon.Counterweight > 0 then
        local cwFrom = gripFrom + gripLen + (if weapon.Pommel > 0 then pommelR * 2 - 2 else 9)
        DrawStrip(cv, frame, cwFrom, cwFrom + 12, total, function(_)
            return 10.5
        end, nil, OutlineColor, 4)
        DrawStrip(cv, frame, cwFrom + 1.5, cwFrom + 10.5, total, function(_)
            return 8.5
        end, nil, Shade(material.Color, 0.72), 4)
        DrawStrip(cv, frame, cwFrom + 12, cwFrom + 21, total, function(_)
            return 7
        end, nil, OutlineColor, 4)
        DrawStrip(cv, frame, cwFrom + 13.5, cwFrom + 19.5, total, function(_)
            return 5.5
        end, nil, Shade(material.Color, 0.55), 4)
    end
    if weapon.Basket > 0 then
        local ribs = math.min(weapon.Basket, 3)
        local fromS = if weapon.Guard > 0 then guardS + 5 else bladeLen + 4
        local toS = gripFrom + gripLen + (if weapon.Pommel > 0 then pommelR * 0.8 else 4)
        local ribPts = {}
        for rib = 1, ribs do
            local extra = 13 + rib * 12
            local pts = {}
            for i = 0, 22 do
                local t = i / 22
                local s = fromS + (toS - fromS) * t
                local o = -(gripHalf + extra * math.sin(math.pi * t) ^ 0.9)
                local x, y = At(frame, s, o, total)
                table.insert(pts, {x, y})
            end
            table.insert(ribPts, pts)
        end
        for _, pts in ipairs(ribPts) do
            cv:polyline(pts, OutlineColor, 7)
        end
        for _, pts in ipairs(ribPts) do
            cv:polyline(pts, Shade(material.Color, 0.88), 4)
            cv:polyline(pts, WithAlpha(material.Edge, 120), 1.5)
        end
        if ribs >= 2 then
            for _, tSlat in ipairs({0.32, 0.68}) do
                local inner = ribPts[1][math.floor(tSlat * 22) + 1]
                local outer = ribPts[ribs][math.floor(tSlat * 22) + 1]
                cv:line(inner[1], inner[2], outer[1], outer[2], OutlineColor, 5)
                cv:line(inner[1], inner[2], outer[1], outer[2], Shade(material.Color, 0.8), 3)
            end
        end
    end
    if weapon.Jewel > 0 then
        local x, y = At(frame, if weapon.Pommel > 0 then pommelS else gripFrom + gripLen + 4, 0, total)
        DrawJewel(cv, x, y, math.min(4 + weapon.Jewel * 2, math.max(pommelR * 0.52, 5)))
    end
    if weapon.Tassel > 0 then
        DrawTassel(cv, frame, gripFrom + gripLen - 8, gripHalf - 2, total)
    end
end

-- ── Hafted weapons: axe / hammer / spear ────────────────────────────────

local function DrawHaft(cv: Canvas, frame: Frame, fromS: number, toS: number, total: number, halfW: number, jag: Random?)
    local function noisy(_: number): number
        return halfW + (if jag then (jag:NextNumber() - 0.5) * 1.5 else 0)
    end
    DrawStrip(cv, frame, fromS, toS, total, function(t)
        return noisy(t) + 1.5
    end, nil, OutlineColor, 18)
    DrawStrip(cv, frame, fromS, toS, total, noisy, nil, WoodColor, 18)
    -- grain
    for _, lane in ipairs({-0.4, 0.25}) do
        local x1, y1 = At(frame, fromS + 6, lane * halfW, total)
        local x2, y2 = At(frame, toS - 6, lane * halfW, total)
        cv:line(x1, y1, x2, y2, WithAlpha(WoodDark, 150), 2)
    end
    local hx1, hy1 = At(frame, fromS + 4, -halfW * 0.55, total)
    local hx2, hy2 = At(frame, toS - 4, -halfW * 0.55, total)
    cv:line(hx1, hy1, hx2, hy2, WithAlpha({r = 160, g = 118, b = 80}, 120), 2)
end

local function DrawSocket(cv: Canvas, frame: Frame, s: number, total: number, halfW: number, depth: number, material: Resolver.Material)
    DrawStrip(cv, frame, s - depth / 2, s + depth / 2, total, function(_)
        return halfW
    end, nil, Shade(material.Color, 0.85), 6)
    local x1, y1 = At(frame, s - depth / 2, -halfW, total)
    local x2, y2 = At(frame, s - depth / 2, halfW, total)
    cv:line(x1, y1, x2, y2, WithAlpha(material.Edge, 140), 2)
end

local function AxeBit(cv: Canvas, frame: Frame, weapon: Resolver.Weapon, material: Resolver.Material,
    headS: number, total: number, side: number, jag: Random?)
    local power = math.min(weapon.HeadPower, 8)
    local bitReach = 66 + power * 14 -- outward
    local bitHalf = 52 + power * 12 -- along-axis half height at the edge
    local cheekHalf = 20 + power * 2

    local points = {}
    -- cheek top (at haft)
    local x, y = At(frame, headS - cheekHalf, side * 10, total)
    table.insert(points, {x, y})
    -- neck out to top horn
    x, y = At(frame, headS - bitHalf, side * bitReach * 0.82, total)
    table.insert(points, {x, y})
    -- cutting edge: an outward-bulging arc from top horn to bottom horn
    local n = 18
    for i = 0, n do
        local t = i / n
        local along = -bitHalf + 2 * bitHalf * t
        local bulge = bitReach * (0.82 + 0.18 * math.sin(math.pi * t))
        if jag then
            bulge += (jag:NextNumber() - 0.5) * 6
        end
        x, y = At(frame, headS + along, side * bulge, total)
        table.insert(points, {x, y})
    end
    -- bottom horn back to cheek (a slight beard)
    x, y = At(frame, headS + bitHalf + 12, side * bitReach * 0.5, total)
    table.insert(points, {x, y})
    x, y = At(frame, headS + cheekHalf, side * 10, total)
    table.insert(points, {x, y})

    cv:strokePolygon(points, OutlineColor, 4)
    cv:polygon(points, material.Color)

    -- cheek shading
    cv:polygon({
        points[1],
        points[2],
        {At(frame, headS, side * bitReach * 0.4, total)},
        points[#points],
    }, WithAlpha(Shade(material.Color, 0.78), 180))

    -- edge sheen along the arc
    local sheen = {}
    for i = 0, n do
        local t = i / n
        local along = -bitHalf + 2 * bitHalf * t
        local bulge = bitReach * (0.82 + 0.18 * math.sin(math.pi * t)) - 3
        x, y = At(frame, headS + along, side * bulge, total)
        table.insert(sheen, {x, y})
    end
    cv:polyline(sheen, WithAlpha(material.Edge, 235), 3)
end

local function RenderAxe(cv: Canvas, frame: Frame, weapon: Resolver.Weapon, material: Resolver.Material, total: number, jag: Random?)
    local headS = total * 0.16
    local stockHalf = math.min(weapon.Stock, 6) * 3.5
    DrawHaft(cv, frame, headS - 30, total - 8, total, 9 + stockHalf, jag)
    if weapon.Hook > 0 then
        local hookLen = 48 + math.min(weapon.Hook, 3) * 10
        local hookPts = {
            {At(frame, headS - 16, -12, total)},
            {At(frame, headS - 6, -hookLen * 0.72, total)},
            {At(frame, headS + hookLen * 0.5, -hookLen, total)},
            {At(frame, headS + 20, -hookLen * 0.46, total)},
            {At(frame, headS + 24, -12, total)},
        }
        cv:strokePolygon(hookPts, OutlineColor, 4)
        cv:polygon(hookPts, Shade(material.Color, 0.92))
        local hx1, hy1 = At(frame, headS - 4, -hookLen * 0.66, total)
        local hx2, hy2 = At(frame, headS + hookLen * 0.44, -hookLen + 4, total)
        cv:line(hx1, hy1, hx2, hy2, WithAlpha(material.Edge, 200), 2)
    end
    AxeBit(cv, frame, weapon, material, headS, total, 1, jag)
    if weapon.HeadPower >= 6 then
        AxeBit(cv, frame, weapon, material, headS, total, -1, jag)
    end
    DrawSocket(cv, frame, headS, total, 13 + stockHalf * 0.8, 46 + math.min(weapon.HeadPower, 8) * 4, material)
    -- top spike nub
    local x, y = At(frame, headS - 40, 0, total)
    local x2, y2 = At(frame, headS - 22, 0, total)
    cv:line(x, y, x2, y2, Shade(material.Color, 0.9), 10)
    DrawEtchings(cv, frame, weapon, headS + 70, total * 0.72, total, 18, WithAlpha({r = 30, g = 24, b = 18}, 235))
    if weapon.ProofMark then
        DrawProofMark(cv, frame, weapon, headS + 46, total, 13)
    end
    if weapon.Pommel > 0 then
        DrawPommel(cv, frame, total - 10, total, 10 + math.min(weapon.Pommel, 3) * 3, material)
    end
    if weapon.Wrap > 0 then
        DrawGrip(cv, frame, total - 150, total - 26, total, 10 + stockHalf, weapon)
    end
    DrawHaftedCharms(cv, frame, weapon, total)
end

local function RenderHammer(cv: Canvas, frame: Frame, weapon: Resolver.Weapon, material: Resolver.Material, total: number, jag: Random?)
    local power = math.min(weapon.HeadPower, 8)
    local headS = total * 0.14
    local faceReach = 62 + power * 13 -- striking face, to the right
    local peinReach = 40 + power * 7 -- back pein, to the left
    local headHalf = 30 + power * 5
    local stockHalf = math.min(weapon.Stock, 6) * 3.5

    DrawHaft(cv, frame, headS - 20, total - 8, total, 9 + stockHalf, jag)

    -- Head block: one polygon spanning pein → face
    local points = {}
    local corners = {
        {-headHalf, -peinReach}, {-headHalf * 0.72, faceReach * 0.92},
        {-headHalf * 0.62, faceReach}, {headHalf * 0.62, faceReach},
        {headHalf * 0.72, faceReach * 0.92}, {headHalf, -peinReach},
    }
    for _, corner in ipairs(corners) do
        local along, out = corner[1], corner[2]
        if jag then
            along += (jag:NextNumber() - 0.5) * 5
            out += (jag:NextNumber() - 0.5) * 5
        end
        local x, y = At(frame, headS + along, out, total)
        table.insert(points, {x, y})
    end
    cv:strokePolygon(points, OutlineColor, 4)
    cv:polygon(points, material.Color)

    -- Face bevel + shading
    local bx1, by1 = At(frame, headS - headHalf * 0.62, faceReach - 8, total)
    local bx2, by2 = At(frame, headS + headHalf * 0.62, faceReach - 8, total)
    cv:line(bx1, by1, bx2, by2, WithAlpha(material.Edge, 200), 4)
    local sx1, sy1 = At(frame, headS + headHalf * 0.6, -peinReach * 0.9, total)
    local sx2, sy2 = At(frame, headS + headHalf * 0.6, faceReach * 0.9, total)
    cv:line(sx1, sy1, sx2, sy2, WithAlpha(Shade(material.Color, 0.65), 220), math.max(4, headHalf * 0.35))
    -- Top light
    local tx1, ty1 = At(frame, headS - headHalf * 0.72, -peinReach * 0.7, total)
    local tx2, ty2 = At(frame, headS - headHalf * 0.72, faceReach * 0.7, total)
    cv:line(tx1, ty1, tx2, ty2, WithAlpha(material.Edge, 110), 3)

    DrawSocket(cv, frame, headS, total, 12 + stockHalf * 0.8, headHalf * 2 - 6, material)
    DrawEtchings(cv, frame, weapon, headS + headHalf + 40, total * 0.7, total, 18, WithAlpha({r = 30, g = 24, b = 18}, 235))
    if weapon.ProofMark then
        DrawProofMark(cv, frame, weapon, headS + headHalf + 20, total, 13)
    end
    if weapon.Pommel > 0 then
        DrawPommel(cv, frame, total - 10, total, 10 + math.min(weapon.Pommel, 3) * 3, material)
    end
    if weapon.Wrap > 0 then
        DrawGrip(cv, frame, total - 150, total - 26, total, 10 + stockHalf, weapon)
    end
    DrawHaftedCharms(cv, frame, weapon, total)
end

local function SpearProng(cv: Canvas, frame: Frame, material: Resolver.Material, fromS: number, length: number,
    lateral: number, halfW: number, total: number, jag: Random?)
    local points = {}
    local n = 14
    -- left side tip → base
    for i = 0, n do
        local t = i / n -- 0 tip → 1 base
        local w = halfW * math.sin(math.min(t * 1.25, 1) * math.pi * 0.5)
        if jag then
            w += (jag:NextNumber() - 0.5) * 2
        end
        local x, y = At(frame, fromS + length * t, lateral - math.max(w, 0.5), total)
        table.insert(points, {x, y})
    end
    for i = n, 0, -1 do
        local t = i / n
        local w = halfW * math.sin(math.min(t * 1.25, 1) * math.pi * 0.5)
        if jag then
            w += (jag:NextNumber() - 0.5) * 2
        end
        local x, y = At(frame, fromS + length * t, lateral + math.max(w, 0.5), total)
        table.insert(points, {x, y})
    end
    cv:strokePolygon(points, OutlineColor, 3)
    cv:polygon(points, material.Color)
    -- midrib + sheen
    local mx1, my1 = At(frame, fromS + 2, lateral, total)
    local mx2, my2 = At(frame, fromS + length - 3, lateral, total)
    cv:line(mx1, my1, mx2, my2, WithAlpha(Shade(material.Color, 0.6), 200), 2)
    local e = {}
    for i = 0, n do
        local t = i / n
        local w = halfW * math.sin(math.min(t * 1.25, 1) * math.pi * 0.5)
        local x, y = At(frame, fromS + length * t, lateral - math.max(w, 0.5) + 1.5, total)
        table.insert(e, {x, y})
    end
    cv:polyline(e, WithAlpha(material.Edge, 220), 2)
end

local function RenderSpear(cv: Canvas, frame: Frame, weapon: Resolver.Weapon, material: Resolver.Material, total: number, jag: Random?)
    local power = math.min(weapon.HeadPower, 8)
    local pointLen = 90 + power * 26
    local trident = weapon.HeadPower >= 4
    local stockHalf = math.min(weapon.Stock, 6) * 3.5

    DrawHaft(cv, frame, pointLen - 6, total - 8, total, 8 + stockHalf, jag)

    if trident then
        local crossS = pointLen * 0.78
        -- crossbar
        local cx1, cy1 = At(frame, crossS, -58, total)
        local cx2, cy2 = At(frame, crossS, 58, total)
        cv:line(cx1, cy1, cx2, cy2, OutlineColor, 14)
        cv:line(cx1, cy1, cx2, cy2, Shade(material.Color, 0.85), 10)
        SpearProng(cv, frame, material, 0, pointLen, 0, 15 + power, total, jag)
        SpearProng(cv, frame, material, pointLen * 0.2, pointLen * 0.62, -52, 10 + power * 0.5, total, jag)
        SpearProng(cv, frame, material, pointLen * 0.2, pointLen * 0.62, 52, 10 + power * 0.5, total, jag)
    else
        SpearProng(cv, frame, material, 0, pointLen, 0, 17 + power * 2, total, jag)
    end

    DrawSocket(cv, frame, pointLen + 4, total, 11 + stockHalf * 0.8, 30, material)
    if weapon.Hook > 0 then
        local hs = pointLen + 24
        local hookDrop = 38 + math.min(weapon.Hook, 3) * 9
        local hookPts = {
            {At(frame, hs, 8, total)},
            {At(frame, hs + 20, hookDrop * 0.8, total)},
            {At(frame, hs + 44, hookDrop, total)},
            {At(frame, hs + 40, hookDrop * 0.55, total)},
            {At(frame, hs + 30, 8, total)},
        }
        cv:strokePolygon(hookPts, OutlineColor, 3)
        cv:polygon(hookPts, Shade(material.Color, 0.92))
        local hx1, hy1 = At(frame, hs + 6, 12, total)
        local hx2, hy2 = At(frame, hs + 40, hookDrop - 3, total)
        cv:line(hx1, hy1, hx2, hy2, WithAlpha(material.Edge, 190), 2)
    end
    DrawEtchings(cv, frame, weapon, pointLen + 50, total * 0.6, total, 16, WithAlpha({r = 30, g = 24, b = 18}, 235))
    if weapon.ProofMark then
        DrawProofMark(cv, frame, weapon, pointLen + 30, total, 12)
    end
    if weapon.Pommel > 0 then
        DrawPommel(cv, frame, total - 10, total, 9 + math.min(weapon.Pommel, 3) * 3, material)
    end
    if weapon.Wrap > 0 then
        DrawGrip(cv, frame, total * 0.55, total * 0.55 + 110, total, 9 + stockHalf, weapon)
    end
    DrawHaftedCharms(cv, frame, weapon, total)
end

-- ── Arrow: slender shaft, head, fletching, nock ──────────────────────────

local function RenderArrow(cv: Canvas, frame: Frame, weapon: Resolver.Weapon, material: Resolver.Material, total: number, jag: Random?)
    local power = math.min(weapon.HeadPower, 6)
    local headLen = 58 + power * 16
    local headHalf = 15 + power * 5
    local shaftHalf = 4.5

    local function noisy(_: number): number
        return shaftHalf + (if jag then (jag:NextNumber() - 0.5) * 1.2 else 0)
    end
    DrawStrip(cv, frame, headLen * 0.84, total - 6, total, function(t)
        return noisy(t) + 1.5
    end, nil, OutlineColor, 20)
    DrawStrip(cv, frame, headLen * 0.84, total - 6, total, noisy, nil, WoodColor, 20)
    local gx1, gy1 = At(frame, headLen + 4, -shaftHalf * 0.4, total)
    local gx2, gy2 = At(frame, total - 14, -shaftHalf * 0.4, total)
    cv:line(gx1, gy1, gx2, gy2, WithAlpha({r = 160, g = 118, b = 80}, 130), 1)

    local function J(spread: number): number
        return if jag then (jag:NextNumber() - 0.5) * spread else 0
    end

    local points = {}
    if weapon.MoonTip > 0 then
        local hornHalf = headHalf * 1.3
        local n = 14
        for i = 0, n do
            local t = i / n
            local o = -hornHalf + 2 * hornHalf * t
            local dip = headLen * 0.52 * math.sin(math.pi * t) ^ 0.9
            local x, y = At(frame, dip + J(3), o, total)
            table.insert(points, {x, y})
        end
        local x, y = At(frame, headLen, shaftHalf + 2, total)
        table.insert(points, {x, y})
        x, y = At(frame, headLen, -shaftHalf - 2, total)
        table.insert(points, {x, y})
    else
        local wideS = headLen * 0.62
        local x, y = At(frame, J(3), 0, total)
        table.insert(points, {x, y})
        x, y = At(frame, wideS + J(3), headHalf, total)
        table.insert(points, {x, y})
        if weapon.Serration > 0 then
            x, y = At(frame, headLen * 1.26 + J(3), headHalf * 0.8, total)
            table.insert(points, {x, y})
            x, y = At(frame, headLen * 0.9, shaftHalf + 1.5, total)
            table.insert(points, {x, y})
            x, y = At(frame, headLen * 0.9, -shaftHalf - 1.5, total)
            table.insert(points, {x, y})
            x, y = At(frame, headLen * 1.26 + J(3), -headHalf * 0.8, total)
            table.insert(points, {x, y})
        else
            x, y = At(frame, headLen, shaftHalf + 1.5, total)
            table.insert(points, {x, y})
            x, y = At(frame, headLen, -shaftHalf - 1.5, total)
            table.insert(points, {x, y})
        end
        x, y = At(frame, wideS + J(3), -headHalf, total)
        table.insert(points, {x, y})
    end
    cv:strokePolygon(points, OutlineColor, 3)
    cv:polygon(points, material.Color)

    if weapon.Hook > 0 and weapon.MoonTip == 0 then
        for _, side in ipairs({-1, 1}) do
            local barb = {
                {At(frame, headLen * 0.72, side * (shaftHalf + 2), total)},
                {At(frame, headLen * 1.34, side * (headHalf * 0.85 + 5), total)},
                {At(frame, headLen * 1.02, side * (shaftHalf + 1), total)},
            }
            cv:strokePolygon(barb, OutlineColor, 3)
            cv:polygon(barb, material.Color)
        end
    end

    if weapon.MoonTip > 0 then
        local glint = {}
        for i = 0, 12 do
            local t = i / 12
            local o = -headHalf * 1.3 + 2 * headHalf * 1.3 * t
            local dip = headLen * 0.52 * math.sin(math.pi * t) ^ 0.9
            local x, y = At(frame, dip + 2.5, o, total)
            table.insert(glint, {x, y})
        end
        cv:polyline(glint, WithAlpha(material.Edge, 235), 3)
    else
        local mx1, my1 = At(frame, 8, 0, total)
        local mx2, my2 = At(frame, headLen * 0.86, 0, total)
        cv:line(mx1, my1, mx2, my2, WithAlpha(Shade(material.Color, 0.6), 210), 2)
        local sx1, sy1 = At(frame, 2, -1, total)
        local sx2, sy2 = At(frame, headLen * 0.62, -headHalf + 2, total)
        cv:line(sx1, sy1, sx2, sy2, WithAlpha(material.Edge, 230), 2)
    end

    if weapon.Wrap > 0 then
        local wire = WithAlpha({r = 226, g = 218, b = 190}, 210)
        for i = 0, 5 do
            local s = headLen + 8 + i * 5
            local x1, y1 = At(frame, s, -shaftHalf - 1.5, total)
            local x2, y2 = At(frame, s + 2.5, shaftHalf + 1.5, total)
            cv:line(x1, y1, x2, y2, wire, 2)
        end
    end

    if weapon.Fletching > 0 then
        local vanes = math.min(weapon.Fletching, 4)
        local fLen = total * 0.16 + vanes * 9
        local fFrom = total - 26 - fLen
        local vaneH = 16 + vanes * 4
        local feather = {r = 228, g = 222, b = 208}
        for _, side in ipairs({-1, 1}) do
            local pts = {
                {At(frame, fFrom, side * shaftHalf, total)},
                {At(frame, fFrom + 12, side * (shaftHalf + vaneH), total)},
                {At(frame, fFrom + fLen - 16, side * (shaftHalf + vaneH * 0.78), total)},
                {At(frame, fFrom + fLen, side * shaftHalf, total)},
            }
            cv:strokePolygon(pts, OutlineColor, 3)
            cv:polygon(pts, feather)
            for i = 1, 6 do
                local s = fFrom + 6 + (fLen - 22) * i / 6
                local x1, y1 = At(frame, s, side * shaftHalf, total)
                local x2, y2 = At(frame, s + 8, side * (shaftHalf + vaneH * 0.82), total)
                cv:line(x1, y1, x2, y2, WithAlpha({r = 150, g = 142, b = 128}, 190), 2)
            end
        end
        if vanes >= 3 then
            DrawStrip(cv, frame, fFrom + 6, fFrom + fLen - 8, total, function(_)
                return 2.5
            end, nil, Shade(feather, 0.78), 8)
        end
    end

    if weapon.Pommel > 0 then
        DrawStrip(cv, frame, total - 16, total - 2, total, function(_)
            return shaftHalf + 2.5
        end, nil, Shade(material.Color, 0.9), 6)
        local x1, y1 = At(frame, total - 12, 0, total)
        local x2, y2 = At(frame, total + 1, 0, total)
        cv:line(x1, y1, x2, y2, OutlineColor, 4)
    end

    DrawEtchings(cv, frame, weapon, headLen + 44, total * 0.62, total, 13, WithAlpha({r = 30, g = 24, b = 18}, 235))
    if weapon.ProofMark then
        DrawProofMark(cv, frame, weapon, headLen + 26, total, 10)
    end
end

-- ── Knuckles: four rings, a bridging plate, and a palm bar ───────────────

local function RenderKnuckles(cv: Canvas, frame: Frame, weapon: Resolver.Weapon, material: Resolver.Material, total: number, jag: Random?)
    local power = math.min(weapon.HeadPower, 6)
    local ringR = 42 + power * 4
    local spacing = ringR * 1.62
    local rowS = total * 0.34
    local holeR = ringR * 0.55
    local holeColor = {r = 14, g = 12, b = 24}

    local rings = {}
    for i = 1, 4 do
        local o = (i - 2.5) * spacing
        local s = rowS - ringR * 0.34 * (1 - ((i - 2.5) / 1.5) ^ 2)
        if jag then
            o += (jag:NextNumber() - 0.5) * 9
        end
        table.insert(rings, {o = o, s = s})
    end

    local plateTop = rowS + ringR * 0.5
    local plateBottom = rowS + ringR * 1.7
    local plateHalfW = spacing * 1.5 + ringR * 0.7
    local barHalfW = spacing * 1.2
    local plate = {
        {At(frame, plateTop, -plateHalfW, total)},
        {At(frame, plateTop, plateHalfW, total)},
        {At(frame, plateBottom, barHalfW, total)},
        {At(frame, plateBottom, -barHalfW, total)},
    }
    cv:strokePolygon(plate, OutlineColor, 4)
    cv:polygon(plate, Shade(material.Color, 0.86))
    cv:polygon({
        {At(frame, plateBottom - ringR * 0.5, -barHalfW - 8, total)},
        {At(frame, plateBottom - ringR * 0.5, barHalfW + 8, total)},
        {At(frame, plateBottom, barHalfW, total)},
        {At(frame, plateBottom, -barHalfW, total)},
    }, WithAlpha(Shade(material.Color, 0.62), 190))

    local barHalf = 13 + power
    local barS = plateBottom + barHalf + 4
    local barPoly = {
        {At(frame, barS - barHalf, -barHalfW, total)},
        {At(frame, barS - barHalf, barHalfW, total)},
        {At(frame, barS + barHalf, barHalfW, total)},
        {At(frame, barS + barHalf, -barHalfW, total)},
    }
    cv:strokePolygon(barPoly, OutlineColor, 4)
    cv:polygon(barPoly, material.Color)
    for _, side in ipairs({-1, 1}) do
        local x, y = At(frame, barS, side * barHalfW, total)
        cv:circle(x, y, barHalf + 2, OutlineColor)
        cv:circle(x, y, barHalf, material.Color)
        cv:circle(x - 2, y - 2, barHalf * 0.3, WithAlpha(material.Edge, 140))
    end
    local bl1x, bl1y = At(frame, barS - barHalf * 0.5, -barHalfW * 0.9, total)
    local bl2x, bl2y = At(frame, barS - barHalf * 0.5, barHalfW * 0.9, total)
    cv:line(bl1x, bl1y, bl2x, bl2y, WithAlpha(material.Edge, 120), 2)

    if weapon.Serration > 0 then
        local spikeLen = 32 + math.min(weapon.Serration, 4) * 8
        for _, ring in ipairs(rings) do
            local pts = {
                {At(frame, ring.s - ringR + 8, ring.o - ringR * 0.42, total)},
                {At(frame, ring.s - ringR - spikeLen, ring.o, total)},
                {At(frame, ring.s - ringR + 8, ring.o + ringR * 0.42, total)},
            }
            cv:strokePolygon(pts, OutlineColor, 3)
            cv:polygon(pts, material.Color)
            local x1, y1 = At(frame, ring.s - ringR + 4, ring.o - ringR * 0.3, total)
            local x2, y2 = At(frame, ring.s - ringR - spikeLen + 6, ring.o - 1, total)
            cv:line(x1, y1, x2, y2, WithAlpha(material.Edge, 220), 2)
        end
    end

    for _, ring in ipairs(rings) do
        local x, y = At(frame, ring.s, ring.o, total)
        cv:circle(x, y, ringR + 3, OutlineColor)
        cv:circle(x, y, ringR, material.Color)
    end
    for _, ring in ipairs(rings) do
        local x, y = At(frame, ring.s, ring.o, total)
        cv:circle(x, y, holeR + 3, Shade(material.Color, 0.5))
        cv:circle(x, y, holeR, holeColor)
        cv:strokeCircle(x, y, holeR + 1, WithAlpha(material.Edge, 90), 1)
        cv:circle(x - ringR * 0.4, y - ringR * 0.42, ringR * 0.14, WithAlpha(material.Edge, 160))
    end

    if weapon.GripSpans > 0 then
        local pad = {
            {At(frame, barS - barHalf + 4, -barHalfW * 0.68, total)},
            {At(frame, barS - barHalf + 4, barHalfW * 0.68, total)},
            {At(frame, barS + barHalf - 4, barHalfW * 0.68, total)},
            {At(frame, barS + barHalf - 4, -barHalfW * 0.68, total)},
        }
        cv:polygon(pad, LeatherColor)
        local ties = 6
        for i = 1, ties do
            local o = -barHalfW * 0.68 + barHalfW * 1.36 * (i - 0.5) / ties
            local x1, y1 = At(frame, barS - barHalf + 5, o - 4, total)
            local x2, y2 = At(frame, barS + barHalf - 5, o + 4, total)
            cv:line(x1, y1, x2, y2, WithAlpha(LeatherDark, 220), 3)
        end
    end
    if weapon.Wrap > 0 then
        local wire = WithAlpha({r = 226, g = 218, b = 190}, 200)
        local turns = 7
        for i = 1, turns do
            local o = -barHalfW * 0.66 + barHalfW * 1.32 * (i - 0.5) / turns
            local x1, y1 = At(frame, barS + barHalf - 4, o - 4, total)
            local x2, y2 = At(frame, barS - barHalf + 4, o + 4, total)
            cv:line(x1, y1, x2, y2, wire, 2)
        end
    end

    if ForgeFont and #weapon.Etchings > 0 then
        local marks = {}
        for _, etching in ipairs(weapon.Etchings) do
            for i = 1, #etching.text do
                table.insert(marks, {letter = string.sub(etching.text, i, i), scale = etching.scale})
            end
        end
        local mid = (plateTop + plateBottom) / 2 + 2
        local reachO = plateHalfW * 0.66
        local size = math.max(math.min(22, reachO * 2 / (#marks + 1) * 0.9), 9)
        for index, mark in ipairs(marks) do
            local o = -reachO + 2 * reachO * index / (#marks + 1)
            local letterSize = math.min(size * (1 + 0.18 * math.min(mark.scale, 4)), 26)
            local x, y = At(frame, mid, o, total)
            local w, h = (ForgeFont :: CanvasFont):measure(mark.letter, letterSize)
            cv:text(mark.letter, x - w / 2 + 1, y - h / 2 + 1, letterSize, WithAlpha({r = 235, g = 235, b = 245}, 90), ForgeFont :: CanvasFont)
            cv:text(mark.letter, x - w / 2, y - h / 2, letterSize, WithAlpha({r = 26, g = 22, b = 32}, 235), ForgeFont :: CanvasFont)
        end
    end
    if weapon.ProofMark then
        DrawProofMark(cv, frame, weapon, plateTop + 14, total, 11)
    end
end

-- ── Sickle: a short haft and a deep reaping crescent ─────────────────────

local function RenderSickle(cv: Canvas, frame: Frame, weapon: Resolver.Weapon, material: Resolver.Material, total: number, jag: Random?)
    local power = math.min(weapon.HeadPower, 7)
    local isScythe = weapon.HaftSpans >= 4
    local rootS = if isScythe then total * 0.3 else total * 0.44
    local sweepStart = math.rad(90)
    local sweepEnd = math.rad(if isScythe then -25 else -80)
    local r = math.min(96 + power * 15, (rootS - 10) / (1 - math.sin(sweepEnd)))
    local cS = rootS - r
    local wMax = 24 + power * 4
    local stockHalf = math.min(weapon.Stock, 6) * 3.5

    DrawHaft(cv, frame, rootS - 4, total - 8, total, (if isScythe then 8 else 9) + stockHalf, jag)

    local function Widths(t: number): (number, number)
        local shape: number
        if t < 0.42 then
            shape = 0.5 + 0.5 * t / 0.42
        else
            shape = math.max(1 - (t - 0.42) / 0.58, 0) ^ 0.9
        end
        local w = math.max(wMax * shape, 0.8)
        return r + w * 0.4, r - w * 0.8
    end

    local n = 40
    local outer = {}
    local inner = {}
    local sheen = {}
    for i = 0, n do
        local t = i / n
        local a = sweepStart + (sweepEnd - sweepStart) * t
        local co, si = math.cos(a), math.sin(a)
        local ro, ri = Widths(t)
        if weapon.Serration > 0 and t > 0.12 and t < 0.88 then
            ri -= ((t * (10 + weapon.Serration * 3)) % 1) * 7
        end
        local sheenR = ri + 2
        if jag then
            local jitter = (jag:NextNumber() - 0.5) * 5
            ro += jitter
            ri += jitter
        end
        table.insert(outer, {At(frame, cS + ro * si, ro * co, total)})
        table.insert(inner, {At(frame, cS + ri * si, ri * co, total)})
        table.insert(sheen, {At(frame, cS + sheenR * si, sheenR * co, total)})
    end

    local silhouette = {}
    for i = 1, #outer do
        table.insert(silhouette, outer[i])
    end
    for i = #inner, 1, -1 do
        table.insert(silhouette, inner[i])
    end
    cv:strokePolygon(silhouette, OutlineColor, 4)
    cv:polygon(silhouette, material.Color)

    local shadePts = {}
    for i = 1, #outer do
        table.insert(shadePts, outer[i])
    end
    for i = n, 0, -1 do
        local t = i / n
        local a = sweepStart + (sweepEnd - sweepStart) * t
        local ro, ri = Widths(t)
        local rm = ro - (ro - ri) * 0.4
        table.insert(shadePts, {At(frame, cS + rm * math.sin(a), rm * math.cos(a), total)})
    end
    cv:polygon(shadePts, WithAlpha(Shade(material.Color, 0.72), 200))

    cv:polyline(sheen, WithAlpha(material.Edge, 235), 3)

    DrawSocket(cv, frame, rootS + 6, total, 12 + stockHalf * 0.8, 26 + power * 2, material)
    DrawEtchings(cv, frame, weapon, rootS + 44, total * (if isScythe then 0.75 else 0.82), total, 16, WithAlpha({r = 30, g = 24, b = 18}, 235))
    if weapon.ProofMark then
        DrawProofMark(cv, frame, weapon, rootS + 26, total, 12)
    end
    if weapon.Pommel > 0 then
        DrawPommel(cv, frame, total - 10, total, 9 + math.min(weapon.Pommel, 3) * 3, material)
    end
    if weapon.Wrap > 0 then
        DrawGrip(cv, frame, total - 130, total - 24, total, 10 + stockHalf, weapon)
    end
    DrawHaftedCharms(cv, frame, weapon, total)
end

-- ── Mace: a flanged head on a hafted socket ──────────────────────────────

local function RenderMace(cv: Canvas, frame: Frame, weapon: Resolver.Weapon, material: Resolver.Material, total: number, jag: Random?)
    local power = math.min(weapon.HeadPower, 8)
    local headS = total * 0.16
    local coreR = 26 + power * 3
    local flangeLen = 24 + power * 6
    local flangeCount = math.clamp(4 + power, 5, 10)
    local stockHalf = math.min(weapon.Stock, 6) * 3.5

    DrawHaft(cv, frame, headS - 10, total - 8, total, 9 + stockHalf, jag)

    -- Top spike carries the line of the haft through the head
    local topLen = coreR + flangeLen * 0.9
    local topPts = {
        {At(frame, headS - 4, -9, total)},
        {At(frame, headS - topLen - 12, 0, total)},
        {At(frame, headS - 4, 9, total)},
    }
    cv:strokePolygon(topPts, OutlineColor, 3)
    cv:polygon(topPts, Shade(material.Color, 0.9))

    if weapon.Hook > 0 then
        local pickLen = coreR + flangeLen + 16 + math.min(weapon.Hook, 3) * 8
        local pickPts = {
            {At(frame, headS - coreR * 0.45, -coreR * 0.4, total)},
            {At(frame, headS + 26, -pickLen, total)},
            {At(frame, headS + coreR * 0.55, -coreR * 0.3, total)},
        }
        cv:strokePolygon(pickPts, OutlineColor, 3)
        cv:polygon(pickPts, Shade(material.Color, 0.92))
        local px1, py1 = At(frame, headS - coreR * 0.3, -coreR * 0.5, total)
        local px2, py2 = At(frame, headS + 24, -pickLen + 6, total)
        cv:line(px1, py1, px2, py2, WithAlpha(material.Edge, 190), 2)
    end

    -- Spikes between the flanges (the morning star's crown)
    if weapon.Serration > 0 then
        local spikeLen = 14 + math.min(weapon.Serration, 4) * 7
        for i = 0, flangeCount - 1 do
            local a = math.pi * 2 * (i + 0.5) / flangeCount
            local ca, sa = math.cos(a), math.sin(a)
            local spikePts = {
                {At(frame, headS + (coreR - 2) * ca - 5 * sa, (coreR - 2) * sa + 5 * ca, total)},
                {At(frame, headS + (coreR + spikeLen) * ca, (coreR + spikeLen) * sa, total)},
                {At(frame, headS + (coreR - 2) * ca + 5 * sa, (coreR - 2) * sa - 5 * ca, total)},
            }
            cv:strokePolygon(spikePts, OutlineColor, 3)
            cv:polygon(spikePts, material.Color)
        end
    end

    -- Flanges radiating from the core
    for i = 0, flangeCount - 1 do
        local a = math.pi * 2 * i / flangeCount + math.pi / flangeCount
        local ca, sa = math.cos(a), math.sin(a)
        local reach = coreR + flangeLen + (if jag then (jag:NextNumber() - 0.5) * 6 else 0)
        local flangePts = {
            {At(frame, headS + (coreR - 6) * math.cos(a - 0.3), (coreR - 6) * math.sin(a - 0.3), total)},
            {At(frame, headS + (coreR + flangeLen * 0.72) * math.cos(a - 0.13), (coreR + flangeLen * 0.72) * math.sin(a - 0.13), total)},
            {At(frame, headS + reach * ca, reach * sa, total)},
            {At(frame, headS + (coreR + flangeLen * 0.72) * math.cos(a + 0.13), (coreR + flangeLen * 0.72) * math.sin(a + 0.13), total)},
            {At(frame, headS + (coreR - 6) * math.cos(a + 0.3), (coreR - 6) * math.sin(a + 0.3), total)},
        }
        cv:strokePolygon(flangePts, OutlineColor, 4)
        cv:polygon(flangePts, material.Color)
        local ex1, ey1 = At(frame, headS + (coreR + 2) * math.cos(a - 0.16), (coreR + 2) * math.sin(a - 0.16), total)
        local ex2, ey2 = At(frame, headS + (reach - 3) * ca, (reach - 3) * sa, total)
        cv:line(ex1, ey1, ex2, ey2, WithAlpha(material.Edge, 180), 2)
    end

    -- The core over the flange roots
    local cx, cy = At(frame, headS, 0, total)
    cv:circle(cx, cy, coreR + 3, OutlineColor)
    cv:circle(cx, cy, coreR, material.Color)
    cv:circle(cx - coreR * 0.3, cy - coreR * 0.32, coreR * 0.34, WithAlpha(material.Edge, 130))
    cv:strokeCircle(cx, cy, coreR * 0.62, WithAlpha(Shade(material.Color, 0.55), 220), 2)

    DrawSocket(cv, frame, headS + coreR + 10, total, 12 + stockHalf * 0.8, 24, material)
    DrawEtchings(cv, frame, weapon, headS + coreR + 44, total * 0.72, total, 18, WithAlpha({r = 30, g = 24, b = 18}, 235))
    if weapon.ProofMark then
        DrawProofMark(cv, frame, weapon, headS + coreR + 26, total, 13)
    end
    if weapon.Pommel > 0 then
        DrawPommel(cv, frame, total - 10, total, 10 + math.min(weapon.Pommel, 3) * 3, material)
    end
    if weapon.Wrap > 0 then
        DrawGrip(cv, frame, total - 150, total - 26, total, 10 + stockHalf, weapon)
    end
    DrawHaftedCharms(cv, frame, weapon, total)
end

-- ── Shield: face-on — buckler / round / kite / tower by the ward rune ────

local function RenderShield(cv: Canvas, frame: Frame, weapon: Resolver.Weapon, material: Resolver.Material, total: number, jag: Random?)
    local power = weapon.HeadPower
    local stock = math.min(weapon.Stock, 6)
    local kind = if power >= 4 then "tower" elseif power == 3 then "kite" elseif power == 2 then "round" else "buckler"

    local height: number
    local halfW: number
    if kind == "buckler" then
        height = total * 0.5
        halfW = height / 2
    elseif kind == "round" then
        height = total * 0.62
        halfW = height / 2
    elseif kind == "kite" then
        height = total * 0.78
        halfW = math.min(total * 0.24, 186)
    else
        height = total * 0.82
        halfW = math.min(total * 0.26, 200)
    end
    local sTop = (total - height) / 2
    local cS = sTop + height / 2

    local function Width(t: number): number
        if kind == "buckler" or kind == "round" then
            return halfW * 2 * math.sqrt(math.max(t * (1 - t), 0))
        elseif kind == "kite" then
            if t < 0.3 then
                local m = (0.3 - t) / 0.3
                return halfW * math.sqrt(math.max(1 - m * m, 0))
            end
            return halfW * (1 - (t - 0.3) / 0.7) ^ 1.15
        end
        if t < 0.07 then
            local m = (0.07 - t) / 0.07
            return halfW * math.sqrt(math.max(1 - m * m, 0))
        elseif t > 0.93 then
            local m = (t - 0.93) / 0.07
            return halfW * math.sqrt(math.max(1 - m * m, 0))
        end
        return halfW
    end

    local n = 56
    local prof = {}
    for i = 0, n do
        local t = i / n
        local w = Width(t)
        local wl = w
        local wr = w
        if jag then
            wl = math.max(wl + (jag:NextNumber() - 0.5) * 9, 0)
            wr = math.max(wr + (jag:NextNumber() - 0.5) * 9, 0)
        end
        table.insert(prof, {t = t, s = sTop + height * t, wl = wl, wr = wr})
    end

    local silhouette = {}
    for _, p in ipairs(prof) do
        table.insert(silhouette, {At(frame, p.s, -p.wl, total)})
    end
    for i = #prof, 1, -1 do
        local p = prof[i]
        table.insert(silhouette, {At(frame, p.s, p.wr, total)})
    end
    cv:strokePolygon(silhouette, OutlineColor, 5 + stock * 2.5)
    cv:polygon(silhouette, if kind == "buckler" then material.Color else WoodColor)
    if stock > 0 then
        cv:strokePolygon(silhouette, WithAlpha(if kind == "buckler" then Shade(material.Color, 0.55) else WoodDark, 220), stock * 3)
    end

    if kind == "buckler" then
        local hx, hy = At(frame, cS - halfW * 0.3, -halfW * 0.28, total)
        cv:circle(hx, hy, halfW * 0.5, WithAlpha(material.Edge, 40))
        local px, py = At(frame, cS, 0, total)
        cv:strokeCircle(px, py, halfW * 0.62, WithAlpha(Shade(material.Color, 0.7), 110), 2)
        cv:strokeCircle(px, py, halfW * 0.82, WithAlpha(Shade(material.Color, 0.7), 90), 2)
    end

    if kind ~= "buckler" then
        local plankGap = math.max(30, halfW / 3.2)
        local o = -halfW + plankGap
        while o < halfW - 4 do
            local first: number? = nil
            local last: number? = nil
            for _, p in ipairs(prof) do
                if math.min(p.wl, p.wr) >= math.abs(o) + 8 then
                    if not first then
                        first = p.s
                    end
                    last = p.s
                end
            end
            if first and last and last - first > 20 then
                local x1, y1 = At(frame, first + 6, o, total)
                local x2, y2 = At(frame, last - 6, o, total)
                cv:line(x1, y1, x2, y2, WithAlpha(WoodDark, 170), 2)
            end
            o += plankGap
        end

        local wash = {}
        for _, p in ipairs(prof) do
            table.insert(wash, {At(frame, p.s, -p.wl * 0.975, total)})
        end
        for i = #prof, 1, -1 do
            local p = prof[i]
            table.insert(wash, {At(frame, p.s, p.wr * 0.975, total)})
        end
        cv:polygon(wash, WithAlpha(material.Color, 140))
    end

    if (kind == "round" or kind == "buckler") and weapon.BladeSpans >= 3 then
        local px, py = At(frame, cS, 0, total)
        cv:strokeCircle(px, py, halfW * 0.58, WithAlpha({r = 30, g = 24, b = 18}, 60), 2)
        cv:strokeCircle(px, py, halfW * 0.78, WithAlpha({r = 30, g = 24, b = 18}, 50), 2)
    end

    local accentPaints = {}
    for _, accent in ipairs(weapon.Accents) do
        table.insert(accentPaints, (Resolver.Materials[accent] :: Resolver.Material).Color)
    end
    if #accentPaints == 1 then
        local half = {}
        for _, p in ipairs(prof) do
            table.insert(half, {At(frame, p.s, -p.wl * 0.94, total)})
        end
        for i = #prof, 1, -1 do
            table.insert(half, {At(frame, prof[i].s, 0, total)})
        end
        cv:polygon(half, WithAlpha(accentPaints[1], 150))
    elseif #accentPaints >= 2 then
        local mid = math.floor(#prof / 2)
        for _, quarter in ipairs({
            {from = 1, to = mid, side = -1, paint = accentPaints[1]},
            {from = mid, to = #prof, side = 1, paint = accentPaints[1]},
            {from = 1, to = mid, side = 1, paint = accentPaints[2]},
            {from = mid, to = #prof, side = -1, paint = accentPaints[2]},
        }) do
            local poly = {}
            for i = quarter.from, quarter.to do
                local p = prof[i]
                local w = if quarter.side < 0 then p.wl else p.wr
                table.insert(poly, {At(frame, p.s, quarter.side * w * 0.94, total)})
            end
            table.insert(poly, {At(frame, prof[quarter.to].s, 0, total)})
            table.insert(poly, {At(frame, prof[quarter.from].s, 0, total)})
            cv:polygon(poly, WithAlpha(quarter.paint, 150))
        end
    end

    local rimW = if weapon.Guard > 0 then 10 + math.min(weapon.Guard, 3) * 5 + stock * 2 else 0
    if rimW > 0 then
        for _, side in ipairs({-1, 1}) do
            local band = {}
            for _, p in ipairs(prof) do
                local w = if side < 0 then p.wl else p.wr
                table.insert(band, {At(frame, p.s, side * w, total)})
            end
            for i = #prof, 1, -1 do
                local p = prof[i]
                local w = if side < 0 then p.wl else p.wr
                table.insert(band, {At(frame, p.s, side * math.max(w - rimW, 0), total)})
            end
            cv:polygon(band, Shade(material.Color, 0.82))
            local inner = {}
            for _, p in ipairs(prof) do
                local w = if side < 0 then p.wl else p.wr
                table.insert(inner, {At(frame, p.s, side * math.max(w - rimW, 0), total)})
            end
            cv:polyline(inner, WithAlpha(material.Edge, 120), 2)
        end
        for _, side in ipairs({-1, 1}) do
            for j = 1, 7 do
                local idx = math.clamp(math.floor(j / 8 * n) + 1, 1, #prof)
                local p = prof[idx]
                local w = if side < 0 then p.wl else p.wr
                if w - rimW > 10 then
                    local rx, ry = At(frame, p.s, side * (w - rimW / 2), total)
                    cv:circle(rx, ry, 3, Shade(material.Color, 0.5))
                    cv:circle(rx - 1, ry - 1, 1.2, WithAlpha(material.Edge, 200))
                end
            end
        end
    else
        local edgeLine = {}
        for _, p in ipairs(prof) do
            table.insert(edgeLine, {At(frame, p.s, -math.max(p.wl - 4, 0), total)})
        end
        for i = #prof, 1, -1 do
            local p = prof[i]
            table.insert(edgeLine, {At(frame, p.s, math.max(p.wr - 4, 0), total)})
        end
        cv:strokePolygon(edgeLine, WithAlpha(Shade(material.Color, 0.62), 190), 3)
    end

    local bossR = if weapon.Pommel > 0 then 24 + math.min(weapon.Pommel, 4) * 6 + math.min(power, 6) * 3 else 0

    if weapon.Pommel == 0 and weapon.Serration > 0 then
        local ringR = math.min(halfW, height / 2) * 0.55
        for i = 0, 7 do
            local a = math.pi * 2 * i / 8
            local sx, sy = At(frame, cS + math.cos(a) * ringR, math.sin(a) * ringR, total)
            cv:circle(sx, sy, 8, OutlineColor)
            cv:circle(sx, sy, 6, material.Color)
            cv:circle(sx, sy, 2.4, WithAlpha(material.Edge, 230))
        end
    end

    if weapon.GripSpans > 0 then
        for _, side in ipairs({-1, 1}) do
            local o = side * (math.max(bossR, 22) + 30)
            local plate = {
                {At(frame, cS - 12, o - 9, total)},
                {At(frame, cS - 12, o + 9, total)},
                {At(frame, cS + 12, o + 9, total)},
                {At(frame, cS + 12, o - 9, total)},
            }
            cv:strokePolygon(plate, OutlineColor, 3)
            cv:polygon(plate, Shade(material.Color, 0.7))
            for _, ds in ipairs({-7, 7}) do
                local px, py = At(frame, cS + ds, o, total)
                cv:circle(px, py, 2.5, WithAlpha(material.Edge, 170))
            end
        end
    end
    if weapon.Wrap > 0 then
        local plateO = math.max(bossR, 22) + 30
        for _, d in ipairs({-1, 1}) do
            local x1, y1 = At(frame, cS - 10 * d, -plateO + 12, total)
            local x2, y2 = At(frame, cS + 10 * d, plateO - 12, total)
            cv:line(x1, y1, x2, y2, WithAlpha({r = 226, g = 218, b = 190}, 150), 3)
        end
    end

    if ForgeFont and #weapon.Etchings > 0 then
        local marks = {}
        for _, etching in ipairs(weapon.Etchings) do
            for i = 1, #etching.text do
                table.insert(marks, {letter = string.sub(etching.text, i, i), scale = etching.scale})
            end
        end
        local rowS = cS + math.max(bossR, 18) + height * 0.09
        local tRow = math.min((rowS - sTop) / height, 0.94)
        local wRow = Width(tRow) * 0.78
        local size = math.clamp(wRow * 2 / (#marks + 1) * 0.95, 12, 64)
        for index, mark in ipairs(marks) do
            local o = -wRow + 2 * wRow * index / (#marks + 1)
            local letterSize = math.min(size * (1 + 0.14 * math.min(mark.scale, 4)), 72)
            local x, y = At(frame, rowS, o, total)
            local w, h = (ForgeFont :: CanvasFont):measure(mark.letter, letterSize)
            cv:text(mark.letter, x - w / 2 + 2, y - h / 2 + 2, letterSize, WithAlpha({r = 20, g = 16, b = 26}, 200), ForgeFont :: CanvasFont)
            cv:text(mark.letter, x - w / 2, y - h / 2, letterSize, WithAlpha({r = 232, g = 224, b = 202}, 240), ForgeFont :: CanvasFont)
        end
    end

    if weapon.Pommel > 0 then
        local x, y = At(frame, cS, 0, total)
        if weapon.Serration > 0 then
            for i = 0, 3 do
                local a = math.pi * 2 * i / 4 + math.pi / 4
                local spikeR = bossR + 22 + math.min(weapon.Serration, 4) * 6
                local spikePts = {
                    {At(frame, cS + math.cos(a - 0.5) * bossR * 0.6, math.sin(a - 0.5) * bossR * 0.6, total)},
                    {At(frame, cS + math.cos(a) * spikeR, math.sin(a) * spikeR, total)},
                    {At(frame, cS + math.cos(a + 0.5) * bossR * 0.6, math.sin(a + 0.5) * bossR * 0.6, total)},
                }
                cv:strokePolygon(spikePts, OutlineColor, 3)
                cv:polygon(spikePts, Shade(material.Color, 0.94))
                local gx1, gy1 = At(frame, cS + math.cos(a) * bossR * 0.7, math.sin(a) * bossR * 0.7, total)
                local gx2, gy2 = At(frame, cS + math.cos(a) * (spikeR - 4), math.sin(a) * (spikeR - 4), total)
                cv:line(gx1, gy1, gx2, gy2, WithAlpha(material.Edge, 180), 2)
            end
        end
        cv:strokeCircle(x, y, bossR + 5, WithAlpha(Shade(material.Color, 0.5), 200), 3)
        cv:circle(x, y, bossR + 3, OutlineColor)
        cv:circle(x, y, bossR, material.Color)
        cv:circle(x - bossR * 0.3, y - bossR * 0.32, bossR * 0.32, WithAlpha(material.Edge, 150))
        cv:strokeCircle(x, y, bossR * 0.6, WithAlpha(Shade(material.Color, 0.55), 220), 2)
        for i = 0, 7 do
            local a = math.pi * 2 * i / 8 + math.pi / 8
            local rx, ry = At(frame, cS + math.cos(a) * (bossR - 5), math.sin(a) * (bossR - 5), total)
            cv:circle(rx, ry, 2.2, WithAlpha(Shade(material.Color, 0.5), 220))
        end
        if weapon.Serration > 0 then
            cv:circle(x, y, bossR * 0.28, WithAlpha(material.Edge, 230))
        end
    end

    if weapon.Jewel > 0 then
        local x, y = At(frame, cS, 0, total)
        DrawJewel(cv, x, y, math.min(6 + weapon.Jewel * 2, math.max(bossR * 0.42, 9)))
    end

    if jag then
        local crack = {}
        local o = (jag:NextNumber() - 0.5) * halfW * 0.5
        local s = sTop + 6
        table.insert(crack, {At(frame, s, o, total)})
        for _ = 1, 5 do
            s += height * (0.07 + jag:NextNumber() * 0.06)
            o += (jag:NextNumber() - 0.5) * 34
            table.insert(crack, {At(frame, s, o, total)})
        end
        cv:polyline(crack, OutlineColor, 4)
        cv:polyline(crack, WithAlpha(WoodDark, 220), 2)
    end

    if weapon.Tassel > 0 then
        DrawTassel(cv, frame, sTop + height - 10, 4, total)
    end
    if weapon.ProofMark then
        DrawProofMark(cv, frame, weapon, sTop + height * 0.8, total, 13)
    end
end

local function RenderIngot(cv: Canvas, frame: Frame, material: Resolver.Material, total: number)
    local length = total * 0.42
    local fromS = (total - length) / 2
    DrawStrip(cv, frame, fromS, fromS + length, total, function(_)
        return 52
    end, nil, OutlineColor, 8)
    DrawStrip(cv, frame, fromS + 3, fromS + length - 3, total, function(_)
        return 48
    end, nil, material.Color, 8)
    DrawStrip(cv, frame, fromS + 3, fromS + length - 3, total, function(_)
        return 48
    end, function(_)
        return 24
    end, WithAlpha(Shade(material.Color, 0.7), 200), 8)
    local x1, y1 = At(frame, fromS + 14, -30, total)
    local x2, y2 = At(frame, fromS + length - 14, -30, total)
    cv:line(x1, y1, x2, y2, WithAlpha(material.Edge, 130), 4)
end

-- ─────────────────────────────────────────────────────────────────────────

function module.Render(weapon: Resolver.Weapon): Canvas
    local material = Resolver.Materials[weapon.Material] :: Resolver.Material

    local base = canvas.new(Width, Height, {r = 11, g = 9, b = 20, a = 255})
    base:circle(Width / 2, Height / 2, Height * 0.44, {r = 20, g = 16, b = 34, a = 255})
    base:circle(Width / 2, Height / 2, Height * 0.30, {r = 26, g = 21, b = 42, a = 255})

    local overlay = canvas.new(Width, Height, {r = 0, g = 0, b = 0, a = 0})

    -- Axis: tilted slightly off vertical; warp adds its rolled lean.
    local tiltDeg = 13 + (if weapon.Warped then weapon.WarpLean else 0)
    local tilt = math.rad(tiltDeg)
    local ux, uy = math.sin(tilt), math.cos(tilt)
    local px, py = math.cos(tilt), -math.sin(tilt)

    -- A dagger should not fill the wall the way a pike does.
    local lengthFactor: number
    if weapon.Category == "knife" then
        lengthFactor = 0.48
    elseif weapon.Category == "sword" then
        lengthFactor = math.min(0.68 + weapon.BladeSpans * 0.035 + weapon.Stretch * 0.025, 0.88)
    elseif weapon.Category == "greatsword" then
        lengthFactor = 0.92
    elseif weapon.Category == "spear" then
        lengthFactor = 0.94
    elseif weapon.Category == "arrow" then
        lengthFactor = math.clamp(0.52 + weapon.HaftSpans * 0.05, 0.6, 0.92)
    elseif weapon.Category == "knuckles" then
        lengthFactor = 0.46
    elseif weapon.Category == "sickle" then
        lengthFactor = math.clamp(0.62 + weapon.HaftSpans * 0.05, 0.62, 0.9)
    elseif weapon.Category == "axe" or weapon.Category == "hammer" or weapon.Category == "mace" then
        lengthFactor = math.clamp(0.5 + weapon.HaftSpans * 0.08, 0.6, 0.92)
    elseif weapon.Category == "shield" then
        lengthFactor = math.clamp(0.42 + weapon.HeadPower * 0.12, 0.5, 0.9)
    else
        lengthFactor = 0.86
    end

    local total = Height * lengthFactor
    local tipX = Width / 2 - ux * total / 2
    local tipY = Height / 2 - uy * total / 2

    local jag: Random? = nil
    local warpFn: (s: number, total: number) -> number
    if weapon.Warped then
        local bendRng = random.new(weapon.WarpSeed)
        local phase = bendRng:NextNumber() * math.pi
        local amp = 16 + weapon.WarpBend * 30
        local waves = 1.6 + bendRng:NextNumber() * 1.4
        warpFn = function(s: number, totalLen: number): number
            local t = s / totalLen
            return math.sin(t * math.pi * waves + phase) * amp * (0.35 + 0.65 * (1 - t))
        end
        jag = random.new(weapon.WarpSeed + 7)
    else
        warpFn = function(_: number, _: number): number
            return 0
        end
    end

    local frame: Frame = {
        tipX = tipX,
        tipY = tipY,
        ux = ux,
        uy = uy,
        px = px,
        py = py,
        warp = warpFn,
    }

    if weapon.Category == "axe" then
        RenderAxe(overlay, frame, weapon, material, total, jag)
    elseif weapon.Category == "hammer" then
        RenderHammer(overlay, frame, weapon, material, total, jag)
    elseif weapon.Category == "spear" then
        RenderSpear(overlay, frame, weapon, material, total, jag)
    elseif weapon.Category == "arrow" then
        RenderArrow(overlay, frame, weapon, material, total, jag)
    elseif weapon.Category == "knuckles" then
        RenderKnuckles(overlay, frame, weapon, material, total, jag)
    elseif weapon.Category == "sickle" then
        RenderSickle(overlay, frame, weapon, material, total, jag)
    elseif weapon.Category == "shield" then
        RenderShield(overlay, frame, weapon, material, total, jag)
    elseif weapon.Category == "mace" then
        RenderMace(overlay, frame, weapon, material, total, jag)
    elseif weapon.Category == "ingot" then
        RenderIngot(overlay, frame, material, total)
    else
        RenderBlade(overlay, frame, weapon, material, total, jag)
    end

    local glowed = overlay:clone():glow(6, WithAlpha(material.Glow, 140), 1.15)
    local merged = base:merge(glowed, "add"):merge(overlay, "normal")
    return merged:vignette(0.35)
end

function module.Encode(image: Canvas): string
    return image:encode("png")
end

return module
