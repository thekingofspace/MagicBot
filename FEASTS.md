# Feast System — Complete Reference

A feast is a rune menu laid with `/feast menu:`. The bot parses it with the same border grammar as spells, the hall solves what the table holds — an entree, a side, a bread, a temperature, a doneness, a baker's score, and a feast verdict — and the table renders as **one candlelit scene**: a great platter, a side vessel, a bread board, a candle, and whatever else the menu earns, all on the dark plank table. Every rule below is implemented; every example was cooked with `lehua run test_feast.luau` and its readout copied verbatim.

Feasting is **hospitality magic**: it seats people, nothing more. The voice is the **herald** — soup is the cook talking to you, ale is the tapster, a feast is *announced*.

---

## 1. Grammar — position is the course

```
menu   := ring* border
border := '{' entree-content '}' | '[' entree-content ']'
entree-content := entree runes + up to two course circles (+ an optional gravy-boat circle)
inner circle #1 := the SIDE          inner circle #2 := the BREAD
glaze-only inner circle := the GRAVY BOAT (never consumes a slot, §6)
```

- Same parser as `/spell`: 200 characters, case-insensitive, spaces separate clusters, smart punctuation folded before cooking (an em-dash becomes `--` — two chill marks). Mismatched borders, stray runes, and missing borders fail exactly as spells do.
- **The outer circle is the entree** — the soup rule, one ring out. Rings pressed on the outer border pour into the entree; rings on an inner border pour into that course.
- **Positional assignment**: inner circles are walked in written order; any glaze-only circle is claimed as the gravy boat (first one only); of the rest, the first is the side and the second is the bread. A fourth circle earns *"The table seats three courses — the rest wait in the kitchen."* and is ignored.
- **An empty inner circle `{}` holds its position**: side slot → *an empty side plate — the kitchen's little joke* (drawn, one herb sprig); bread slot → *a bare board, dusted with flour* (drawn). This is how you serve bread with no side: `{entree {} {bread}}`. Empty plates don't count as courses.
- **Entree runes but no main** (only glazes and garnish in the outer circle): *"an empty platter, garnished with hope."* Verdict capped at An Honest Supper.
- **`{}`** is a valid menu: **A Bare Table** — *candles lit for nobody; the kitchen sends its regrets.* One guttering candle on an empty table. Feast-wide marks still read (`^^{}` earns *"The hall is warm, at least."*).
- **Depth-3 circles** nested inside a course circle fold their runes into that course: *"A circle within the circle — the kitchen folds it into the side."*
- `.` `,` `%` and digits belong to the course they are written in. `^ - ' $` are feast-wide wherever they appear (§7).
- **`[ ]` is the chaotic potluck** (§8). A `[ ]` inner circle rerolls just that course.

## 2. The entree (outer circle)

### 2a. Mains — strongest run wins, ties to first-written

Count is the size: **1–2** a modest haunch (*Beef Haunch*) · **3–4** a full roast (*Roast Beef*) · **5+** a whole beast (*Whole Roast Beef*). A rival main goes back to the larder with a note (*"One centerpiece per table"*) — except a meat rune losing to a pie, skewers, or sausages, which flavors the filling instead (§2d).

| Rune | Entree | Rendered signature |
|------|--------|--------------------|
| `B` | beef | mahogany crust, trussing strings, rose interior |
| `P` | pork | golden crust, pale fat-cap band, blush interior |
| `L` | lamb | dark honeyed crust, white fat-cap band, rosy interior |
| `M` | mutton | gray-rose, honest and humble — feeds many, impresses none |
| `X` | boar | near-black bristled crust (jittered stroke), loves an apple |
| `V` | venison | wine-dark lean interior, thin dark crust; begs the wine glaze |
| `U` | rabbit | pale slight roast, delicate — easy to ruin |
| `W` | roast bird | body, wing bumps, two drumsticks; hen (1–2) → goose (3–4) → *a bird of unreasonable size* (5+) |
| `F` | fish | 1–2 a fillet with flake striations; 3+ a **whole fish** — head, eye, gill arc, tail, grill marks |
| `D` | **dragon** | overlapping scale scallops, **iridescent teal–violet–gold bands**, dark ridge scutes, opal-pink interior |
| `Y` | wyvern | green-bronze scale crosshatch, paler serpent flesh — dragon's poor cousin |
| `!` | **phoenix** | golden bird, **glowing ember fissures**, sparks rising; cannot be overdone |
| `*` | **shadow-beast** | matte void flesh, no shine, thin violet rim-light, dark wisps instead of steam |
| `O` | piled noodles | mounded nest of strands, twirled crown, strands spilling off the pile |
| `I` | broth noodles | a deep bowl on the platter, strands looped over the rim, chopsticks across it |
| `Q` | meat pie | crimped rim, vent cross, **one wedge cut out** showing filling, a gravy drip |
| `K` | skewers | count = sticks (cap 4), cubes threaded on visible sticks, laid diagonal |
| `S` | sausages | count = links (cap 6), S-curved links pinched at the joins, char dashes |

