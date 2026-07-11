--#include[serde, cryptography]

local module = {}

export type UploadFile = {
    filename: string,
    contentType: string,
    bytes: string,
}

function module.ColorInt(color: {r: number, g: number, b: number}): number
    return color.r * 65536 + color.g * 256 + color.b
end

function module.Respond(client, interaction, payload): boolean
    return (pcall(function()
        client:RestSend("POST", `interactions/{interaction.id}/{interaction.token}/callback`, payload)
    end))
end

function module.EditOriginal(client, interaction, payload): boolean
    return (pcall(function()
        client:RestSend("PATCH", `webhooks/{interaction.application_id}/{interaction.token}/messages/@original`, payload)
    end))
end

function module.FailWithInput(client, interaction, themed: string, input: string?): boolean
    local content = themed
    if input and #input > 0 then
        local snippet = input
        if #snippet > 1500 then
            local cut = utf8.offset(snippet, 0, 1500) or 1500
            snippet = string.sub(snippet, 1, cut)
        end
        content ..= `\n-# An internal error occurred. Your incantation, so nothing is lost:\n\`\`\`\n{snippet}\n\`\`\``
    end
    return module.EditOriginal(client, interaction, {content = content})
end

function module.EditOriginalMultipart(client, interaction, payload, files: {UploadFile}): boolean
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

return module
