--#include[fs]
local Parser = require("@src/spell/Parser")
local Hall = require("@src/feast/Hall")
local Table = require("@src/feast/Table")

local outDir = fs.join(__dirname, "renders")
pcall(function()
    fs.mkdir(outDir)
end)

local MaxOrder = "{" .. string.rep("D", 60) .. " 55 ;; JJ R H // ,, ^^ {" .. string.rep("P", 30) .. " ~ .} {" .. string.rep("B", 30) .. " ! //// S 22} '' $SILVERSPIT}"

local cases = {
    {"drover-beef", "{BBBB 22 ~ J R / {PP ~ .} {O // S 33}}"},
    {"dragon-ages", "{DDDDDD 55 ; JJ R H / , ^^ {;;} {GGG ~ ,} {B ! /// S 22} '' $SILVERSPIT}"},
    {"coast-fish", "{FFF 2 CC J {SS ( .}}"},
    {"potluck", "[WWW 44 {RR} {O /}]"},
    {"lone-rabbit", "{U 55}"},
    {"phoenix-reignite", "{!!!! 66 6 ~ {EE .} {FF 2}}"},
    {"pork-orchard", "{PPPPP 44 EE J {RR .} {O //}}"},
    {"lamb-shepherd", "{LLL 22 : J {RRR 2 ,} {I / Y}}"},
    {"mutton-humble", "{MM 44 {OO 2} {FF}}"},
    {"fruit-side", "{UU 5 {FFF ,} {O //}}"},
    {"boar-black", "{XXXXX 44 E A {MM 3} {O // *}}"},
    {"venison-hunt", "{VVV 1 :: J {BB ~} {I //}}"},
    {"wyvern-cheap", "{YYY 44 {CC} {F}}"},
    {"shadow-midnight", "{****** 1 - {LL} {O / * S}}"},
    {"bird-goose", "{WWW 44 T J {PP ~ .} {R RRR W /}}"},
    {"hen-modest", "{W 4 {E}}"},
    {"noodle-pile", "{OOOO ( {EE} {F ! 2}}"},
    {"broth-market", "{IIII 1 ^^ {EEE .} {O /}}"},
    {"dragon-pie", "{QQQ DD 33 {PP ~} {O // S}}"},
    {"venison-skewers", "{KKK VV 22 . {SS (} {RR W}}"},
    {"fairground", "{SSSS PP 33 {OO 2} {RRRR W /}}"},
    {"gravy-boat", "{BBBB 22 {::} {PP} {O //}}"},
    {"empty-side-slot", "{LLL 22 {} {B ! ///}}"},
    {"empty-platter", "{~~ JJ {PP} {O /}}"},
    {"bare-table", "{}"},
    {"warm-bare", "^^{}"},
    {"charred-beef", "{BBB 66 {PP} {O /}}"},
    {"blue-rare-pork", "{PPP 0 {RR} {O /}}"},
    {"overdone-dragon", "{DDDD 44 {GG} {O /}}"},
    {"spoiled-entree", "{BBB %%% {PP ~} {O //}}"},
    {"spoiled-side", "{BBB 22 {PP %%%} {O //}}"},
    {"mellowed-taint", "{BBBB %% 44 {PP} {O //}}"},
    {"burst-loaf", "{BBB 22 {PP} {O}}"},
    {"burnt-loaf", "{BBB 22 {PP} {O / 9}}"},
    {"pale-loaf", "{BBB 22 {PP} {O / 1}}"},
    {"ribbons-loaf", "{BBB 22 {PP} {O ///////}}"},
    {"wheatstalk", "{BBB 22 {PP} {B //// ! S 33}}"},
    {"rolls-five", "{SSS 33 {LL} {RRRRR W / ,}}"},
    {"baguette", "{VV 2 {CC} {I / Y 22}}"},
    {"flatbread", "{LL 22 {SS (} {F ! J}}"},
    {"inner-chaos-side", "{BBB 22 [RR] {O /}}"},
    {"inner-chaos-bread", "{BBB 22 {PP} [O]}"},
    {"third-circle", "{BBB 22 {PP} {O /} {SS} {::}}"},
    {"depth-fold", "{BBB 22 {PP {~}} {O /}}"},
    {"cold-vigil", "{FF 1 CC --- {LL} {F *}}"},
    {"lukewarm", "{BBB 22 ^ - {PP} {O /}}"},
    {"menu-long", "{BBB 22 $GRANDHARVESTFEAST {PP} {O /}}"},
    {"emdash-chill", "{BBB\u{2014}22 {PP} {O /}}"},
    {"max-order", MaxOrder},
    {"scraps", "{BBB NN ZZ @@ 22 {PP ??} {O / ==}}"},
    {"bad-no-border", "BBBB"},
    {"bad-mismatch", "{BB {PP] O}"},
}

local onlyRender = {...}

for _, case in ipairs(cases) do
    local name, text = case[1], case[2]
    local spell, parseErr = Parser.Parse(text)
    if not spell then
        print(`== {name} :: {text}`)
        print(`   PARSE ERR: {parseErr}`)
        continue
    end

    local okSolve, banquet = pcall(Hall.Solve, spell)
    if not okSolve then
        print(`== {name} :: {text}`)
        print(`   SOLVE ERR: {banquet}`)
        continue
    end

    print(`== {name} :: {text}`)
    print(`   {banquet.Title}`)
    for _, line in ipairs(banquet.Lines) do
        print(`   {line}`)
    end
    for _, note in ipairs(banquet.Notes) do
        print(`   note: {note}`)
    end
    print(`   entree={banquet.EntreeField} side={banquet.SideField} bread={banquet.BreadField} doneness={banquet.DonenessField} temp={banquet.TempLabel} seats={banquet.SeatsLabel} total={banquet.Total} tier={banquet.Tier.Label}`)

    local okRender, image = pcall(Table.Render, banquet)
    if not okRender then
        print(`   RENDER ERR: {image}`)
        continue
    end

    fs.writeImage(`{outDir}/feast-{name}.png`, image, "png")
    print(`   saved feast-{name}.png`)

    if not spell.unstable and name ~= "inner-chaos-side" and name ~= "inner-chaos-bread" then
        local banquet2 = Hall.Solve(spell)
        local same = banquet.Title == banquet2.Title
            and table.concat(banquet.Lines, "|") == table.concat(banquet2.Lines, "|")
            and table.concat(banquet.Notes, "|") == table.concat(banquet2.Notes, "|")
            and banquet.Seed == banquet2.Seed
        if not same then
            print("   DETERMINISM ERR: second solve differs")
            continue
        end
        local bytes1 = Table.Encode(image)
        local bytes2 = Table.Encode(Table.Render(banquet2))
        if bytes1 ~= bytes2 then
            print("   DETERMINISM ERR: second render differs")
        else
            print("   deterministic ok")
        end
    end
end

local Feast = require("@src/feast")
assert(Feast.Commands[1].name == "feast", "command name mismatch")
assert(Feast.Commands[1].options[1].name == "menu", "option name mismatch")
assert(typeof(Feast.Handlers.feast) == "function", "handler missing")
print("module contract ok")

print("done")
