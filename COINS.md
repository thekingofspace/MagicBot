# The Mint — Complete Reference

A coin is a rune design struck with `/coin design:`. The mint parses it with the same border grammar as spells, melts every rune in the crucible, and solves one coin: material, shape, device, edge, and an assayed worth in **bits** (readouts are solved assays like *"A crown of very fine gold, struck true at 30 mm across… Assayed at 22 bits."*). The embed describes the coin; the image is its face — rim, denticles, legend, and the stamped device under a raised-relief sheen. Every example below was struck and its readout copied verbatim.

**Command**: `/coin design:` mints (200 runes). The same characters write other crafts — `/spell` (SPELLS.md), and the sibling commands listed there.

---

## 1. Grammar

```
design := ring* border
border := '{' rune-clusters '}' | '[' rune-clusters ']'
```

- Borders work exactly as in spells: `{ }` is a true strike, `[ ]` is the **hammer** (§8). Rings, clusters, and nested circles are all legal — but the mint owns one crucible: **everything melts together**, wherever it was written. `{!! {WW A} 2}` pours the inner silver straight into the gold.
- `{}` is a blank flan — the mint pours honest copper and strikes a plain token.
- Runes the mint doesn't know are noted and not struck: *"The - rune means nothing to the mint — it is not struck."*

## 2. Metals

Repetition is **fineness** — more of the body metal makes a purer coin (coarse → honest → fine → very fine → flawless, capped at five). The strongest metal takes the body; ties go to the nobler metal.

| Rune | Metal | Nobility | Look |
|------|-------|----------|------|
| `*` | Voidmetal | 12 | deep violet, an outer glow, stars in the field |
| `!` | Gold | 9 | warm and bright |
| `^` | Electrum | 7 | pale green-gold |
| `W` | Silver | 6 | white and cold |
| `B` | Copper | 3 | ruddy |
| `G` | Iron | 2 | grey and honest |

**Bimetal work**: the second-strongest metal becomes a **ring inlay** around the field, like a euro — `{!!!! WW O A 1}` strikes a gold center in a silver ring, and the readout adds *"Silver rings its field — bimetal work of the old mints."* The inlay's nobility adds a little to the assay.

### Overlays — Aeon `:` and Rot `%`

Two material runes work on the coin rather than in it:

| Rune | Overlay | Effect |
|------|---------|--------|
| `:` | **Age** | verdigris patina, an "Ancient" name, and an antiquity premium — collectors pay for centuries (×1.25 per rune, up to ×2) |
| `%` | **Corrosion** | pits the field, bites the edge, a "Corroded" name, and the assayers mark it down (−15% per rune, floor 30%) |

With **no true metal named**, the stronger overlay becomes the body itself: `{::::}` is Ancient Bronze (patinated, worth keeping); `{%%%}` is Slag (*"more corrosion than coin"*).

## 3. Shape & size

| Rune | Shape |
|------|-------|
| `O` | round (the default) |
| `#` | square flan |
| `V` | wedge — *"one cut of a broader wheel"* |
| `X` | scalloped edge, twelve lobes |
| `.` | a **square hole** punched through the heart — a cash coin, strung on a cord. Holed coins are always named **Cash**, and the device and figure move to sit about the hole |
| `R` | larger diameter — +6 mm per Reach, from 24 mm up to 48 mm (four Reaches; more fall away with a note) |

The strongest shape rune wins; ties go to the first written. The hole and Reach combine freely with any shape.

## 4. Devices (emblems)

Ten letterforms stamp as the face device. **The first named takes the face; the next two become the mint's small marks** beside it; further devices are set aside with a note. Repetition strikes the device **bolder** — larger and deeper, from *lightly struck* through *struck deep and bold* to *struck so bold it near splits the flan* (five runes).

| Rune | Device | On the face |
|------|--------|-------------|
| `A` | Sword | a sword, point to heaven |
| `C` | Crescent | a crescent moon with her star |
| `D` | Shield | a quartered shield |
| `K` | Crown | a three-pointed crown |
| `L` | Scepter | an orbed scepter |
| `S` | Serpent | a coiled serpent |
| `T` | Hammer | a smith's hammer |
| `U` | Chalice | a chalice |
| `Y` | Trident | a trident |
| `Z` | Thunderbolt | a thunderbolt |

**Digits** stamp a numeral onto the face — the coin's face-value figure, written in the order the digits appear (`{W 100}` stamps **100**). The die holds four figures; the rest are set aside. The figure is design, not worth — the assay decides worth.

## 5. Edge & strike

| Rune | Work |
|------|------|
| `&` | **milled** — fine reeding against the clipper's shears (+craft) |
| `)` | **sunwise turn** — the die rotated in the striking; swirl marks cross the field and the legends sit askew |
| `(` | **widdershins turn** — the same, the other way |

The embed reports **Edge** (plain / milled / scalloped / irregular) and **Strike** (true / hammered, with any turn).

## 6. The assay

**Worth = nobility × size × craft**, in bits.

