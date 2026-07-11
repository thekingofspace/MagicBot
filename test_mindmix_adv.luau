--#include[fs, canvas]
-- Adversarial verification for the Mind mixtures. Scratch file; safe to delete.
local Parser = require("@src/spell/Parser")
local Resolver = require("@src/spell/Resolver")
local Renderer = require("@src/spell/Renderer")

local outDir = fs.join(__dirname, "renders")
pcall(function()
    fs.mkdir(outDir)
end)

-- {name, incantation, expected element (nil = anything), expectParseError}
local cases = {
    -- bound forms, forward: base cluster with Muse runes tacked on
    {"adv-bound-fervor", "{BBB''}", "Fervor"},
    {"adv-bound-reverie", "{WWW''}", "Reverie"},
    {"adv-bound-whisper", "{ZZZ''}", "Whisper"},
    {"adv-bound-resolve", "{GGG''}", "Resolve"},
    {"adv-bound-instinct", "{JJJ''}", "Instinct"},
    {"adv-bound-clarity", "{!!!''}", "Clarity"},
    {"adv-bound-impulse", "{^^^''}", "Impulse"},
    {"adv-bound-memory", "{:::''}", "Memory"},
    {"adv-bound-astral", "{***''}", "Astral"},
    {"adv-bound-burden", "{@@@''}", "Burden"},

    -- bound forms, reversed: Muse cluster with the base rune tacked on
    {"adv-rbound-fervor", "{'''BB}", "Fervor"},
    {"adv-rbound-reverie", "{'''WW}", "Reverie"},
    {"adv-rbound-whisper", "{'''ZZ}", "Whisper"},
    {"adv-rbound-resolve", "{'''GG}", "Resolve"},
    {"adv-rbound-instinct", "{'''JJ}", "Instinct"},
    {"adv-rbound-clarity", "{'''!!}", "Clarity"},
    {"adv-rbound-impulse", "{'''^^}", "Impulse"},
    {"adv-rbound-memory", "{'''::}", "Memory"},
    {"adv-rbound-astral", "{'''**}", "Astral"},
    {"adv-rbound-burden", "{'''@@}", "Burden"},

    -- corruptors corrupt, they never mix
    {"adv-mind-decay", "{''' %%%}", "Mind"},
    {"adv-decay-mind", "{%%% '''}", "Mind"},
    {"adv-mind-ruin", "{''' ///}", "Mind"},
    {"adv-mind-decay-heavy", "{'' %%%%%%}", "Mind"},
    {"adv-oblivion-still-works", "{%%% ///}", "Oblivion"},
    {"adv-mix-plus-both-corruptors", "{''' BBB %% //}", "Fervor"},

    -- smart punctuation from real chat clients
    {"adv-curly-fervor", "{\u{2019}\u{2019}\u{2019} BBB}", "Fervor"},
    {"adv-prime-memory", "{\u{2032}\u{2032}\u{2032} :::}", "Memory"},

    -- nesting with corruptors and mixtures together
    {"adv-nested-corrupt", "{''' @@@ {%%% '''}}", "Burden"},

    -- big lone Mind cluster stays Mind
    {"adv-lone-mind-big", "{'''''''''}", "Mind"},

    -- malformed borders must be graceful parse errors, not crashes
    {"adv-unterminated", "{''' BBB", nil, true},
    {"adv-mismatched", "{''' BBB]", nil, true},
    {"adv-stray-tail", "{''' BBB} x", nil, true},
}

local failures = 0

for _, case in ipairs(cases) do
    local name, text, expected, expectParseError = case[1], case[2], case[3], case[4]
    local okParse, spell, parseErr = pcall(Parser.Parse, text)
    if not okParse then
        print(`== {name} :: {text}`)
        print(`   PARSER CRASHED: {spell}`)
        failures += 1
        continue
    end
    if not spell then
        print(`== {name} :: {text}`)
        if expectParseError then
            print(`   graceful parse error (expected): {parseErr}`)
        else
            print(`   PARSE ERR: {parseErr}`)
            failures += 1
        end
        continue
    end
    if expectParseError then
        print(`== {name} :: {text}`)
        print(`   EXPECTED A PARSE ERROR but it parsed`)
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

if failures > 0 then
    print(`done — {failures} FAILURES`)
else
    print("done — adversarial suite clean")
end
