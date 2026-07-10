export type Run = {letter: string, count: number}

export type Group = {
    kind: "group",
    letters: string,
    runs: {Run},
}

export type Spell = {
    kind: "spell",
    parts: {Group | Spell},
    rings: {Run},
    depth: number,
    unstable: boolean,
    raw: string,
}

local MaxLength = 200
local SymbolRunes = "*@~#()&.!^%/_:-?<$>="

local module = {}

local function IsRuneChar(char: string): boolean
    return string.match(char, "%u") ~= nil
        or string.match(char, "%d") ~= nil
        or string.find(SymbolRunes, char, 1, true) ~= nil
end

local function BuildRuns(letters: string): {Run}
    local runs: {Run} = {}
    for index = 1, #letters do
        local letter = string.sub(letters, index, index)
        local last = runs[#runs]
        if last and last.letter == letter then
            last.count += 1
        else
            table.insert(runs, {letter = letter, count = 1})
        end
    end
    return runs
end

function module.Parse(text: string, maxLength: number?): (Spell?, string?)
    local limit = maxLength or MaxLength
    if typeof(text) ~= "string" or #text == 0 then
        return nil, "Your spell needs a border — wrap your runes in { } or [ ]."
    end
    if #text > limit then
        return nil, `That incantation is too long (max {limit} characters).`
    end

    local upper = string.upper(text)
    local index = 1
    local length = #upper

    local function ParseLayer(depth: number, rings: {Run}, closer: string, unstable: boolean): (Spell?, string?)
        local parts: {Group | Spell} = {}
        local buffer = ""

        local function Flush(): string?
            if buffer == "" then
                return nil
            end
            table.insert(parts, {
                kind = "group",
                letters = buffer,
                runs = BuildRuns(buffer),
            })
            buffer = ""
            return nil
        end

        while index <= length do
            local char = string.sub(upper, index, index)
            index += 1

            if char == "{" or char == "[" then
                local childRings = BuildRuns(buffer)
                buffer = ""
                local childCloser = if char == "{" then "}" else "]"
                local sub, err = ParseLayer(depth + 1, childRings, childCloser, char == "[")
                if not sub then
                    return nil, err
                end
                table.insert(parts, sub)
            elseif char == "}" or char == "]" then
                if char ~= closer then
                    return nil, `Mismatched border — a circle opened with {if closer == "}" then "\{" else "["} was closed with {char}.`
                end
                local flushErr = Flush()
                if flushErr then
                    return nil, flushErr
                end
                return {
                    kind = "spell",
                    parts = parts,
                    rings = rings,
                    depth = depth,
                    unstable = unstable,
                    raw = "",
                }, nil
            elseif string.match(char, "%s") then
                local flushErr = Flush()
                if flushErr then
                    return nil, flushErr
                end
            elseif IsRuneChar(char) then
                buffer ..= char
            else
                return nil, `Only rune letters A–Z, the marks {SymbolRunes}, digits, spaces, and borders belong in a spell (found "{char}").`
            end
        end

        return nil, `Unbalanced border — a {if closer == "}" then "\{" else "["} was never closed with {closer}.`
    end

    local prefix = ""
    local opener: string? = nil
    while index <= length do
        local char = string.sub(upper, index, index)
        if char == "{" or char == "[" then
            opener = char
            break
        elseif IsRuneChar(char) then
            prefix ..= char
            index += 1
        elseif string.match(char, "%s") then
            index += 1
        else
            return nil, `Only rune letters A–Z, the marks {SymbolRunes}, digits, spaces, and borders belong in a spell (found "{char}").`
        end
    end

    if not opener then
        return nil, "Your spell needs a border — wrap your runes in { } or [ ]."
    end

    index += 1
    local closer = if opener == "{" then "}" else "]"
    local spell, err = ParseLayer(1, BuildRuns(prefix), closer, opener == "[")
    if not spell then
        return nil, err
    end

    while index <= length do
        local char = string.sub(upper, index, index)
        if not string.match(char, "%s") then
            return nil, "Stray runes found after the border — rings go in front, runes go inside."
        end
        index += 1
    end

    spell.raw = text
    return spell, nil
end

return module
