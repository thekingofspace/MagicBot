# Potion System — Complete Reference

A potion is a rune recipe brewed with `/potion recipe:`. The bot parses it with the same border grammar as spells, solves what the bottle holds (readouts are solved lines like `On consume: knits wounds closed (potency 4) for 12 beats.`), and renders the bottle itself — glass, cork, liquid, and light. Every rule below is implemented; every example was brewed and its readout copied verbatim.

Potions are **limited magic**: restoration, enhancement, and modification only. Nothing in a bottle throws fire or calls doom. The one dark corner of the craft is the ferment — a brew left to rot sours into a thin poison.

---

## 1. Grammar

```
recipe  := rim* border
border  := '{' cluster* '}' | '[' cluster* ']'
rim     := runes pressed against the border — they steep into the brew all the same
inner   := a border inside the border:
           plain        → a charm, sealed in the glass (§9)
           pressed >    → a sub-brew, steeped into the pot (§8)
           pressed 1–9  → a sub-brew corked into that numbered phial (§8)
```

- Same parser as `/spell`: 200 characters, case-insensitive, spaces separate clusters, smart punctuation is folded back into runes before brewing.
- `[ ]` brews the bottle **volatile** (§11). Mismatched borders, stray runes, and missing borders fail exactly as spells do.
- `{}` is a valid recipe: *Clear Water — On consume: quenches thirst — nothing more.*
- **Determinism**: the same runes always bottle the same brew, byte for byte — text and render. Only an uneven border `[ ]` re-rolls per pour, and even that is stilled by frost (§7).

## 2. Essences

Every run of an essence rune adds its count to that essence's strength. The **strongest essence is the base effect** (ties go to whichever was written first).

| Rune | Essence | Effect (on consume) | Hue |
|------|---------|--------------------|-----|
| `J` | Jiva | knits wounds closed | heartsblood crimson |
| `W` | Tide | rinses ill humors and addlement away | clear azure |
| `G` | Stone | sets the skin hard as quarried stone | earthen ochre |
| `Z` | Zephyr | lightens the step to a swift hush | pale sky |
| `B` | Ember | banks a warmth in the blood against flame and frost | ember orange |
| `!` | Ray | opens the eyes to see in the dark | lantern gold |
| `^` | Spark | quickens hand and heart | spark yellow |
| `:` | Aeon | slows the toll of the years | dusk violet |
| `'` | Muse | stills a racing mind to one clear thought | lake teal |
| `*` | Astra | frees the body of its weight | midnight blue |
| `@` | Vortex | roots the drinker fast to the earth | iron plum |
| `A` | Ardor | fills the limbs with a tireless vigor | sunrise coral |
| `D` | Poppy | dulls every ache to a far-off murmur | milk white |
| `F` | Fox | sharpens eye, ear, and nose to a fox's keenness | russet amber |
| `K` | Kin | opens the ear to every spoken tongue | honeyed rose |
| `L` | Clover | tips the small chances of the day kindly | clover green |
| `M` | Iron | steels the nerve until the hand cannot shake | steel grey |
| `N` | Night | lays the drinker into a deep and dreamless sleep | starless indigo |
| `Y` | Wren | rings the voice out clear as a struck bell | pale primrose |
| `%` | Rot | **ferment** — spoilage, never a virtue (§10) | murk green |
| `/` | Rend | **ferment**, caustic strain | bile green |

Every essence carries three phrasings — on consume, on apply, and on inhale (§6, the `R` rune) — plus a modifying clause for when it rides second.

**The half rule**: a second essence colors the brew only if it holds **at least half** the base's strength (a catalyst lowers that bar, §7). A weaker second gets a note and settles out; a third always does (*"a brew binds only two"*) — unless an elixir base makes room (§7). What a bound pair becomes depends on the pair:

- Most pairs bind as a **clause**: the second rides the base as a modifier (`JJJJ ^^` → *knits wounds closed, in a hurry*) and layers its hue beneath the base's in the glass. The embed's Bind field reads `clause`.
- Thirty-two pairs **fuse into a named compound** (§3) — the merge lattice.
- Seven pairs **react** instead of binding (§4).
- Eight pairs with Muse are the **mind suite** (§5).
- A **Lasting** second (`:`) doubles the whole duration, whatever else the pair does.

