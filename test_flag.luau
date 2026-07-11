--#include[fs]
local Parser = require("@src/spell/Parser")
local Resolver = require("@src/flag/Resolver")
local Renderer = require("@src/flag/Renderer")

local outDir = fs.join(__dirname, "renders")
pcall(function()
    fs.mkdir(outDir)
end)

-- A long-but-legal banner: field, bars, ordinaries, point emblems, a shield,
-- and a war-torn inset that taints the whole cloth.
local MaxDesign = "!{" .. string.rep("B", 60) .. " " .. string.rep("!", 40) .. " "
    .. string.rep("A", 30) .. "W XX! OO3! .7' C! SS^ L: VVG {W *!} [GG TTB]}"
print(`max-design length: {#MaxDesign}`)

local cases = {
    {"example", "{BBB WW A}"},
    {"azure-gold", "{W !!! AAAB}"},
    {"tricolor", "{WWW!}"},
    {"halved", "{BBRW}"},
    {"bendy", "{GGRR!}"},
    {"saltire", "{G XXX!}"},
    {"cross", "{W TTT!}"},
    {"pile", "{! VVB}"},
    {"night", "{* C! *!}"},
    {"starfield", "{* .9!}"},
    {"roundels", "{J OO3!}"},
    {"harbor", "{B LW SS!}"},
    {"shield", "{W {B *!}}"},
    {"deep-shield", "{G !! {W {B *!}}}"},
    {"war", "[BB AAAW]"},
    {"war-night", "[* .7! C!]"},
    {"fringed", "!{W AAB}"},
    {"bare", "{}"},
    {"single", "{B}"},
    {"emdash", "{W \u{2014}O}"},
    {"everything", MaxDesign},
    {"numeral", "{W 7}"},
    {"mismatch", "{W AAA]"},
    {"borderless", "WW AAA"},
    {"six-band", "{WWWWWW R}"},
    {"war-adv", "[BBB WW A]"},
    {"emblem-only", "{A}"},
    {"nested-adv", "{B {W O}}"},
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
    print(`   TITLE: {plan.title}`)
    print(`   {plan.description}`)
    for _, note in ipairs(plan.notes) do
        print(`   note: {note}`)
    end
    print(`   palette: {table.concat(plan.palette, ", ")} | layers: {plan.layerCount} | {if plan.warTorn then "war-torn" else "pristine"}`)

    local okRender, image = pcall(Renderer.Render, plan)
    if not okRender then
        print(`   RENDER ERR: {image}`)
        continue
    end

    fs.writeImage(`{outDir}/flag-{name}.png`, image, "png")
    print(`   saved flag-{name}.png`)
end

print("done")
