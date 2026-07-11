local names = {"forge", "potion", "coin", "flag", "soup", "ale", "grimoire", "wand", "feast"}
for _, name in ipairs(names) do
    local ok, moduleOrErr = pcall(require, `@src/{name}`)
    if not ok then
        print(`{name}: REQUIRE FAILED: {moduleOrErr}`)
        continue
    end
    local module = moduleOrErr
    local commands = module.Commands
    local handlers = module.Handlers
    if typeof(commands) ~= "table" or #commands == 0 then
        print(`{name}: BAD Commands`)
        continue
    end
    local report = {}
    for _, command in ipairs(commands) do
        local handler = handlers and handlers[command.name]
        table.insert(report, `{command.name} ({if typeof(handler) == "function" then "handler ok" else "MISSING HANDLER"})`)
        local option = command.options and command.options[1]
        if option then
            table.insert(report, `option={option.name} max={option.max_length}`)
        end
    end
    print(`{name}: {table.concat(report, ", ")}`)
end

local okBot, botErr = pcall(require, "@src/bot")
print(`bot module load: {if okBot then "ok" else botErr}`)
print("done")
