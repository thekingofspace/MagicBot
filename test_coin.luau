--#include[fs]
local Parser = require("@src/spell/Parser")
local Resolver = require("@src/coin/Resolver")
local Renderer = require("@src/coin/Renderer")

local outDir = fs.join(__dirname, "renders")
pcall(function()
    fs.mkdir(outDir)
end)

local cases = {
    {"gold-sword", "{!!! A}"},
    {"iron-token", "{G}"},
    {"blank-flan", "{}"},
    {"euro", "{!!!! WW O A 1}"},
    {"hammered-bit", "[BB A]"},
    {"void-cash", "{**** . C}"},
    {"ancient-crown", "{!!!! ::: K R}"},
    {"square-iron", "{GG # T 5}"},
    {"electrum-wedge", "{^^^ V Y}"},
    {"silver-scallop", "{WWW X S &}"},
    {"spiral-copper", "{BBB ) Z}"},
    {"debased", "{GG %%% A}"},
    {"pure-slag", "{%%%}"},
    {"pure-ancient", "{::::}"},
    {"big-flawless-gold", "{!!!!! RRRR & A K 1}"},
    {"numeral-100", "{W 100}"},
    {"nested", "{!! {WW A} 2}"},
    {"hammered-silver-serpent", "[WWWW SSS &]"},
    {"hammered-void", "[***** Z RR]"},
    {"widdershins-crown", "{^^^^ (( K 3}"},
    {"crowded", "{!! W A C D K L 7 & ) R}"},
    {"emdash", "{!!\u{2014}A}"},
    {"max-length", "{" .. string.rep("!", 60) .. " " .. string.rep("W", 40) .. " " .. string.rep("A", 40) .. " RRRR & 9999 KK LL}"},
    {"bad-no-border", "AAA BBB"},
    {"bad-mismatch", "{!!!]"},
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
    print(`   Material: {Resolver.Materials[plan.material].Name} | Denomination: {plan.denomination} ({plan.value} bits) | Diameter: {plan.diameter} mm | Edge: {plan.edge} | Strike: {plan.strike}`)
    for _, note in ipairs(plan.notes) do
        print(`   note: {note}`)
    end

    local okRender, image = pcall(Renderer.Render, plan)
    if not okRender then
        print(`   RENDER ERR: {image}`)
        continue
    end

    fs.writeImage(`{outDir}/coin-{name}.png`, image, "png")
    print(`   saved coin-{name}.png`)
end

-- Module contract check: the command module must load and expose /coin.
local Coin = require("@src/coin")
assert(Coin.Commands and Coin.Commands[1].name == "coin", "coin command missing")
assert(Coin.Commands[1].options[1].name == "design", "design option missing")
assert(typeof(Coin.Handlers.coin) == "function", "coin handler missing")
print("module contract: /coin command and handler present")

-- Hammered designs must roll fresh variation per cast.
local hammerA = Resolver.Resolve(Parser.Parse("[BBBB A]") :: any)
local hammerB = Resolver.Resolve(Parser.Parse("[BBBB A]") :: any)
if hammerA.seed ~= hammerB.seed then
    print("hammer: fresh strike every cast")
else
    print("hammer: WARNING — two strikes matched seeds")
end

-- Determinism check: the same stable design must resolve and seed identically.
local first = Resolver.Resolve(Parser.Parse("{!!! A}") :: any)
local second = Resolver.Resolve(Parser.Parse("{!!! A}") :: any)
if first.seed == second.seed and first.value == second.value and first.description == second.description then
    print("determinism: stable designs match across casts")
else
    print("determinism: MISMATCH on stable design!")
end

print("done")
