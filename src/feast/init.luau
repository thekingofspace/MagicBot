local Parser = require("@src/spell/Parser")
local Hall = require("@src/feast/Hall")
local Table = require("@src/feast/Table")
local Helpers = require("@src/bot/helpers")

local module = {}

module.Commands = {
    {
        name = "feast",
        description = "Lay a feast from a rune menu",
        type = 1,
        options = {
            {
                type = 3,
                name = "menu",
                description = "Your menu, e.g. {BBBB 22 ~ J {PP ~} {O // S}}",
                required = true,
                max_length = 200,
            },
        },
    },
}

local function BuildEmbed(banquet, menu: string)
    local description = table.concat(banquet.Lines, " ")
    if #banquet.Notes > 0 then
        description ..= "\n"
        for _, note in ipairs(banquet.Notes) do
            description ..= `\n-# {note}`
        end
    end

    local fields = {
        {name = "Entree", value = banquet.EntreeField, inline = true},
        {name = "Side", value = banquet.SideField, inline = true},
        {name = "Bread", value = banquet.BreadField, inline = true},
        {name = "Doneness", value = if banquet.DonenessField ~= "" then banquet.DonenessField else "—", inline = true},
        {name = "Temperature", value = banquet.TempLabel, inline = true},
        {name = "Seats", value = if banquet.Seats > 0 then banquet.SeatsLabel else "nobody", inline = true},
    }

    local footer = menu
    if #footer > 120 then
        local cut = 117
        local boundary = utf8.offset(footer, 0, cut + 1)
        if boundary then
            cut = boundary - 1
        end
        footer = string.sub(footer, 1, cut) .. "..."
    end

    return {
        title = `🍖 {banquet.Title}`,
        description = description,
        color = Helpers.ColorInt(banquet.Tier.Color),
        fields = fields,
        image = {url = "attachment://feast.png"},
        footer = {text = footer},
    }
end

local function HandleFeast(client, interaction)
    local menu = interaction.data.options[1].value

    local spell, parseError = Parser.Parse(menu)
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
        local banquet = Hall.Solve(spell)
        local image = Table.Render(banquet)
        local bytes = Table.Encode(image)

        local payload = {
            embeds = {BuildEmbed(banquet, menu)},
            attachments = {{id = 0, filename = "feast.png"}},
        }

        local sent = Helpers.EditOriginalMultipart(client, interaction, payload, {
            {filename = "feast.png", contentType = "image/png", bytes = bytes},
        })
        if not sent then
            error("upload failed")
        end
    end)

    if not ok then
        print(`[feast] the pass went dark: {err}`)
        Helpers.FailWithInput(client, interaction, "💥 The kitchen caught fire — the feast never left the pass.", menu)
    end
end

module.Handlers = {
    feast = HandleFeast,
}

return module