### 2b. Doneness — digits are hours over the fire (summed)

**No digits = the kitchen's judgment**: medium interior, no deliberate-fire credit. Written digits sum (`55` = 10 hours):

| Hours | Doneness | Line |
|-------|----------|------|
| 0 | blue-rare | *shown the fire and taken away again — it remembers the field* |
| 1–2 | rare | *cooked rare — the knife blushes* |
| 3–4 | medium-rare | *cooked medium-rare — the cook's pride and the carver's mercy* |
| 5–6 | medium | *cooked to the middle of the argument* |
| 7–8 | well-done | *cooked through, no doubts left in it* |
| 9–11 | overdone | *held too long over the fire — it apologizes with every bite* |
| 12+ | **charred** | *charred — the fire won* — black, ash flecks, char cracks, −1 leg |

The carved face and fanned slices are drawn in the doneness color — a blue-rare cut face is deep purple-red, a charred one is black.

**Proper fires** (the proper-fire quality leg needs written digits inside the window): venison & fish 1–2 · beef, lamb & skewers 3–4 · rabbit, pie & sausages 5–6 · pork, boar, mutton, bird & wyvern 7–8 · **dragon & phoenix 9–11** (for them the 9–11 band *is* the proper fire, never "overdone": *"what would ruin an ox merely wakes a dragon"*) · shadow-beast 0–2 (eaten cold and dark) · noodles 0–2 (*noodles want minutes, not hours* — 3+ hours is mush, −1).

**Specials**: phoenix cannot char — at 12+ hours it **reignites** (*"at the eighteenth hour the bird reignited — it refuses the insult, and glows the brighter for it"*; no penalty, ember fissures burn brighter). Blue-rare pork, boar, or bird: *"the physicker is already saddling his horse"* — −1 leg. Fish prose scales from *done to flaking* to *dried to argument*. Dragon at well-done or charred dulls its iridescent bands with a mournful note.

### 2c. Glazes — first written coats the meat

Repetition deepens the lacquer (more sheen bands, more drips down the carved face). A second glaze kind: *"One glaze coats — the rest arrive in the ewer or not at all."*

| Rune | Glaze | Rendered |
|------|-------|----------|
| `~` | honey | lacquered gold sheen bands, drips down the cut face |
| `:` | red-wine reduction | dark garnet drape |
| `&` | cream sauce | white ribbon drape |
| `;` | ember glaze | chili-red lacquer, glowing flecks seated on the band |

### 2d. Formats, garnish, craft, and the knife

When `Q`/`K`/`S` wins, the strongest meat rune present names the filling (*"a pie of dragon, no less"*) and colors the interior; no meat = *"a pie of honest mystery"*. When a meat wins, lesser format runs are noted (*"The pie tins stay on the shelf."*).

| Rune | Meaning | Rendered / read |
|------|---------|-----------------|
| `J` | herb sprigs | tucked against the roast's base |
| `C` | citrus wheels | lemon wheels leaned along the platter rim |
| `E` | roast apples | burnished apples by the roast; **in the mouth** of a whole (5+) pork or boar |
| `G` | roast garlic | caramelized bulbs at the base |
| `T` | stuffing | at a bird's cavity; elsewhere *"the stuffing finds no cavity — it arrives in a quiet bowl"* |
| `A` | spice-studded | clove and anise studs across the crust |
| `H` | smoked | smoke ribbons clinging to the meat; *"smoked over orchard wood"* |
| `R` | resting jus | glossy drippings pool spreading under the roast |
| `( )` | spit-turned | even char rings; on noodles: *"the carver stares at the noodles, then at the herald"* |
| `/` | the carving knife | each `/` fans one more carved slice (cap 4); carvable roasts always show one carved end face |