## 3. The merge lattice — compounds

When base and second are one of these pairs (order does not matter), the brew fuses: the compound replaces the effect line, takes its **own name and hue**, and adds **half the second's strength** to the potency. The two source hues remain visible as thin luminous strata in the glass, and the embed carries a Compound field (`Jiva + Tide → Balm`) with Bind `fused`.

| Pair | Compound | Hue | Effect line |
|---|---|---|---|
| `J`+`W` | **Balm** | rose-water pink | knits and rinses in one kindness |
| `B`+`J` | **Hearthblood** | hearth red | warms the blood and knits it as it goes |
| `G`+`J` | **Knitbone** | fired clay | closes wounds beneath a stone-hard scar |
| `A`+`J` | **Second Wind** | dawn crimson | mends and refills the limbs in one long breath |
| `D`+`J` | **Mercy** | blushed ivory | knits wounds the drinker never feels |
| `:`+`J` | **Everbalm** | wine violet | a slow mending that keeps watch for days |
| `B`+`W` | **Sweatlodge** | steam pearl | a purging warmth that sweats the ill humors out |
| `N`+`W` | **Stillwater** | deep slate blue | washes the day away into black, quiet depths |
| `F`+`W` | **Clearscent** | glass green | rinses the senses until the world smells new-washed |
| `G`+`M` | **Bulwark** | granite grey | sets skin and nerve alike to stone |
| `B`+`G` | **Kilnhide** | terracotta | fires the hide hard as kiln-brick, and warm through |
| `@`+`G` | **Bedrock** | deep ochre | roots and armors — the drinker will not be moved |
| `:`+`G` | **Monument** | aged sandstone | the body weathers like a monument, slow and grand |
| `*`+`Z` | **Gossamer** | pale opal | each stride a gliding leap, near weightless |
| `F`+`Z` | **Prowl** | dusk amber | the hush and keen tread of a hunting cat |
| `Z`+`^` | **Swallowtail** | sky yellow | swift and turning as a swallow on the wing |
| `B`+`^` | **Bellows** | forge gold | stokes heart and hands like a smith's bellows |
| `B`+`D` | **Toddy** | mulled amber | a deep hearthside comfort that dulls every ache |
| `!`+`F` | **Huntsmoon** | harvest gold | the eyes and ears of the night hunter |
| `!`+`L` | **Lodestar** | gilt green | a kindly inner light that leads toward lucky turns |
| `M`+`^` | **the Duelist** | rapier grey | quick hands under an unshaking eye |
| `F`+`L` | **Foxluck** | lucky russet | the fox's knack for being elsewhere when trouble lands |
| `F`+`N` | **Catnap** | moonlit amber | a sleep that keeps one ear open — the drinker wakes at the first wrong sound |
| `A`+`D` | **Mettle** | oxblood | tireless limbs that shrug off every hurt |
| `:`+`A` | **Wellspring** | deep coral | a vigor drawn from a well that does not empty |
| `K`+`Y` | **Parley** | rose gold | speaks and is understood by every ear in the hall |
| `:`+`L` | **Providence** | evergreen | luck that leans close and stays the season |
| `D`+`M` | **Sawbones** | bone grey | steady hands that feel no flinch — the chirurgeon's nerve |
| `@`+`M` | **the Anvil** | anvil black | stands to be struck and does not ring |
| `D`+`N` | **Twilightsleep** | deep lilac | a painless, dreamless dark — the chirurgeon's hour |
| `:`+`N` | **Brumal** | midwinter blue | a bear's winter sleep — the years pass light as one night |
| `*`+`N` | **Cradle** | night opal | sleeps aloft, light as a babe rocked in air |

Compounds ride everything the craft can do: a compound mist is breathed (*"The Balm rides the vapor."*), a compound can sour and hide under honey, and the notes **tease near misses** — a too-weak second (*"…Balm waits past that line."*), a settled third (*"Had it bound the Jiva, Balm waited."*), and the augur names what a soured or curdled brew would have been. The still can **crack** a compound: three or more `X` boil the second essence out with the vapor (*"The still cracks the Balm — Tide rides out with the vapor."*).

