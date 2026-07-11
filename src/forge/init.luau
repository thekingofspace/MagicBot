-- /forge — weapons written in runes. Same characters as spells, but this is
-- a blade language: the parser is shared, the meanings are the smithy's own.
local Parser = require("@src/spell/Parser")
local Resolver = require("@src/forge/Resolver")
local Renderer = require("@src/forge/Renderer")
local Helpers = require("@src/bot/helpers")

local module = {}

local ColorInt = Helpers.ColorInt
local Respond = Helpers.Respond
local EditOriginalMultipart = Helpers.EditOriginalMultipart

module.Commands = {
    {
        name = "forge",
        description = "Forge a weapon from a rune pattern",
        type = 1,
        options = {
            {
                type = 3,
                name = "pattern",
                description = "Your weapon pattern, e.g. {IIIAG TTO}",
                required = true,
                max_length = 200,
            },
        },
    },
}

local function BuildEmbed(weapon: Resolver.Weapon, pattern: string)
    local material = Resolver.Materials[weapon.Material] :: Resolver.Material

    local description = weapon.Description
    if #weapon.Notes > 0 then
        description ..= "\n"
        for _, note in ipairs(weapon.Notes) do
            description ..= `\n-# {note}`
        end
    end

    local fields = {
        {name = "Weight", value = `{weapon.Weight} lb`, inline = true},
        {name = "Sharpness", value = `{weapon.Sharpness} / 10`, inline = true},
        {name = "Durability", value = `{weapon.Durability} / 10`, inline = true},
        {name = "Balance", value = `{weapon.Balance}%`, inline = true},
        {name = if weapon.Category == "shield" then "Coverage" else "Reach", value = `{weapon.Reach} {if weapon.Reach == 1 then "span" else "spans"}`, inline = true},
        {name = "Quality", value = weapon.Quality, inline = true},
    }

    local footer = pattern
    if #footer > 120 then
        -- Cut on a UTF-8 boundary: byte 117 may land mid-rune (em-dashes
        -- and smart quotes are multi-byte) and a split char breaks the payload.
        local cut = (utf8.offset(footer, 0, 118) or 118) - 1
        footer = string.sub(footer, 1, cut) .. "..."
    end

    return {
        title = `{weapon.Emoji} {weapon.Name}`,
        description = description,
        color = ColorInt(material.Color),
        fields = fields,
        image = {url = "attachment://forge.png"},
        footer = {text = footer},
    }
end

local function HandleForge(client, interaction)
    local pattern = interaction.data.options[1].value

    local spell, parseError = Parser.Parse(pattern)
    if not spell then
        Respond(client, interaction, {
            type = 4,
            data = {
                content = `⚠️ {parseError}`,
                flags = 64,
            },
        })
        return
    end

    Respond(client, interaction, {type = 5})

    local ok, err = pcall(function()
        local weapon = Resolver.Resolve(spell)
        local image = Renderer.Render(weapon)
        local bytes = Renderer.Encode(image)

        local payload = {
            embeds = {BuildEmbed(weapon, pattern)},
            attachments = {{id = 0, filename = "forge.png"}},
        }

        local sent = EditOriginalMultipart(client, interaction, payload, {
            {filename = "forge.png", contentType = "image/png", bytes = bytes},
        })
        if not sent then
            error("upload failed")
        end
    end)

    if not ok then
        print(`[forge] the forging failed: {err}`)
        Helpers.FailWithInput(client, interaction, "💥 The billet cracked on the anvil — something went wrong at the forge.", pattern)
    end
end

module.Handlers = {
    forge = HandleForge,
}

return module
