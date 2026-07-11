# Flag System — Banner Reference

A banner is a text design raised with `/flag design:`. The bot reads the same rune grammar as `/spell` — `{ }` borders, clusters split by spaces, runs of a letter for power — but on the loom the runes weave cloth instead of magic. The bot solves the design into a blazon (the title), a plain readout of every layer, and a render: a waving flag on a hoist pole, gold finial and all. Every example below was run and its readout copied verbatim.

**The one rule to remember**: *the first color cluster paints the field; everything after it stacks above, in written order.*

---

## 1. Grammar

```
banner  := ring* border
border  := '{' cluster* '}' | '[' cluster* ']'
cluster := rune+                 -- separated by spaces
ring    := runes pressed against the border (dye for the fringe)
```

- Same parser as spells: 200 characters, case-insensitive, smart punctuation forgiven (a phone's em-dash folds back into `--` before the loom reads it).
- `{ }` flies pristine. `[ ]` is the **war-torn** border — the fly edge tatters, holes burn through, stains soak the weave, and the wounds roll fresh every cast. A war-torn inset (§6) taints the whole cloth.
- `{}` is a valid bare standard: *"The field is bare slate — no color was named."*

## 2. Dyes — the element runes

Every element rune is a vat of dye. The cloth names run heraldic:

| Rune | Element | Field name | Tint | | Rune | Element | Field name | Tint |
|------|---------|------------|------|-|------|---------|------------|------|
| `B` | Fire | Gules | crimson | | `^` | Volt | Cerulean | storm-blue |
| `W` | Water | Azure | azure | | `:` | Time | Buff | tan |
| `Z` | Air | Pearl | pale-sky | | `*` | Space | Purpure | violet |
| `G` | Ground | Russet | russet | | `@` | Gravity | Amethyst | amethyst |
| `J` | Life | Vert | verdant | | `'` | Mind | Rose | rose |
| `!` | Light | Or | gold | | `%` | Decay | Murk | murky |
| `/` | Ruin | Rust | rust | | | | | |

## 3. The field (back layer)

The **first** element cluster is the field. Its power splits the cloth:

- `{B}` — solid. `{BB}` — halved. `{BBB}` — three bands… up to seven.
- Bands alternate the base dye against **dusk** (its own shadow), or against a second element bound on: `{WWW!}` = azure and gold.
- Bands run **upright** (vertical) by default. Each `R` rotates them: `R` = level (horizontal), `RR` = bendwise (diagonal). `{BBRW}` is a crimson-over-azure horizontal halving.

## 4. Bars

Any element cluster *after* the field lays **bars** of that dye across the cloth — power is the count (`!!!` = three gold bars). Bars lie level by default; `R` sets them bendwise, `RR` stands them upright. In the blazon they read as bars, pallets, or bendlets.

## 5. Devices (emblems)

Every other cluster raises a device above the field, stacked in written order. Bind an element to dye it (`AAAB` = a crimson chevron); unbound devices take **argent** or **sable**, whichever stands out against the field. Repetition (power) thickens ordinaries and grows charges. A digit sets the count for roundels, crescents, stars, and scatters (`OO3!` = three gold roundels).

| Rune | Device | On the cloth |
|------|--------|--------------|
| `A` | chevron | rises point-up from the base |
| `X` | saltire | corner-to-corner diagonal cross |
| `T` | cross | quarters the cloth, upright |
| `O` | roundel | a disc on the center line |
| `V` | pile | a wedge driving in from the hoist |
| `C` | crescent | horns turned to the fly |
| `S` | wave | a rippling stripe the cloth's length |
| `L` | canton | a block in the upper hoist |
| `.` | scatter | a company of small stars in ranks (default seven; digit to muster more, up to twelve) |
| `*` + dye | star | the void bound to a color burns as a five-pointed star — `*!` is the gold star |

Point devices (roundels, crescents, stars, shields) share the center line, spaced evenly in written order — `{* C! *!}` hangs a crescent and star side by side.

## 6. The inescutcheon — nested `{ }`

A border inside a border weaves a **shield inset** at the banner's heart, carrying its own field and charges: `{W {B *!}}` is azure with a crimson shield bearing a gold star. Shields nest deeper (`{G !! {W {B *!}}}` — a shield upon a shield); charges inside are woven bolder so they stay legible small. An `[ ]` inset marks the whole banner war-torn.

## 7. Fringe — rings

A dye rune pressed against the border trims the free edges with fringe tassels: `!{W AAB}` hangs gold fringe. One fringe per banner; other runes on the ring *"find no purchase on cloth."*

## 8. Reading the result

**Title** — the blazon: field first (`Azure`, or `Paly of three, crimson and dusk`), then each device in order. **Description** — the layers read out plainly, back to front, then fringe and condition. **Fields**: Layers (field + everything above it) · Palette (dye names in order) · Condition (*pristine* or *war-torn*). Footer = your design; the image is the banner.

**The render**: hoist pole with a gold finial, the cloth waving in two-and-a-half ripples (troughs shaded, emblems following the cloth), field bands, devices crisp on top, fringe tassels if trimmed — and for war-torn banners a drooping, tattered fly, scorched holes, and stains. Deterministic for the same design, except `[ ]`, which weathers anew each raising.

## 9. Worked examples (readouts verbatim from the harness)

| Design | Blazon & readout |
|---|---|
| `{BBB WW A}` | **Paly of three, crimson and dusk, two bars azure, an argent chevron** — The field breaks into three upright bands — crimson against dusk. Two azure bars lie across it. An argent chevron rises from the base. |
| `{W !!! AAAB}` | **Azure, three bars gold, a crimson chevron** — The field is azure, hoist to fly. Three gold bars lie across it. A crimson chevron rises from the base. |
| `{WWW!}` | **Paly of three, azure and gold, plain** — The field breaks into three upright bands — azure against gold. |
| `{G XXX!}` | **Russet, a gold saltire** — The field is russet, hoist to fly. A gold saltire spans corner to corner. |
| `{! VVB}` | **Or, a crimson pile** — The field is gold, hoist to fly. A crimson pile drives in from the hoist. |
| `{* C! *!}` | **Purpure, a gold crescent, a gold star** — The field is violet, hoist to fly. A gold crescent turns its horns to the fly. A gold star burns at the heart. |
| `{* .9!}` | **Purpure, nine gold stars strewn** — The field is violet, hoist to fly. Nine gold stars are strewn across the field. |
| `{J OO3!}` | **Vert, three gold roundels** — The field is verdant, hoist to fly. Three gold roundels march in file. |
| `{B LW SS!}` | **Gules, an azure canton, a gold wave** — The field is crimson, hoist to fly. An azure canton holds the upper hoist. A gold wave runs the cloth's length. |
| `{W {B *!}}` | **Azure, an inescutcheon** — The field is azure, hoist to fly. An inset shield rides at its heart — crimson, bearing one charge. |
| `[BB AAAW]` | **Paly of two, crimson and dusk, an azure chevron** — …An azure chevron rises from the base. The fly hangs in ribbons and the weave is stained — this banner has seen war. |
| `!{W AAB}` | **Azure, a crimson chevron** — The field is azure, hoist to fly. A crimson chevron rises from the base. Gold fringe trims its free edges. |

Runes with no place on cloth are skipped with a gentle note (*"The 7 rune raises no device — the loom leaves it out."*); mismatched borders and missing borders fail the same way spells do.

## 10. Extending the loom

- **Devices**: the `Devices` table in `src/flag/Resolver.luau` (rune → device) plus a geometry test in `src/flag/Renderer.luau`'s `MakeSampler`.
- **Dyes** come straight from `src/spell/elements/` — new elements dye cloth automatically; name them in `Tinctures`.
- **Test without Discord**: `lehua run test_flag.luau` raises every sample banner into `renders/flag-*.png` and prints the solved blazons.
