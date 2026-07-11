--#include[fs]
local Parser = require("@src/spell/Parser")
local Resolver = require("@src/grimoire/Resolver")
local Renderer = require("@src/grimoire/Renderer")

local outDir = fs.join(__dirname, "renders")
pcall(function()
    fs.mkdir(outDir)
end)

local cases = {
    {"leather-journal", "{GGG E H U}"},
    {"dragonhide-grimoire", "{BBBB S HH R UUU ~ &}"},
    {"vellum-eye", "{WWWW '' E ~ F}"},
    {"gilt-codex", "{!!!!! DD HHH K RR UUUU ~ .... 2 $LEX $AUREA}"},
    {"void-codex", "{***** EEEEE HH K R UUUUUU FF .... ~ & 7 III $NOX}"},
    {"ancient-tome", "{:::: C U U I 3}"},
    {"storm-ward", "{^^^ DDD H U F}"},
    {"dream-eye", "{''''' EEE ~ FF U}"},
    {"flesh-folio", "{%%% S K &}"},
    {"ruin-chapbook", "{// X}"},
    {"locked-fat", "{GG K IIIII HH}"},
    {"chained-library", "{::: T & U U U 12}"},
    {"studded-knot", "{BB X ........ R}"},
    {"thin-plain", "{W}"},
    {"titled-serpent", "{GGGG SSS $VENOM U U F}"},
    {"exlibris-nested", "{!! B M {O} R H}"},
    {"cursed-battered", "[GG E HH F]"},
    {"cursed-void", "[**** EEE K &]"},
    {"degenerate", "{}"},
    {"single-rune", "{E}"},
    {"tower-mountains", "{^^ T M U U}"},
    {"max-length", "{" .. string.rep("*", 50) .. " " .. string.rep("E", 30) .. " HHH K RR " .. string.rep("U", 20) .. " " .. string.rep("I", 20) .. " FFFF ........ ~ & 999 $CODEX $MAXIMA}"},
    {"emdash", "{GG\u{2014}E}"},
    {"bad-no-border", "GGG EEE"},
    {"bad-mismatch", "{GG E]"},
}

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
        print(`   RESOLVE ERR: {plan}`)
        continue
    end

    print(`== {name} :: {text}`)
    print(`   {plan.name}`)
    print(`   {plan.description}`)
    print(`   Cover: {Resolver.Materials[plan.material].Name} | Quality: {plan.qualityWord} {plan.tierNoun} (score {string.format("%.1f", plan.score)}) | Pages: {plan.pageCount} | Clasps: {plan.clasps}`)
    for _, note in ipairs(plan.notes) do
        print(`   note: {note}`)
    end

    local okRender, image = pcall(Renderer.Render, plan)
    if not okRender then
        print(`   RENDER ERR: {image}`)
        continue
    end

    fs.writeImage(`{outDir}/grimoire-{name}.png`, image, "png")
    print(`   saved grimoire-{name}.png`)
end

local Grimoire = require("@src/grimoire")
assert(Grimoire.Commands and Grimoire.Commands[1].name == "grimoire", "grimoire command missing")
assert(Grimoire.Commands[1].options[1].name == "design", "design option missing")
assert(typeof(Grimoire.Handlers.grimoire) == "function", "grimoire handler missing")
print("module contract: /grimoire command and handler present")

local stableA = Resolver.Resolve(Parser.Parse("{BBBB S HH R UUU ~ &}") :: any)
local stableB = Resolver.Resolve(Parser.Parse("{BBBB S HH R UUU ~ &}") :: any)
if stableA.seed == stableB.seed and stableA.description == stableB.description and stableA.score == stableB.score then
    local bytesA = Renderer.Encode(Renderer.Render(stableA))
    local bytesB = Renderer.Encode(Renderer.Render(stableB))
    if bytesA == bytesB then
        print("determinism: stable designs bind identically, down to the pixel")
    else
        print("determinism: MISMATCH — same plan drew two different books!")
    end
else
    print("determinism: MISMATCH on stable design!")
end

local cursedA = Resolver.Resolve(Parser.Parse("[GG E HH F]") :: any)
local cursedB = Resolver.Resolve(Parser.Parse("[GG E HH F]") :: any)
if cursedA.seed ~= cursedB.seed then
    print("curse: fresh roll every summoning")
else
    print("curse: WARNING — two summonings matched seeds")
end

print("done")
