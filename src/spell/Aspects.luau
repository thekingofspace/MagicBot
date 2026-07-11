export type AspectEntry = {
    Name: string,
    Verb: string,
    Fallback: string,
    Draw: (cv: Canvas, x: number, y: number, size: number, color: any) -> (),
}

local module = {}

local function Rays(cv: Canvas, x: number, y: number, inner: number, outer: number, count: number, color: any, thickness: number)
    for i = 0, count - 1 do
        local a = 2 * math.pi * i / count - math.pi / 2
        cv:line(
            x + inner * math.cos(a), y + inner * math.sin(a),
            x + outer * math.cos(a), y + outer * math.sin(a),
            color, thickness
        )
    end
end

module.Registry = {
    C = {
        Name = "Craft",
        Verb = "creates",
        Fallback = "matter",
        Draw = function(cv, x, y, size, color)
            cv:strokeCircle(x, y, size * 0.34, color, 3)
            Rays(cv, x, y, size * 0.42, size * 0.6, 4, color, 3)
            cv:circle(x, y, math.max(2, size * 0.07), color)
        end,
    },
    D = {
        Name = "Doom",
        Verb = "unmakes",
        Fallback = "what it touches",
        Draw = function(cv, x, y, size, color)
            cv:strokeCircle(x, y, size * 0.5, color, 2)
            local arm = size * 0.34
            cv:line(x - arm, y - arm, x + arm, y + arm, color, 3)
            cv:line(x - arm, y + arm, x + arm, y - arm, color, 3)
        end,
    },
    L = {
        Name = "Lumen",
        Verb = "sheds light upon",
        Fallback = "its surroundings",
        Draw = function(cv, x, y, size, color)
            cv:strokeCircle(x, y, size * 0.3, color, 3)
            Rays(cv, x, y, size * 0.4, size * 0.6, 8, color, 2)
        end,
    },
    F = {
        Name = "Fathom",
        Verb = "seeks",
        Fallback = "what is hidden",
        Draw = function(cv, x, y, size, color)
            cv:strokeCircle(x - size * 0.1, y - size * 0.1, size * 0.38, color, 3)
            cv:circle(x - size * 0.1, y - size * 0.1, math.max(2, size * 0.06), color)
            cv:line(
                x + size * 0.17, y + size * 0.17,
                x + size * 0.55, y + size * 0.55,
                color, 3
            )
        end,
    },
    K = {
        Name = "Kindred",
        Verb = "copies",
        Fallback = "its target",
        Draw = function(cv, x, y, size, color)
            cv:strokeCircle(x - size * 0.18, y, size * 0.34, color, 3)
            cv:strokeCircle(x + size * 0.18, y, size * 0.34, color, 2)
        end,
    },
    M = {
        Name = "Missive",
        Verb = "carries word to",
        Fallback = "a distant ear",
        Draw = function(cv, x, y, size, color)
            local w = size * 0.55
            cv:circle(x - w, y, math.max(2, size * 0.09), color)
            cv:circle(x + w, y, math.max(2, size * 0.09), color)
            cv:polyline({
                {x - w * 0.7, y},
                {x - w * 0.25, y - size * 0.2},
                {x + w * 0.25, y + size * 0.2},
                {x + w * 0.7, y},
            }, color, 2)
        end,
    },
    X = {
        Name = "Weave",
        Verb = "links",
        Fallback = "what it binds",
        Draw = function(cv, x, y, size, color)
            cv:strokeCircle(x - size * 0.22, y, size * 0.3, color, 3)
            cv:strokeCircle(x + size * 0.22, y, size * 0.3, color, 3)
            cv:line(x - size * 0.52, y, x + size * 0.52, y, color, 2)
        end,
    },
    ["="] = {
        Name = "Radiate",
        Verb = "radiates",
        Fallback = "in every direction",
        Draw = function(cv, x, y, size, color)
            cv:circle(x, y, math.max(2, size * 0.09), color)
            for _, dir in ipairs({-1, 1}) do
                for ring = 1, 2 do
                    local r = size * (0.14 + 0.22 * ring)
                    local points = {}
                    local steps = 8
                    for i = 0, steps do
                        local a = -math.pi * 0.28 + math.pi * 0.56 * i / steps
                        table.insert(points, {x + dir * r * math.cos(a), y + r * math.sin(a)})
                    end
                    cv:polyline(points, color, 2)
                end
            end
        end,
    },
    ["-"] = {
        Name = "Hoar",
        Verb = "freezes",
        Fallback = "the air around it",
        Draw = function(cv, x, y, size, color)
            for i = 0, 2 do
                local a = i * math.pi / 3
                local dx, dy = math.cos(a) * size * 0.55, math.sin(a) * size * 0.55
                cv:line(x - dx, y - dy, x + dx, y + dy, color, 2)
                for _, t in ipairs({0.62, -0.62}) do
                    local px, py = x + dx * t, y + dy * t
                    local bx, by = -math.sin(a) * size * 0.14, math.cos(a) * size * 0.14
                    cv:line(px, py, px + bx + dx * 0.14 * math.sign(t), py + by + dy * 0.14 * math.sign(t), color, 2)
                    cv:line(px, py, px - bx + dx * 0.14 * math.sign(t), py - by + dy * 0.14 * math.sign(t), color, 2)
                end
            end
        end,
    },
    ["+"] = {
        Name = "Mend",
        Verb = "restores",
        Fallback = "what is broken",
        Draw = function(cv, x, y, size, color)
            cv:strokeCircle(x, y, size * 0.5, color, 2)
            local arm = size * 0.32
            cv:line(x - arm, y, x + arm, y, color, 4)
            cv:line(x, y - arm, x, y + arm, color, 4)
            for _, corner in ipairs({{-1, -1}, {1, -1}, {-1, 1}, {1, 1}}) do
                cv:circle(x + corner[1] * size * 0.38, y + corner[2] * size * 0.38, math.max(1, size * 0.05), color)
            end
        end,
    },
    [","] = {
        Name = "Stride",
        Verb = "moves",
        Fallback = "what it touches",
        Draw = function(cv, x, y, size, color)
            local r = size * 0.5
            local steps = 12
            local points = {}
            for i = 0, steps do
                local t = i / steps
                local a = math.pi + math.pi * t
                table.insert(points, {x + r * math.cos(a) * 0.9, y + math.sin(a) * r * 0.7})
            end
            cv:polyline(points, color, 3)
            cv:circle(x - r * 0.9, y, math.max(2, size * 0.08), color)
            local tx, ty = x + r * 0.9, y
            cv:line(tx, ty, tx - size * 0.16, ty - size * 0.14, color, 3)
            cv:line(tx, ty, tx + size * 0.02, ty - size * 0.2, color, 3)
        end,
    },
    ["~"] = {
        Name = "Flux",
        Verb = "transmutes",
        Fallback = "what it touches",
        Draw = function(cv, x, y, size, color)
            local r = size * 0.42
            local steps = 14
            for _, half in ipairs({0, math.pi}) do
                local points = {}
                for i = 0, steps do
                    local a = half + math.pi * 0.82 * i / steps
                    table.insert(points, {x + r * math.cos(a), y + r * math.sin(a)})
                end
                cv:polyline(points, color, 3)
                local tipAngle = half + math.pi * 0.82
                local tx, ty = x + r * math.cos(tipAngle), y + r * math.sin(tipAngle)
                local ux, uy = -math.sin(tipAngle), math.cos(tipAngle)
                cv:line(tx, ty, tx - ux * size * 0.18 + math.cos(tipAngle) * size * 0.12, ty - uy * size * 0.18 + math.sin(tipAngle) * size * 0.12, color, 3)
            end
            cv:circle(x, y, math.max(2, size * 0.08), color)
        end,
    },
} :: {[string]: AspectEntry}

function module.Get(letter: string): AspectEntry?
    return module.Registry[letter]
end

return module