## 4. Reactions

Seven pairs do not bind — they fight. Reactions fire when the pair would otherwise bind, and put a Reaction field on the embed.

| Pair | Kind | What happens |
|---|---|---|
| `*`+`@` | **thunder** | Astra and Vortex war in the glass — the brew turns volatile even in `{ }` (the roll is fixed per recipe, §11). In an uneven `[ ]` border the glass gives way entirely: **Shattered Vessel**, rendered as shards, a spilled shimmer, and a thrown cork. |
| `^`+`N` | **fizz** | The Spark spends itself against the Night — the brew fizzes flat: the base loses 1 strength (a base spent to nothing leaves water), the second is lost, and the bottle seethes with bubbles. |
| `@`+`Z` | **fizz** | The Zephyr spends itself against the Vortex — same spent hiss. |
| `D`+`F` | **curdle** | The Poppy dulls what the Fox whets — the brew **curdles**: the second drops out as a clotted layer (rendered as curds beneath the brew), Bind reads `curdled`, and sediment thickens. |
| `:`+`^` | **curdle** | The Spark races what the Aeon reins. |
| `A`+`N` | **curdle** | Vigor against sleep. |
| `G`+`Z` | **curdle** | Stone drags what the Zephyr lifts. |

A double catalyst (`CC`, §7) can force a curdling pair into an **uneasy** blend — Bind `uneasy`, churning strands in the render — but only fresh: any aging undoes it (*"Time undoes what the catalyst forced — the blend curdles in the cellar."*).

## 5. The mind suite

`'` (Muse) is the mind's essence, and bound to the right partner it brews a **named draught** — the pair replaces both title and effect line, whichever of the two runs stronger. Mind-brews of one or two doses bottle in a tiny **heart-shaped phial**.

| Pair | Named brew | On consume |
|---|---|---|
| `'` + `J` | **Cordial of High Heart** | lifts a heavy heart to steady courage |
| `'` + `:` | **Tonic of Remembered Days** | brings lost days back sharp and whole to memory (the Lasting second still doubles duration) |
| `'` + `!` | **Philtre of Clear Sight** | grants a quiet insight that sees through muddle and mask |
| `'` + `W` | **Draught of Untroubled Sleep** | washes the day's troubles away and lays down an untroubled sleep |
| `'` + `L` | **Philtre of Happenstance** | a quiet knowing of where luck waits, one step ahead |
| `'` + `N` | **Draught of Deep Dreaming** | vivid, kindly dreams the dreamer steers |
| `'` + `M` | **Tonic of the Even Keel** | fear finds no purchase on a level mind |
| `'` + `K` | **Philtre of the Unspoken** | hears the meaning beneath the words, spoken or not |

Two edges of the craft:

- **The Deep Trance** — a pure Muse brew of potency 6 or more (`{''''''}`) stops being a stillmind tonic: it *sinks mind and body into a deep meditative trance, far below thought*.
- **The Draught of Forgetting** — the one dark mind-brew. A Muse base soured by venom (`{''' %%%}`) does not sicken the gut: it *gently unwrites the drinker's last days*. Fog grey, bottled in the heart phial, and honey cannot sweeten it (§10).

## 6. Structure runes

