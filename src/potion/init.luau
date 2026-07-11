local Parser = require("@src/spell/Parser")
local Brewer = require("@src/potion/Brewer")
local Bottle = require("@src/potion/Bottle")
local Helpers = require("@src/bot/helpers")

local module = {}

module.Commands = {
    {
        name = "potion",
        description = "Brew a potion from a rune recipe",
        type = 1,
        options = {
            {
                type = 3,
                name = "recipe",
                description = "Your brew, e.g. {JJJW ..}",
                required = true,
                max_length = 200,
            },
        },
    },
}

local function BuildEmbed(brew: Brewer.Brew, recipe: string)
    local description = table.concat(brew.Lines, " ")
    if #brew.Foretold > 0 then
        description ..= "\n\n**Foretold**"
        for _, told in ipairs(brew.Foretold) do
            description ..= `\n> {told}`
        end
    end
    if #brew.Notes > 0 then
        description ..= "\n"
        for _, note in ipairs(brew.Notes) do
            description ..= `\n-# {note}`
        end
    end

    local volatility = "settled"
    if brew.Kind == "shattered" then
        volatility = "shattered"
    elseif brew.Volatile then
        volatility = if brew.Soured then "volatile — soured this pour" else "volatile"
    end

    local fields = {
        {name = "Potency", value = brew.PotencyLabel, inline = true},
        {name = "Duration", value = if brew.Duration > 0 then `{brew.Duration} beats` else "—", inline = true},
        {name = "Doses", value = tostring(brew.Doses), inline = true},
        {name = "Volatility", value = volatility, inline = true},
        {name = "Hue", value = brew.Hue, inline = true},
    }
    if brew.Compound then
        table.insert(fields, {name = "Compound", value = brew.Compound :: string, inline = true})
    end
    if brew.Reaction then
        table.insert(fields, {name = "Reaction", value = brew.Reaction :: string, inline = true})
    end
    if brew.Bind ~= "—" then
        table.insert(fields, {name = "Bind", value = brew.Bind, inline = true})
        table.insert(fields, {name = "Binds", value = brew.Binds, inline = true})
    end
    if brew.Chain then
        table.insert(fields, {name = "Chain", value = brew.Chain :: string, inline = true})
    end
    if brew.Phials then
        table.insert(fields, {name = "Phials", value = brew.Phials :: string, inline = true})
    end

    local footer = recipe
    if #footer > 120 then
        footer = string.sub(footer, 1, 117) .. "..."
    end

    return {
        title = `🧪 {brew.Title}`,
        description = description,
        color = Helpers.ColorInt(brew.Color),
        fields = fields,
        image = {url = "attachment://potion.png"},
        footer = {text = footer},
    }
end

local function HandlePotion(client, interaction)
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
        local brew = Brewer.Brew(spell)
        local image = Bottle.Render(brew)
        local bytes = Bottle.Encode(image)

        local payload = {
            embeds = {BuildEmbed(brew, recipe)},
            attachments = {{id = 0, filename = "potion.png"}},
        }

        local sent = Helpers.EditOriginalMultipart(client, interaction, payload, {
            {filename = "potion.png", contentType = "image/png", bytes = bytes},
        })
        if not sent then
            error("upload failed")
        end
    end)

    if not ok then
        print(`[potion] the brew boiled over: {err}`)
        Helpers.FailWithInput(client, interaction, "🫧 The cauldron cracked — the brew was lost to the fire.", recipe)
    end
end

module.Handlers = {
    potion = HandlePotion,
}

return module