Anything unclaimed in context (`N`, `Z`, `@ # _ ? < > = +`, …) is larder scraps: *"The kitchen cannot place N — back to the larder it goes."* Scraps are inert notes, never errors.

## 3. The side (first course circle)

Strongest run wins; ties to first-written. Count ≥ 2 = *a proper helping*. Each side owns its vessel — plates, bowls, a wooden salad bowl, a little cheese board.

| Rune | Side | Vessel | Rendered |
|------|------|--------|----------|
| `R` | roasted roots | plate | carrot batons, parsnip wedges, beet halves, char tips |
| `P` | mashed potatoes | bowl | swirled pale mound, **molten butter pool** in the crater, one drip over the side |
| `G` | rice | bowl | smooth dome, steam if hot, stray grains at the base |
| `S` | salad | wooden bowl | torn greens in two hues, tomato halves, sheen if dressed |
| `C` | cheese board | board | three wedges (pale, gold, blue-veined), one cut slice |
| `E` | eggs | plate | soft-boiled halves yolk-up |
| `F` | seasonal fruits | bowl | grape cluster draped over the rim, fig halves, apple crescents |
| `M` | buttered mushrooms | plate | glossy caps piled, gill arcs |
| `B` | buttered greens | plate | folded dark-green ribbons, butter gleam |
| `O` | roasted onions | plate | caramelized halves, ring layers |
| `L` | pickles | plate | bumpy green gherkins |

**Modifiers**: `~` butter gloss · `&` cream dollop · `( )` tossed · `/` knife-fanned plating · `.` pepper · `,` flaky salt · digits = oven hours (0/none fresh — right for salad, cheese, fruit, pickles; 1–3 golden; 4–6 burnished; 7+ scorched, −1) · `%` taint (§7).

## 4. The bread (second course circle)

### 4a. Shape and flour

| Rune | Shape | Rendered |
|------|-------|----------|
| `O` | boule | round domed loaf, flour-dusted shoulder (the default shape) |
| `I` | baguette | long diagonal loaf on the board |
| `B` | plait | alternating angled lobes with crease shadows at every overlap |
| `R` | rolls | count = rolls in a touching cluster (cap 5) |
| `F` | flatbread | blistered disc, char spots, one torn edge |

| Rune | Flour | Cast |
|------|-------|------|
| — | wheat (default) | honest hearth-brown |
| `W` | white | pale golden crust, ivory crumb |
| `Y` | rye | deep matte brown |
| `*` | charcoal | **black loaf** — the midnight bread |
| `!` | golden saffron | radiant gold crust, sun-yellow crumb |

### 4b. Crust hours (digits)

No digits = golden default (looks right, earns no deliberate-bake credit). Written: 0–1 pale (*"barely baked — dough in disguise"*) · 2–3 golden · 4–5 amber · 6–8 bold dark bake · 9+ burnt (*"the baker looked away"* — black, a smoke wisp).

### 4c. Scoring — the cuts are drawn

Each slash is a tapered lens — dark opening stroke, pale crumb showing inside, a darker seam.

| `/` count | Pattern |
|-----------|---------|
| 1 | a single **ear** — one long curved slash |
| 2 | a **cross** |
| 3 | **three parallel cuts** |
| 4 | the **wheat-stalk** — the baker's showpiece |
| 5+ | *"cut half to ribbons"* — the loaf deflates, no scoring credit |

**An unscored loaf bursts** (boule, plait, baguette — flatbread and rolls exempt): a ragged tear at the shoulder. *"Unscored, it burst where it pleased — the oven forgives nothing."*

