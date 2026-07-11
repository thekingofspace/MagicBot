--#include[fs]
local Parser = require("@src/spell/Parser")
local Resolver = require("@src/wand/Resolver")
local Renderer = require("@src/wand/Renderer")

local outDir = fs.join(__dirname, "renders")
pcall(function()
    fs.mkdir(outDir)
end)

local cases = {
    {"oak-plain", "{GGG}"},
    {"cherry-crystal", "{BBB AA}"},
    {"willow-fork", "{WWW IIII Y}"},
    {"golden-orb", "{!!! OO ~~~ T}"},
    {"ebon-heirloom", "{**** O ~~ TT X H}"},
    {"petrified-straight", "{:::: = A U}"},
    {"ash-zigzag-wild", "[^^^ ZZ IIII]"},
    {"dream-body", "{'''' A}"},
    {"gem-tip", "{GGGG '}"},
    {"green-living", "{JJJ .. C F}"},
    {"blight-twig", "{%%%}"},
    {"two-tone", "{!!! WW O TT X}"},
    {"serpentine", "{BBB SSS R}"},
    {"spiral", "{WWW && IIIII}"},
    {"gnarled", "{GGG .... II}"},
    {"curved", "{^^ (( A}"},
    {"inscribed", "{**** $NOX O T}"},
    {"charmed", "{!!! {W} O}"},
    {"staff", "{:::: IIIIIIIIII = U TT K}"},
    {"wild-blight", "[%% J .. Y]"},
    {"degenerate", "{}"},
    {"single-rune", "{G}"},
    {"maker-mark", "{BB 77 T X}"},
    {"sealed", "{WWW TT}"},
    {"fork-pommel", "{GGG Y O}"},
    {"max-length", "{" .. string.rep("*", 40) .. " " .. string.rep("I", 9) .. " " .. string.rep("~", 30) .. " " .. string.rep("W", 30) .. " OOO TT XX HH KK FF NN $LUMOS 9912 UU && ....}"},
    {"emdash", "{!!\u{2014}A}"},
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
    print(`   Wood: {plan.wood}{if plan.handleWood then ` (handle {plan.handleWood})` else ""} | Spans: {plan.spans}/{plan.handleSpans} | Tip: {plan.tip} x{plan.tipPower} | Form: {plan.silhouette} | Quality: {plan.quality} ({plan.score})`)
    print(`   Core: {plan.core}`)
    for _, note in ipairs(plan.notes) do
        print(`   note: {note}`)
    end

    local okRender, image = pcall(Renderer.Render, plan)
    if not okRender then
        print(`   RENDER ERR: {image}`)
        continue
    end

    fs.writeImage(`{outDir}/wand-{name}.png`, image, "png")
    print(`   saved wand-{name}.png`)
end

local Wand = require("@src/wand")
assert(Wand.Commands and Wand.Commands[1].name == "wand", "wand command missing")
assert(Wand.Commands[1].options[1].name == "design", "design option missing")
assert(typeof(Wand.Handlers.wand) == "function", "wand handler missing")
print("module contract: /wand command and handler present")

local wildA = Resolver.Resolve(Parser.Parse("[^^^ ZZ]") :: any)
local wildB = Resolver.Resolve(Parser.Parse("[^^^ ZZ]") :: any)
if wildA.seed ~= wildB.seed then
    print("wild: fresh turning every cast")
else
    print("wild: WARNING — two turnings matched seeds")
end

local stableDesigns = {"{**** $NOX O T}", "{!!! WW O TT X}", "{JJJ .. C F}"}
local deterministic = true
for _, design in ipairs(stableDesigns) do
    local firstPlan = Resolver.Resolve(Parser.Parse(design) :: any)
    local secondPlan = Resolver.Resolve(Parser.Parse(design) :: any)
    if firstPlan.seed ~= secondPlan.seed or firstPlan.description ~= secondPlan.description or firstPlan.name ~= secondPlan.name then
        deterministic = false
        print(`determinism: RESOLVE MISMATCH on {design}`)
        continue
    end
    local firstBytes = Renderer.Encode(Renderer.Render(firstPlan))
    local secondBytes = Renderer.Encode(Renderer.Render(secondPlan))
    if firstBytes ~= secondBytes then
        deterministic = false
        print(`determinism: RENDER MISMATCH on {design}`)
    end
end
if deterministic then
    print("determinism: stable designs match across casts, pixel for pixel")
end

local staffCases = {
    {"staff-crystal", "{GGG AA H}"},
    {"staff-orb", "{**** OO ~ F}"},
    {"staff-lantern", "{JJJ L X T}"},
    {"staff-fork", "{^^ YYY V}"},
    {"staff-crescent", "{'''' C T}"},
    {"staff-knotgem", "{GGG ' ..}"},
    {"staff-antler", "{BBB D T 7}"},
    {"staff-vine", "{:::: J $WAYFARER X T}"},
    {"staff-wild", "[%% ^^ Z L]"},
    {"staff-tall", "{!!! IIII O ~~~ HH V F F}"},
    {"staff-bare", "{WWW =}"},
    {"staff-degenerate", "{}"},
    {"staff-bells", "{WWW C T ++}"},
    {"staff-ribbons", "{^^^ A /// V}"},
    {"staff-dreamcatcher", "{BBB YY # F}"},
    {"staff-serpent-gems", "{GGG Q << T}"},
    {"staff-moss", "{:::: M O T}"},
    {"staff-wisps-teeth", "{'''' EE ; C}"},
    {"staff-keys-rope", "{** - @ L}"},
    {"staff-wax", "{!! LL T}"},
    {"staff-everything", "{**** III OO ~~ H + / # << M E Q - @ ; 7 $VIA X T F N ..}"},
}

for _, case in ipairs(staffCases) do
    local name, text = case[1], case[2]
    local spell, parseErr = Parser.Parse(text)
    if not spell then
        print(`== {name} :: {text}`)
        print(`   PARSE ERR: {parseErr}`)
        continue
    end

    local okResolve, plan = pcall(Resolver.ResolveStaff, spell)
    if not okResolve then
        print(`== {name} :: {text}`)
        print(`   RESOLVE ERR: {plan}`)
        continue
    end

    print(`== {name} :: {text}`)
    print(`   {plan.name}`)
    print(`   {plan.description}`)
    print(`   Wood: {plan.wood}{if plan.handleWood then ` (crown {plan.handleWood})` else ""} | Spans: {plan.spans} | Head: {plan.head} x{plan.headPower} | Foot: {plan.foot} | Form: {plan.silhouette} | Quality: {plan.quality} ({plan.score})`)
    print(`   Core: {plan.core}`)
    for _, note in ipairs(plan.notes) do
        print(`   note: {note}`)
    end

    local okRender, image = pcall(Renderer.RenderStaff, plan)
    if not okRender then
        print(`   RENDER ERR: {image}`)
        continue
    end

    fs.writeImage(`{outDir}/staff-{name}.png`, image, "png")
    print(`   saved staff-{name}.png`)
end

assert(Wand.Commands[2] and Wand.Commands[2].name == "staff", "staff command missing")
assert(Wand.Commands[2].options[1].name == "design", "staff design option missing")
assert(typeof(Wand.Handlers.staff) == "function", "staff handler missing")
print("module contract: /staff command and handler present")

local wildStaffA = Resolver.ResolveStaff(Parser.Parse("[%% ^^ Z L]") :: any)
local wildStaffB = Resolver.ResolveStaff(Parser.Parse("[%% ^^ Z L]") :: any)
if wildStaffA.seed ~= wildStaffB.seed then
    print("wild staff: fresh raising every cast")
else
    print("wild staff: WARNING — two raisings matched seeds")
end

local stableStaffDesigns = {"{JJJ L X T}", "{:::: J $WAYFARER X T}", "{**** OO ~ F}", "{**** III OO ~~ H + / # << M E Q - @ ; 7 $VIA X T F N ..}"}
local staffDeterministic = true
for _, design in ipairs(stableStaffDesigns) do
    local firstPlan = Resolver.ResolveStaff(Parser.Parse(design) :: any)
    local secondPlan = Resolver.ResolveStaff(Parser.Parse(design) :: any)
    if firstPlan.seed ~= secondPlan.seed or firstPlan.description ~= secondPlan.description or firstPlan.name ~= secondPlan.name then
        staffDeterministic = false
        print(`staff determinism: RESOLVE MISMATCH on {design}`)
        continue
    end
    local firstBytes = Renderer.Encode(Renderer.RenderStaff(firstPlan))
    local secondBytes = Renderer.Encode(Renderer.RenderStaff(secondPlan))
    if firstBytes ~= secondBytes then
        staffDeterministic = false
        print(`staff determinism: RENDER MISMATCH on {design}`)
    end
end
if staffDeterministic then
    print("staff determinism: stable designs match across casts, pixel for pixel")
end

print("done")