- **size** = diameter ÷ 24 mm (a hole loses 15% of the metal).
- **craft** starts at 1 and rises with the device (+0.15 and +0.05 per boldness), each small mark (+0.05), a figure (+0.1), milling (+0.2), and a turned die (+0.15); fineness scales it ×0.76 (coarse) to ×1.0 (flawless).
- Age multiplies; corrosion divides (§2). The inlay adds a share of its own nobility.
- The **denomination** is the worth's tier: **Bit** (<3) · **Penny** (<6) · **Groat** (<10) · **Mark** (<16) · **Crown** (<26) · **Sovereign** (<42) · **Dynast** (42+). Holed coins are titled **Cash** whatever their tier.

A big flawless gold sovereign assays at 28 bits; an iron token at 2 — *a big flawless gold coin is worth many iron bits.*

## 7. Determinism

The same design strikes the same coin, down to every patina speckle — reruns match exactly. The one exception is the hammer:

## 8. The hammer — `[ ]`

A design in an uneven border is **hammer-struck**, and no two strikes fall alike: the flan comes out ragged (a fresh outline every cast), the round die lands **off-center** — legends and denticles run off the edge where the strike missed — and the craft rolls low (×0.55–0.85, fresh per cast). The name gains **Hammered**, the edge reads *irregular (hammered)*, and the readout owns it: *"Hammer-struck on an uneven flan — no two of its kind fall alike."* Very charming; worth less.

## 9. Reading the result

**Description** — the solved assay in order: the strike line (tier, fineness, metal, diameter) → flan shape → inlay → device and boldness → small marks → figure → hole → milling → die turn → patina → corrosion → hammer → *"Assayed at n bits."* **Notes** (small text): poured copper, set-aside devices, unknown runes.

**Embed fields**: Material (with fineness and any inlay ring) · Denomination (tier and worth) · Diameter · Edge · Strike · Device. Title = the coin's name (*Ancient Gold Crown*, *Hammered Copper Bit*, *Holed Voidmetal Cash*). Footer = your design; the image is the face, with the name and worth struck as legends around the rim.

## 10. Worked examples (readouts verbatim from the harness)

| Design | Coin | Readout |
|---|---|---|
| `{!!! A}` | **Gold Mark** | A mark of fine gold, struck true at 24 mm across. Its face bears a sword, point to heaven, lightly struck. Assayed at 10 bits. |
| `{G}` | **Iron Bit** | A bit of coarse iron, struck true at 24 mm across. Assayed at 2 bits. |
| `{!!!! WW O A 1}` | **Gold Mark** | A mark of very fine gold, struck true at 24 mm across. Silver rings its field — bimetal work of the old mints. Its face bears a sword, point to heaven, lightly struck. The figure 1 names its face. Assayed at 13 bits. |
| `[BB A]` | **Hammered Copper Bit** | A bit of honest copper, struck off-center under the hammer at 24 mm across. Its face bears a sword, point to heaven, lightly struck. Hammer-struck on an uneven flan — no two of its kind fall alike. Assayed at 2 bits. |
| `{**** . C}` | **Holed Voidmetal Cash** | A cash of very fine voidmetal, struck true at 24 mm across. Its face bears a crescent moon with her star, lightly struck. A square hole pierces its heart, cut for the stringing cord. Assayed at 12 bits. |
| `{!!!! ::: K R}` | **Ancient Gold Crown** | A crown of very fine gold, struck true at 30 mm across. Its face bears a three-pointed crown, lightly struck. Verdigris lies upon the field; age has multiplied its worth. Assayed at 22 bits. |
| `{^^^ V Y}` | **Electrum Groat** | A groat of fine electrum, struck true at 24 mm across. Its flan is a wedge — one cut of a broader wheel. Its face bears a trident, lightly struck. Assayed at 7 bits. |
| `{WWW X S &}` | **Silver Groat** | A groat of fine silver, struck true at 24 mm across. Its edge blooms in twelve scallops. Its face bears a coiled serpent, lightly struck. The edge is milled fine against the clipper's shears. Assayed at 7 bits. |
| `{GG %%% A}` | **Corroded Iron Bit** | A bit of honest iron, struck true at 24 mm across. Its face bears a sword, point to heaven, lightly struck. Corrosion pits the field — debased metal, and the assayers mark it down. Assayed at 1 bit. |
| `{::::}` | **Ancient Bronze Groat** | A groat of very fine ancient bronze, struck true at 24 mm across. Verdigris blooms across the old bronze; centuries sit upon it. Assayed at 8 bits. |
| `{!!!!! RRRR & A K 1}` | **Gold Sovereign** | A sovereign of flawless gold, struck true at 48 mm across. Its face bears a sword, point to heaven, lightly struck. Beside it sit the mint's small marks: the crown. The figure 1 names its face. The edge is milled fine against the clipper's shears. Assayed at 28 bits. |
| `{BBB ) Z}` | **Copper Penny** | A penny of fine copper, struck true at 24 mm across. Its face bears a thunderbolt, lightly struck. The die turned sunwise in the striking — the device sits askew. Assayed at 4 bits. |

## 11. Extending the mint

- **Metals & overlays**: `src/coin/Resolver.luau` — `Materials` (colors, nobility) and the rune maps.
- **Devices**: `Emblems` in the Resolver names them; `EmblemArt` in `src/coin/Renderer.luau` draws them.
- **Test without Discord**: `lehua run test_coin.luau` strikes every sample into `renders/coin-*.png` and prints the solved assays.