| Rune | Meaning | Exact behavior |
|------|---------|----------------|
| `H` | Steep | +4 beats of duration per rune |
| `P` | Pour | +1 dose in the bottle per rune |
| digit | Age | ages the brew that many seasons: +1 beat each, and every 2 seasons mellow 1 point of ferment (§10). Pressed on an inner border it numbers a phial instead (§8) |
| `S` `O` | drinker marks | the brew works **on consume** |
| `V` `_` `#` | surface marks | the brew works **on apply** — poured over a thing or a place |
| `R` | Vapor | the bottle brews as a **mist**: one line, **On inhale:** — it overrides both marks and is never drunk. Frost freezes it flat (§7) |
| `T` | Thicken | syrup: +3 beats of duration per rune; it pours slow, and the render holds fewer, fatter bubbles |
| `X` | Distill | +1 potency and −1 dose per rune (never below 1 dose); the brew fills a twisted **alembic**; 3+ cracks a compound (§3) |
| `U` | Dilute | −1 potency (never below 1) and +1 dose per rune |
| `~` | Sweeten | honey: a wholesome brew just goes down easy — but a venom-soured brew hides as a **Honeyed Cordial** (§10) |
| `$` | Label | everything after `$` in its cluster is hand-inked on a paper label glued to the glass (12 letters fit; the first label wins) — written, never brewed |
| `.` | Bubble | the brew carbonates (drawn as bubbles) |
| `&` | Current | slow swirling strands in the liquid |
| `(` `)` | Spiral | a spiral current winds the body of the bottle |
| `C` `E` `I` `Q` | the alchemist's craft | catalyst, elixir, frost, quintessence — §7 |
| `+` `;` `=` `?` `-` | the finer marks | boon, chain, resonance, augur, rime — §7 |
| `>` | Scum | pours 1 point of ferment off per rune; pressed on an inner border it steeps a sub-brew instead (§8) |
| `<` | Skim | ladles the weakest essence out of the pot per rune; followed by a digit it draws that phial instead (§8) |
| `,` | Trace | halves the essence run that follows it (`,,JJJJ` quarters it); a trace of nothing is a note and a loss |

Every letter `A`–`Z` and every mark the parser knows now brews — nothing is inert.

- **No mark = on consume.** Both kinds of mark = a **liniment** (both lines print). `R` outranks every mark: a vaporous brew is breathed.
- **Potency** = the base essence's strength, ± distilling and dilution, + half the second's strength when a compound fuses, + boons (max 3), + 2 per quintessence.
- **Duration** (potions) = potency × 3 + steeping (4/`H`) + age + thickening (3/`T`) + frost (2/`I`) + rime (1/`-`) + 2 if radiant − augury (1/`?`) − 1 if the Ember hisses — then doubled by a Lasting second. Poisons run rot × 2 + steeping + thickening + frost + rime − augury (min 1 beat).

## 7. The alchemist's craft

