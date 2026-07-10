--#include[canvas, fs, random]
local Elements = require("@src/spell/elements")
local Aspects = require("@src/spell/Aspects")
local Runes = require("@src/spell/Runes")
local Parser = require("@src/spell/Parser")
local Resolver = require("@src/spell/Resolver")

local module = {}

local Size = 900

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

local Rng = random.new()

local RingColor = {r = 226, g = 216, b = 250}
local SilverColor = {r = 208, g = 208, b = 228}
local GoldColor = {r = 235, g = 205, b = 130}
local DimColor = {r = 125, g = 118, b = 150}

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

local function DrawTextCentered(cv: Canvas, value: string, x: number, y: number, size: number, color: any)
    if not RuneFont then
        return
    end
    local width, height = RuneFont:measure(value, size)
    cv:text(value, x - width / 2, y - height / 2, size, color, RuneFont :: CanvasFont)
end

local function DrawArc(cv: Canvas, cx: number, cy: number, radius: number, fromAngle: number, toAngle: number, color: any, thickness: number)
    local steps = 28
    local points = {}
    for i = 0, steps do
        local t = fromAngle + (toAngle - fromAngle) * i / steps
        table.insert(points, {cx + radius * math.cos(t), cy + radius * math.sin(t)})
    end
    cv:polyline(points, color, thickness)
end

local function DrawWobblyRing(cv: Canvas, cx: number, cy: number, radius: number, color: any, thickness: number)
    local segments = 46
    local points = {}
    local first = nil
    for i = 0, segments - 1 do
        local a = 2 * math.pi * i / segments
        local wobble = (Rng:NextNumber() - 0.5) * radius * 0.08
        if Rng:NextNumber() < 0.15 then
            wobble *= 2.2
        end
        local r = radius + wobble
        local point = {cx + r * math.cos(a), cy + r * math.sin(a)}
        if not first then
            first = point
        end
        table.insert(points, point)
    end
    table.insert(points, first)
    cv:polyline(points, color, thickness)
end

local function DrawArrowGlyph(cv: Canvas, cx: number, cy: number, radius: number, angle: number, power: number, color: any)
    local ax = cx + radius * 0.88 * math.cos(angle)
    local ay = cy + radius * 0.88 * math.sin(angle)
    local ux, uy = -math.cos(angle), -math.sin(angle)
    local px, py = -math.sin(angle), math.cos(angle)
    local wing = math.max(9, radius * 0.05)
    local step = wing * 1.7
    local count = math.clamp(power, 1, 5)

    for i = 0, count - 1 do
        local tx = ax + ux * (wing * 1.6 + i * step)
        local ty = ay + uy * (wing * 1.6 + i * step)
        local bx = tx - ux * wing * 1.5
        local by = ty - uy * wing * 1.5
        cv:line(bx + px * wing, by + py * wing, tx, ty, color, 4)
        cv:line(bx - px * wing, by - py * wing, tx, ty, color, 4)
    end
end

