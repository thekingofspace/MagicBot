--#include[fs]
local Parser = require("@src/spell/Parser")
local Cellar = require("@src/ale/Cellar")
local Tankard = require("@src/ale/Tankard")

local outDir = fs.join(__dirname, "renders")
pcall(function()
    fs.mkdir(outDir)
end)

local MaxOrder = "{" .. string.rep("G", 80) .. " " .. string.rep(":", 40) .. " DD PP && .. 44 " .. string.rep("H", 20) .. " ~ N {CHEERS} $GILDEDBOAR}"

local cases = {
    {"amber-pint", "{BBB}"},
    {"stout-tankard", "{GGGG T P}"},
    {"lager-flute", "{WWW I .}"},
    {"mead-horn", "{!!! X ~}"},
    {"cordial-jug", "{JJJ C}"},
    {"vintage-wine", "{:::: Y 7}"},
    {"porter-pint", "{*** .}"},
    {"firewater-snifter", "{^^^ O}"},
    {"dream-goblet", "{''' V .}"},
    {"skunked", "{%%% P F}"},
    {"frosted-tankard", "{WWW T --}"},
    {"mulled-chalice", "{::: U N 2}"},
    {"rowdy-firewater", "[^^^^ O]"},
    {"oak-aged-stout", "{GGGG D 8 PP &}"},
    {"toast-tankard", "{GGG T {TO THE KING} P}"},
    {"tavern-barrel", "{BBB D $GILDEDBOAR}"},
    {"wine-bottle", "{::::: Q 12 $OLDCROW}"},
    {"empty", "{}"},
    {"single-rune", "{B}"},
    {"emdash", "{WW\u{2014}T}"},
    {"foam-only", "{PPP}"},
    {"mulled-lager", "{WWW N}"},
    {"splash-blend", "{BBBB GG T}"},
    {"rowdy-stout", "[GGG T P]"},
    {"big-horn", "{!!!! XX 3}"},
    {"vinegar-lager", "{WWWW 66}"},
    {"honeyed-mead-chalice", "{!!! U ~ N}"},
    {"nested-empty-toast", "{BB T {}}"},
    {"max-order", MaxOrder},
    {"bottle-stout", "{GGGG QQ}"},
    {"bottle-spirits", "{^^^ QQQ $BLACKKEG}"},
    {"bottle-swingtop", "{WWW QQQQ}"},
    {"bottle-demijohn", "{!!!! QQQQQ $MOTHERS}"},
    {"bottle-gin", "{^^^ QQQQQQ $DRYOATH}"},
    {"margarita", "{^^^ FF = S A}"},
    {"margarita-rowdy", "[^^^ FF = S A]"},
    {"tavern-sour", "{^^^ FF K}"},
    {"boilermaker", "{^^ GG K}"},
    {"sparkler", "{:::: .. ( I}"},
    {"fey-martini", "{^^ '' S M}"},
    {"moonglow", "{''' !! S A}"},
    {"regret", "{%% ^^ S K}"},
    {"shandy", "{WWW FF L}"},
    {"house-mix", "{BB :: S}"},
    {"meadowsweet", "{!!! JJ ( L}"},
    {"salt-stout", "{GGG T =}"},
    {"bad-no-border", "BBB"},
    {"bad-mismatch", "{BB]"},
}

for _, case in ipairs(cases) do
    local name, text = case[1], case[2]
    local spell, parseErr = Parser.Parse(text)
    if not spell then
        print(`== {name} :: {text}`)
        print(`   PARSE ERR: {parseErr}`)
        continue
    end

    local okServe, pour = pcall(Cellar.Serve, spell)
    if not okServe then
        print(`== {name} :: {text}`)
        print(`   SERVE ERR: {pour}`)
        continue
    end

    print(`== {name} :: {text}`)
    print(`   {pour.Title}`)
    for _, line in ipairs(pour.Lines) do
        print(`   {line}`)
    end
    for _, note in ipairs(pour.Notes) do
        print(`   note: {note}`)
    end
    print(`   family={pour.FamilyName} glass={pour.VesselLabel} proof={pour.ProofLabel} age={pour.AgeLabel} head={pour.HeadLabel} quality={pour.QualityLabel}{if pour.Cocktail then ` mixed={pour.Cocktail}` else ""}{if pour.Rowdy then " (rowdy)" else ""}`)

    local okRender, image = pcall(Tankard.Render, pour)
    if not okRender then
        print(`   RENDER ERR: {image}`)
        continue
    end

    fs.writeImage(`{outDir}/ale-{name}.png`, image, "png")
    print(`   saved ale-{name}.png`)
end

-- Contract check: the module must expose Commands and Handlers for the bot.
local Ale = require("@src/ale")
assert(Ale.Commands[1].name == "ale", "command name mismatch")
assert(Ale.Commands[1].options[1].name == "recipe", "option name mismatch")
assert(Ale.Commands[1].options[1].max_length == 200, "option max_length mismatch")
assert(typeof(Ale.Handlers.ale) == "function", "handler missing")
print("module contract ok")

print("done")
