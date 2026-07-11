local Parser = require("@src/spell/Parser")
local FlagResolver = require("@src/flag/Resolver")
local FlagRenderer = require("@src/flag/Renderer")
local Helpers = require("@src/bot/helpers")

local module = {}

module.Commands = {
    {
        name = "flag",
        description = "Weave a banner from runes — the first color paints the field",
        type = 1,
        options = {
            {
                type = 3,
                name = "design",
                description = "Your banner, e.g. {BBB WW A}",
                required = true,
                max_length = 200,
            },
        },
    },
}

local function BuildEmbed(plan: FlagResolver.Plan, design: string)
    local description = plan.description
    if #plan.notes > 0 then
        description ..= "\n"
        for _, note in ipairs(plan.notes) do
            description ..= `\n-# {note}`
        end
    end

    local footer = design
    if #footer > 120 then
        footer = string.sub(footer, 1, 117) .. "..."
    end

    return {
        title = `{if plan.warTorn then "🏴" else "🚩"} {plan.title}`,
        description = description,
        color = Helpers.ColorInt(plan.field.color),
        fields = {
            {name = "Layers", value = tostring(plan.layerCount), inline = true},
            {name = "Palette", value = table.concat(plan.palette, ", "), inline = true},
            {name = "Condition", value = if plan.warTorn then "war-torn" else "pristine", inline = true},
        },
        image = {url = "attachment://flag.png"},
        footer = {text = footer},
    }
end

local function HandleFlag(client, interaction)
    local design = interaction.data.options[1].value

    local spell, parseError = Parser.Parse(design)
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
        local plan = FlagResolver.Resolve(spell)
        local image = FlagRenderer.Render(plan)

        local payload = {
            embeds = {BuildEmbed(plan, design)},
            attachments = {{id = 0, filename = "flag.png"}},
        }

        local sent = Helpers.EditOriginalMultipart(client, interaction, payload, {
            {filename = "flag.png", contentType = "image/png", bytes = image:encode("png")},
        })
        if not sent then
            error("upload failed")
        end
    end)

    if not ok then
        print(`[flagbot] failed to raise: {err}`)
        Helpers.FailWithInput(client, interaction, "🏳️ The banner slipped its halyard — something went wrong while raising it.", design)
    end
end

module.Handlers = {
    flag = HandleFlag,
}

return module
