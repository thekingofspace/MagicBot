--#include[process, serde, cryptography]
local Nocturn = require("@root/nocturn")
local Parser = require("@src/spell/Parser")
local Resolver = require("@src/spell/Resolver")
local Renderer = require("@src/spell/Renderer")
local Elements = require("@src/spell/elements")
local Runes = require("@src/spell/Runes")

local module = {}

local Commands = {
    {
        name = "spell",
        description = "Cast a spell circle from an incantation",
        type = 1,
        options = {
            {
                type = 3,
                name = "incantation",
                description = "Your spell, e.g. {AAARB BBB AAARB}",
                required = true,
                max_length = 200,
            },
        },
    },
    {
        name = "symbols",
        description = "List every symbol the circle recognizes",
        type = 1,
    },
    {
        name = "example",
        description = "Show the general shape of a spell",
        type = 1,
    },
    {
        name = "shapeform",
        description = "Render only a spell's shapeform — black on white",
        type = 1,
        options = {
            {
                type = 3,
                name = "incantation",
                description = "A spell containing $ shapeforms",
                required = true,
                max_length = 200,
            },
        },
    },
    {
        name = "spelladv",
        description = "Cast a long-form spell (up to 3500 runes) — readout attached as a file",
        type = 1,
    },
}

for _, command in ipairs(Commands) do
    -- 0 = server install, 1 = user install
    command.integration_types = {0, 1}
    -- usable in servers (0), bot DMs (1), and group/other DMs (2)
    command.contexts = {0, 1, 2}
end

local function ColorInt(color: {r: number, g: number, b: number}): number
    return color.r * 65536 + color.g * 256 + color.b
end

local function Respond(client, interaction, payload)
    return (pcall(function()
        client:RestSend("POST", `interactions/{interaction.id}/{interaction.token}/callback`, payload)
    end))
end

type UploadFile = {
    filename: string,
    contentType: string,
    bytes: string,
}

local function EditOriginalMultipart(client, interaction, payload, files: {UploadFile})
    local boundary = "SpellBoundary" .. cryptography.uuid()
    local parts = {
        `--{boundary}`,
        `Content-Disposition: form-data; name="payload_json"`,
        "Content-Type: application/json",
        "",
        serde.encode("json", payload),
    }

    for index, file in ipairs(files) do
        table.insert(parts, `--{boundary}`)
        table.insert(parts, `Content-Disposition: form-data; name="files[{index - 1}]"; filename="{file.filename}"`)
        table.insert(parts, `Content-Type: {file.contentType}`)
        table.insert(parts, "")
        table.insert(parts, file.bytes)
    end

    table.insert(parts, `--{boundary}--`)
    table.insert(parts, "")

    return (pcall(function()
        client:RestSend(
            "PATCH",
            `webhooks/{interaction.application_id}/{interaction.token}/messages/@original`,
            table.concat(parts, "\r\n"),
            {["Content-Type"] = `multipart/form-data; boundary={boundary}`}
        )
    end))
end

local function EditOriginal(client, interaction, payload)
    return (pcall(function()
        client:RestSend("PATCH", `webhooks/{interaction.application_id}/{interaction.token}/messages/@original`, payload)
    end))
end

