# Ale System — Complete Reference

A drink is a rune order poured with `/ale recipe:`. The bot parses it with the same border grammar as spells, the cellar solves what the glass holds — family, glass, proof, age, head, flavor, and a quality verdict in the tavern's own voice — and the tankard renders the vessel itself on a lamplit shelf. Every rule below is implemented; every example was poured and its readout copied verbatim.

Ales are **tavern craft, not magic**: nothing in a mug throws fire. The worst a pour can do is bite, go to vinegar, or arrive skunked with flies.

---

## 1. Grammar

```
order  := rim* border
border := '{' cluster* '}' | '[' cluster* ']'
rim    := runes pressed against the border — they pour into the drink all the same
toast  := a border inside the border — words carved or etched on the glass
```

- Same parser as `/spell`: 200 characters, case-insensitive, spaces separate clusters, smart punctuation (em-dashes, curly quotes) is folded back into runes before pouring.
- `[ ]` makes the pour **rowdy** (§8). Mismatched borders, stray runes, and missing borders fail exactly as spells do.
- `{}` is a valid order: *An Empty Glass — Nothing on tap — a polished glass and a long wait.*

## 2. Brew families

The strongest family rune is the drink (ties go to whichever was written first). A second family at **half or more** of the base's strength is *cut in as a splash* — it tints the pour and earns a note; anything weaker (or third) loses itself in the blend.

| Rune | Family | Hue | Head | Base proof | Ages well? |
|------|--------|-----|------|-----------|------------|
| `B` | Amber Ale | lamplit amber | full | 9 | no |
| `G` | Dark Stout | peat brown | thick cream | 11 | yes |
| `W` | Pale Lager | straw gold | white and fizzy | 8 | no |
| `!` | Golden Mead | clover gold | thin | 24 | yes |
| `J` | Herbal Cordial | stillroom green | none | 32 | no |
| `:` | Wine-Dark Vintage | wine-dark garnet | none | 26 | yes |
| `*` | Void Porter | void black | densest of all | 13 | yes |
| `^` | Firewater | flame amber | none | 78 | yes |
| `'` | Dream-Wine | opal sheen (rendered iridescent) | faint | 20 | yes |
| `%` | Skunked Swill | ditchwater olive | none — foam refuses | 5 | no |

- **Firewater doubles as the proof rune**: every `^` anywhere adds +7 proofs on top of the family's base (§4), and enough `^` makes firewater the drink itself.
- **Skunked swill** is always quality *Swill*, renders murky with blotches, and flies circle the glass. Garnish it at your peril.
- **Dream-wine** renders with pastel opal bands and glows brighter than anything else on the shelf.

## 3. The glass