local function DrawTargetSymbol(cv: Canvas, target: string, x: number, y: number, size: number, color: any)
    if target == "vessel" then
        cv:polyline({
            {x - size * 0.55, y - size * 0.5},
            {x - size * 0.55, y + size * 0.25},
            {x - size * 0.25, y + size * 0.55},
            {x + size * 0.25, y + size * 0.55},
            {x + size * 0.55, y + size * 0.25},
            {x + size * 0.55, y - size * 0.5},
        }, color, 3)
        cv:line(x - size * 0.7, y - size * 0.5, x + size * 0.7, y - size * 0.5, color, 2)
    elseif target == "tether" then
        cv:circle(x - size * 0.55, y + size * 0.4, math.max(2, size * 0.14), color)
        cv:circle(x + size * 0.55, y - size * 0.4, math.max(2, size * 0.14), color)
        cv:line(x - size * 0.55, y + size * 0.4, x + size * 0.55, y - size * 0.4, color, 2)
    elseif target == "essence" then
        cv:polygon({
            {x, y - size * 0.6},
            {x - size * 0.42, y},
            {x, y + size * 0.6},
            {x + size * 0.42, y},
        }, color)
    elseif target == "self" then
        cv:strokeCircle(x, y, size * 0.5, color, 3)
        cv:circle(x, y, math.max(2, size * 0.12), color)
    elseif target == "other" then
        cv:strokeCircle(x - size * 0.2, y, size * 0.45, color, 3)
        cv:circle(x + size * 0.62, y, math.max(2, size * 0.12), color)
    elseif target == "place" then
        cv:strokePolygon({
            {x - size * 0.5, y - size * 0.5},
            {x + size * 0.5, y - size * 0.5},
            {x + size * 0.5, y + size * 0.5},
            {x - size * 0.5, y + size * 0.5},
        }, color, 3)
        cv:circle(x, y, math.max(2, size * 0.12), color)
    elseif target == "spell" then
        cv:strokeCircle(x, y, size * 0.55, color, 2)
        cv:strokeCircle(x, y, size * 0.34, color, 1)
        for i = 0, 2 do
            local a = -math.pi / 2 + 2 * math.pi * i / 3
            cv:circle(x + size * 0.55 * math.cos(a), y + size * 0.55 * math.sin(a), math.max(1, size * 0.09), color)
        end
    elseif target == "offering" then
        cv:line(x - size * 0.65, y + size * 0.45, x + size * 0.65, y + size * 0.45, color, 3)
        cv:line(x - size * 0.3, y + size * 0.45, x - size * 0.2, y + size * 0.25, color, 2)
        cv:line(x + size * 0.3, y + size * 0.45, x + size * 0.2, y + size * 0.25, color, 2)
        cv:line(x - size * 0.2, y + size * 0.25, x + size * 0.2, y + size * 0.25, color, 2)
        cv:strokeCircle(x, y - size * 0.08, size * 0.28, color, 2)
    else
        cv:strokeCircle(x, y, size * 0.5, color, 2)
    end
end

local function DrawTriggerMark(cv: Canvas, cx: number, cy: number, radius: number, letter: string, color: any): boolean
    if letter == "V" then
        for i = 0, 9 do
            local a = 2 * math.pi * i / 10
            cv:circle(cx + (radius + 6) * math.cos(a), cy + (radius + 6) * math.sin(a), 4, color)
        end
    elseif letter == "&" then
        for i = 0, 7 do
            local a = 2 * math.pi * i / 8
            local px, py = -math.sin(a), math.cos(a)
            local ux, uy = math.cos(a), math.sin(a)
            local ox, oy = cx + radius * ux, cy + radius * uy
            cv:polyline({
                {ox - px * 12, oy - py * 12},
                {ox - px * 6 + ux * 6, oy - py * 6 + uy * 6},
                {ox + px * 0 - ux * 6, oy + py * 0 - uy * 6},
                {ox + px * 6 + ux * 6, oy + py * 6 + uy * 6},
                {ox + px * 12, oy + py * 12},
            }, color, 2)
        end
    elseif letter == "R" then
        for i = 0, 5 do
            local a = 2 * math.pi * i / 6
            DrawArc(cv, cx, cy, radius + 6, a - 0.1, a + 0.1, color, 2)
            DrawArc(cv, cx, cy, radius + 12, a - 0.16, a + 0.16, WithAlpha(GoldColor, 120), 2)
        end
    elseif letter == "." then
        for i = 0, 5 do
            local a = 2 * math.pi * i / 6 + 0.2
            cv:polyline({
                {cx + (radius + 9) * math.cos(a - 0.04), cy + (radius + 9) * math.sin(a - 0.04)},
                {cx + (radius - 5) * math.cos(a), cy + (radius - 5) * math.sin(a)},
                {cx + (radius + 9) * math.cos(a + 0.06), cy + (radius + 9) * math.sin(a + 0.06)},
            }, color, 2)
        end
    elseif letter == "(" or letter == ")" then
        for i = 0, 3 do
            local a = 2 * math.pi * i / 4
            local sweep = if letter == ")" then 0.35 else -0.35
            DrawArc(cv, cx, cy, radius, a, a + sweep, color, 2)
            local tip = a + sweep
            local tx, ty = cx + radius * math.cos(tip), cy + radius * math.sin(tip)
            local dir = if letter == ")" then 1 else -1
            local px, py = -math.sin(tip) * dir, math.cos(tip) * dir
            cv:line(tx, ty, tx - px * 8 + math.cos(tip) * 6, ty - py * 8 + math.sin(tip) * 6, color, 2)
            cv:line(tx, ty, tx - px * 8 - math.cos(tip) * 6, ty - py * 8 - math.sin(tip) * 6, color, 2)
        end
    elseif letter == "?" then
        for i = 0, 7 do
            local a = 2 * math.pi * i / 8
            local ox, oy = cx + (radius + 7) * math.cos(a), cy + (radius + 7) * math.sin(a)
            cv:strokeCircle(ox, oy, 6, color, 1)
            cv:circle(ox, oy, 2, color)
        end
    else
        return false
    end
    return true
