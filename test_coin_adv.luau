--#include[fs]
-- Adversarial cases for the mint. Every case must resolve cleanly or produce
-- a graceful parse error — never a crash, never a broken render.
local Parser = require("@src/spell/Parser")
local Resolver = require("@src/coin/Resolver")
local Renderer = require("@src/coin/Renderer")

local outDir = fs.join(__dirname, "renders")
pcall(function()
    fs.mkdir(outDir)
end)

local cases = {
    -- required adversarial set
    {"empty", "{}"},
    {"hammered-pure-gold", "[!!!]"},
    {"hole-only", "{.}"},
    {"cluster-digit", "{!!O5}"},
    {"emdash", "{!!\u{2014}A}"},
    -- one of every material body
    {"mat-gold", "{!}"},
    {"mat-silver", "{W}"},
    {"mat-copper", "{B}"},
    {"mat-iron", "{G}"},
    {"mat-voidmetal", "{*}"},
    {"mat-electrum", "{^}"},
    {"mat-ancientbronze", "{::}"},
    {"mat-slag", "{%%}"},
    -- pile-on probes
    {"zero-numeral", "{0}"},
    {"numeral-flood", "{000111222333}"},
    {"hammered-hole", "[. *]"},
    {"size-flood", "{RRRRRRRRRRRR}"},
    {"square-hole", "{# . G 5}"},
    {"wedge-hole", "{V . B}"},
    {"spiral-flood", "{(((((((( W}"},
    {"rings-prefix", "!!!{A}"},
    {"deep-nest", "{{{{{!}}}}}"},
    {"stable-inside-hammer", "[{!} W]"},
    {"unknown-symbols", "{?? ~~ <> W}"},
    {"lowercase", "{www a}"},
    {"tie-metals", "{! W}"},
    {"tie-shapes", "{# X GG}"},
    {"all-runes", "{!^WBG* :% O#VX. R& () ACDKLSTUYZ 0123456789 ?}"},
    -- graceful-error expectations
    {"bad-word", "hello there"},
    {"bad-unicode", "{\u{1F600}}"},
    {"bad-unclosed", "{!!!"},
    {"bad-empty-string", ""},
}

local failures = 0

for _, case in ipairs(cases) do
    local name, text = case[1], case[2]
    local spell, parseErr = Parser.Parse(text)
    if not spell then
        print(`== {name} :: {text}`)
        print(`   PARSE ERR: {parseErr}`)
        continue
    end

    local okResolve, plan = pcall(Resolver.Resolve, spell)
    if not okResolve then
        print(`== {name} :: {text}`)
        print(`   RESOLVE CRASH: {plan}`)
        failures += 1
        continue
    end

    print(`== {name} :: {text}`)
    print(`   {plan.name} | {plan.denomination} ({plan.value} bits) | {plan.diameter} mm | edge {plan.edge} | strike {plan.strike}`)
    for _, note in ipairs(plan.notes) do
        print(`   note: {note}`)
    end

    local okRender, image = pcall(Renderer.Render, plan)
    if not okRender then
        print(`   RENDER CRASH: {image}`)
        failures += 1
        continue
    end

    fs.writeImage(`{outDir}/coinadv-{name}.png`, image, "png")
    print(`   saved coinadv-{name}.png`)
end

if failures > 0 then
    error(`{failures} adversarial case(s) crashed`)
end
print("adversarial: all cases resolved or errored gracefully")