local function BuildEmbed(effect: Resolver.Effect, incantation: string)
    local element = Elements.Get(effect.Element)

    local description = effect.Description
    if #effect.Notes > 0 then
        description ..= "\n"
        for _, note in ipairs(effect.Notes) do
            description ..= `\n-# {note}`
        end
    end

    local fields = {
        {name = "Strength", value = tostring(effect.Strength), inline = true},
        {
            name = "Angle",
            value = if effect.Homing
                then "back at its source"
                elseif effect.AngleDeg then `{effect.AngleDeg}° ({effect.Compass})`
                else "even",
            inline = true,
        },
        {name = "Spread", value = tostring(effect.Spread), inline = true},
        {name = "Balance", value = `{math.floor(effect.Balance * 100 + 0.5)}%`, inline = true},
        {name = "Circles", value = tostring(effect.Layers), inline = true},
    }

    if effect.Components then
        table.insert(fields, {
            name = "Elements",
            value = `{effect.Components[1]} + {effect.Components[2]} → {element.Name}`,
            inline = true,
        })
    end

    if effect.Endless then
        table.insert(fields, {name = "Repeats", value = "∞", inline = true})
    elseif effect.Repeats > 0 then
        table.insert(fields, {name = "Repeats", value = `×{effect.Repeats + 1}`, inline = true})
    end
    if effect.Sustain > 0 then
        table.insert(fields, {name = "Sustain", value = `{effect.Sustain} beats`, inline = true})
    end
    if effect.Delay > 0 then
        table.insert(fields, {name = "Delay", value = `{effect.Delay} beats`, inline = true})
    end
    if effect.Stopper then
        table.insert(fields, {name = "Until", value = effect.Stopper, inline = true})
    end
    if effect.Trigger then
        table.insert(fields, {name = "Trigger", value = `when {effect.Trigger}`, inline = true})
    elseif effect.Conditional then
        table.insert(fields, {
            name = "Condition",
            value = `while {effect.ConditionTarget or "its condition"} holds`,
            inline = true,
        })
    end

    local path = {}
    if effect.Curve ~= 0 then
        table.insert(path, if effect.Curve > 0 then "bends sunwise" else "bends widdershins")
    end
    if effect.Coil > 0 then
        table.insert(path, `coils ×{effect.Coil}`)
    end
    if effect.Motes > 0 then
        table.insert(path, `{effect.Motes + 1} motes`)
    end
    if effect.Range > 0 then
        table.insert(path, `lands {effect.Range} spans out`)
    end
    if #path > 0 then
        table.insert(fields, {name = "Path", value = table.concat(path, ", "), inline = true})
    end

    if effect.Unstable > 0 then
        table.insert(fields, {
            name = "Stability",
            value = if effect.Unstable > 1 then `unstable ×{effect.Unstable}` else "unstable",
            inline = true,
        })
    end
    if effect.Corruption then
        table.insert(fields, {
            name = "Corruption",
            value = `{effect.Corruption.Name} ({effect.Corruption.Power}{if effect.Corruption.Full then "" else ", mild"})`,
            inline = true,
        })
    end

    local footer = incantation
    if #footer > 120 then
        footer = string.sub(footer, 1, 117) .. "..."
    end

    return {
        title = `{element.Emoji} {element.Name}`,
        description = description,
        color = ColorInt(element.Color),
        fields = fields,
        image = {url = "attachment://spell.png"},
        footer = {text = footer},
    }
end

local function HandleSpell(client, interaction)
    local incantation = interaction.data.options[1].value

    local spell, parseError = Parser.Parse(incantation)
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
        local effect, plan = Resolver.Resolve(spell)
        local image = Renderer.Render(plan, effect)
        local bytes = Renderer.Encode(image)

        local payload = {
            embeds = {BuildEmbed(effect, incantation)},
            attachments = {{id = 0, filename = "spell.png"}},
        }

        local sent = EditOriginalMultipart(client, interaction, payload, {
            {filename = "spell.png", contentType = "image/png", bytes = bytes},
        })
        if not sent then
            error("upload failed")
        end
    end)

    if not ok then
        print(`[spellbot] failed to cast: {err}`)
        EditOriginal(client, interaction, {content = "💥 The spell fizzled — something went wrong while drawing the circle."})
    end
end

