--#include[fs]
local Parser = require("@src/spell/Parser")
local Resolver = require("@src/spell/Resolver")
local Renderer = require("@src/spell/Renderer")

local outDir = fs.join(__dirname, "renders")
pcall(function()
    fs.mkdir(outDir)
end)

local Stroke = {
    tall = "{AAA!>>}",
    short = "{AAA!>}",
    bar = "{LL AAA!> LL LL}",
    arch = "{LL AAA!)> LL LL}",
    loop = "{LL AAA!((((((((> LL LL}",
    open = "{LL AAA!((((((> LL LL}",
    swayR = "{LL AAA!)))> LL LL}",
    swayL = "{LL AAA!(((> LL LL}",
    gap = "{MM}",
}

local Glyphs = {
    I = {"tall"},
    a = {"loop", "short"},
    m = {"short", "arch", "arch"},
    t = {"tall", "bar"},
    h = {"tall", "arch"},
    e = {"loop", "bar"},
    c = {"open"},
    o = {"loop"},
    l = {"tall"},
    s = {"swayR", "swayL"},
    p = {"tall", "loop"},
    r = {"short", "arch"},
    n = {"short", "arch"},
    [" "] = {"gap"},
}

local function Skywrite(sentence: string): string
    local parts = {"IUUQM{XXT# CCCC!# !!!"}
    for i = 1, #sentence do
        local glyph = Glyphs[string.sub(sentence, i, i)]
        if glyph then
            for _, strokeName in ipairs(glyph) do
                table.insert(parts, Stroke[strokeName])
            end
        end
    end
    return table.concat(parts, " ") .. "}"
end

local MegaSkywrite = Skywrite("I am the coolest person here")

