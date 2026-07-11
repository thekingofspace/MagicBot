local Compounds = require("@src/potion/Compounds")

export type Reaction = {
    Kind: "thunder" | "fizz" | "curdle",
    Message: string,
    Field: string,
}

local module = {}

module.Registry = {
    ["*|@"] = {
        Kind = "thunder",
        Message = "Astra and Vortex war in the glass — the bottle will not sit still.",
        Field = "thunder: Astra against Vortex",
    },
    ["N|^"] = {
        Kind = "fizz",
        Message = "The Spark spends itself against the Night — the brew fizzes flat.",
        Field = "fizzed: Spark against Night",
    },
    ["@|Z"] = {
        Kind = "fizz",
        Message = "The Zephyr spends itself against the Vortex — a long hiss of spent force.",
        Field = "fizzed: Zephyr against Vortex",
    },
    ["D|F"] = {
        Kind = "curdle",
        Message = "The Poppy dulls what the Fox whets — the brew curdles.",
        Field = "curdled: Poppy against Fox",
    },
    [":|^"] = {
        Kind = "curdle",
        Message = "The Spark races what the Aeon reins — the brew curdles.",
        Field = "curdled: Spark against Aeon",
    },
    ["A|N"] = {
        Kind = "curdle",
        Message = "Vigor against sleep — the brew curdles.",
        Field = "curdled: Ardor against Night",
    },
    ["G|Z"] = {
        Kind = "curdle",
        Message = "Stone drags what the Zephyr lifts — the brew curdles.",
        Field = "curdled: Stone against Zephyr",
    },
} :: {[string]: Reaction}

function module.Get(a: string, b: string): Reaction?
    return module.Registry[Compounds.Key(a, b)]
end

return module
