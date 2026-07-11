-- /soup — bowls written in runes. Humble magic: it feeds people.
-- The one dark corner is a pot left too long to itself.
local Parser = require("@src/spell/Parser")
local Kitchen = require("@src/soup/Kitchen")
local Bowl = require("@src/soup/Bowl")
local Helpers = require("@src/bot/helpers")

local module = {}

module.Commands = {
    {
        name = "soup",
        description = "Ladle a bowl of soup from a rune recipe",
        type = 1,
        options = {
            {
                type = 3,
                name = "recipe",
                description = "Your recipe, e.g. {!!!! O CC E ^^}",
                required = true,
                max_length = 200,
            },
        },
    },
}

local function BuildEmbed(dish: Kitchen.Dish, recipe: string)
    local description = table.concat(dish.Lines, " ")
    if #dish.Notes > 0 then
        description ..= "\n"
        for _, note in ipairs(dish.Notes) do
            description ..= `\n-# {note}`
        end
    end

    local fields = {
        {name = "Stock", value = dish.StockField, inline = true},
        {name = "Temperature", value = dish.HeatLabel, inline = true},
        {name = "Taste", value = dish.TasteLabel, inline = true},
        {name = "Simmer", value = dish.SimmerLabel, inline = true},
        {name = "Body", value = dish.BodyLabel, inline = true},
        {name = "Serves", value = dish.ServesLabel, inline = true},
        {name = "Quality", value = dish.Quality, inline = true},
    }

    local footer = recipe
    if #footer > 120 then
        local cut = 117
        local boundary = utf8.offset(footer, 0, cut + 1)
        if boundary then
            cut = boundary - 1
        end
        footer = string.sub(footer, 1, cut) .. "..."
    end

    return {
        title = `🍲 {dish.Title}`,
        description = description,
        color = Helpers.ColorInt(dish.Color),
        fields = fields,
        image = {url = "attachment://soup.png"},
        footer = {text = footer},
    }
end

local function HandleSoup(client, interaction)
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
        local dish = Kitchen.Solve(spell)
        local image = Bowl.Render(dish)
        local bytes = Bowl.Encode(image)

        local payload = {
            embeds = {BuildEmbed(dish, recipe)},
            attachments = {{id = 0, filename = "soup.png"}},
        }

        local sent = Helpers.EditOriginalMultipart(client, interaction, payload, {
            {filename = "soup.png", contentType = "image/png", bytes = bytes},
        })
        if not sent then
            error("upload failed")
        end
    end)

    if not ok then
        print(`[soup] the pot boiled over: {err}`)
        Helpers.FailWithInput(client, interaction, "🥣 The pot boiled over — the kitchen lost this one.", recipe)
    end
end

module.Handlers = {
    soup = HandleSoup,
}

return module
