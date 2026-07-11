-- /ale — drinks written in runes. The cellar solves what the glass holds:
-- family, pour, head, age, proof, and whether it was worth pouring at all.
local Parser = require("@src/spell/Parser")
local Cellar = require("@src/ale/Cellar")
local Tankard = require("@src/ale/Tankard")
local Helpers = require("@src/bot/helpers")

local module = {}

module.Commands = {
    {
        name = "ale",
        description = "Order a drink written in runes",
        type = 1,
        options = {
            {
                type = 3,
                name = "recipe",
                description = "Your order, e.g. {GGGG D P &}",
                required = true,
                max_length = 200,
            },
        },
    },
}

local function BuildEmbed(pour: Cellar.Pour, recipe: string)
    local description = table.concat(pour.Lines, " ")
    if #pour.Notes > 0 then
        description ..= "\n"
        for _, note in ipairs(pour.Notes) do
            description ..= `\n-# {note}`
        end
    end

    local fields = {
        {name = "Family", value = pour.FamilyName, inline = true},
        {name = "Glass", value = pour.VesselLabel, inline = true},
        {name = "Proof", value = pour.ProofLabel, inline = true},
        {name = "Age", value = pour.AgeLabel, inline = true},
        {name = "Head", value = pour.HeadLabel, inline = true},
        {name = "Quality", value = pour.QualityLabel, inline = true},
    }
    if pour.Cocktail then
        table.insert(fields, 2, {name = "Mixed", value = pour.Cocktail, inline = true})
    end

    local footer = recipe
    if #footer > 120 then
        local cut = utf8.offset(footer, 0, 118) or 118
        footer = string.sub(footer, 1, cut - 1) .. "..."
    end

    return {
        title = `🍺 {pour.Title}`,
        description = description,
        color = Helpers.ColorInt(pour.Color),
        fields = fields,
        image = {url = "attachment://ale.png"},
        footer = {text = footer},
    }
end

local function HandleAle(client, interaction)
    local recipe = interaction.data.options[1].value

    local spell, parseError = Parser.Parse(recipe)
    if not spell then
        Helpers.Respond(client, interaction, {
            type = 4,
            data = {
                content = `⚠️ {parseError}`,
                flags = 64,
            },
        })
        return
    end

    Helpers.Respond(client, interaction, {type = 5})

    local ok, err = pcall(function()
        local pour = Cellar.Serve(spell)
        local image = Tankard.Render(pour)
        local bytes = Tankard.Encode(image)

        local payload = {
            embeds = {BuildEmbed(pour, recipe)},
            attachments = {{id = 0, filename = "ale.png"}},
        }

        local sent = Helpers.EditOriginalMultipart(client, interaction, payload, {
            {filename = "ale.png", contentType = "image/png", bytes = bytes},
        })
        if not sent then
            error("upload failed")
        end
    end)

    if not ok then
        print(`[ale] the keg kicked: {err}`)
        Helpers.FailWithInput(client, interaction, "🍺 The keg kicked — the pour was lost down the drain.", recipe)
    end
end

module.Handlers = {
    ale = HandleAle,
}

return module