end

local function DrawRing(cv: Canvas, cx: number, cy: number, radius: number, run: Parser.Run, small: boolean, hasQuery: boolean)
    local entry = Runes.Get(run.letter)
    local color = WithAlpha(GoldColor, 190)

    if entry.Class == "element" and entry.Element then
        color = WithAlpha(Elements.Get(entry.Element).Color, 190)
        cv:strokeCircle(cx, cy, radius, color, 2)
        return
    end

    if entry.Class == "modifier" then
        color = WithAlpha(SilverColor, 170)
    elseif entry.Class == "shape" then
        color = WithAlpha(GoldColor, 220)
    elseif entry.Class ~= "flow" then
        color = WithAlpha(DimColor, 150)
    end

    cv:strokeCircle(cx, cy, radius, WithAlpha(color, 120), 1)

    if small then
        return
    end

    if hasQuery and DrawTriggerMark(cv, cx, cy, radius, run.letter, WithAlpha(GoldColor, 220)) then
        return
    end

    if entry.Class == "shape" then
        for i = 0, 11 do
            local a = 2 * math.pi * i / 12
            local ux, uy = math.cos(a), math.sin(a)
            local px, py = -math.sin(a), math.cos(a)
            local tx = cx + (radius + 10) * ux
            local ty = cy + (radius + 10) * uy
            local bx = cx + (radius - 2) * ux
            local by = cy + (radius - 2) * uy
            cv:line(bx + px * 6, by + py * 6, tx, ty, color, 2)
            cv:line(bx - px * 6, by - py * 6, tx, ty, color, 2)
        end
        return
    end

    local flow = entry.Flow

    if flow == "repeat" then
        for i = 0, 14 do
            local a = 2 * math.pi * i / 15
            for _, offset in ipairs({-0.035, 0.035}) do
                cv:circle(cx + radius * math.cos(a + offset), cy + radius * math.sin(a + offset), 3, color)
            end
        end
    elseif flow == "loop" then
        for i = 0, 15 do
            local a = 2 * math.pi * i / 16
            cv:strokeCircle(cx + radius * math.cos(a), cy + radius * math.sin(a), 5, color, 2)
        end
    elseif flow == "sustain" then
        cv:strokeCircle(cx, cy, radius, color, 2)
        cv:strokeCircle(cx, cy, radius - 5, WithAlpha(color, 130), 1)
    elseif flow == "delay" then
        for i = 0, 7 do
            local a = 2 * math.pi * i / 8
            cv:circle(cx + radius * math.cos(a), cy + radius * math.sin(a), 4, color)
        end
    elseif flow == "condition" then
        for i = 0, 11 do
            local a = 2 * math.pi * i / 12
            DrawArc(cv, cx, cy, radius, a, a + 0.22, color, 2)
            local dotAngle = a + 0.38
            cv:circle(cx + radius * math.cos(dotAngle), cy + radius * math.sin(dotAngle), 3, color)
        end
    elseif flow == "invert" then
        for i = 0, 11 do
            local a = 2 * math.pi * i / 12
            local ox, oy = cx + radius * math.cos(a), cy + radius * math.sin(a)
            local ux, uy = -math.cos(a), -math.sin(a)
            local px, py = -math.sin(a), math.cos(a)
            local tx, ty = ox + ux * 10, oy + uy * 10
            cv:line(ox + px * 6, oy + py * 6, tx, ty, color, 2)
            cv:line(ox - px * 6, oy - py * 6, tx, ty, color, 2)
        end
    elseif flow == "surge" then
        for i = 0, 23 do
            local a = 2 * math.pi * i / 24
            cv:line(
                cx + (radius - 5) * math.cos(a), cy + (radius - 5) * math.sin(a),
                cx + (radius + 6) * math.cos(a), cy + (radius + 6) * math.sin(a),
                color, 2
            )
        end
    else
        for i = 0, 17 do
            local a = 2 * math.pi * i / 18
            DrawArc(cv, cx, cy, radius, a, a + 0.16, color, 2)
        end
    end
