--#include[fs]
local Parser = require("@src/spell/Parser")
local Brewer = require("@src/potion/Brewer")
local Bottle = require("@src/potion/Bottle")

local outDir = fs.join(__dirname, "renders")
pcall(function()
    fs.mkdir(outDir)
end)

local MaxBrew = "{" .. string.rep("J", 90) .. " " .. string.rep("W", 44) .. " " .. string.rep("H", 30) .. " PPPP ..&&}"

local cases = {
    {"water", "{}"},
    {"simple-heal", "{JJJ}"},
    {"hurried-mending", "{JJJJ ^^ ..}"},
    {"volatile-stoneskin", "[GGGG HH]"},
    {"owl-light", "{!!! HHH P}"},
    {"liniment", "{GGG V S &}"},
    {"stone-oil", "{GG V}"},
    {"charmed-clearwater", "{WWW {!!}}"},
    {"soured", "{JJ %%%}"},
    {"tainted-mending", "{JJJJ %%}"},
    {"caustic", "{//// V}"},
    {"aged-longyear", "{:::: 3 PP}"},
    {"feather-jug", "{ZZZZZ PPPP W ( )}"},
    {"ember-phial", "{B}"},
    {"emdash", "{JJ\u{2014}W}"},
    {"volatile-ferment", "[JJJ %%]"},
    {"grounding-draught", "{@@@ ::: S}"},
    {"rim-runes", "PPHH{BBB}"},
    {"grand-brew", "PP{JJJJJ ^^^ WW HHH .. && 2 {!!} S V}"},
    {"quenched-rot", "{%% 4}"},
    {"stillmind", "{''' HH}"},
    {"unburdening", "{**** @@ .}"},
    {"trembling-charm", "{BBB [^^]}"},
    {"foxsense", "{FFF}"},
    {"numbing-oil", "{DDD V}"},
    {"dreamless", "{NNNN P}"},
    {"ironnerve", "{MM ^}"},
    {"fortune", "{LL}"},
    {"truetongue", "{KKK H}"},
    {"vigor", "{AAAA}"},
    {"clarion", "{YY}"},
    {"high-heart", "{'''' JJ}"},
    {"remembered-days", "{'''' ::}"},
    {"clear-sight", "{''' !!}"},
    {"untroubled-sleep", "{'''' WW}"},
    {"deep-trance", "{''''''}"},
    {"forgetting", "{''' %%%}"},
    {"honeyed-poison", "{JJ %%% ~}"},
    {"warm-mist", "{BBB R}"},
    {"distilled", "{JJJJ XX PP}"},
    {"diluted", "{GGGG UU}"},
    {"syrup", "{JJJ TT}"},
    {"labeled", "{JJJ $LOVE}"},
    {"labeled-mist", "{'''' :: R TT $MEMORY}"},
    {"max-brew", MaxBrew},
    {"balm", "{JJJJ WW}"},
    {"catnap-chain", "{FFF NN PP ;; ?}"},
    {"forced-mettle", "{AAAAA D CC}"},
    {"elixir-balm", "{JJJJ WW GG E}"},
    {"bellows-steep", "{BBB >{^^} 1{!!} <1 ..}"},
    {"keepsake", "{'''' :: Q I $KEEPSAKE}"},
    {"happenstance", "{'''' LL}"},
    {"deep-dreaming", "{''' NN}"},
    {"even-keel", "{'''' MM}"},
    {"unspoken", "{''' KK}"},
    {"bad-no-border", "JJJ"},
    {"mismatch", "{JJ]"},
}

for _, case in ipairs(cases) do
    local name, text = case[1], case[2]
    local spell, parseErr = Parser.Parse(text)
    if not spell then
        print(`== {name} :: {text}`)
        print(`   PARSE ERR: {parseErr}`)
        continue
    end

    local okBrew, brew = pcall(Brewer.Brew, spell)
    if not okBrew then
        print(`== {name} :: {text}`)
        print(`   BREW ERR: {brew}`)
        continue
    end

    print(`== {name} :: {text}`)
    print(`   {brew.Title}`)
    for _, line in ipairs(brew.Lines) do
        print(`   {line}`)
    end
    for _, note in ipairs(brew.Notes) do
        print(`   note: {note}`)
    end
    for _, told in ipairs(brew.Foretold) do
        print(`   foretold: {told}`)
    end
    local volatility = "settled"
    if brew.Kind == "shattered" then
        volatility = "shattered"
    elseif brew.Volatile then
        volatility = if brew.Soured then "volatile — soured this pour" else "volatile"
    end
    print(`   potency={brew.PotencyLabel} duration={brew.Duration} doses={brew.Doses} volatility={volatility} hue={brew.Hue} vessel={brew.Vessel} mode={brew.Mode}`)
    local craft = {}
    if brew.Compound then
        table.insert(craft, `compound={brew.Compound}`)
    end
    if brew.Reaction then
        table.insert(craft, `reaction={brew.Reaction}`)
    end
    if brew.Bind == "fused" and brew.Compound or brew.Bind == "forced" or brew.Bind == "uneasy" or brew.Bind == "curdled" then
        table.insert(craft, `bind={brew.Bind}`)
    end
    if brew.Binds == "three (elixir)" then
        table.insert(craft, `binds={brew.Binds}`)
    end
    if brew.Chain then
        table.insert(craft, `chain={brew.Chain}`)
    end
    if brew.Phials then
        table.insert(craft, `phials={brew.Phials}`)
    end
    if #craft > 0 then
        print(`   {table.concat(craft, " · ")}`)
    end

    local okRender, image = pcall(Bottle.Render, brew)
    if not okRender then
        print(`   RENDER ERR: {image}`)
        continue
    end

    fs.writeImage(`{outDir}/potion-{name}.png`, image, "png")
    print(`   saved potion-{name}.png`)
end

local Potion = require("@src/potion")
assert(Potion.Commands[1].name == "potion", "command name mismatch")
assert(Potion.Commands[1].options[1].name == "recipe", "option name mismatch")
assert(typeof(Potion.Handlers.potion) == "function", "handler missing")
print("module contract ok")

print("done")
