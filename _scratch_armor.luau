local Parser = require("@src/spell/Parser")
local Resolver = require("@src/forge/Resolver")

local cases = {
    {"bascinet", "{CCG @@ T X , ~}"},
    {"hounskull", "{CCG @@ > T X ~}"},
    {"grim-mask", "{CCCG @@@ N T X ~~ '}"},
    {"cuirass", "{PPGGG III RR HH OO X T ~~ (( U}"},
    {"hauberk", "{PPP&&&G III T X ~}"},
    {"spiked-gauntlets", "{ZZG .. A T X ~}"},
    {"locking-gauntlets", "{ZZ* T X ? ~}"},
    {"legharness", "{LLLW III T X O ~}"},
    {"laminated", "{PPGG IIII T X U ~~ {***} {GGGGG}}"},
    {"full-harness", "{CC PPP ZZ LL GGG IIIII T X ~~ , {ANVIL}}"},
    {"battered-byrnie", "[PP&&&G III T]"},
    {"slapdash", "{IIIIIIIIAQ TZZPP LC}"},
    {"slag-floor", "{IIIIIIIIAQ T --}"},
    {"open-helm", "{CCG T X}"},
    {"scale-corslet", "{PPP<<<G III T X ~}"},
    {"lamellar-corslet", "{PPP====G III T X ~}"},
    {"lost-to-weld", "{PPGG III T X {GTX}}"},
    {"warden", "{PP G {WARDEN}}"},
    {"single-c", "{C}"},
    {"harness-of-ones", "{C P Z L}"},
    {"weapon-wins", "{AAAA C P Z}"},
    {"emdash", "{\u{2014}-IIIAG T O}"},
}

for _, case in ipairs(cases) do
    local name, text = case[1], case[2]
    local spell, parseErr = Parser.Parse(text)
    if not spell then
        print(`== {name} :: PARSE ERR {parseErr}`)
        continue
    end
    local ok, weapon = pcall(Resolver.Resolve, spell)
    if not ok then
        print(`== {name} :: RESOLVE ERR {weapon}`)
        continue
    end
    print(`== {name} :: {text}`)
    print(`   {weapon.Emoji} {weapon.Name}`)
    print(`   {weapon.Description}`)
    for _, note in ipairs(weapon.Notes) do
        print(`   note: {note}`)
    end
    print(`   weight {weapon.Weight} lb | sharp {weapon.Sharpness}/10 | defl {weapon.Durability}/10 | artic {weapon.Balance}% | cover {weapon.Reach} | {weapon.Quality} ({weapon.QualityScore})`)
end
print("done")