end

local function DrawSpreadBand(cv: Canvas, cx: number, cy: number, radius: number, power: number, color: any)
    local ticks = 12 + math.clamp(power, 1, 8) * 6
    local inner = radius * 0.94
    local outer = radius * 0.94 + math.min(6 + power * 3, 20)
    for i = 0, ticks - 1 do
        local a = 2 * math.pi * i / ticks
        cv:line(
            cx + inner * math.cos(a), cy + inner * math.sin(a),
            cx + outer * math.cos(a), cy + outer * math.sin(a),
            color, 2
        )
    end
end

local function DrawCore(cv: Canvas, cx: number, cy: number, radius: number, element: string?)
    local entry = Elements.Get(element)
    for i = 5, 1, -1 do
        cv:circle(cx, cy, radius * i / 5, WithAlpha(entry.Color, 16))
    end
end

local function DrawLayer(cv: Canvas, plan: Resolver.LayerPlan, cx: number, cy: number, radius: number, depth: number)
    local ringAlpha = math.max(110, 230 - depth * 45)
    if plan.unstable then
        DrawWobblyRing(cv, cx, cy, radius, WithAlpha(RingColor, ringAlpha), if depth == 0 then 4 else 3)
        DrawWobblyRing(cv, cx, cy, radius - math.max(7, radius * 0.04), WithAlpha(RingColor, ringAlpha * 0.55), 2)
    else
        cv:strokeCircle(cx, cy, radius, WithAlpha(RingColor, ringAlpha), if depth == 0 then 4 else 3)
        cv:strokeCircle(cx, cy, radius - math.max(7, radius * 0.04), WithAlpha(RingColor, ringAlpha * 0.55), 2)
    end

    local small = radius < 120

    local hasQuery = false
    for _, run in ipairs(plan.rings) do
        if run.letter == "Q" then
            hasQuery = true
        end
    end

    local ringIndex = 0
    for _, run in ipairs(plan.rings) do
        if string.match(run.letter, "%d") then
            continue
        end
        ringIndex += 1
        if ringIndex > 3 then
            break
        end
        local gap = if small then 8 + (ringIndex - 1) * 8 else 18 + (ringIndex - 1) * 15
        DrawRing(cv, cx, cy, radius + gap, run, small, hasQuery)
    end

    local angles = {}
    for _, glyph in ipairs(plan.glyphs) do
        for _, angle in ipairs(glyph.slots) do
            table.insert(angles, angle)
        end
    end

    if #angles >= 3 then
        local points = {}
        for _, angle in ipairs(angles) do
            table.insert(points, {cx + radius * 0.62 * math.cos(angle), cy + radius * 0.62 * math.sin(angle)})
        end
        cv:strokePolygon(points, WithAlpha(RingColor, ringAlpha * 0.35), 2)
    elseif #angles == 2 then
        cv:line(
            cx + radius * 0.62 * math.cos(angles[1]), cy + radius * 0.62 * math.sin(angles[1]),
            cx + radius * 0.62 * math.cos(angles[2]), cy + radius * 0.62 * math.sin(angles[2]),
            WithAlpha(RingColor, ringAlpha * 0.35), 2
        )
    end

    for _, band in ipairs(plan.bands) do
        DrawSpreadBand(cv, cx, cy, radius, band.power, WithAlpha(SilverColor, 190))
    end

    for _, glyph in ipairs(plan.glyphs) do
        local color: any = WithAlpha(SilverColor, 235)
        if glyph.kind == "unknown" then
            color = WithAlpha(DimColor, 200)
        elseif glyph.kind == "aspect" or glyph.kind == "phial" then
            color = if glyph.bound then WithAlpha(Elements.Get(glyph.bound).Color, 240) else WithAlpha(GoldColor, 235)
        elseif glyph.bound then
            color = WithAlpha(Elements.Get(glyph.bound).Color, 240)
        end

        for _, angle in ipairs(glyph.slots) do
            local gx = cx + radius * 0.82 * math.cos(angle)
            local gy = cy + radius * 0.82 * math.sin(angle)

            if glyph.kind == "arrow" then
                DrawArrowGlyph(cv, cx, cy, radius, angle, glyph.power, color)
            elseif glyph.kind == "aspect" then
                local aspect = Aspects.Get(glyph.letter)
                local aspectSize = math.max(16, radius * 0.09)
                if aspect then
                    aspect.Draw(cv, gx, gy, aspectSize, color)
                else
                    cv:strokeCircle(gx, gy, aspectSize * 0.6, color, 2)
                end
            else
                cv:strokeCircle(gx, gy, math.max(10, radius * 0.05), color, 2)
                if not small then
                    DrawTextCentered(cv, glyph.letter, gx, gy, math.max(14, radius * 0.055), color)
                end
            end
        end

        if #glyph.slots == 2 then
            DrawArc(cv, cx, cy, radius * 0.94, glyph.slots[1], glyph.slots[2], WithAlpha(color, 170), 2)
        end

        if not small and #glyph.slots > 0 then
            local labelAngle = glyph.slots[1]
            local labelRadius = if #plan.rings > 0 then radius * 0.70 else radius + math.max(16, radius * 0.07)
            DrawTextCentered(
                cv, glyph.letters,
                cx + labelRadius * math.cos(labelAngle),
                cy + labelRadius * math.sin(labelAngle),
                math.max(13, radius * 0.045), WithAlpha(RingColor, 200)
            )
        end
    end

    local subCount = #plan.subs
    local sigilCount = #plan.sigils
    local targetCount = #plan.targets

    if plan.element and (depth == 0 or sigilCount > 0) then
        DrawCore(cv, cx, cy, radius * 0.16, plan.element)
    end

    if sigilCount > 0 then
        if subCount == 0 then
            for index, sigil in ipairs(plan.sigils) do
                local entry = Elements.Get(sigil.element)
                local scale = 1 - (index - 1) * 0.24
                entry.Sigil(cv, cx, cy, math.max(24, radius * 0.16) * math.max(scale, 0.4), sigil.power, 235)
                if sigil.spread > 0 then
                    cv:strokeCircle(cx, cy, math.max(20, radius * 0.14) * scale, WithAlpha(entry.Accent, 120), 2)
                end
            end
        else
            local orbit = radius * 0.76
            for index, sigil in ipairs(plan.sigils) do
                local a = -math.pi / 2 - 0.6 - 2 * math.pi * (index - 1) / sigilCount
                local sx = cx + orbit * math.cos(a)
                local sy = cy + orbit * math.sin(a)
                local entry = Elements.Get(sigil.element)
                entry.Sigil(cv, sx, sy, math.max(24, radius * 0.14), sigil.power, 235)
                if sigil.spread > 0 then
                    cv:strokeCircle(sx, sy, math.max(20, radius * 0.12), WithAlpha(entry.Accent, 120), 2)
                end
            end
        end
    end

    if targetCount > 0 then
        local orbit = if sigilCount > 0 or subCount > 0 then radius * 0.42 else radius * 0.3
        for index, target in ipairs(plan.targets) do
            local a = math.pi / 2 - 2 * math.pi * (index - 1) / targetCount
            local tx = cx + orbit * math.cos(a)
            local ty = cy + orbit * math.sin(a)
            local size = math.max(12, radius * 0.07)
            DrawTargetSymbol(cv, target.target :: string, tx, ty, size, WithAlpha(SilverColor, 220))

            local dots = math.clamp(target.power, 1, 4)
            if dots > 1 then
                for d = 1, dots do
                    cv:circle(tx - (dots + 1) * 3 + d * 6, ty + size * 0.95, 2, WithAlpha(SilverColor, 200))
                end
            end
        end
    end

    local function DrawSub(sub: Resolver.LayerPlan, sx: number, sy: number, sr: number)
        DrawLayer(cv, sub, sx, sy, sr, depth + 1)
        if sub.phial then
            DrawTextCentered(cv, sub.phial, sx, sy - sr - math.max(10, sr * 0.16), math.max(14, sr * 0.16), WithAlpha(GoldColor, 230))
        end
    end

    if #plan.forms > 0 and RuneFont then
        for index, form in ipairs(plan.forms) do
            local size = math.max(24, radius * 0.16 * math.min(math.max(form.scale, 1), 3))
            DrawTextCentered(
                cv, form.text,
                cx, cy - radius * 0.1 + (index - 1) * size * 1.2,
                size, WithAlpha(GoldColor, 230)
            )
        end
    end

    if subCount == 1 then
        DrawSub(plan.subs[1], cx, cy, radius * 0.52)
    elseif subCount > 1 then
        for index, sub in ipairs(plan.subs) do
            local a = -math.pi / 2 - 2 * math.pi * (index - 1) / subCount
            DrawSub(sub, cx + radius * 0.5 * math.cos(a), cy + radius * 0.5 * math.sin(a), radius * 0.3)
        end
    end