**The baker's score (0–10, always read out)**: start at 5, then +1 shape chosen · +1 flour chosen · +1 extra for an ambitious flour (`*` or `!`) · +1 scored (1–4 cuts) · +1 extra for the wheat-stalk (exactly 4) · +1 deliberate crust hours in the 2–8 window · +1 topped · −2 burst · −2 pale · −2 burnt. Clamp 0–10. At 9–10: *"and the baker signs it."* **Feast legs from bread**: score ≥ 8 → +2 · 6–7 → +1 · ≤ 2 → −1.

**Toppings**: `S` seed sprinkle · `~` butter gloss (a melting pat if the feast is hot) · `,` flaky salt crystals · `J` rosemary baked into the crust · `&` a **crock of whipped butter** on the board.

## 5. The gravy boat

**An inner circle whose runes are only glaze runes (`~ : & ;`) is the gravy boat.** It never consumes a course slot: `{BBBB {::} {PP} {O //}}` = wine ewer + mash side + boule bread. Rings pressed on its border count as contents. One boat; a second glaze-only circle waits (*"One ewer per table — the second waits its turn."*). An empty `{}` has no glaze runes, so it stays the positional empty plate.

The strongest glaze names the sauce: *a honey ewer / a wine jus / a cream boat / an ember oil*. It renders front-left, lip overlapping the platter's rim, spout toward the platter, sauce meniscus in the glaze color. A filled boat = +1 composition.

## 6. Feast-wide runes, temperature, spoilage