| Rune | Name | Exact behavior |
|------|------|----------------|
| `C` | Catalyst | lowers the half-rule bar: one `C` binds a second at a **third** of the base's strength, `CC`+ binds **any** essence of strength ≥ 1. A bind that needed the catalyst is `forced` (*"a harsh marriage"*) and shows a bright seam in the glass. `CC` can force curdling pairs uneasy (§4). A catalyst with nothing to bind notes *"The catalyst finds nothing to hurry."* |
| `E` | Elixir | makes room for a **third essence** if it clears the same bar: Binds reads `three (elixir)`, the third rides as a clause and a banded hue, and the bottle is a slender **flute** (*Elixir of…*). A fourth still settles out. Alone it brews a **Blank Elixir** (*"a base awaiting a virtue"*); ferment is no virtue. |
| `I` | Frost | freezes the doses into **faceted lozenges** (*"On consume (let melt on the tongue):"*), +2 beats each, kills all vapor (*"Frozen fast — no vapor rises."*), and **stills a volatile roll** — this pour is the pour forever, render included. Ember hisses against it. |
| `Q` | Quintessence | exalts whatever it finds: +2 potency each in a potion, **deepens the rot** in a poison, floors a volatile roll at the written strength (*"The quintessence sings"*), and titles a fused or mind brew **Quintessent**. Pure, it is *Quintessence of Water*. |
| `+` | Boon | +1 potency each, at most 3 — excess settles as sediment (*"Virtue holds only so much"*). *"No kindness amplifies a poison."* |
| `;` | Chain | doses fire end to end: up to 1+chains doses chain (*"Each dose wakes as the last fades — 3 doses, 33 beats end to end"*), grimly noted for poisons (*"the poisoner's drip"*). One dose hangs slack. |
| `=` | Resonance | a fused or mind pair turns **radiant** — rings of light shimmer on the surface, +2 beats. A plain clause pair instead gives the second essence **its own effect line**. Nothing answers in water; the resonance dies in a sour. |
| `?` | Augur | reads the brew before it is drunk (−1 beat per augur, the reading's price): a **Foretold** block reveals the honey's lie, a volatile bind's roll range, what a soured or curdled brew *would have been*, and counts the Forgetting's days. Clean brews read clean. |
| `-` | Rime | brewed on ice: +1 beat each; **three or more becalm a volatile bind entirely** (*"Brewed on ice — the bind steadies."* — thunder excepted). Ember hisses a thread of steam past the cork; the glass frosts over in the render. |

## 8. Sub-brews — steeping and the phial rack

An inner border **pressed with runes** is a sub-brew, resolved with its own halving, aging, scums, skims, and stills:

- **Steep** — `>{...}`: the sub-brew's essences join the pot (*"An inner brew steeps through the glass — Spark (2) joins the pot."*). Ferment steeps through too; a volatile inner border makes the whole bottle volatile. Steeps nest three borders deep.
- **Phial** — `1{...}` through `9{...}`: the sub-brew is corked into that numbered phial, rendered as a tiny corked bottle hanging in the liquid, and listed in the embed's Phials field (`1: corked`). Corking the same number twice spills the second into the fire.
- **Draw** — `<1`: pours phial 1 over the top. A drawn phial strong enough (half the base) adds +1 potency per draw, its clause, and shoots its hue through the brew; a weak one is *"a top-note … more scent than substance"*; an empty number, *"the ladle comes up empty."* Drawn phials render uncorked and empty.

## 9. Charms

A plain border **inside** the border is not a sub-brew — it is a **charm**: its strongest essence is sealed as a glowing mote suspended in the liquid. `{WWW {!!}}` → *A charm of owl-light hangs suspended in the glass.* A volatile inner border (`[ ]`) makes the mote tremble. Three charms fit in a bottle at most; an empty inner border hangs as *a charm of nothing*.

## 10. The ferment — souring and aging

`%` and `/` pool into one ferment count (the stronger strain names it: venom or caustic). Measured against the base essence's potency:

| Ferment | Result | Readout |
|---|---|---|
| below half | boils off | *"A sour note boils off in the brewing…"* |
| ≥ half, < potency | **tainted** | *"A sour ferment rides beneath the taste (venom n) — drink it fresh, or not at all."* |
| ≥ potency | **soured** | the whole bottle turns: **Soured Brew — a thin poison** (or *a caustic slime*, which is applied, never drunk) |

Ferment with no wholesome essence at all sours immediately — the deliberate poisoner's recipe. **Aging tames it**: every 2 seasons of age mellow 1 point of ferment. `{%% 4}` ages the rot away entirely and leaves clear water. The `>` scum mark pours it off directly.

Four faces of a soured bottle:

- **Sweetened** (`~`): a venom-soured brew reads as a harmless **Honeyed Cordial** — title, effect line, hue, even the potency field drop the word *venom*. Only the final note tells the truth: *"Beneath the honey: … — a sweet lie."* The mask holds even over a soured compound. Honey does nothing for a caustic slime, and it cannot sweeten the Draught of Forgetting or a blight.
- **Vaporous** (`R`): a soured mist is a **foul miasma**, breathed instead of drunk.
- **A Muse base**: the Draught of Forgetting (§5).
- **Blightwater**: venom and caustic soured in near-balance fuse into a **blight that sickens and scars in one** — black-green, and past honey's help.

## 11. Volatility

An uneven border `[ ]` brews the bottle **volatile**: potency re-rolls with every pour (about three-quarters to a third again its written strength), fizz climbs the neck in the render, and the ferment rolls too — a tainted volatile brew can sour in the glass on an unlucky pour (the readout says so). A volatile inner steep infects the whole bottle.

The craft bargains with it: **frost** (`I`) stills the roll — this pour is the pour forever, render included; **quintessence** (`Q`) floors the roll at the written strength; **three rimes** (`---`) becalm the bind outright; the **augur** (`?`) foretells the roll's range. A **thunder** pair (§4) turns even a `{ }` brew volatile, but its roll is fixed per recipe — everything but a true `[ ]` pour bottles the same way every time.

## 12. Vessels and the glass

- 1 dose & strength ≤ 3 bottles as a **vial**; 4+ doses or strength ≥ 9 fills a **jug**; everything between takes the round **flask**. Named mind-brews, the trance, and the forgetting take the **heart phial** at ≤ 2 doses and strength ≤ 8; any distilled brew takes the **alembic**; a three-bound elixir takes the slender **flute**.
- Nouns follow the glass: Phial / Tonic / Jug — a two-essence brew is a *Draught of…*, an apply brew an *Oil*, a both-ways brew a *Liniment*, a vaporous brew a *Mist*, an alembic brew a *Distillate*, a three-bound brew an *Elixir of…*.
- Every profile is corked with the cork under the glass and a completed mouth-rim drawn over it, so the bottle reads closed. Every brew glows faintly; potency ≥ 6 glows brighter. Compounds show their source hues as strata; elixirs band three; curdles clot; radiance rings the surface; frost facets and rimes the glass; a shattered vessel is drawn as its shards.

## 13. Verified brews

Readouts copied verbatim from the brewing harness (`lehua run test_potion.luau`).

**`{JJJ}`** — the classic red one.
> **Mending Phial** — On consume: knits wounds closed (potency 3) for 9 beats.

**`{JJJJ ^^ ..}`** — healing with a strong haste second, carbonated.
> **Draught of Hurried Mending** — On consume: knits wounds closed, in a hurry (potency 4) for 12 beats. *It bubbles gently against the stopper.*

**`[GGGG HH]`** — stoneskin in an uneven bind; this pour rolled high.
> **Volatile Stoneskin Tonic** — On consume: sets the skin hard as quarried stone (potency 5) for 23 beats. *The brew fizzes in its bind — potency rolls with every pour.*

**`{GGG V S &}`** — marked for skin and stone both.
> **Stoneskin Liniment** — On consume: sets the skin hard as quarried stone (potency 3) for 9 beats. On apply: hardens what it coats to stone (potency 3) for 9 beats. *Slow currents swirl the brew.*

**`{WWW {!!}}`** — a cleanse with a light sealed inside.
> **Clearwater Phial** — On consume: rinses ill humors and addlement away (potency 3) for 9 beats. A charm of owl-light hangs suspended in the glass.

**`{JJ %%%}`** — the ferment outgrew the mending.
> **Soured Brew — a thin poison** — On consume: sickens the gut (venom 3) for 6 beats.

**`{//// V}`** — vitriol, bottled on purpose.
> **Soured Brew — a caustic slime** — On apply: eats at flesh, cloth, and lock alike (caustic 4) — do not drink.

**`{:::: 3 PP}`** — longevity, cellared three seasons, three doses.
> **Long-Year Tonic** — On consume: slows the toll of the years (potency 4) for 15 beats. *Aged 3 seasons — the brew drinks smoother for it.*

**`{ZZZZZ PPPP W ( )}`** — five doses of featherstep in a fat jug.
> **Featherstep Jug** — On consume: lightens the step to a swift hush (potency 5) for 15 beats. *The Tide (1) is too weak to color the brew — it needs half the Zephyr's strength (5). A spiral current winds through it, top to bottom.*

**`{@@@ ::: S}`** — grounding that will not let go.
> **Phial of Lasting Grounding** — On consume: roots the drinker fast to the earth, and lingers well past its hour (potency 3) for 18 beats.

**`PPHH{BBB}`** — rim-runes steep into the brew all the same.
> **Emberwarmth Tonic** — On consume: banks a warmth in the blood against flame and frost (potency 3) for 17 beats.

Three doses in the bottle — the rim's `PP` pours and `HH` steeps exactly as if they were written inside.

**`{%% 4}`** — rot, aged past harm.
> **Clear Water** — On consume: quenches thirst — nothing more. *Aged 4 seasons — the ferment (2) mellows away entirely.*

**`PP{JJJJJ ^^^ WW HHH .. && 2 {!!} S V}`** — the full craft in one bottle.
> **Liniment of Hurried Mending** — On consume: knits wounds closed, in a hurry (potency 5) for 29 beats. On apply: closes the cuts it is poured over, in a hurry (potency 5) for 29 beats. A charm of owl-light hangs suspended in the glass. *A third essence (Tide) settles out — a brew binds only two. (Had it bound the Jiva, Balm waited.) Aged 2 seasons — the brew drinks smoother for it. It bubbles gently against the stopper. Slow currents swirl the brew.*

**`{FFF}`** — a hunter's tonic.
> **Foxsense Phial** — On consume: sharpens eye, ear, and nose to a fox's keenness (potency 3) for 9 beats.

**`{DDD V}`** — numbness, rubbed in rather than drunk.
> **Numbing Oil** — On apply: numbs the flesh it is rubbed into (potency 3) for 9 beats.

**`{NNNN P}`** — two doses of black, restful nothing.
> **Dreamless Tonic** — On consume: lays the drinker into a deep and dreamless sleep (potency 4) for 12 beats.

**`{MM ^}`** — Iron and Spark fuse in the lattice.
> **Phial of the Duelist** — On consume: quick hands under an unshaking eye (potency 2) for 6 beats. *(Compound: Iron + Spark → the Duelist.)*

**`{'''' JJ}`** — the mind suite: Muse and Jiva, in the heart phial.
> **Cordial of High Heart** — On consume: lifts a heavy heart to steady courage (potency 4) for 12 beats.

**`{'''' ::}`** — Muse and Aeon; the Lasting second doubles it.
> **Tonic of Remembered Days** — On consume: brings lost days back sharp and whole to memory (potency 4) for 24 beats.

**`{''' !!}`** — Muse and Ray.
> **Philtre of Clear Sight** — On consume: grants a quiet insight that sees through muddle and mask (potency 3) for 9 beats.

**`{'''' WW}`** — Muse and Tide.
> **Draught of Untroubled Sleep** — On consume: washes the day's troubles away and lays down an untroubled sleep (potency 4) for 12 beats.

**`{''''''}`** — pure Muse, potency six: past stillness, into trance.
> **Phial of the Deep Trance** — On consume: sinks mind and body into a deep meditative trance, far below thought (potency 6) for 18 beats.

**`{''' %%%}`** — the one dark mind-brew.
> **Draught of Forgetting** — On consume: gently unwrites the drinker's last days (venom 3) for 6 beats.

**`{JJ %%% ~}`** — a soured brew, sweetened. The embed reads harmless to the last line.
> **Honeyed Cordial** — On consume: tastes of warm honey and easy comfort. *Beneath the honey: a soured brew that sickens the gut (venom 3) for 6 beats — a sweet lie.*

**`{BBB R}`** — warmth brewed as a breath.
> **Emberwarmth Mist** — On inhale: fills the chest with a banked and lasting warmth (potency 3) for 9 beats. *Brewed vaporous — uncork it and breathe; it is never drunk.*

**`{JJJJ XX PP}`** — mending run twice through the still; the pours boil down to one.
> **Mending Distillate** — On consume: knits wounds closed (potency 6) for 18 beats. *Distilled twice over — fiercer for it, but the bottle holds less.*

**`{GGGG UU}`** — stoneskin cut with water.
> **Stoneskin Tonic** — On consume: sets the skin hard as quarried stone (potency 2) for 6 beats. *Watered thin — a gentler draught, and more of it.*

**`{JJJ TT}`** — mending boiled to a syrup.
> **Mending Phial** — On consume: knits wounds closed (potency 3) for 15 beats. *Thickened to a slow syrup — it pours slow and lasts long.*

**`{JJJ $LOVE}`** — a mending phial with a name inked on it.
> **Mending Phial** — On consume: knits wounds closed (potency 3) for 9 beats. *A paper label is glued to the glass — it reads "LOVE".*

**`{'''' :: R TT $MEMORY}`** — a thickened memory-mist in a labeled heart phial.
> **Tonic of Remembered Days** — On inhale: returns lost days with every slow breath (potency 4) for 36 beats. *Thickened to a slow syrup — it pours slow and lasts long. Brewed vaporous — uncork it and breathe; it is never drunk. A paper label is glued to the glass — it reads "MEMORY".*

**`{JJJJ WW}`** — the lattice's first fusion.
> **Draught of Balm** — On consume: knits and rinses in one kindness (potency 5) for 15 beats. *(Compound: Jiva + Tide → Balm, bind fused.)*

**`{FFF NN PP ;; ?}`** — a chained catnap, read by the augur.
> **Draught of Catnap** — On consume: a sleep that keeps one ear open — the drinker wakes at the first wrong sound (potency 4) for 11 beats. *Each dose wakes as the last fades — 3 doses, 33 beats end to end.* Foretold: *The augury reads clean — no lie beneath.*

**`{AAAAA D CC}`** — a weak Poppy forced into Mettle by a double catalyst.
> **Draught of Mettle** — On consume: tireless limbs that shrug off every hurt (potency 5) for 15 beats. *The catalyst forces the Poppy into the bind — a harsh marriage.* *(Bind forced.)*

**`{JJJJ WW GG E}`** — an elixir base makes room for a third.
> **Elixir of Balm** — On consume: knits and rinses in one kindness, stone-steady all the while (potency 5) for 15 beats. *(Compound: Jiva + Tide → Balm (+ Stone rides third), binds three (elixir), in the flute.)*

**`{BBB >{^^} 1{!!} <1 ..}`** — a steeped spark fuses Bellows; a corked ray is drawn over the top.
> **Draught of Bellows** — On consume: stokes heart and hands like a smith's bellows, glowing gently all the while (potency 5) for 15 beats. *An inner brew steeps through the glass — Spark (2) joins the pot. It bubbles gently against the stopper.* *(Phials: 1: drawn.)*

**`{'''' :: Q I $KEEPSAKE}`** — a quintessent memory, frozen into a lozenge.
> **Quintessent Tonic of Remembered Days** — On consume (let melt on the tongue): brings lost days back sharp and whole to memory (potency 6) for 40 beats. *The frost sets every dose into a faceted lozenge. A paper label is glued to the glass — it reads "KEEPSAKE".*

**`{DDD FF}`** — an unmergeable pair.
> **Numbing Phial** — On consume: dulls every ache to a far-off murmur (potency 3) for 9 beats. *The Poppy dulls what the Fox whets — the brew curdles.* *(Reaction: curdled: Poppy against Fox.)*

**`{DDD FF CC}`** — the same pair, forced uneasy.
> **Phial of Keen Numbing** — On consume: dulls every ache to a far-off murmur, every sense pricked keen (potency 3) for 9 beats. *The catalyst forces the Fox against the Poppy — an uneasy blend, churning in the glass.*

**`{**** @@}`** — thunder in a steady border; the roll is fixed per recipe.
> **Volatile Unburdening Phial** — On consume: frees the body of its weight (potency 3) for 9 beats. *Astra and Vortex war in the glass — the bottle will not sit still.*

**`[*** @@]`** — thunder in an uneven border.
> **Shattered Vessel** — The glass gives way — nothing survives the war of weight and weightlessness.

**`{%%% ///}`** — both strains, in balance.
> **Blightwater** — On consume: a blight that sickens and scars in one — drunk or applied, it does not care (blight 6) for 12 beats.

**`{JJJJ WW =}`** — resonance on a fused pair.
> **Draught of Balm** — On consume: knits and rinses in one kindness (potency 5) for 17 beats. *The resonance turns the Balm radiant — rings of light shimmer on the surface.*

**`{JJJJ ^^ =}`** — resonance on a clause pair gives the second its own voice.
> **Draught of Hurried Mending** — On consume: knits wounds closed, in a hurry (potency 4) for 12 beats. On consume: quickens hand and heart (potency 2) for 12 beats. *The resonance gives the Spark its own voice — two virtues speak outright.*

**`{JJJJ WW XXX}`** — the still cracks the fusion.
> **Mending Distillate** — On consume: knits wounds closed (potency 7) for 21 beats. *The still cracks the Balm — Tide rides out with the vapor. Distilled 3 times over — fiercer for it, but the bottle holds less.*

**`{''' %%% ?}`** — the augur counts the Forgetting's days.
> **Draught of Forgetting** — On consume: gently unwrites the drinker's last days (venom 3) for 5 beats. Foretold: *three days, taken gently.*
