--#include[fs]
local Parser = require("@src/spell/Parser")
local Resolver = require("@src/forge/Resolver")
local Renderer = require("@src/forge/Renderer")

local outDir = fs.join(__dirname, "renders")
pcall(function()
    fs.mkdir(outDir)
end)

local cases = {
    -- simple blades
    {"forge-plain-sword", "{IIIAG TTO}"},
    {"forge-arming-sword", "{IIIAAAG H T O U}"},
    {"forge-dagger", "{IAAAW T O}"},
    {"forge-greatsword", "{IIIIIIAAG HH TT OO UU}"},
    -- category heads
    {"forge-axe", "{DDDG III T X}"},
    {"forge-broadaxe", "{DDDDDG IIII O}"},
    {"forge-double-axe", "{DDDDDDB IIII}"},
    {"forge-hammer", "{MMMG III O}"},
    {"forge-maul", "{MMMMMG IIIII X}"},
    {"forge-spear", "{YYG IIIII}"},
    {"forge-trident", "{YYYYW IIIIII O}"},
    -- materials
    {"forge-steel-longsword", "{IIIIAAAGGG H T O ~~}"},
    {"forge-silver-axe", "{DDDW III X O}"},
    {"forge-gilded-knife", "{IAA! T O}"},
    {"forge-voidsteel", "{IIIA* H T O ~}"},
    {"forge-storm-greatsword", "{IIIIIAAA^^ HH TT OO U ~~}"},
    {"forge-ancient-blade", "{IIIA: H T O}"},
    {"forge-corrupted", "{IIIA% T}"},
    {"forge-blued-steel", "{IIIABG H T O}"},
    -- edge shapes
    {"forge-scimitar", "{IIIAAG))) H T O}"},
    {"forge-kukri", "{IAAA(( T O}"},
    {"forge-flamberge", "{IIIIIAA&&G HH TT OO}"},
    {"forge-sawback", "{IIIAG... H T O}"},
    -- warp
    {"forge-warped-sword", "[IIIAG H T O]"},
    {"forge-warped-voidsteel-flamberge", "[IIIIIAA&&* HH TT OO]"},
    -- etchings, inscriptions, proof marks
    {"forge-etched", "{IIIAG H T O $KAI}"},
    {"forge-inscribed", "{IIIAAAG H T O U ~~ X {GRIMNIR}}"},
    {"forge-proofed", "{IIIAG H T O 7}"},
    -- craftsmanship extremes
    {"forge-mythic", "{IIIAAAG H T O U ~~ X $WOLF {ANVIL}}"},
    {"forge-slapdash", "{IIIIIIIIAQ TZZPP LC}"},
    {"forge-slag-floor", "{IIIIIIIIAQ T --}"},
    {"forge-bare-tang", "{IIAG}"},
    -- degenerates
    {"forge-empty", "{}"},
    {"forge-single-rune", "{A}"},
    {"forge-emdash", "{\u{2014}-IIIAG T O}"},
    -- max-length monster
    {"forge-monster", "GGG{IIIII AAAAAA HH TT OO UU ~~~ X $DOOM {THE LAST WORK OF HALDOR} RR ... &716}"},
    -- intentionally bad (parse errors expected)
    {"forge-bad-border", "{IIIAG]"},
    {"forge-no-border", "IIIAG TTO"},
    -- ammunition, fists, and the harvest
    {"forge-arrow", "{VVG IIII FF O}"},
    {"forge-cloth-yard", "{VVW IIIIII FFF O ~}"},
    {"forge-broadhead", "{VVVVB IIIIIIII FF O ~}"},
    {"forge-crescent-arrow", "{VVG IIII FF O <}"},
    {"forge-knuckles", "{KKKB T X}"},
    {"forge-spiked-knuckles", "{KKKG.. T ~}"},
    {"forge-etched-knuckles", "{KKB T X ~~ $OOF {IRONJAW}}"},
    {"forge-sickle", "{SSSG II O ~}"},
    {"forge-scythe", "{SSSSW IIIII O X}"},
    {"forge-etched-sickle", "{SSS^ II O X $REAP}"},
    {"forge-warped-sickle", "[SSS: II O]"},
    -- the moon tip and the cutlass
    {"forge-moon-tip", "{IIIAAG H T O <}"},
    {"forge-pirate-cutlass", "{IIIAAAW))) RR H T O X ~ <}"},
    -- the wall — shields
    {"forge-buckler", "{EG T O}"},
    {"forge-round-shield", "{EEG III H T O}"},
    {"forge-kite-shield", "{EEEW III H T O $ROSE}"},
    {"forge-tower-shield", "{EEEEG IIIII HH T O ~~ X}"},
    {"forge-painted-shield", "{EEG III H T O ! ^}"},
    {"forge-spiked-buckler", "{E* .. T O}"},
    {"forge-warped-tower", "[EEEEG IIII H T O]"},
    -- the flanged head — maces
    {"forge-mace", "{JJJG III T O}"},
    {"forge-morning-star", "{JJJJ* III ... O}"},
    {"forge-great-mace", "{JJJJJJB IIIIII X O}"},
    -- the grind and the furniture
    {"forge-bowie", "{IAAG> T O +}"},
    {"forge-damascus", "{IIIAAAGGGGG H T O U ~~}"},
    {"forge-damascus-basket-cutlass", "{IIIAAAGGGGG))) H T O X @@ ~ '}"},
    {"forge-broadsword", "{IIIAAG @@ T O =}"},
    {"forge-hollow-grind", "{IIAAAW _ T O ;}"},
    {"forge-spined-greatsword", "{IIIIIIAAG++ HH TT OO #}"},
    {"forge-skull-scimitar", "{IIIAAG))) H T O N ,}"},
    {"forge-halberd", "{DDDG IIIII ? O}"},
    {"forge-barbed-voidsteel-arrow", "{VV* IIII FF O .. ?}"},
    -- the thick stock
    {"forge-thick-sword", "{III--AG T O}"},
    {"forge-slab-cleaver", "{III-----AAG T O}"},
    {"forge-thick-guarded", "{III---AAG HH T O}"},
    {"forge-thick-axe", "{DDDG III--- X O}"},
    {"forge-thick-tower", "{EEEEG IIIII-- HH T O}"},
}

for _, case in ipairs(cases) do
    local name, text = case[1], case[2]
    local spell, parseErr = Parser.Parse(text)
    if not spell then
        print(`== {name} :: {text}`)
        print(`   PARSE ERR: {parseErr}`)
        continue
    end

    local okResolve, weapon = pcall(Resolver.Resolve, spell)
    if not okResolve then
        print(`== {name} :: {text}`)
        print(`   RESOLVE ERR: {weapon}`)
        continue
    end

    print(`== {name} :: {text}`)
    print(`   {weapon.Emoji} {weapon.Name}`)
    print(`   {weapon.Description}`)
    for _, note in ipairs(weapon.Notes) do
        print(`   note: {note}`)
    end
    print(`   weight {weapon.Weight} lb | sharp {weapon.Sharpness}/10 | dur {weapon.Durability}/10 | balance {weapon.Balance}% | reach {weapon.Reach} | {weapon.Quality} ({weapon.QualityScore})`)

    local okRender, image = pcall(Renderer.Render, weapon)
    if not okRender then
        print(`   RENDER ERR: {image}`)
        continue
    end

    fs.writeImage(`{outDir}/{name}.png`, image, "png")
    print(`   saved {name}.png`)
end

print("done")
