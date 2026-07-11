local Parser = require("@src/spell/Parser")
local Resolver = require("@src/wand/Resolver")
local Renderer = require("@src/wand/Renderer")
local Helpers = require("@src/bot/helpers")

local module = {}

local ColorInt = Helpers.ColorInt
local Respond = Helpers.Respond
local EditOriginal = Helpers.EditOriginal
local EditOriginalMultipart = Helpers.EditOriginalMultipart

module.Commands = {
    {
        name = "wand",
        description = "Turn a wand from a rune design",
        type = 1,
        options = {
            {
                type = 3,
                name = "design",
                description = "Your wand, e.g. {*** O ~~ TT X}",
                required = true,
                max_length = 200,
            },
        },
    },
    {
        name = "staff",
        description = "Raise a staff from a rune design",
        type = 1,
        options = {
            {
                type = 3,
                name = "design",
                description = "Your staff, e.g. {JJJ L HH F IIII}",
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

local function Capitalize(word: string): string
    return string.upper(string.sub(word, 1, 1)) .. string.sub(word, 2)
end

local function BuildEmbed(plan: Resolver.WandPlan, design: string)
    local wood = Resolver.Woods[plan.wood]

    local description = plan.description
    if #plan.notes > 0 then
        description ..= "\n"
        for _, note in ipairs(plan.notes) do
            description ..= `\n-# {note}`
        end
    end

    local woodValue = wood.Name
    if plan.handleWood then
        woodValue ..= `, {string.lower(Resolver.Woods[plan.handleWood :: string].Name)} handle`
    end

    local tipValue = Resolver.TipNames[plan.tip]
    if plan.tip == "orb" or plan.tip == "crystal" or plan.tip == "crescent" or plan.tip == "gem" then
        tipValue ..= ` — {Resolver.GlowWords[math.clamp(plan.tipPower, 1, 5)]}`
    end

    local fields = {
        {name = "Wood", value = woodValue, inline = true},
        {name = "Length", value = `{plan.spans} {if plan.spans == 1 then "span" else "spans"} — {Resolver.SpanWords[plan.spans]}`, inline = true},
        {name = "Tip", value = tipValue, inline = true},
        {name = "Core", value = plan.core, inline = true},
        {name = "Quality", value = Capitalize(plan.quality), inline = true},
    }

    if plan.wild then
        table.insert(fields, {name = "Wild", value = "no two casts alike", inline = true})
    end

    return {
        title = `🪄 {plan.name}`,
        description = description,
        color = ColorInt(wood.Mid),
        fields = fields,
        image = {url = "attachment://wand.png"},
        footer = {text = TruncateFooter(design, 120)},
    }
end

local function HandleWand(client, interaction)
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
            attachments = {{id = 0, filename = "wand.png"}},
        }

        local sent = EditOriginalMultipart(client, interaction, payload, {
            {filename = "wand.png", contentType = "image/png", bytes = bytes},
        })
        if not sent then
            error("upload failed")
        end
    end)

    if not ok then
        print(`[wandwright] failed to turn: {err}`)
        EditOriginal(client, interaction, {
            content = "🪄 The wand splintered on the lathe — an internal error occurred. Your design:\n```" .. design .. "```",
        })
    end
end

local function BuildStaffEmbed(plan: Resolver.StaffPlan, design: string)
    local wood = Resolver.Woods[plan.wood]

    local description = plan.description
    if #plan.notes > 0 then
        description ..= "\n"
        for _, note in ipairs(plan.notes) do
            description ..= `\n-# {note}`
        end
    end

    local woodValue = wood.Name
    if plan.handleWood then
        woodValue ..= `, {string.lower(Resolver.Woods[plan.handleWood :: string].Name)} crown`
    end

    local headValue = Resolver.HeadNames[plan.head]
    if plan.head == "fork" then
        headValue ..= if plan.headPower >= 3 then " — triple" else " — twin"
    elseif plan.head ~= "bare" and plan.head ~= "antler" then
        headValue ..= ` — {Resolver.GlowWords[math.clamp(plan.headPower, 1, 5)]}`
    end

    local fields = {
        {name = "Wood", value = woodValue, inline = true},
        {name = "Height", value = `{plan.spans} spans — {Resolver.StaffSpanWords[plan.spans]}`, inline = true},
        {name = "Head", value = headValue, inline = true},
        {name = "Core", value = plan.core, inline = true},
        {name = "Foot", value = Resolver.FootNames[plan.foot], inline = true},
        {name = "Quality", value = Capitalize(plan.quality), inline = true},
    }

    if plan.wild then
        table.insert(fields, {name = "Wild", value = "no two casts alike", inline = true})
    end

    return {
        title = `🪵 {plan.name}`,
        description = description,
        color = ColorInt(wood.Mid),
        fields = fields,
        image = {url = "attachment://staff.png"},
        footer = {text = TruncateFooter(design, 120)},
    }
end

local function HandleStaff(client, interaction)
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
        local plan = Resolver.ResolveStaff(spell)
        local image = Renderer.RenderStaff(plan)
        local bytes = Renderer.Encode(image)

        local payload = {
            embeds = {BuildStaffEmbed(plan, design)},
            attachments = {{id = 0, filename = "staff.png"}},
        }

        local sent = EditOriginalMultipart(client, interaction, payload, {
            {filename = "staff.png", contentType = "image/png", bytes = bytes},
        })
        if not sent then
            error("upload failed")
        end
    end)

    if not ok then
        print(`[staffwright] failed to raise: {err}`)
        EditOriginal(client, interaction, {
            content = "🪵 The staff cracked at the crown — an internal error occurred. Your design:\n```" .. design .. "```",
        })
    end
end

module.Handlers = {
    wand = HandleWand,
    staff = HandleStaff,
}

return module
