--#include[fs]
local Parser = require("@src/spell/Parser")
local Kitchen = require("@src/soup/Kitchen")
local Bowl = require("@src/soup/Bowl")

local outDir = fs.join(__dirname, "renders")
pcall(function()
    fs.mkdir(outDir)
end)

local MaxOrder = "{" .. string.rep("B", 80) .. " " .. string.rep("M", 40) .. " " .. string.rep("C", 30) .. " " .. string.rep("L", 20) .. " OO E ^^ .. & 44 H}"

local cases = {
    {"golden-consomme", "{!!! R}"},
    {"ember-stew", "{BBBB MMM CC L H ^^ . 3}"},
    {"dishwater-clear", "{WWW}"},
    {"empty-pot", "{}"},
    {"mushroom-earth", "{GGG DD LL ( ) 2}"},
    {"garden-gazpacho", "{JJJJ CC TT -- .}"},
    {"lavender-dream", "{''' EE &}"},
    {"miso-noodles", "{:::: IIII OO ^ 44}"},
    {"void-ink", "{**** FF D .}"},
    {"spoiled", "{%%%% MM}"},
    {"tainted", "{!!!! %% .}"},
    {"mellowed", "{!!!! %% 44}"},
    {"mystery", "[OO CC]"},
    {"side-dumplings", "{!!! OOO {DD}}"},
    {"side-cup", "{BBB MM {::}}"},
    {"side-surprise", "{JJJ CC [D]}"},
    {"chef", "{JJJ CC $MARA}"},
    {"single-egg", "{E}"},
    {"emdash-chill", "{JJ\u{2014}C}"},
    {"everything-bowl", "{WWWW O I D F C L M E A T ^}"},
    {"legendary", "{BBBBBB MMM CC LL OO E ^^ .. & 44 H}"},
    {"saffron-bisque", "{!!! FF &&}"},
    {"stirred-ember", "{BB ( )}"},
    {"rim-heat", "^^{GG MM}"},
    {"blend", "{!!!! GG D L}"},
    {"lukewarm", "{JJJ ^ -}"},
    {"visc-light", "{GGG MM CC R}"},
    {"visc-thin", "{GGG MM CC RR}"},
    {"visc-watery", "{GGG MM CC RRR}"},
    {"visc-thick", "{GGG MM CC H}"},
    {"visc-spoon", "{GGG MM CC HH}"},
    {"visc-solid", "{GGG MM CC HHHH}"},
    {"watery-dishwater", "{!! RRR}"},
    {"max-order", MaxOrder},
    {"bad-no-border", "OOO"},
    {"bad-mismatch", "{OO]"},
}

for _, case in ipairs(cases) do
    local name, text = case[1], case[2]
    local spell, parseErr = Parser.Parse(text)
    if not spell then
        print(`== {name} :: {text}`)
        print(`   PARSE ERR: {parseErr}`)
        continue
    end

    local okSolve, dish = pcall(Kitchen.Solve, spell)
    if not okSolve then
        print(`== {name} :: {text}`)
        print(`   SOLVE ERR: {dish}`)
        continue
    end

    print(`== {name} :: {text}`)
    print(`   {dish.Title}`)
    for _, line in ipairs(dish.Lines) do
        print(`   {line}`)
    end
    for _, note in ipairs(dish.Notes) do
        print(`   note: {note}`)
    end
    print(`   stock={dish.StockField} temp={dish.HeatLabel} taste={dish.TasteLabel} simmer={dish.SimmerLabel} body={dish.BodyLabel} serves={dish.ServesLabel} quality={dish.Quality}`)

    local okRender, image = pcall(Bowl.Render, dish)
    if not okRender then
        print(`   RENDER ERR: {image}`)
        continue
    end

    fs.writeImage(`{outDir}/soup-{name}.png`, image, "png")
    print(`   saved soup-{name}.png`)

    if not spell.unstable and name ~= "side-surprise" then
        local dish2 = Kitchen.Solve(spell)
        local same = dish.Title == dish2.Title
            and table.concat(dish.Lines, "|") == table.concat(dish2.Lines, "|")
            and table.concat(dish.Notes, "|") == table.concat(dish2.Notes, "|")
            and dish.Seed == dish2.Seed
        if not same then
            print("   DETERMINISM ERR: second solve differs")
            continue
        end
        local bytes1 = Bowl.Encode(image)
        local bytes2 = Bowl.Encode(Bowl.Render(dish2))
        if bytes1 ~= bytes2 then
            print("   DETERMINISM ERR: second render differs")
        else
            print("   deterministic ok")
        end
    end
end

-- Contract check: the module must expose Commands and Handlers for the bot.
local Soup = require("@src/soup")
assert(Soup.Commands[1].name == "soup", "command name mismatch")
assert(Soup.Commands[1].options[1].name == "recipe", "option name mismatch")
assert(typeof(Soup.Handlers.soup) == "function", "handler missing")
print("module contract ok")

print("done")
