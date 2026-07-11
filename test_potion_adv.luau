--#include[fs]
local Parser = require("@src/spell/Parser")
local Brewer = require("@src/potion/Brewer")
local Bottle = require("@src/potion/Bottle")

local outDir = fs.join(__dirname, "renders")
pcall(function()
    fs.mkdir(outDir)
end)

local MaxRecipe = "{" .. string.rep("J", 109) .. " " .. string.rep("W", 55) .. " " .. string.rep("H", 22) .. " PPPP ..&&}"
assert(#MaxRecipe == 200, `max recipe must be 200 chars, got {#MaxRecipe}`)

local failures = 0

local cases = {
    {"adv-empty", "{}"},
    {"adv-fully-soured", "{%%%%%%}"},
    {"adv-volatile", "[JJJ^^^]"},
    {"adv-max-200", MaxRecipe},
    {"adv-single", "{J}"},
    {"adv-emdash", "{\u{2014}-JJJ}"},
    {"adv-apply", "{GGG V}"},
    {"adv-consume", "{GGG O}"},
    {"adv-deep-nest", "{J{W{B}}}"},
    {"adv-digits-only", "{123}"},
    {"adv-symbol-soup", "{??<<>>++==~~;;,,--}"},
    {"adv-unclosed", "{JJJ", true},          -- expect graceful parse error
    {"adv-volatile-empty", "[]"},
    {"adv-empty-charm", "{JJ {}}"},
    {"adv-mismatch-inner", "{JJ [W}]", true}, -- expect graceful parse error
    {"adv-label-blank", "{JJ $}"},
    {"adv-label-long", "{J $ABCDEFGHIJKLMNOP}"},
    {"adv-two-labels", "{J $AA $BB}"},
    {"adv-vapor-poison", "{%%% R}"},
    {"adv-sweet-caustic", "{/// ~}"},
    {"adv-distilled-water", "{XX}"},
    {"adv-honeyed-venom", "{JJ %%% ~~}"},
    {"adv-mist", "{ZZZ R}"},
    {"adv-catalyst-idle", "{JJJ C}"},
    {"adv-catalyst-third", "{JJJJJJ WW C}"},
    {"adv-catalyst-any", "{JJJJJ W CC}"},
    {"adv-catalyst-weak", "{JJJJJJJ W C}"},
    {"adv-curdle", "{DDD FF}"},
    {"adv-uneasy", "{DDD FF CC}"},
    {"adv-uneasy-aged", "{DDD FF CC 2}"},
    {"adv-fizz", "{^^^ NN}"},
    {"adv-fizz-zephyr", "{ZZZ @@}"},
    {"adv-thunder", "{**** @@}"},
    {"adv-shatter", "[*** @@]"},
    {"adv-blightwater", "{%%% ///}"},
    {"adv-elixir-blank", "{E}"},
    {"adv-elixir-soured", "{%% E}"},
    {"adv-elixir-mind", "{'''' JJ WW E}"},
    {"adv-elixir-fourth", "{JJJJ WW GG BB E}"},
    {"adv-frost-vapor", "{BBB R I}"},
    {"adv-frost-volatile", "[GGGG I]"},
    {"adv-rime-becalm", "[GGGG ---]"},
    {"adv-rime-hiss", "{BBB --}"},
    {"adv-quint-sing", "[JJJJ Q]"},
    {"adv-quint-water", "{Q}"},
    {"adv-quint-poison", "{%%% Q}"},
    {"adv-quint-trance", "{'''' Q}"},
    {"adv-crack", "{JJJJ WW XXX}"},
    {"adv-steep-rotten", "{JJJ >{%%%%}}"},
    {"adv-steep-volatile", "{BBB >[^^]}"},
    {"adv-steep-nested", "{JJ >{W >{BBB}}}"},
    {"adv-phial-corked", "{JJJ 1{!!}}"},
    {"adv-phial-empty-draw", "{JJJ <2}"},
    {"adv-phial-weak-note", "{BBBBBB 1{!} <1}"},
    {"adv-phial-double-draw", "{BBB 1{!!} <11}"},
    {"adv-skim", "{JJJ WW <}"},
    {"adv-scum", "{JJJJ %% >}"},
    {"adv-resonance", "{JJJJ ^^ =}"},
    {"adv-radiant", "{JJJJ WW =}"},
    {"adv-resonance-sour", "{JJ %%% =}"},
    {"adv-boon", "{JJJ ++}"},
    {"adv-boon-cap", "{JJJ +++++}"},
    {"adv-boon-poison", "{%%% +}"},
    {"adv-trace", "{JJJJ ,^^^^}"},
    {"adv-trace-tease", "{JJJJJ ,WWWW}"},
    {"adv-chain-poison", "{%%% PP ;;}"},
    {"adv-foretold-mask", "{JJ %%% ~ ?}"},
    {"adv-foretold-volatile", "[GGGG ?]"},
    {"adv-foretold-curdle", "{DDD FF ?}"},
    {"adv-foretold-sour", "{JJJ WW %%%% ?}"},
    {"adv-forgetting-augur", "{''' %%% ?}"},
    {"adv2-catalyst-alone", "{C}"},
    {"adv2-frost-alone", "{I}"},
    {"adv2-rime-alone", "{-}"},
    {"adv2-boon-alone", "{+}"},
    {"adv2-chain-alone", "{;}"},
    {"adv2-resonance-alone", "{=}"},
    {"adv2-augur-alone", "{?}"},
    {"adv2-scum-alone", "{>}"},
    {"adv2-skim-alone", "{<}"},
    {"adv2-trace-alone", "{,}"},
    {"adv2-catalyst-flood", "{CCCCCCCCCCCC}"},
    {"adv2-quint-flood", "{QQQQQQQQ}"},
    {"adv2-frost-flood", "{IIIIII PPP}"},
    {"adv2-digit-flood", "{99999999999999999999}"},
    {"adv2-compound-mist", "{JJJJ WW R}"},
    {"adv2-compound-sweet-distill", "{JJJJ WW ~ X}"},
    {"adv2-compound-aged", "{JJJJ WW 6}"},
    {"adv2-compound-volatile", "[JJJJ WW]"},
    {"adv2-crack-sweet-vapor", "{JJJJJ WWW XXX R ~}"},
    {"adv2-masked-compound", "{JJJJ WW %%%%%%%%%% ~}"},
    {"adv2-deep-steep", "{A >{B >{G >{Z}}}}"},
    {"adv2-remembered", "{'''' ::}"},
    {"adv2-symbol-flood", "{CEIQ +;=? -<>, ~R X U}"},
}

local brews: {[string]: Brewer.Brew} = {}

for _, case in ipairs(cases) do
    local name, text, expectError = case[1], case[2], case[3]
    print(`== {name} :: {text}`)

    local okParse, spell, parseErr = pcall(Parser.Parse, text)
    if not okParse then
        print(`   FAIL parser crashed: {spell}`)
        failures += 1
        continue
    end
    if not spell then
        if expectError then
            print(`   graceful parse error (expected): {parseErr}`)
        else
            print(`   FAIL unexpected parse error: {parseErr}`)
            failures += 1
        end
        continue
    end
    if expectError then
        print("   FAIL expected a parse error, got a spell")
        failures += 1
        continue
    end

    local okBrew, brew = pcall(Brewer.Brew, spell)
    if not okBrew then
        print(`   FAIL brew crashed: {brew}`)
        failures += 1
        continue
    end
    brews[name] = brew

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
    print(`   potency={brew.PotencyLabel} duration={brew.Duration} doses={brew.Doses} vessel={brew.Vessel} mode={brew.Mode} kind={brew.Kind}`)
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
        print(`   FAIL render crashed: {image}`)
        failures += 1
        continue
    end
    local okEncode, bytes = pcall(Bottle.Encode, image)
    if not okEncode or typeof(bytes) ~= "string" or #bytes < 1000 then
        print(`   FAIL encode broken: {if okEncode then `only {#bytes} bytes` else bytes}`)
        failures += 1
        continue
    end
    fs.writeImage(`{outDir}/potion-{name}.png`, image, "png")
    print(`   saved potion-{name}.png ({#bytes} bytes)`)
end

do
    local applyBrew = brews["adv-apply"]
    local consumeBrew = brews["adv-consume"]
    assert(applyBrew and consumeBrew, "apply/consume brews missing")
    assert(applyBrew.Mode == "apply", `V mark must brew on-apply, got {applyBrew.Mode}`)
    assert(consumeBrew.Mode == "consume", `O mark must brew on-consume, got {consumeBrew.Mode}`)
    assert(string.sub(applyBrew.Lines[1], 1, 9) == "On apply:", `apply line wrong: {applyBrew.Lines[1]}`)
    assert(string.sub(consumeBrew.Lines[1], 1, 11) == "On consume:", `consume line wrong: {consumeBrew.Lines[1]}`)
    assert(applyBrew.Lines[1] ~= consumeBrew.Lines[1], "apply and consume lines must differ")
    print("apply/consume phrasing ok")
end

assert(brews["adv-fully-soured"] and brews["adv-fully-soured"].Kind == "poison", "{%%%%%%} must sour into poison")
assert(brews["adv-empty"] and brews["adv-empty"].Kind == "water", "{} must brew clear water")

do
    local honeyed = brews["adv-honeyed-venom"]
    assert(honeyed and honeyed.Kind == "poison" and honeyed.Masked, "{JJ %%% ~~} must be a masked poison")
    assert(honeyed.Title == "Honeyed Cordial", `masked poison must hide its name, got {honeyed.Title}`)
    assert(not string.find(honeyed.Lines[1], "venom", 1, true), `masked line must not name venom: {honeyed.Lines[1]}`)
    assert(string.find(honeyed.Notes[#honeyed.Notes], "venom", 1, true), "the last note must reveal the venom")
    assert(not string.find(honeyed.PotencyLabel, "venom", 1, true), "masked potency label must not name venom")
    print("honey mask ok")
end

do
    local mist = brews["adv-mist"]
    assert(mist and mist.Mode == "inhale", `R must brew a mist, got {mist and mist.Mode}`)
    assert(string.sub(mist.Lines[1], 1, 10) == "On inhale:", `mist line wrong: {mist.Lines[1]}`)
    local miasma = brews["adv-vapor-poison"]
    assert(miasma and miasma.Kind == "poison" and string.sub(miasma.Lines[1], 1, 10) == "On inhale:", "a vaporous ferment must be a miasma")
    print("vapor phrasing ok")
end

do
    local labeled = brews["adv-label-long"]
    assert(labeled and labeled.Potency == 1, `label letters must not brew, got potency {labeled and labeled.Potency}`)
    assert(labeled.Label == "ABCDEFGHIJKL", `long label must trim to 12, got {labeled.Label}`)
    assert(brews["adv-label-blank"] and brews["adv-label-blank"].Label == "", "a lone $ must glue a blank label")
    assert(brews["adv-two-labels"] and brews["adv-two-labels"].Label == "AA", "the first label wins")
    print("labels ok")
end

do
    local a = select(2, pcall(Brewer.Brew, (Parser.Parse("{JJJ ^^ ..}"))))
    local b = select(2, pcall(Brewer.Brew, (Parser.Parse("{JJJ ^^ ..}"))))
    assert(a.Title == b.Title and table.concat(a.Lines, "|") == table.concat(b.Lines, "|")
        and a.Potency == b.Potency and a.Duration == b.Duration, "non-volatile brew must be deterministic")
    local imgA = Bottle.Encode(Bottle.Render(a))
    local imgB = Bottle.Encode(Bottle.Render(b))
    assert(imgA == imgB, "non-volatile render must be byte-identical")
    local c = select(2, pcall(Brewer.Brew, (Parser.Parse("{BBB [^^]}"))))
    assert(c.Volatile == false, "{BBB [^^]} must not be volatile")
    local imgC = Bottle.Encode(Bottle.Render(c))
    local imgD = Bottle.Encode(Bottle.Render(c))
    assert(imgC == imgD, "trembling-charm render must be byte-identical for a settled brew")
    local e = select(2, pcall(Brewer.Brew, (Parser.Parse("{''' :: R TT $MIST}"))))
    local imgE = Bottle.Encode(Bottle.Render(e))
    local imgF = Bottle.Encode(Bottle.Render(e))
    assert(imgE == imgF, "labeled mist render must be byte-identical")
    local t1 = select(2, pcall(Brewer.Brew, (Parser.Parse("{**** @@}"))))
    local t2 = select(2, pcall(Brewer.Brew, (Parser.Parse("{**** @@}"))))
    assert(t1.Potency == t2.Potency and t1.Title == t2.Title, "a thunder brew in a { } border must be deterministic")
    assert(Bottle.Encode(Bottle.Render(t1)) == Bottle.Encode(Bottle.Render(t2)), "thunder render in a { } border must be byte-identical")
    local f1 = select(2, pcall(Brewer.Brew, (Parser.Parse("[GGGG I]"))))
    local f2 = select(2, pcall(Brewer.Brew, (Parser.Parse("[GGGG I]"))))
    assert(f1.Potency == f2.Potency, "frost must still the volatile roll — this pour is the pour forever")
    assert(Bottle.Encode(Bottle.Render(f1)) == Bottle.Encode(Bottle.Render(f2)), "frost-stilled render must be byte-identical")
    print("determinism ok")
end

do
    local remembered = brews["adv2-remembered"]
    assert(remembered and remembered.Title == "Tonic of Remembered Days", `mind suite regressed: {remembered and remembered.Title}`)
    assert(remembered.Duration == 24, `the Lasting second must still double duration, got {remembered.Duration}`)
    assert(string.find(remembered.Lines[1], "brings lost days back sharp and whole to memory", 1, true), `mind line regressed: {remembered.Lines[1]}`)
    assert(remembered.Vessel == "heart", `mind brews still take the heart phial, got {remembered.Vessel}`)
    print("mind suite ok")
end

do
    local fused = brews["adv2-compound-volatile"]
    assert(fused and fused.Compound and string.find(fused.Compound :: string, "Balm", 1, true), `volatile compound must still fuse, got {fused and fused.Compound}`)
    assert(fused.Volatile, "[JJJJ WW] must be volatile")
    local mist = brews["adv2-compound-mist"]
    assert(mist and mist.Mode == "inhale" and mist.Compound, "a compound must ride the vapor")
    local masked = brews["adv2-masked-compound"]
    assert(masked and masked.Title == "Honeyed Cordial" and masked.Masked, `a soured compound under honey must stay masked, got {masked and masked.Title}`)
    local elixir = brews["adv-elixir-fourth"]
    assert(elixir and elixir.Vessel == "flute", `a three-bound elixir takes the flute, got {elixir and elixir.Vessel}`)
    local shatter = brews["adv-shatter"]
    assert(shatter and shatter.Kind == "shattered", "[*** @@] must shatter")
    print("compound craft ok")
end

local Potion = require("@src/potion")

local function NewStub()
    local calls = {}
    local client = {}
    function client.RestSend(_, method, path, payload, headers)
        table.insert(calls, {method = method, path = path, payload = payload, headers = headers})
    end
    return client, calls
end

local function NewInteraction(recipe: string)
    return {
        id = "1234",
        token = "tok-abc",
        application_id = "app-777",
        data = {options = {{name = "recipe", value = recipe}}},
    }
end

do -- good recipe: defer then multipart PATCH with PNG bytes
    local client, calls = NewStub()
    Potion.Handlers.potion(client, NewInteraction("{JJJ ^^}"))
    assert(#calls == 2, `expected 2 rest calls, got {#calls}`)
    assert(calls[1].method == "POST" and calls[1].path == "interactions/1234/tok-abc/callback", `bad defer path: {calls[1].path}`)
    assert(typeof(calls[1].payload) == "table" and calls[1].payload.type == 5, "first call must defer (type 5)")
    assert(calls[2].method == "PATCH" and calls[2].path == "webhooks/app-777/tok-abc/messages/@original", `bad edit path: {calls[2].path}`)
    local body = calls[2].payload
    assert(typeof(body) == "string", "multipart body must be a raw string")
    assert(calls[2].headers and string.find(calls[2].headers["Content-Type"], "multipart/form-data", 1, true), "missing multipart content type")
    assert(string.find(body, 'filename="potion.png"', 1, true), "multipart must attach potion.png")
    assert(string.find(body, "\137PNG\r\n\26\n", 1, true), "multipart must carry real PNG bytes")
    assert(string.find(body, '"attachments"', 1, true), "payload_json must declare attachments")
    print("handler good-recipe ok")
end

do -- parse error: single ephemeral reply, nothing else
    local client, calls = NewStub()
    Potion.Handlers.potion(client, NewInteraction("JJJ"))
    assert(#calls == 1, `expected 1 rest call, got {#calls}`)
    assert(calls[1].method == "POST" and typeof(calls[1].payload) == "table", "parse error must respond immediately")
    assert(calls[1].payload.type == 4, "parse error must be an immediate reply (type 4)")
    assert(calls[1].payload.data.flags == 64, "parse error must be ephemeral")
    assert(string.find(calls[1].payload.data.content, "⚠️", 1, true) == 1, "parse error must lead with the warning sign")
    print("handler parse-error ok")
end

do -- render failure path: broken upload must fall back to themed EditOriginal
    local calls = {}
    local client = {}
    function client.RestSend(_, method, path, payload, headers)
        table.insert(calls, {method = method, path = path, payload = payload, headers = headers})
        if headers then -- fail the multipart upload
            error("boom: discord is down")
        end
    end
    Potion.Handlers.potion(client, NewInteraction("{JJJ}"))
    local last = calls[#calls]
    assert(last.method == "PATCH" and typeof(last.payload) == "table" and last.payload.content, "failed upload must fall back to a themed message")
    assert(string.find(last.payload.content, "cauldron", 1, true), `fallback must be themed, got: {last.payload.content}`)
    assert(string.find(last.payload.content, "{JJJ}", 1, true), `fallback must return the recipe so nothing is lost, got: {last.payload.content}`)
    print("handler failure-path ok")
end

if failures > 0 then
    error(`{failures} adversarial case(s) failed`)
end
print("all adversarial cases clean")
