export type RGB = {r: number, g: number, b: number}

export type Context = {
    Strength: number,
    AngleDeg: number?,
    Compass: string?,
    Directional: boolean,
    Homing: boolean?,
    Spread: number,
    SpreadArcDeg: number,
    Balance: number,
    Layers: number,
    GlyphCount: number,
    Components: {string}?,
}

export type SigilDrawer = (cv: Canvas, x: number, y: number, size: number, power: number, alpha: number) -> ()

export type ElementModule = {
    Name: string,
    Emoji: string,
    Color: RGB,
    Accent: RGB,
    Sigil: SigilDrawer,
    Describe: (ctx: Context) -> string,
}

return true