A glass rune picks the vessel; repeating it sizes the pour (`XX` = generous, `XXX` = a giant's). Writing two different glasses sends the weaker back to the shelf with a note. No glass rune = a plain pint.

| Rune | Vessel | Rendered as | Fits |
|------|--------|-------------|------|
| `T` | glass tankard | heavy straight-walled mug with a handle | amber, stout, lager, porter |
| `V` | stemmed goblet | round bowl on a stem and foot | mead, vintage, dream-wine, cordial |
| `I` | pilsner flute | tall taper with a flared foot | lager |
| `O` | round snifter | balloon bowl, short stem | firewater, dream-wine |
| `U` | wide chalice | shallow ceremonial bowl, knopped stem | mead, vintage |
| `D` | barrel-mug | wooden tankard: staves, two iron bands, riveted handle | amber, stout, porter |
| `Y` | wine glass | thin tall bowl, tall stem | vintage, dream-wine, mead |
| `Q` | the bottle rack | **the count of Q picks the bottle** (§3a), not the size | per bottle |
| `X` | drinking horn | horn cradled upright in an iron ring stand on a wood block | mead, amber |
| `C` | clay jug | earthenware body, ear handle at the neck | cordial, mead |
| `A` | margarita coupe | wide stepped bowl on a tall stem | cocktails (§8) |
| `M` | martini glass | knife-edged V-cone on a stem | cocktails (§8) |
| `K` | rocks glass | squat tumbler, thick base, **ice cube drawn** | cocktails (§8) |
| `L` | highball | tall straight glass, **stacked ice drawn** | cocktails (§8) |
| — | plain pint | the default shaker glass | lager, amber, stout |

A **fitting glass** is one leg of quality (§7) — but only if you actually chose it; the default pint flatters nothing. Cocktail glasses fit no plain family — they earn their leg by holding the right cocktail. Ordering any of the four cocktail glasses is itself a mixing trigger (§8).

### 3a. The bottle rack — `Q` by count

Bottles come in the size the glassblower made them, so the **count of `Q` picks the bottle**. All bottles fill themselves (*"A bottle pours itself — no hand can hurry or heavy it."*), carry a paper label — the `$` house name if given, the house default if not, plus `N YEARS` when aged — and read *laid on the shelf*.

| Runes | Bottle | Rendered as | Fits | Default label |
|-------|--------|-------------|------|---------------|
| `Q` | wine bottle | dark green glass, red foil cap | vintage | VINTAGE |
| `QQ` | stout bottle | squat, round-shouldered, brown glass, scalloped **crown cap** | stout, porter | STOUT |
| `QQQ` | spirits bottle | tall and slim, near-clear glass, cork | firewater | OLD FLAME |
| `QQQQ` | swing-top bottle | green glass, ceramic stopper, red gasket, **wire bail** | lager, amber | BREWHOUSE |
| `QQQQQ` | wicker demijohn | fat belly in a woven **wicker skirt**, glass neck, cork | mead, cordial | MOTHERS BEST |
| `QQQQQQ` | square gin bottle | square shoulders, straight sides, clear glass, tall label | firewater, cordial | DRY OATH |

## 4. Proof and age

- **Proof** = family base + 7 per `^` rune. Rendered and read out in *proofs*:
  - **45+** — slow legs cling to the glass (drawn above the surface).
  - **70+** — *"it bites, and the fumes bite first."*
- **Digits are AGE in years**: each digit adds its value (e.g. `66` = 12 years). Age deepens the liquid's color, settles sediment at the base, and reads *"laid down N years"*.
  - Families that **age well** (stout, mead, vintage, porter, firewater, dream-wine) gain a leg of quality from any cellaring.
  - Families that don't, held **10+ years, go to vinegar**: the color sallows, quality drops, and the title earns *Vinegared*.

## 5. Head & body

| Rune | Meaning | Exact behavior |
|------|---------|----------------|
| `P` | extra head | each adds foam, scaled by the family's head nature; drawn creamy with bumps and lace trails on the glass. On flat families the pour shrugs it off with a note; on heady families it is a leg of quality |
| `H` | full body | +fill per rune (a heavier pour, up to brimming) |
| `R` | thin pour | −fill per rune; *"Pulled thin and quick — the tapster had somewhere to be."* |
| `.` | bubbles | rising bubble streams, drawn climbing the glass |
| `&` | nitro | a cascading surge band under the head and streaks down the walls; a leg of quality on stout or porter, a wasted trick elsewhere |
| `(` `)` | stirred | sinuous currents still turning in the body; with more than one spirit in the glass it is a **mixing trigger** (§8) |
| `S` | shaken | a mixing trigger (§8): *"Shaken over ice until the shaker frosts, then strained sharp."* Shaking a lone family earns only a note — *"the tapster humors you"* |

Head is read out in fingers: *flat → a thin collar → two fingers → a proud crown → overflowing* (an overflowing head mushrooms over the rim and drips down the outside).

## 6. Flavor

| Rune | Meaning | Exact behavior |
|------|---------|----------------|
| `~` | honeyed | *"it drinks sweet and slow"*; titles as **Honeyed**; counts as an ingredient in the shaker (§8) |
| `F` | fruit | **one** `F` = an orange wheel drawn on the rim (or waiting beside vessels with no rim to take it); **two or more** = **citrus juice pressed into the drink** — the cocktail book's sour element (§8), with a lime wedge drawn on the rim |
| `=` | salt rim | a crust of sea-salt drawn along the rim — *"The rim wears a crust of sea-salt."* Required for a Margarita (§8) |
| `N` | mulled | steam curls off the drink, spice flecks drift in it; a leg of quality on vintage, mead, amber, or cordial — **mulled lager loses one** (*"the tapster mutters a prayer for your soul"*) |
| `-` | chilled | frost speckle and condensation droplets on the glass; titles as **Frosted**. Mulled beats chilled: *"The frost gives up against a mulled cup."* |

Anything the cellar doesn't know is **slops** — fished out with a note, left as sediment.

## 7. Quality

Solved from composition, never rolled. A drink starts *honest* (1) and gains or loses legs:

| Leg | Condition |
|-----|-----------|
| +1 | a chosen glass that fits the family |
| +1 | aged, and the family ages well |
| −1 | gone to vinegar (§4) |
| +1 | extra head (`P`) on a heady family |
| −1 | forcing foam on a flat family |
| +1 | nitro on stout or porter |
| +1 | mulled where mulling belongs |
| −1 | mulled lager |

0 = **Swill**, 1 = **Honest**, 2 = **Fine**, 3 = **Prized**, 4+ = **Legendary** — each with its own tavern-voice verdict, from *"Pour it in the gutter and apologize to the gutter."* to *"A pour worth a song — the bard is already clearing his throat."* Skunked swill and a glass of pure foam (`{PPP}`) are Swill regardless.

Cocktails (§8) score their own way: *honest* for an unnamed house mix, +1 for a pour the book names, +1 for serving it in its proper glass (*"the house nods"*) — a Margarita in its coupe is **Prized**. The Regret is Swill, always.

## 8. The mixing book — cocktails

Mix when a **mixing trigger** meets more than one ingredient. Triggers: `S` (shaken), `(` or `)` (stirred), or ordering any cocktail glass (`A` `M` `K` `L`). Ingredients: a second family in the glass, citrus (`FF`), or bubbles for the sparkler. No trigger = the old splash-blend rules; a trigger with two families but no page in the book = an unnamed **House Mix**.

The readout names the pour (*"The house calls this one a Margarita — sharp, sour, and sure of itself."*), states the method (shaken / stirred / *"Built right in the glass, the house way"*), lists the ingredients, and the embed gains a **Mixed** field. Cocktail proof mixes down (60% base + 40% mixer, plus 7 per `^`); age is ignored (*"Nobody cellars a cocktail — the years slide off it."*); rocks and highball pours go **over drawn ice**.

| Recipe | Cocktail | Proper glass | Garnish drawn |
|--------|----------|-------------|---------------|
| firewater + citrus + salt | **Margarita** | coupe (`A`) | lime wedge + salt crust |
| firewater + citrus | **Tavern Sour** | rocks (`K`) | orange wheel |
| firewater + stout | **Boilermaker** | rocks (`K`) | — |
| firewater + mead | **The Bee's Sting** | coupe (`A`) | — |
| firewater + cordial | **The Physicker** | martini (`M`) | — |
| firewater + dream-wine | **Fey Martini** | martini (`M`) | olive on a pick |
| firewater + vintage | **Cellar Negroni** | rocks (`K`) | orange wheel |
| porter + firewater | **Blackpowder** | rocks (`K`) | — |
| mead + cordial | **Meadowsweet** | highball (`L`) | — |
| dream-wine + mead | **Moonglow** | coupe (`A`) | **paper umbrella** (flashy) |
| dream-wine + vintage | **Violet Hour** | martini (`M`) | — |
| vintage + bubbles | **Garnet Sparkler** | flute (`I`) | — |
| lager + citrus | **Shandy** | highball (`L`) | lime wedge |
| anything + swill | **The Regret** | any | umbrella — someone put one in anyway |

Two-family pages are matched first, then the single-family recipes, first page wins; a third family stays on the shelf. Honey (`~`) and salt (`=`) always join the ingredients line.

## 9. The rowdy pour — `[ ]`

An uneven border is a night already going well. The stats roll fresh with **every** pour: proof jitters, the fill comes up short, the liquid sits **sloshed at a tilt** in the glass, foam runs over the rim, and a spill puddles on the shelf. A rowdy **cocktail** always gets a paper umbrella, **bent double by the pour**. Everything else about an order is deterministic — the same runes always pour the same drink, to the pixel.

## 10. Toasts and the house

- **Nested `{}`** — a toast **etched** on glass vessels, **carved/burned** into wood, clay, and horn. 18 characters fit; a nested `[ ]` toast is carved crooked (*"the engraver was drinking too"*). Runes pressed against a toast's border pour into the drink like any rim runes. `{BB T {}}` etches *an empty toast — to nothing and no one*.
- **`$` + letters** — the rest of the cluster is the **tavern's name**: painted on a cork coaster under the glass, burned into a barrel-mug's staves, or printed on any bottle's label (§3a). 14 letters fit; the first `$` wins.

## 11. Verified pours

Readouts copied verbatim from the pouring harness (`lehua run test_ale.luau`).

**`{^^^ FF = S A}`** — the margarita: firewater, lime, salt, shaken, in its coupe.
> **Prized Margarita** — The house calls this one a Margarita — sharp, sour, and sure of itself. Shaken over ice until the shaker frosts, then strained sharp. In it: Firewater, lime pressed sharp, and a salted rim. Poured full into a wide-lipped margarita coupe. A wedge of lime bites the rim. Runs 68 proofs — slow legs cling to the glass. A prized pour — regulars will swear they were there the night it was tapped. *The margarita coupe is the proper glass for it — the house nods.*

**`[^^^ FF = S A]`** — the same order on a rowdy night. This pour rolled 73 proofs; yours will differ.
> **Rowdy Prized Margarita** — The house calls this one a Margarita — sharp, sour, and sure of itself. Shaken over ice until the shaker frosts, then strained sharp. In it: Firewater, lime pressed sharp, and a salted rim. Poured full into a wide-lipped margarita coupe. A wedge of lime bites the rim. A paper umbrella lists in it, bent double by the pour. Runs 73 proofs — it bites, and the fumes bite first. A rowdy pour — the shelf gets its share and the floor gets the rest. A prized pour — regulars will swear they were there the night it was tapped.

**`{^^ GG K}`** — a shot dropped in a stout, over ice.
> **Prized Boilermaker** — The house calls this one a Boilermaker — a shot dropped where it has no business. Built right in the glass, the house way. In it: Firewater and Dark Stout. Poured shy into a squat rocks glass over a fist of ice. Runs 65 proofs — slow legs cling to the glass. A prized pour — regulars will swear they were there the night it was tapped.

**`{:::: .. ( I}`** — the vintage, stirred with bubbles into a flute.
> **Prized Garnet Sparkler** — The house calls this one a Garnet Sparkler — the vintage taught to laugh. Stirred slow over ice, the spoon ringing the glass like a bell. In it: Wine-Dark Vintage. Poured full into a tall pilsner flute. Bubble streams climb it without rest. Runs a gentle 16 proofs. A prized pour — regulars will swear they were there the night it was tapped.

**`{^^ '' S M}`** — firewater and dream-wine, shaken bone-dry.
> **Prized Fey Martini** — The house calls this one a Fey Martini — dry as a fairy bargain. Shaken over ice until the shaker frosts, then strained sharp. In it: Firewater and Dream-Wine. Poured full into a knife-edged martini glass. An olive rides a pick across the mouth. Runs 69 proofs — slow legs cling to the glass. A prized pour — regulars will swear they were there the night it was tapped.

**`{''' !! S A}`** — the flashy one.
> **Prized Moonglow** — The house calls this one a Moonglow — glows faintly and asks the fiddler for something slow. Shaken over ice until the shaker frosts, then strained sharp. In it: Dream-Wine and Golden Mead. Poured full into a wide-lipped margarita coupe. A paper umbrella leans in it, ambition outrunning dignity. Runs a gentle 22 proofs. A prized pour — regulars will swear they were there the night it was tapped.

**`{%% ^^ S K}`** — swill in the shaker.
> **The Regret** — The house calls this one The Regret — everyone orders it once. Shaken over ice until the shaker frosts, then strained sharp. In it: Skunked Swill and Firewater. Poured shy into a squat rocks glass over a fist of ice. A paper umbrella leans in it, ambition outrunning dignity. Runs 48 proofs — slow legs cling to the glass. Pour it in the gutter and apologize to the gutter.

**`{WWW FF L}`** — lager and lime in a tall glass.
> **Prized Shandy** — The house calls this one a Shandy — half a lager, twice the afternoon. Built right in the glass, the house way. In it: Pale Lager and lime pressed sharp. Poured full into a tall highball over stacked ice. A wedge of lime bites the rim. Runs a gentle 5 proofs. A prized pour — regulars will swear they were there the night it was tapped.

**`{BB :: S}`** — a mix the book has no page for.
> **House Mix** — The house pours your invention and declines to name it. Shaken over ice until the shaker frosts, then strained sharp. In it: Amber Ale and Wine-Dark Vintage. Poured full into a plain pint glass. Runs a gentle 16 proofs. An honest pour — it does what a drink must and asks no praise for it.

**`{GGGG QQ}`** — stout in its own bottle, crown cap and all.
> **Fine Stout** — A squat brown bottle of dark stout, black-brown as turned earth, laid on the shelf. A thin collar of foam rings the glass. Runs a gentle 11 proofs. A fine pour — good enough to quiet a table for the first three swallows. *The stout bottle suits it — the shelf approves.*

**`{!!!! QQQQQ $MOTHERS}`** — mead in a wicker demijohn, the house name on the skirt.
> **Fine Mead** — A wicker-skirted demijohn of golden mead, thick with clover honey, laid on the shelf. Runs a gentle 24 proofs. The label names the house — "MOTHERS". A fine pour — good enough to quiet a table for the first three swallows. *The wicker demijohn suits it — the shelf approves.*

**`{GGGG T P}`** — stout, tankard, extra head.
> **Prized Stout** — A full pour of dark stout, black-brown as turned earth, served in a heavy glass tankard. Two fingers of cream stand proud and leave lace where they cling. Runs a gentle 11 proofs. A prized pour — regulars will swear they were there the night it was tapped. *The glass tankard suits it — the shelf approves.*

**`{GGGG D 8 PP &}`** — the full craft: stout, barrel-mug, eight years, foam, nitro.
> **Legendary Oak-Aged Stout** — A full pour of dark stout, black-brown as turned earth, served in a wooden barrel-mug bound in iron. The head overruns the rim and will not be told. Nitro-poured — a cascade tumbles down the glass in slow waves. Laid down 8 years — it pours the darker and the wiser for it. Runs a gentle 11 proofs. A pour worth a song — the bard is already clearing his throat.

**`{:::: Y 7}`** — a vintage laid down seven years, in the right glass.
> **Prized 7-Year Vintage** — A full pour of a wine-dark vintage, deep as garnet, served in a tall stemmed wine glass. Laid down 7 years — it pours the darker and the wiser for it. Runs a gentle 26 proofs. A prized pour — regulars will swear they were there the night it was tapped.

**`{^^^ O}`** — firewater in a snifter; the `^`s stack the proof.
> **Fine Firewater** — A full pour of firewater, pale flame in a glass, served in a round-bellied snifter. Runs 99 proofs — it bites, and the fumes bite first. A fine pour — good enough to quiet a table for the first three swallows.

**`[^^^^ O]`** — the same idea, ordered rowdy. This pour rolled 118; yours will differ.
> **Rowdy Fine Firewater** — A shy pour of firewater, pale flame in a glass, served in a round-bellied snifter. Runs 118 proofs — it bites, and the fumes bite first. A rowdy pour — the shelf gets its share and the floor gets the rest. A fine pour — good enough to quiet a table for the first three swallows.

**`{%%% P F}`** — swill, garnished, hopefully.
> **Skunked Swill** — A full pour of skunked swill, flat and murky as ditchwater, served in a plain pint glass. An orange wheel rides the rim. Runs a gentle 5 proofs. Pour it in the gutter and apologize to the gutter. *Even the foam has abandoned it.*

**`{::: U N 2}`** — mulled vintage in a chalice: three legs, one song.
> **Legendary 2-Year Vintage** — A full pour of a wine-dark vintage, deep as garnet, served in a wide ceremonial chalice. Mulled and steaming, with spice adrift in it. Laid down 2 years — it pours the darker and the wiser for it. Runs a gentle 26 proofs. A pour worth a song — the bard is already clearing his throat.

**`{WWW N}`** — a warning to the curious.
> **Sorry Mulled Lager** — A full pour of pale lager, straw-gold and clean, served in a plain pint glass. A thin collar of foam rings the glass. Mulled and steaming, with spice adrift in it. Runs a gentle 8 proofs. The tapster pulls his cap down and pretends he poured it for someone else. *Mulled lager — the tapster mutters a prayer for your soul.*

**`{WWWW 66}`** — twelve years too many for a lager.
> **Sorry Vinegared Lager** — A full pour of pale lager, straw-gold and clean, served in a plain pint glass. A thin collar of foam rings the glass. Laid down 12 years — and gone to vinegar; Lager was never meant to wait. Runs a gentle 8 proofs. The tapster pulls his cap down and pretends he poured it for someone else.

**`{GGG T {TO THE KING} P}`** — a toast etched on the tankard.
> **Prized Stout** — A full pour of dark stout, black-brown as turned earth, served in a heavy glass tankard. Two fingers of cream stand proud and leave lace where they cling. Runs a gentle 11 proofs. Etched on the glass: "TO THE KING". A prized pour — regulars will swear they were there the night it was tapped.

**`{::::: Q 12 $OLDCROW}`** — a bottle from the house cellar, label and all.
> **Prized 3-Year Vintage** — A corked bottle of a wine-dark vintage, deep as garnet, laid on the shelf. Laid down 3 years — it pours the darker and the wiser for it. Runs a gentle 26 proofs. The label names the house — "OLDCROW". A prized pour — regulars will swear they were there the night it was tapped.

**`{BBB D $GILDEDBOAR}`** — the house name, burned into the staves.
> **Fine Amber Ale** — A full pour of amber ale, bright as lamplit copper, served in a wooden barrel-mug bound in iron. A thin collar of foam rings the glass. Runs a gentle 9 proofs. The house name is burned into the staves — "GILDEDBOAR". A fine pour — good enough to quiet a table for the first three swallows.

**`{!!!! XX 3}`** — a generous horn of aged mead, upright in its stand.
> **Prized 3-Year Mead** — A full pour of golden mead, thick with clover honey, served in a generous drinking horn. Laid down 3 years — it pours the darker and the wiser for it. Runs a gentle 24 proofs. A prized pour — regulars will swear they were there the night it was tapped.

**`{BBBB GG T}`** — the tapster's own blend.
> **Fine Amber Ale** — A full pour of amber ale, bright as lamplit copper, served in a heavy glass tankard. A thin collar of foam rings the glass. Runs a gentle 9 proofs. A fine pour — good enough to quiet a table for the first three swallows. *Cut with a splash of Dark Stout — the tapster's own blend. The glass tankard suits it — the shelf approves.*

**`{PPP}`** — an order the tapster should have refused.
> **A Glass of Foam** — A pull of pure foam settles in a plain pint glass — all head, no heart. All head and no heart — the tapster owes you an apology.