| Rune | Meaning | Behavior |
|------|---------|----------|
| `^` / `-` | heat / chill | pooled feast-wide wherever written; net ≥ 3 **piping hot** · 1–2 **steaming** · marks but net 0 **lukewarm** (*"the kitchen argued about the fire and nobody won"*) · none **table-warm** · −1–2 **served cold — a traveler's spread** · ≤ −3 **ice-cold — a winter vigil**. Steam rises only off hot-natured dishes; a cold feast beads the dishware |
| `'` | candle | one lit candle per rune, cap 3 (one is always drawn — the scene's light); two earn *"Two candles burn for it."*; the third: *"A third candle — someone is courting."* |
| `$` | menu card | rest of the cluster written on a folded tent card by the front of the table (first `$` anywhere wins; 10 letters fit, then *"the chalk ran short"*) |
| `.` / `,` | pepper / salt | counted per course, drawn as flecks and crystals on that course |
| `%` | taint | per course, below |
| digits | hours | per course: roasting (entree) / oven (side) / crust (bread) |

**Spoilage**: `%` is measured against that course's main strength, exactly the soup rule, and **hours fight taint** — every 2 hours cook away 1 point (*"Whatever had turned in the entree (2), the hours over the fire cooked it clean away."*). A surviving whiff: −2 legs on that course, *"eat it tonight or not at all."* Taint ≥ the main: the course **turns** — gray-green cast, scum, stink lines, **flies over that dish only**. **Any turned course poisons the banquet**: the verdict is forced to A Poisoned Banquet regardless of everything else.

## 7. Determinism & the chaotic potluck

Same menu → same table, pixel for pixel. The render seeds its randomness from the menu text, with per-station sub-streams — editing the bread never reshuffles the roast.

**An outer `[ ]` is a potluck**: every course rolls fresh per serving — entree, doneness, glaze, side, bread, flour, crust, scoring. Seasoning, temperature, candles, and the menu card stay yours; quality is judged on what arrived. The render sits slightly askew — dishes tilted a few degrees, crumbs scattered, one small spill. Title prefix: *"A Potluck: …"*. A `[ ]` **inner** circle rerolls just that course.

## 8. Quality — legs, pairings, verdict

**Entree legs**: +1 main strength ≥ 3 · +1 proper fire hit · +1 glazed · +1 garnished (any of `J C E G`) · +1 seasoned (`.` or `,`) · +1 one craft extra (`T A H R ( )`, cap 1) · −1 charred · −1 blue-rare pork/boar/bird · −1 mushy noodles · −2 sour whiff.

**Side legs**: +1 proper helping (≥ 2) · +1 dressed (`~ & ( ) /`) · +1 seasoned · +1 deliberate hours in the golden window (1–6, roastables) · −1 scorched · −2 whiff.

**Bread legs**: from the baker's score (§4c).

**Composition**: +2 all three courses present and real (*"A balanced table"*) · +1 per old pairing, cap 2 · +1 menu card · +1 candles lit · +1 filled gravy boat · +1 deliberate temperature (net ≠ 0).

**The old pairings** (each earns a herald's note):

| Pairing | Name |
|---------|------|
| fish + citrus wheels | the coast pairing |
| pork or boar + roast apples | the orchard pairing |
| dragon + ember glaze | fighting fire with fire |
| dragon + charcoal bread | the fireproof supper |
| shadow-beast + charcoal bread | a table dressed for midnight |
| phoenix + saffron bread | gold answers fire |
| beef + mashed potatoes | the drover's pairing |
| lamb or mutton + roasted roots | the shepherd's pairing |
| broth noodles + eggs side | the night-market pairing |
| venison + wine reduction | the hunt pairing |
| sausages + rolls | the fairground pairing |

**Feast verdict** (total = entree + side + bread + composition):

| Total | Verdict |
|-------|---------|
| any turned course | **A Poisoned Banquet** — the flies were seated first. Burn the tablecloth and start again. |
| `{}` | **A Bare Table** — candles lit for nobody; the kitchen sends its regrets. |
| ≤ 2 | **A Beggar's Plate** — eaten standing, and quickly, before anyone asks after it. |
| 3–5 | **An Honest Supper** — no herald needed; the food speaks in a plain voice and tells no lies. |
| 6–9 | **A Hearty Spread** — elbows on the table, and no one leaves before the last of it. |
| 10–13 | **A Lord's Table** — the hall falls quiet as the platters pass, and the fires burn taller for it. |
| 14+ | **A Feast for the Ages** — the bards will argue over this menu for a hundred winters. |

**Caps**: one real course caps at An Honest Supper; two cap at A Hearty Spread — *a lord's table demands a full table.* An empty-platter entree caps at An Honest Supper.

**Seats** = 1 + entree main count + 2 per additional real course, cap 12 (*"a hall of twelve"*).

There are also rumors of finer table settings appearing when the hall approves of a menu — the herald refuses to say more.

## 9. Rune budget — master table

*R rests the roast at the platter, roots the side, and rolls the board — the table decides what a rune means.*

| Rune | Entree circle | Side circle | Bread circle |
|------|---------------|-------------|--------------|
| `A` | spice-studded | scraps | scraps |
| `B` | beef | buttered greens | plait |
| `C` | citrus wheels | cheese board | scraps |
| `D` | dragon | scraps | scraps |
| `E` | roast apples | eggs | scraps |
| `F` | fish | seasonal fruits | flatbread |
| `G` | roast garlic | rice | scraps |
| `H` | smoked | scraps | scraps |
| `I` | broth noodles | scraps | baguette |
| `J` | herb sprigs | scraps | rosemary crust |
| `K` | skewers | scraps | scraps |
| `L` | lamb | pickles | scraps |
| `M` | mutton | buttered mushrooms | scraps |
| `O` | piled noodles | roasted onions | boule |
| `P` | pork | mashed potatoes | scraps |
| `Q` | meat pie | scraps | scraps |
| `R` | resting jus | roasted roots | rolls |
| `S` | sausages | salad | seed sprinkle |
| `T` | stuffing | scraps | scraps |
| `U` | rabbit | scraps | scraps |
| `V` | venison | scraps | scraps |
| `W` | roast bird | scraps | white flour |
| `X` | boar | scraps | scraps |
| `Y` | wyvern | scraps | rye flour |
| `!` | phoenix | scraps | saffron flour |
| `*` | shadow-beast | scraps | charcoal flour |
| digits | roasting hours | oven hours | crust hours |
| `~` | honey glaze | butter gloss | butter gloss |
| `:` | wine reduction | scraps | scraps |
| `;` | ember glaze | scraps | scraps |
| `&` | cream sauce | cream dollop | butter crock |
| `/` | carving slices (cap 4) | fanned plating | **scoring cuts** |
| `( )` | spit-turned | tossed | scraps |
| `^` `-` | temperature — pooled feast-wide |||
| `.` `,` | pepper / salt — per course, all contexts |||
| `%` | taint — per course, all contexts |||
| `'` | candle (cap 3) |||
| `$` | menu card (first anywhere, 10 letters) |||
| `N Z @ # _ ? < > = +` | scraps everywhere — *back to the larder it goes* |||

A glaze-only inner circle = the gravy boat (§5).

## 10. Verified feasts

Readouts copied verbatim from the hall harness (`lehua run test_feast.luau`).

**`{BBBB 22 ~ J R / {PP ~ .} {O // S 33}}`** — the drover done proud.
> **A Lord's Table: Honey-Glazed Roast Beef with Seeded Boule** — The first course enters: a full roast of beef, lacquered in honey, cooked medium-rare — the cook's pride and the carver's mercy, resting in its own jus, herb sprigs tucked close, one slice already carved and fanned. Beside it, a proper helping of mashed potatoes, a pool of butter melting in the crater, dusted with cracked pepper. And from the ovens, a wheat boule, cross-scored, seeded, baked six hours to a bold dark crust. The baker's score: 9 of 10, and the baker signs it. The table is set table-warm, and seats a hall of nine. A lord's table — the hall falls quiet as the platters pass, and the fires burn taller for it. *-# Beef and mash — the drover's pairing, written in the old menus. -# A balanced table — entree, side, and bread all answer the bell.*

**`{DDDDDD 55 ; JJ R H / , ^^ {;;} {GGG ~ ,} {B ! /// S 22} '' $SILVERSPIT}`** — the ewer rides with the dragon.
> **A Feast for the Ages: Ember-Glazed Whole Roast Dragon with Saffron Plait** — The first course enters: a whole roast dragon, lacquered in ember glaze, smoked over orchard wood, ten hours on the fire — what would ruin an ox merely wakes a dragon, and this one is cooked to its proper fire, resting in its own jus, herb sprigs tucked close, finished with flaky salt, one slice already carved and fanned, an ember oil riding beside it. Beside it, a proper helping of rice, domed smooth in its bowl, buttered, finished with flaky salt. And from the ovens, a golden saffron plait, cut three ways, seeded, baked four hours to an amber crust. The baker's score: 10 of 10, and the baker signs it. The table is set steaming, and seats a hall of eleven. A feast for the ages — the bards will argue over this menu for a hundred winters. *-# Two candles burn for it. -# The menu card reads, in a proud hand: SILVERSPIT. -# Dragon under ember glaze — fighting fire with fire. -# A balanced table — entree, side, and bread all answer the bell.*

**`{FFF 2 CC J {SS ( .}}`** — the coast, two courses only.
> **A Hearty Spread: Whole Roast Fish with Tossed Salad** — The first course enters: a whole fish, head and tail and all, done to flaking — it parts at the touch of a fork, herb sprigs tucked close, lemon wheels leaned along the platter rim. Beside it, a proper helping of torn greens in a wooden bowl, tossed, dusted with cracked pepper. No bread came from the ovens — its place at the board stays bare. The table is set table-warm, and seats six. A hearty spread — elbows on the table, and no one leaves before the last of it. *-# Fish and citrus — the coast pairing, written in the old menus.*

**`{!!!! 66 6 ~ {EE .} {FF 2}}`** — the bird that refuses.
> **A Hearty Spread: Honey-Glazed Roast Phoenix with Flatbread** — The first course enters: a full roast of phoenix, lacquered in honey, and at the eighteenth hour the bird reignited — it refuses the insult, and glows the brighter for it. Beside it, a proper helping of soft-boiled eggs, halved yolk-up, dusted with cracked pepper. And from the ovens, a blistered wheat flatbread, baked two hours to a golden crust. The baker's score: 7 of 10. The table is set table-warm, and seats a hall of nine. A hearty spread — elbows on the table, and no one leaves before the last of it. *-# A balanced table — entree, side, and bread all answer the bell.*

**`{XXXXX 44 E A {MM 3} {O // *}}`** — the black boar.
> **A Lord's Table: Whole Roast Boar with Charcoal Boule** — The first course enters: a whole roast boar, studded with cloves and anise, cooked through, no doubts left in it, a roast apple set in its mouth. Beside it, a proper helping of buttered mushrooms, caps glossy and piled, roasted three hours to a golden turn. And from the ovens, a charcoal boule, cross-scored, baked golden. The baker's score: 9 of 10, and the baker signs it. The table is set table-warm, and seats a hall of ten. A lord's table — the hall falls quiet as the platters pass, and the fires burn taller for it. *-# Boar and roast apples — the orchard pairing, written in the old menus. -# A balanced table — entree, side, and bread all answer the bell.*

**`{VVV 1 :: J {BB ~} {I //}}`** — the hunt.
> **A Lord's Table: Wine-Glazed Roast Venison with Baguette** — The first course enters: a full roast of venison, draped in a red-wine reduction, cooked rare — the knife blushes, herb sprigs tucked close. Beside it, a proper helping of buttered greens folded in dark ribbons, buttered. And from the ovens, a wheat baguette, cross-scored, baked golden. The baker's score: 7 of 10. The table is set table-warm, and seats a hall of eight. A lord's table — the hall falls quiet as the platters pass, and the fires burn taller for it. *-# Venison under a wine reduction — the hunt pairing, written in the old menus. -# A balanced table — entree, side, and bread all answer the bell.*

**`{****** 1 - {LL} {O / * S}}`** — a table dressed for midnight.
> **A Hearty Spread: Whole Roast Shadow-Beast with Charcoal Boule** — The first course enters: a whole roast shadow-beast, cooked rare — the knife blushes. Beside it, a proper helping of bumpy green pickles. And from the ovens, a charcoal boule, cut with a single ear, seeded, baked golden. The baker's score: 10 of 10, and the baker signs it. The table is set cold — a traveler's spread, and seats a hall of eleven. A hearty spread — elbows on the table, and no one leaves before the last of it. *-# Shadow-beast beside charcoal bread — a table dressed for midnight. -# A balanced table — entree, side, and bread all answer the bell.*

**`{QQQ DD 33 {PP ~} {O // S}}`** — a pie of dragon, made cheap.
> **A Hearty Spread: Dragon Pie with Seeded Boule** — The first course enters: a pie of dragon, no less, cooked to the middle of the argument. Beside it, a proper helping of mashed potatoes, a pool of butter melting in the crater. And from the ovens, a wheat boule, cross-scored, seeded, baked golden. The baker's score: 8 of 10. The table is set table-warm, and seats a hall of eight. A hearty spread — elbows on the table, and no one leaves before the last of it. *-# A balanced table — entree, side, and bread all answer the bell.*

**`{IIII 1 ^^ {EEE .} {O /}}`** — the night market.
> **A Hearty Spread: Broth Noodles with Boule** — The first course enters: a deep bowl of broth noodles, strands looped over the rim, pulled the minute they were done. Beside it, a proper helping of soft-boiled eggs, halved yolk-up, dusted with cracked pepper. And from the ovens, a wheat boule, cut with a single ear, baked golden. The baker's score: 7 of 10. The table is set steaming, and seats a hall of nine. A hearty spread — elbows on the table, and no one leaves before the last of it. *-# Broth noodles and eggs — the night-market pairing, written in the old menus. -# A balanced table — entree, side, and bread all answer the bell.*

**`{SSSS PP 33 {OO 2} {RRRR W /}}`** — the fairground.
> **A Hearty Spread: Pork Links with White Rolls** — The first course enters: a coil of four pork links, cooked to the middle of the argument. Beside it, a proper helping of roasted onions, caramelized to the rings, roasted two hours to a golden turn. And from the ovens, four white rolls, cut with a single ear, baked golden. The baker's score: 8 of 10. The table is set table-warm, and seats a hall of nine. A hearty spread — elbows on the table, and no one leaves before the last of it. *-# Sausages and rolls — the fairground pairing, written in the old menus. -# A balanced table — entree, side, and bread all answer the bell.*

**`{BBBB 22 {::} {PP} {O //}}`** — the gravy boat never takes a seat.
> **A Hearty Spread: Roast Beef with Boule** — The first course enters: a full roast of beef, cooked medium-rare — the cook's pride and the carver's mercy, a wine jus riding beside it. Beside it, a proper helping of mashed potatoes, a pool of butter melting in the crater. And from the ovens, a wheat boule, cross-scored, baked golden. The baker's score: 7 of 10. The table is set table-warm, and seats a hall of nine. A hearty spread — elbows on the table, and no one leaves before the last of it. *-# Beef and mash — the drover's pairing, written in the old menus. -# A balanced table — entree, side, and bread all answer the bell.*

**`{BBB 22 {PP} {B //// ! S 33}}`** — the baker's showpiece.
> **A Hearty Spread: Roast Beef with Saffron Plait** — The first course enters: a full roast of beef, cooked medium-rare — the cook's pride and the carver's mercy. Beside it, a proper helping of mashed potatoes, a pool of butter melting in the crater. And from the ovens, a golden saffron plait, scored to the wheat-stalk — the baker's showpiece, seeded, baked six hours to a bold dark crust. The baker's score: 10 of 10, and the baker signs it. The table is set table-warm, and seats a hall of eight. A hearty spread — elbows on the table, and no one leaves before the last of it. *-# Beef and mash — the drover's pairing, written in the old menus. -# A balanced table — entree, side, and bread all answer the bell.*

**`{U 55}`** — the herald earns his wage.
> **A Beggar's Plate: Overdone Rabbit Haunch, Alone** — The first course enters, and it is also the last: a modest haunch of rabbit, held too long over the fire — it apologizes with every bite. No side, no bread — a hunter's supper. The table is set table-warm, and seats two. A beggar's plate — eaten standing, and quickly, before anyone asks after it.

**`{BBB 22 {PP %%%} {O //}}`** — one turned dish poisons the banquet.
> **A Poisoned Banquet: Roast Beef** — The first course enters: a full roast of beef, cooked medium-rare — the cook's pride and the carver's mercy. Beside it, a proper helping of mashed potatoes, a pool of butter melting in the crater. And from the ovens, a wheat boule, cross-scored, baked golden. The baker's score: 7 of 10. The table is set table-warm, and seats a hall of eight. A poisoned banquet — the flies were seated first. Burn the tablecloth and start again. *-# The side has turned — gray-green, and the flies have found it. -# Beef and mash — the drover's pairing, written in the old menus. -# A balanced table — entree, side, and bread all answer the bell.*

**`{BBBB %% 44 {PP} {O //}}`** — the fire saves it.
> **A Hearty Spread: Roast Beef with Boule** — The first course enters: a full roast of beef, cooked through, no doubts left in it. Beside it, a proper helping of mashed potatoes, a pool of butter melting in the crater. And from the ovens, a wheat boule, cross-scored, baked golden. The baker's score: 7 of 10. The table is set table-warm, and seats a hall of nine. A hearty spread — elbows on the table, and no one leaves before the last of it. *-# Whatever had turned in the entree (2), the hours over the fire cooked it clean away. -# Beef and mash — the drover's pairing, written in the old menus. -# A balanced table — entree, side, and bread all answer the bell.*

**`{LLL 22 {} {B ! ///}}`** — bread with no side, by way of the empty plate.
> **An Honest Supper: Roast Lamb with Saffron Plait** — The first course enters: a full roast of lamb, cooked medium-rare — the cook's pride and the carver's mercy. Beside it, an empty side plate — the kitchen's little joke. And from the ovens, a golden saffron plait, cut three ways, baked golden. The baker's score: 9 of 10, and the baker signs it. The table is set table-warm, and seats six. An honest supper — no herald needed; the food speaks in a plain voice and tells no lies.

**`[WWW 44 {RR} {O /}]`** — the potluck (one sample sitting; yours will differ).
> **A Potluck: Overdone Cream-Sauced Pork Haunch with White Rolls** — The neighbors brought what they brought. The first course enters: a modest haunch of pork, ribboned with cream sauce, held too long over the fire — it apologizes with every bite. Beside it, a proper helping of buttered mushrooms, caps glossy and piled. And from the ovens, two white rolls, baked nine hours to a burnt black blister — the baker looked away. The baker's score: 5 of 10. The table is set table-warm, and seats six. An honest supper — no herald needed; the food speaks in a plain voice and tells no lies. *-# A balanced table — entree, side, and bread all answer the bell. -# A potluck — every sitting comes up different.*

**`{}`** — the saddest menu.
> **A Bare Table** — Candles lit for nobody; the kitchen sends its regrets. A bare table — candles lit for nobody; the kitchen sends its regrets.
