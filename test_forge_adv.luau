--#include[fs]
-- Adversarial harness for the forge subsystem.
local Parser = require("@src/spell/Parser")
local Resolver = require("@src/forge/Resolver")
local Renderer = require("@src/forge/Renderer")

local outDir = fs.join(__dirname, "renders")
pcall(function()
    fs.mkdir(outDir)
end)

local allI = "{" .. string.rep("I", 198) .. "}"
assert(#allI == 200, "allI must be exactly 200 chars")

local cases = {
    {"forgeadv-mixed-border", "{[}"},
    {"forgeadv-200-all-I", allI},
    {"forgeadv-dollar-only", "{$$$$}"},
    {"forgeadv-digits-only", "{123}"},
    {"forgeadv-deep-nest", "{A{B{C}}}"},
    {"forgeadv-emdash", "{\u{2014}-III}"},
    -- one of every category, for silhouette comparison
    {"forgeadv-cat-sword", "{IIIAG H T O}"},
    {"forgeadv-cat-knife", "{IAG T O}"},
    {"forgeadv-cat-greatsword", "{IIIIIIAG HH TT OO}"},
    {"forgeadv-cat-axe", "{DDDG III}"},
    {"forgeadv-cat-hammer", "{MMMG III}"},
    {"forgeadv-cat-spear", "{YYG IIIII}"},
    -- extra hostile pokes
    {"forgeadv-201-too-long", "{" .. string.rep("I", 199) .. "}"},
    {"forgeadv-open-inner", "{A{B}"},
    {"forgeadv-huge-etch", "{$" .. string.rep("Z", 60) .. " IIIA}"},
    {"forgeadv-all-symbols", "{(((&&&...~~~$X9}"},
    {"forgeadv-zero-grip-mono", "{IIIIIIIIIIIIIIIIIIIIA}"},
    {"forgeadv-all-new-symbols", "{@#_?>=+',; EJN}"},
    {"forgeadv-shield-monster", "{EEEEEEEE IIIIIIII HHHH TT OO ''' ,, ## ~~~ $WARD}"},
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