local function HandleSpellAdvModal(client, interaction)
    local incantation = ""
    for _, row in ipairs(interaction.data.components or {}) do
        for _, component in ipairs(row.components or {}) do
            if component.custom_id == "incantation" and component.value then
                incantation = component.value
            end
        end
    end

    local spell, parseError = Parser.Parse(incantation, 3500)
    if not spell then
        Respond(client, interaction, {
            type = 4,
            data = {content = `⚠️ {parseError}`, flags = 64},
        })
        return
    end

    Respond(client, interaction, {type = 5})

    local ok, err = pcall(function()
        local effect, plan = Resolver.Resolve(spell)
        local image = Renderer.Render(plan, effect)
        local bytes = Renderer.Encode(image)

        local readout = {
            incantation,
            "",
            effect.Description,
        }
        for _, note in ipairs(effect.Notes) do
            table.insert(readout, `- {note}`)
        end

        local embed = BuildEmbed(effect, incantation)
        embed.description = nil
        embed.footer = nil

        local payload = {
            embeds = {embed},
            attachments = {
                {id = 0, filename = "spell.png"},
                {id = 1, filename = "spell.txt"},
            },
        }

        local sent = EditOriginalMultipart(client, interaction, payload, {
            {filename = "spell.png", contentType = "image/png", bytes = bytes},
            {filename = "spell.txt", contentType = "text/plain", bytes = table.concat(readout, "\n")},
        })
        if not sent then
            error("upload failed")
        end
    end)

    if not ok then
        print(`[spellbot] advanced cast failed: {err}`)
        EditOriginal(client, interaction, {content = "💥 The spell fizzled — something went wrong while drawing the circle."})
    end
end

local function HandleShapeform(client, interaction)
    local incantation = interaction.data.options[1].value

    local spell, parseError = Parser.Parse(incantation)
    if not spell then
        Respond(client, interaction, {
            type = 4,
            data = {content = `⚠️ {parseError}`, flags = 64},
        })
        return
    end

    local ok, err = pcall(function()
        local _, plan = Resolver.Resolve(spell)
        local image = Renderer.RenderShapeform(plan)

        if not image then
            Respond(client, interaction, {
                type = 4,
                data = {content = "⚠️ No shapeform found — add a `$` cluster to sculpt something.", flags = 64},
            })
            return
        end

        Respond(client, interaction, {type = 5})

        local footer = incantation
        if #footer > 120 then
            footer = string.sub(footer, 1, 117) .. "..."
        end

        local payload = {
            embeds = {{
                title = "📐 Shapeform",
                color = ColorInt({r = 235, g = 205, b = 130}),
                image = {url = "attachment://shapeform.png"},
                footer = {text = footer},
            }},
            attachments = {{id = 0, filename = "shapeform.png"}},
        }

        local sent = EditOriginalMultipart(client, interaction, payload, {
            {filename = "shapeform.png", contentType = "image/png", bytes = Renderer.Encode(image)},
        })
        if not sent then
            error("upload failed")
        end
    end)

    if not ok then
        print(`[spellbot] shapeform failed: {err}`)
        EditOriginal(client, interaction, {content = "💥 The form collapsed — something went wrong."})
    end
end

local function HandleSymbols(client, interaction)
    local letters = {}
    local marks = {}
    for letter in pairs(Runes.Registry) do
        if string.match(letter, "%u") then
            table.insert(letters, letter)
        else
            table.insert(marks, letter)
        end
    end
    table.sort(letters)
    table.sort(marks)

    Respond(client, interaction, {
        type = 4,
        data = {
            flags = 64,
            embeds = {{
                title = "🔣 Known Symbols",
                description = "Every mark the circle recognizes. What each one does is yours to discover.",
                color = ColorInt({r = 165, g = 125, b = 255}),
                fields = {
                    {name = "Letters", value = `\`{table.concat(letters, "\` \`")}\``, inline = false},
                    {name = "Marks", value = `\`{table.concat(marks, "\` \`")}\``, inline = false},
                    {name = "Numbers", value = "`0` `1` `2` `3` `4` `5` `6` `7` `8` `9`", inline = false},
                    {name = "Borders", value = "`{` `}` `[` `]`", inline = false},
                },
            }},
        },
    })
