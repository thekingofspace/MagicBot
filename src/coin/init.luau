local Parser = require("@src/spell/Parser")
local Resolver = require("@src/coin/Resolver")
local Renderer = require("@src/coin/Renderer")
local Helpers = require("@src/bot/helpers")

-- /coin — the mint. Strikes a coin from a rune design and returns the face
-- with a solved assay readout.

local module = {}

local ColorInt = Helpers.ColorInt
local Respond = Helpers.Respond
local EditOriginal = Helpers.EditOriginal
local EditOriginalMultipart = Helpers.EditOriginalMultipart

module.Commands = {
    {
        name = "coin",
        description = "Mint a coin from a rune design",
        type = 1,
        options = {
            {
                type = 3,
                name = "design",
                description = "Your coin, e.g. {!!!O A}",
                required = true,
                max_length = 200,
            },
        },
    },
}

local function BuildEmbed(plan: Resolver.CoinPlan, design: string)
    local mat = Resolver.Materials[plan.material]

    local description = plan.description
    if #plan.notes > 0 then
        description ..= "\n"
        for _, note in ipairs(plan.notes) do
            description ..= `\n-# {note}`
        end
    end

    local materialValue = `{mat.Name} ({Resolver.FinenessWords[plan.fineness]})`
    if plan.inlay then
        materialValue ..= `, {Resolver.Materials[plan.inlay :: string].Name} ring`
    end

    local fields = {
        {name = "Material", value = materialValue, inline = true},
        {name = "Denomination", value = `{plan.denomination} — worth {plan.value} {if plan.value == 1 then "bit" else "bits"}`, inline = true},
        {name = "Diameter", value = `{plan.diameter} mm`, inline = true},
        {name = "Edge", value = plan.edge, inline = true},
        {name = "Strike", value = plan.strike, inline = true},
    }

    if plan.emblem then
        table.insert(fields, {name = "Device", value = (plan.emblem :: Resolver.Emblem).name, inline = true})
    end

    local footer = design
    if #footer > 120 then
        footer = string.sub(footer, 1, 117) .. "..."
    end

    return {
        title = `🪙 {plan.name}`,
        description = description,
        color = ColorInt(mat.Mid),
        fields = fields,
        image = {url = "attachment://coin.png"},
        footer = {text = footer},
    }
end

local function HandleCoin(client, interaction)
    local design = interaction.data.options[1].value

    local spell, parseError = Parser.Parse(design)
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
        local plan = Resolver.Resolve(spell)
        local image = Renderer.Render(plan)
        local bytes = Renderer.Encode(image)

        local payload = {
            embeds = {BuildEmbed(plan, design)},
            attachments = {{id = 0, filename = "coin.png"}},
        }

        local sent = EditOriginalMultipart(client, interaction, payload, {
            {filename = "coin.png", contentType = "image/png", bytes = bytes},
        })
        if not sent then
            error("upload failed")
        end
    end)

    if not ok then
        print(`[coinmint] failed to strike: {err}`)
        Helpers.FailWithInput(client, interaction, "💥 The die cracked in the press — the strike failed.", design)
    end
end

module.Handlers = {
    coin = HandleCoin,
}

return module
