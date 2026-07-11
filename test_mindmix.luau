--#include[fs, canvas]
local Parser = require("@src/spell/Parser")
local Resolver = require("@src/spell/Resolver")
local Renderer = require("@src/spell/Renderer")
local Elements = require("@src/spell/elements")

local outDir = fs.join(__dirname, "renders")
pcall(function()
    fs.mkdir(outDir)
end)

-- {render name, incantation, expected resolved element (nil = just must not crash)}
local cases = {
    -- every Mind pair, cast both ways
    {"mix-fervor", "{''' BBB}", "Fervor"},
    {"mix-fervor-rev", "{BBB '''}", "Fervor"},
    {"mix-reverie", "{''' WWW}", "Reverie"},
    {"mix-reverie-rev", "{WWW '''}", "Reverie"},
    {"mix-whisper", "{''' ZZZ}", "Whisper"},
    {"mix-whisper-rev", "{ZZZ '''}", "Whisper"},
    {"mix-resolve", "{''' GGG}", "Resolve"},
    {"mix-resolve-rev", "{GGG '''}", "Resolve"},
    {"mix-instinct", "{''' JJJ}", "Instinct"},
    {"mix-instinct-rev", "{JJJ '''}", "Instinct"},
    {"mix-clarity", "{''' !!!}", "Clarity"},
    {"mix-clarity-rev", "{!!! '''}", "Clarity"},
    {"mix-impulse", "{''' ^^^}", "Impulse"},
    {"mix-impulse-rev", "{^^^ '''}", "Impulse"},
    {"mix-memory", "{''' :::}", "Memory"},
    {"mix-memory-rev", "{::: '''}", "Memory"},
    {"mix-astral", "{''' ***}", "Astral"},
    {"mix-astral-rev", "{*** '''}", "Astral"},
    {"mix-burden", "{''' @@@}", "Burden"},
    {"mix-burden-rev", "{@@@ '''}", "Burden"},

    -- bound forms: the muse rune riding another cluster
    {"mix-bound-fervor", "{AAA'' BB}", "Fervor"},
    {"mix-bound-reverie", "{WWW''}", "Reverie"},
    {"mix-bound-weak", "{AAA' BBB}", "Fire"}, -- one muse is too weak to bind

    -- three elements: only two can bind
    {"mix-three", "{''' BBB ZZ}", "Fervor"},
    {"mix-nested", "PPQ'{''''' BBBBB RRR {ZZ ''}}", "Fervor"},

    -- corruptors ride the mixture, they do not replace it
    {"mix-corrupt", "{''' @@@ %%%}", "Burden"},
    {"mix-corrupt-mild", "{'''' BBBB %%}", "Fervor"},

    -- uneven border: unstable, may roll variation per cast
    {"mix-unstable", "[''' ^^^]", "Impulse"},

    -- smart punctuation must fold back into runes without crashing
    {"mix-emdash", "{''' WWW \u{2014}}", "Reverie"},

    -- degenerate circles
    {"mix-ward", "{}", nil},
    {"mix-lone-muse", "{'}", "Mind"},
}

local failures = 0

for _, case in ipairs(cases) do
    local name, text, expected = case[1], case[2], case[3]
    local spell, parseErr = Parser.Parse(text)
    if not spell then
        print(`== {name} :: {text}`)
        print(`   PARSE ERR: {parseErr}`)
        failures += 1
        continue
    end

    local okResolve, effect, plan = pcall(Resolver.Resolve, spell)
    if not okResolve then
        print(`== {name} :: {text}`)
        print(`   RESOLVE ERR: {effect}`)
        failures += 1
        continue
    end

    local verdict = ""
    if expected then
        if effect.Element == expected then
            verdict = `element {effect.Element} — OK`
        else
            verdict = `element {effect.Element} — EXPECTED {expected}`
            failures += 1
        end
    else
        verdict = `element {effect.Element or "none"}`
    end

    print(`== {name} :: {text}`)
    print(`   {verdict}`)
    print(`   {effect.Description}`)
    for _, note in ipairs(effect.Notes) do
        print(`   note: {note}`)
    end

    local okRender, image = pcall(Renderer.Render, plan, effect)
    if not okRender then
        print(`   RENDER ERR: {image}`)
        failures += 1
        continue
    end

    fs.writeImage(`{outDir}/{name}.png`, image, "png")
    print(`   saved {name}.png`)
end

-- A contact sheet of every Mind-mixture sigil, drawn large, to eyeball them.
local MixNames = {
    "Fervor", "Reverie", "Whisper", "Resolve", "Instinct",
    "Clarity", "Impulse", "Memory", "Astral", "Burden",
}

local SheetFont: CanvasFont? = nil
for _, path in ipairs({"C:/Windows/Fonts/constan.ttf", "C:/Windows/Fonts/georgia.ttf", "C:/Windows/Fonts/arial.ttf"}) do
    if fs.exists(path) then
        local ok, font = pcall(function()
            return canvas.font(path)
        end)
        if ok then
            SheetFont = font
            break
        end
    end
end

local Cell = 210
local sheet = canvas.new(Cell * 5, Cell * 2 + 40, {r = 11, g = 9, b = 20, a = 255})
for index, mixName in ipairs(MixNames) do
    local col = (index - 1) % 5
    local row = math.floor((index - 1) / 5)
    local cx = Cell * col + Cell / 2
    local cy = Cell * row + Cell / 2 - 8
    local entry = Elements.Get(mixName)

    sheet:strokeCircle(cx, cy, Cell * 0.42, {r = 60, g = 55, b = 80, a = 255}, 2)
    entry.Sigil(sheet, cx, cy, 66, 3, 255)

    if SheetFont then
        local width = (SheetFont :: CanvasFont):measure(mixName, 22)
        sheet:text(mixName, cx - width / 2, cy + Cell * 0.44, 22, {r = 208, g = 208, b = 228, a = 255}, SheetFont :: CanvasFont)
    end
end
fs.writeImage(`{outDir}/mix-sigils.png`, sheet, "png")
print("saved mix-sigils.png")

if failures > 0 then
    print(`done — {failures} FAILURES`)
else
    print("done — all mixtures resolved")
end
