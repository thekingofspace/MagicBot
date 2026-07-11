local Parser = require("@src/spell/Parser")
local Resolver = require("@src/grimoire/Resolver")
local Renderer = require("@src/grimoire/Renderer")
local Helpers = require("@src/bot/helpers")

local module = {}

local ColorInt = Helpers.ColorInt
local Respond = Helpers.Respond
local EditOriginal = Helpers.EditOriginal
local EditOriginalMultipart = Helpers.EditOriginalMultipart

module.Commands = {
    {
        name = "grimoire",
        description = "Bind a grimoire from a rune design",
        type = 1,
        options = {
            {
                type = 3,
                name = "design",
                description = "Your book, e.g. {*** EE HH K ~ $NOX}",
                required = true,
                max_length = 200,
            },
        },
    },
}

local function TruncateFooter(text: string, limit: number): string
    if #text <= limit then
        return text
    end
    local boundary = utf8.offset(text, 0, limit - 2) or (limit - 2)
    return string.sub(text, 1, boundary - 1) .. "..."
end

local function BuildEmbed(plan: Resolver.GrimoirePlan, design: string)
    local mat = Resolver.Materials[plan.material]

    local description = plan.description
    if #plan.notes > 0 then
        description ..= "\n"
        for _, note in ipairs(plan.notes) do
            description ..= `\n-# {note}`
        end
    end

    local coverValue = `{mat.Name} ({Resolver.FinenessWords[plan.fineness]})`
    if plan.trim then
        coverValue ..= `, {string.lower(Resolver.Materials[plan.trim :: string].Trim)} trim`
    end

    local sigilValue = "plain boards"
    if plan.sigil then
        local sigil = plan.sigil :: Resolver.Sigil
        sigilValue = `{sigil.name} — {Resolver.EmbossWords[sigil.power]}`
    end

    local pagesValue = `{plan.pageCount} leaves — {Resolver.ThicknessWords[plan.pages + 1]}`
    if plan.gilt then
        pagesValue ..= ", gilt-edged"
    end

    local metalWord = if plan.metal == "iron" then "black iron" else "brass"
    local claspsValue = if plan.clasps == 0
        then "none"
        else `{({"one", "two", "three"})[plan.clasps]}, {metalWord}`

    local fields = {
        {name = "Cover", value = coverValue, inline = true},
        {name = "Sigil", value = sigilValue, inline = true},
        {name = "Pages", value = pagesValue, inline = true},
        {name = "Clasps", value = claspsValue, inline = true},
        {name = "Quality", value = `{plan.qualityWord} {string.lower(plan.tierNoun)}`, inline = true},
    }

    if plan.locked then
        table.insert(fields, {name = "Locked", value = "a heavy hasp-lock", inline = true})
    end
    if plan.chained then
        table.insert(fields, {name = "Chained", value = "stapled to the shelf", inline = true})
    end
    if plan.cursed then
        table.insert(fields, {name = "Cursed", value = "torn and restless — no two summonings alike", inline = true})
    end

    return {
        title = `📖 {plan.name}`,
        description = description,
        color = ColorInt(mat.Mid),
        fields = fields,
        image = {url = "attachment://grimoire.png"},
        footer = {text = TruncateFooter(design, 120)},
    }
end

local function HandleGrimoire(client, interaction)
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
            attachments = {{id = 0, filename = "grimoire.png"}},
        }

        local sent = EditOriginalMultipart(client, interaction, payload, {
            {filename = "grimoire.png", contentType = "image/png", bytes = bytes},
        })
        if not sent then
            error("upload failed")
        end
    end)

    if not ok then
        print(`[bindery] failed to bind: {err}`)
        EditOriginal(client, interaction, {
            content = `📕 The binding tore — an internal error occurred. Your design:\n\`\`\`\n{design}\n\`\`\``,
        })
    end
end

module.Handlers = {
    grimoire = HandleGrimoire,
}

return module