end

local function FlarePath(cx: number, cy: number, ux: number, uy: number, reach: number, curve: number, coil: number): {{number}}
    local baseAngle = math.atan2(uy, ux)
    local bend = math.rad(math.clamp(20 * curve, -160, 160))
    local points = {}
    local steps = 30
    for i = 0, steps do
        local t = i / steps
        local a = baseAngle + bend * t
        if coil > 0 then
            a += math.sin(t * math.pi * 2 * math.min(coil, 4)) * 0.45
        end
        local r = reach * t
        table.insert(points, {cx + r * math.cos(a), cy + r * math.sin(a)})
    end
    return points
end

local function DrawFlare(cv: Canvas, effect: Resolver.Effect, cx: number, cy: number, radius: number, color: any, accentColor: any)
    if effect.Homing and effect.Directional then
        local r = radius * 0.34
        DrawArc(cv, cx, cy, r, -math.pi / 2, math.pi, accentColor, 6)
        local tipX, tipY = cx + r * math.cos(math.pi), cy + r * math.sin(math.pi)
        cv:line(tipX, tipY, tipX + 16, tipY - 14, accentColor, 5)
        cv:line(tipX, tipY, tipX - 6, tipY - 20, accentColor, 5)
        cv:circle(cx, cy - r, 6, accentColor)
        return
    end

    if not effect.Compass then
        return
    end

    local mag = math.sqrt(effect.Direction.x ^ 2 + effect.Direction.y ^ 2)
    if mag < 1e-6 then
        return
    end

    local ux, uy = effect.Direction.x / mag, effect.Direction.y / mag
    local reach = radius * (0.55 + 0.4 * math.min(1, mag / 12))

    if effect.Curve == 0 and effect.Coil == 0 and effect.Motes == 0 then
        cv:arrow(cx, cy, cx + ux * reach, cy + uy * reach, accentColor, 7, 30)
    else
        local points = FlarePath(cx, cy, ux, uy, reach, effect.Curve, effect.Coil)

        if effect.Motes > 0 then
            for i = 1, #points, 2 do
                local point = points[i]
                cv:circle(point[1], point[2], 3 + 3 * (i / #points), accentColor)
            end
        else
            cv:polyline(points, accentColor, 6)
        end

        local last = points[#points]
        local prev = points[#points - 2] or points[#points - 1]
        local headAngle = math.atan2(last[2] - prev[2], last[1] - prev[1])
        for _, side in ipairs({-1, 1}) do
            local a = headAngle + math.pi + side * 0.5
            cv:line(last[1], last[2], last[1] + 24 * math.cos(a), last[2] + 24 * math.sin(a), accentColor, 6)
        end
    end

    if effect.Spread > 0 then
        local half = math.rad(math.clamp(20 + effect.Spread * 15, 20, 120)) / 2
        local baseAngle = math.atan2(uy, ux)
        for _, offset in ipairs({-half, half}) do
            local a = baseAngle + offset
            cv:arrow(cx, cy, cx + math.cos(a) * reach * 0.8, cy + math.sin(a) * reach * 0.8, color, 4, 18)
        end
    end
end

function module.Render(plan: Resolver.LayerPlan, effect: Resolver.Effect): Canvas
    local base = canvas.new(Size, Size, {r = 11, g = 9, b = 20, a = 255})
    local cx, cy = Size / 2, Size / 2
    local radius = Size * 0.4

    base:circle(cx, cy, radius * 1.12, {r = 20, g = 16, b = 34, a = 255})

    local hostModule = Elements.Get(effect.Element)
    local glowRGB = hostModule.Color
    local accentRGB = hostModule.Accent

    local topTint: string? = nil
    local topTintPower = 0
    for name, power in pairs(effect.Tints) do
        if power > topTintPower then
            topTintPower = power
            topTint = name
        end
    end
    if topTint and topTint ~= effect.Element then
        local tintModule = Elements.Get(topTint)
        glowRGB = BlendRGB(glowRGB, tintModule.Color, 0.5)
        accentRGB = BlendRGB(accentRGB, tintModule.Accent, 0.5)
    end

    if effect.Corruption then
        local corruptModule = Elements.Get(effect.Corruption.Name)
        local blend = if effect.Corruption.Full then 0.45 else 0.2
        glowRGB = BlendRGB(glowRGB, corruptModule.Color, blend)
        accentRGB = BlendRGB(accentRGB, corruptModule.Accent, blend)
    end

    local overlay = canvas.new(Size, Size, {r = 0, g = 0, b = 0, a = 0})
    DrawLayer(overlay, plan, cx, cy, radius, 0)
    DrawFlare(overlay, effect, cx, cy, radius, WithAlpha(glowRGB, 170), WithAlpha(accentRGB, 235))

    local glowed = overlay:clone():glow(6, WithAlpha(glowRGB, 150), 1.3)

    local merged = base:merge(glowed, "add"):merge(overlay, "normal")
    return merged:vignette(0.35)
end

type BlobSlice = {
    width: number,
    offset: number,
    lobes: number,
    separation: number,
}

local function SliceProfile(letter: string, t: number): BlobSlice
    local slice: BlobSlice = {width = 0.5, offset = 0, lobes = 1, separation = 0}

    if letter == "I" then
        slice.width = 0.34
    elseif letter == "O" then
        slice.width = math.max(0.2, 0.95 * math.sin(math.pi * t))
    elseif letter == "V" then
        slice.width = 0.9 * (1 - t) + 0.08
    elseif letter == "A" then
        slice.width = 0.15 + 0.85 * t
    elseif letter == "H" then
        if t > 0.4 and t < 0.6 then
            slice.width = 0.9
        else
            slice.lobes = 2
            slice.separation = 0.55
            slice.width = 0.3
        end
    elseif letter == "W" then
        slice.lobes = 2
        slice.separation = 0.5
        slice.width = 0.42 * (1 - t) + 0.08
    elseif letter == "Y" then
        if t < 0.5 then
            slice.lobes = 2
            slice.separation = 0.7 * (1 - t * 2) + 0.1
            slice.width = 0.28
        else
            slice.width = 0.3
        end
    elseif letter == "X" then
        slice.width = 0.25 + 0.65 * math.abs(t - 0.5) * 2
    elseif letter == "B" then
        slice.width = 0.45 + 0.4 * math.abs(math.sin(2 * math.pi * t))
        slice.offset = 0.08
    elseif letter == "M" then
        slice.width = 0.55 + 0.3 * math.abs(math.sin(3 * math.pi * t))
    elseif letter == "S" then
        slice.width = 0.36
        slice.offset = 0.35 * math.sin(2 * math.pi * t)
    elseif letter == "Z" then
        slice.width = 0.32
        slice.offset = if t < 0.33 then 0.3 elseif t < 0.66 then 0.3 - 1.8 * (t - 0.33) else -0.3
    elseif letter == "C" then
        slice.width = math.max(0.18, 0.7 * math.sin(math.pi * t))
        slice.offset = -0.2
    elseif letter == "D" then
        slice.width = math.max(0.2, 0.8 * math.sin(math.pi * t))
        slice.offset = 0.12
    elseif letter == "E" then
        slice.width = if (t * 3) % 1 < 0.5 then 0.7 else 0.3
    elseif letter == "F" then
        slice.width = if t < 0.15 or (t > 0.45 and t < 0.6) then 0.7 else 0.3
    elseif letter == "G" then
        slice.width = math.max(0.2, 0.7 * math.sin(math.pi * t))
        slice.offset = if t > 0.75 then 0.25 else -0.15
    elseif letter == "J" then
        slice.width = 0.3
        slice.offset = if t > 0.7 then -1.1 * (t - 0.7) else 0
    elseif letter == "K" then
        slice.width = 0.3 + (if t > 0.4 then (t - 0.4) * 0.8 else 0)
    elseif letter == "L" then
        slice.width = if t > 0.8 then 0.85 else 0.3
        slice.offset = if t > 0.8 then 0.2 else 0
    elseif letter == "N" then
        slice.width = 0.36
        slice.offset = 0.28 - 0.56 * t
    elseif letter == "P" then
        slice.width = if t < 0.45 then 0.7 else 0.28
        slice.offset = if t < 0.45 then 0.12 else 0
    elseif letter == "Q" then
        slice.width = math.max(0.16, 0.85 * math.sin(math.pi * math.min(t / 0.85, 1)))
        slice.offset = if t > 0.85 then 0.45 else 0
    elseif letter == "R" then
        slice.width = if t < 0.45 then 0.7 else 0.34
        slice.offset = if t > 0.55 then 0.3 * (t - 0.55) / 0.45 else 0.08
    elseif letter == "T" then
        slice.width = if t < 0.25 then 0.95 else 0.28
    elseif letter == "U" then
        if t < 0.65 then
            slice.lobes = 2
            slice.separation = 0.6
            slice.width = 0.28
        else
            slice.width = 0.8
        end
    else
        slice.width = math.max(0.25, 0.6 * math.sin(math.pi * t))
    end

    return slice
end

function module.RenderShapeform(plan: Resolver.LayerPlan): Canvas?
    local forms: {{text: string, scale: number}} = {}
    local function Collect(layer: Resolver.LayerPlan)
        for _, form in ipairs(layer.forms) do
            if #form.text > 0 then
                table.insert(forms, form)
            end
        end
        for _, sub in ipairs(layer.subs) do
            Collect(sub)
        end
    end
    Collect(plan)

    if #forms == 0 then
        return nil
    end

    local base = canvas.new(Size, Size, {r = 255, g = 255, b = 255, a = 255})

    local rim = {r = 25, g = 25, b = 32, a = 255}
    local body = {r = 70, g = 70, b = 80, a = 255}
    local sheen = {r = 145, g = 145, b = 158, a = 255}
    local shadow = {r = 208, g = 208, b = 214, a = 255}

    for index, form in ipairs(forms) do
        local columnX = Size * index / (#forms + 1)

        local rows: {{letter: string, count: number}} = {}
        for i = 1, #form.text do
            local letter = string.sub(form.text, i, i)
            local last = rows[#rows]
            if last and last.letter == letter then
                last.count += 1
            else
                table.insert(rows, {letter = letter, count = 1})
            end
        end

        local scale = math.min(math.max(form.scale, 1), 3)
        local rowH = math.min(Size * 0.8 / #rows, Size * 0.22 * scale)
        local topEdge = Size / 2 - (rowH * #rows) / 2
        local columnWidth = Size * 0.82 / #forms

        base:ellipse(
            columnX, topEdge + rowH * #rows + rowH * 0.12,
            math.min(columnWidth * 0.4, rowH * 1.2), rowH * 0.14,
            shadow
        )

        local discs = {}
        local slicesPerRow = 14

        for r, row in ipairs(rows) do
            local partW = math.min(rowH * 1.5, columnWidth / row.count)
            local rowWidth = partW * row.count
            local rowY = topEdge + (r - 1) * rowH

            for c = 1, row.count do
                local partX = columnX - rowWidth / 2 + (c - 0.5) * partW

                for s = 0, slicesPerRow - 1 do
                    local t = (s + 0.5) / slicesPerRow
                    local slice = SliceProfile(row.letter, t)
                    local ry = rowH / slicesPerRow * 1.6
                    local rx = math.max(3, slice.width * partW * 0.5)
                    local y = rowY + t * rowH

                    if slice.lobes == 2 then
                        local gap = slice.separation * partW * 0.5
                        table.insert(discs, {partX + slice.offset * partW - gap, y, rx, ry})
                        table.insert(discs, {partX + slice.offset * partW + gap, y, rx, ry})
                    else
                        table.insert(discs, {partX + slice.offset * partW, y, rx, ry})
                    end
                end
            end
        end

        for _, disc in ipairs(discs) do
            base:ellipse(disc[1], disc[2], disc[3] + math.max(3, disc[3] * 0.12), disc[4] + 3, rim)
        end
        for _, disc in ipairs(discs) do
            base:ellipse(disc[1], disc[2], disc[3], disc[4], body)
        end
        for _, disc in ipairs(discs) do
            base:ellipse(
                disc[1] - disc[3] * 0.3, disc[2] - disc[4] * 0.2,
                math.max(2, disc[3] * 0.42), math.max(2, disc[4] * 0.6),
                sheen
            )
        end
    end

    return base
end

function module.Encode(image: Canvas): string
    return image:encode("png")
end

return module