end

local function HandleExample(client, interaction)
    Respond(client, interaction, {
        type = 4,
        data = {
            flags = 64,
            embeds = {{
                title = "📐 The Shape of a Spell",
                description = table.concat({
                    "```",
                    "PP{ AAAA AAAB {WWW} [ZZ] 1{CC} B1 }",
                    "```",
                    "**`{ }`** — your main spell lives inside a border, either `{ }` or `[ ]`. `[ ]` is uneven — anything cast in it is unstable.",
                    "**`PP{`** — runes pressed against a border from the outside become rings that wrap that circle.",
                    "**`AAAA`** — a cluster. The first rune is the base; repeating it makes it stronger.",
                    "**`AAAB`** — extra runes at the end of a cluster attach to and change the base.",
                    "**`{WWW}`** — a border inside a border is a sub-spell: an inner circle that merges into its parent.",
                    "**`1{CC}`** — a circle with a number pressed against it is held apart instead of merging.",
                    "**`B1`** — a number written in a cluster draws on the circle holding that number.",
                    "",
                    "Letters, marks, and numbers are all runes — `/symbols` lists every one the circle knows. Spaces separate clusters. What each rune does is yours to discover.",
                }, "\n"),
                color = ColorInt({r = 165, g = 125, b = 255}),
            }},
        },
    })
end

local function RegisterCommands(client, appId: string, guild: string?)
    local scopes = {
        {path = `applications/{appId}/commands`, body = Commands :: any},
    }

    -- Clear any old guild-scoped copies so commands don't appear twice in that server
    if guild and guild ~= "" then
        table.insert(scopes, {path = `applications/{appId}/guilds/{guild}/commands`, body = "[]" :: any})
    end

    for _, scope in ipairs(scopes) do
        local ok, err = pcall(function()
            client:RestSend("PUT", scope.path, scope.body)
        end)

        if ok then
            print(`[spellbot] synced commands at {scope.path}`)
        else
            print(`[spellbot] command sync failed at {scope.path}: {err}`)
        end
    end
end

function module.Start()
    local token = process.getenv("DISCORD_TOKEN")
    assert(token and token ~= "", "DISCORD_TOKEN missing from environment")

    local guild = process.getenv("GUILD_ID")
    local client = Nocturn.new(token :: string, Nocturn.Intents.Guilds)
    local booted = false

    client:On("Ready", function(ready)
        if booted then
            return
        end
        booted = true

        local user = ready.user
        print(`[spellbot] logged in as {if user then user.username else "?"}`)
        RegisterCommands(client, ready.application.id, guild)
    end)

    client:On("INTERACTION_CREATE", function(interaction)
        local ok, err = pcall(function()
            if interaction.type == 2 and interaction.data then
                if interaction.data.name == "spell" then
                    HandleSpell(client, interaction)
                elseif interaction.data.name == "symbols" then
                    HandleSymbols(client, interaction)
                elseif interaction.data.name == "example" then
                    HandleExample(client, interaction)
                elseif interaction.data.name == "shapeform" then
                    HandleShapeform(client, interaction)
                elseif interaction.data.name == "spelladv" then
                    Respond(client, interaction, {
                        type = 9,
                        data = {
                            custom_id = "adv",
                            title = "Advanced Casting",
                            components = {{
                                type = 1,
                                components = {{
                                    type = 4,
                                    custom_id = "incantation",
                                    label = "Incantation",
                                    style = 2,
                                    required = true,
                                    max_length = 3500,
                                    placeholder = "{AAARB BBB AAARB}",
                                }},
                            }},
                        },
                    })
                end
            elseif interaction.type == 5 and interaction.data and interaction.data.custom_id == "adv" then
                HandleSpellAdvModal(client, interaction)
            end
        end)
        if not ok then
            print(`[spellbot] interaction error: {err}`)
        end
    end)

    client:Start()

    return client
end

return module