local cases = {
    {"even-fire", "{AAARB BBB AAARB}"},
    {"skewed-fire", "{AAARB BBB AAAR}"},
    {"layered-fan", "{RRR BB {AAA}}"},
    {"steam-mix", "{WWW BBB}"},
    {"bottles", "PP{XX VV E}"},
    {"twin-bottles", "PPHHQT{XXXVVE T {KKES E S} {KKEO E O}}"},
    {"petrify", "PPPPHHQS{RRR GGG FFO DDOE CCCGO}"},
    {"fire-west", "{AAA AAA AAA AAAB}"},
    {"fire-west-hot", "{AAA AAA AAA AAAB BBB}"},
    {"crystal-plague", "IQJ{RRR GGG !!! FFJ DDJE ~~~GO}"},
    {"fire-trap", "QB{RRR WWW}"},
    {"nested-trap", "{GGG QJ{DDDO}}"},
    {"colored-fire", "{BBB1 1{CCCG !!}}"},
    {"curveball", "{AAAB) BBB}"},
    {"mote-coil", "{AAAB.. AAA& BBB}"},
    {"singularity", "I{*** @@@}"},
    {"eclipse", "{@@@ !!!}"},
    {"gravity-place", "{@@@@ ~~@# RRR}"},
    {"lightning-west", "{AAA AAA AAA AAA^ ^^^}"},
    {"plasma", "{BBB ^^^}"},
    {"boom", "[AAA AAA AAA AAA BBBB RRR]"},
    {"unstable-core", "{WWW [AAA^]}"},
    {"blight", "{BBB %%%}"},
    {"ruin-west", "{AAA AAA AAA AAA/ ///}"},
    {"oblivion", "{%%% ///}"},
    {"decayed-steam", "{WWW BBB %%%%}"},
    {"mismatch", "{AAA]"},
    {"storm-30", "IHHHHHHHHHHHHHHHHHHHHHHHHHHHHHH[^^^^^^]"},
    {"stone-trap", "QM{RRR GGG ~~~GO}"},
    {"loud-noise", "{MMMMM ZZZZ RRR OO}"},
    {"bang", "[MMMMM ZZZZ RRR OO]"},
    {"nuke", "UUUYYY[BBBBB !!!!! %%%%% RRRR DDDDO# AAAA AAAA AAAA AAAA I{=====% RRRRR ~~~%# DDDD%O}]"},
    {"petrify-curse", "IQTYYYYY{GG ~~GOE %%}"},
    {"anchored-curse", "IQTYYYYY{XXTO GG ~~GOE %%}"},
    {"brain-off", "{^^^ JJJ FFF^O DDD^OE}"},
    {"infinite-wine", "I{CCCCWV WW JJ %%}"},
    {"altar-take", "{XXXX_S}"},
    {"altar-trap", "Q_{~~~G_ GG}"},
    {"time-slow", "{:::: RRR}"},
    {"stasis-field", "{@@@ ::: RRR}"},
    {"flash-freeze", "{----O WW}"},
    {"erosion", "{WWW :::}"},
    {"pocket-space", "I{*** CCCCC*#}"},
    {"heal", "PPPQT{XXTO JJJ CCCCJOE DDD%OE}"},
    {"terrarium", "IUU{XX_ *** :::: CCC*# CCCW CCCG {BBB !!!}}"},
    {"full-terrarium", "IUU{XXX_T *** :::: CCC*# CCCW CCCG CCJ_ %% IRR{BBB !!!} P{WWW ZZ RR}}"},
    {"impact-bolt", "{AAAAB QA[BBBBB RRRR]}"},
    {"singularity-cannon", "UU{AAAAAAG CCCCG QA{*** @@@ UUU} [BBBB]}"},
    {"touch-shock", "QV{^^^ RRR}"},
    {"shake-ward", "Q&{GGG RRR}"},
    {"proximity-mine", "QR[BBBB RRR]"},
    {"landmine", "QV[XXT# BBBBB GGG RRRR ..]"},
    {"trapped-chest", "Q([XXTV BBBBB RRRR .. DDO]"},
    {"magnum-opus", "IUUNYYHHQM[AAARB ~~~GO# KK_S %%% ::: ..&) BBB5 MMO 5[!!! ***] QA{^^^^ @@ Q&[JJ %%]} {WWW --O}]"},
    {"floating-mountains", "IUUU{XXT# ~~~~G# GGGG RRRRR IN{@@@@@@ ~~~@#}}"},
    {"aim-two-slots", "{AAAB AAAB}"},
    {"aim-fine", "{AAAAB AAB}"},
    {"aim-flip", "N{AAAB}"},
    {"aim-pad", "{LL AAAB}"},
    {"aim-diagonal", "{AAAB AAAB AAA AAA}"},
    {"sea-freeze", "INQG{WWWW ----W RRRRR XXT#}"},
    {"break-shake", "INQ&{BBB RRR}"},
    {"until-severed", "INQT{BBB RRR}"},
    {"until-taken", "INQ_{!!! RRR}"},
    {"until-spent", "INQE{JJ CCJO}"},
    {"hour-timer", "INQ:{^^^ RRR}"},
    {"hour-trap", "Q:{BBB RRR}"},
    {"ash-pollution", "INQZS{BBBB JJJJ RRRRR}"},
    {"mud-the-sea", "INQG4{CCCCG GGG WW RRRR XXT#}"},
    {"pollution-engine", "I{XXT# INQZS{BBBB JJJJ RRRRR} INQG4{CCCCG GGG WW RRRR}}"},
    {"volt-redirect", "INQ.{XXTV IUQ?{FFF^O DDD^? AAAA1< 1NU{^^^^^^}}}"},
    {"fire-shield", "INQ.{XXTV IUQ?{FFFBO DDDB? AAAA1< 1NU{BBBBBB}}}"},
    {"golem", "I{CCCCCG GG $$VHII CCCJJ}"},
    {"storm-spider", "IU{CCCCCG $$DONNNNNNNN CCCJJJ JJ I[^^^^^ RRR]}"},
    {"skywrite-the", "IUUQM{XXT# CCCC!# !!! {AAA!>>} {LL AAA!> LL LL} {AAA!>>} {LL AAA!)> LL LL} {LL AAA!((((((((> LL LL} {LL AAA!> LL LL}}"},
    {"skywrite-coolest", MegaSkywrite},
    {"tornado", "UUUUUUUU[ZZZZZ @@@ &&&&& RRRRR N{@@}]"},
    {"reshape-offering", "{$$WO _ ~~G_}"},
    {"aim-ahead", "{AAAB >>>}"},
    {"counterspell", "IQ?{DDDD?}"},
    {"spell-mirror", "IQ?{XXX?O KK?S}"},
    {"spell-forge", "IQ?{CCC^? ~~~B?}"},
    {"spell-freeze", "IQ?{----? FF?}"},
    {"extinction", "IUUUNQJ0[FFFJ DDDDDJO RRRRR {JJJ @@@@@@@@} INQZS{BBBB JJJJ RRRRR} INQG4{CCCCG GGG WW RRRR} IQJ0{JJJJJJ WWW CCCCCJ# CCCW CCCZ RRRRR}]"},
    {"radiate-decay", "{===%O RRRR}"},
    {"radiate-listen", "Q={!!! RRR}"},
    {"radiate-tuned", "Q=%{DDDDO RRR}"},
    {"radiate-marked", "Q=7{^^^ RRR}"},
    {"radiate-until", "INQ=B{WWWW RRRR}"},
    {"radiate-bottled", "{==4 ZZ 4{BBB !!}}"},
    {"radiate-offering", "{===_ ZZ}"},
    {"ward", "{}"},
    {"kitchen-sink", "PPUUN{AAAB GG CCB LL {WWR AAA} VV}"},
    {"bad", "AAA BBB"},
}

for _, case in ipairs(cases) do
    local name, text = case[1], case[2]
    local spell, parseErr = Parser.Parse(text, 3500)
    if not spell then
        print(`== {name} :: {text}`)
        print(`   PARSE ERR: {parseErr}`)
        continue
    end

    local okResolve, effect, plan = pcall(Resolver.Resolve, spell)
    if not okResolve then
        print(`== {name} :: {text}`)
        print(`   RESOLVE ERR: {effect}`)
        continue
    end

    print(`== {name} :: {text}`)
    print(`   {effect.Description}`)
    for _, note in ipairs(effect.Notes) do
        print(`   note: {note}`)
    end

    local okRender, image = pcall(Renderer.Render, plan, effect)
    if not okRender then
        print(`   RENDER ERR: {image}`)
        continue
    end

    fs.writeImage(`{outDir}/{name}.png`, image, "png")
    print(`   saved {name}.png`)
end

for name, incantation in pairs({
    ["shapeform-golem"] = "{CCCCCG $$VHII CCCJJ}",
    ["shapeform-spider"] = "IU{CCCCCG $$DONNNNNNNN CCCJJJ JJ I[^^^^^ RRR]}",
}) do
    local shapeSpell = Parser.Parse(incantation)
    if shapeSpell then
        local _, shapePlan = Resolver.Resolve(shapeSpell)
        local shapeImage = Renderer.RenderShapeform(shapePlan)
        if shapeImage then
            fs.writeImage(`{outDir}/{name}.png`, shapeImage, "png")
            print(`{name} render saved`)
        else
            print(`{name} render FAILED`)
        end
    end
end

print("done")
