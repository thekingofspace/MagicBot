# Spell System — Complete Reference

A spell is a text incantation cast with `/spell`. The bot parses it, solves what it does from the numbers (descriptions are solved readouts like `Fire shoots out at 315° (southeast) with strength 16.`), and renders the spell circle as an image. The embed describes the spell; the image is only the circle. Every rule below is implemented — every example was run and its readout copied verbatim.

**Commands**: `/spell incantation:` casts (200 runes). `/spelladv` opens a form for **long-form casting — up to 3500 runes**, with raised limits (60 clusters per circle, 5 circle depth); the readout arrives as an attached `spell.txt` below the embed, with the circle image in the embed as usual. `/symbols` lists every recognized character (no meanings). `/example` shows the general shape of a spell. `/shapeform incantation:` ignores everything but the spell's `$` clusters and renders the body itself — shaded blob, sculpted by the letters.

---

## 1. Grammar

```
spell   := ring* border
border  := '{' element* '}' | '[' element* ']'
element := cluster | ring* spell     -- a nested spell is an inner circle
cluster := rune+                     -- separated by spaces
ring    := runes written directly against a border
```

- Runes are letters `A–Z`, the marks `* @ ~ # ( ) . & ! ^ % / _ : - ? < > $`, and digits `0–9`. Case-insensitive; any whitespace separates clusters.
- **Limits**: 200 characters total, circles nest 3 deep, 10 clusters per circle. Cluster length and ring length are unlimited (within the 200).
- **Rings**: runes *pressed against* a border wrap that circle — `PP{AAA}` rings the border. Inside a circle, a space breaks the bond (`PP {AAA}` = a Pulse cluster plus an unringed inner circle). At the top level all runes before the first border are rings, spaced or not.
- **Unstable border**: `[ ]` casts that circle unstable (§10). Border types nest freely in each other; mismatched pairs (`{AAA]`) are an error, as are runes after the final border, stray characters, and missing borders. `{}` is a valid empty circle (*"An empty circle — nothing resolves."*).

## 2. Cluster anatomy

The **first run** of letters is the *base rune*; repetition is its power (`AAA` = a power-3 arrow — power scales force, sigil strength, and working strength alike). Every rune after the first run attaches to the base as a **modifier**:

| Modifier | Effect on the base |
|---|---|
| element (`AAAB`) | **binds** — the glyph carries that element. If several element modifiers appear, the first one wins the binding (all still add their element power to the pool) |
| target (`DDOE`) | **aims** — the working acts on those targets |
| `R` on a slot glyph (`AAAR`) | **reach** — stretches across two border positions |
| `R` on a sigil (`WWWR`) | **widens** — sigils hold the core, so R adds spread instead |
| motion (`AAAB)`) | the whole cast takes that motion (§5) |
| digit (`BBB1`) | **injects** phial 1 (§11) |

If the same letter as the base reappears later in the cluster (`ABA`), it adds to the base's power.

## 3. The border: slots & geometry

**Slot-taking glyphs** — arrows, aspects, motion marks, standalone digits, and unknown runes — share the border, spaced **evenly around the full circle, counter-clockwise from the top**, in written order. An `R`-reaching glyph takes two consecutive positions.

**Everything else lives inside**: element sigils stack at the core (several draw atop each other, largest first), targets orbit between core and border as drawn symbols, spread bands are tick marks, rings wrap outside.

Slot positions by count (S = total positions):

| S | Positions (in written order) |
|---|------------------------------|
| 1 | top |
| 2 | top, bottom |
| 3 | top, lower-left, lower-right |
| 4 | top, left, bottom, right |
| n | every 360°/n counter-clockwise from the top |

## 4. Arrows & aiming

**`A` — Arrow.** The force rune. Each arrow pushes **inward from its slot, through the center, and out the far side** — an arrow at the top fires the spell *south*; one on the east side fires it *west*. Every arrow pushes; there are no inert arrows. An element-bound arrow (`AAAB`) additionally pushes its element (**flow**), which biases direction just like force does.

How to point a spell, with verified castings:

| Goal | Technique | Verified |
|---|---|---|
| **South** (default) | one arrow cluster — it takes the top slot | `{AAAB}` → *270° (south)* |
| **Even (no direction)** | equal arrows on opposing slots cancel | `{AAAB AAAB}` → *Fire burns evenly* |
| **Any cardinal** | pad with non-pushing slot-fillers (aspects, motion marks, unknown letters) to steer the arrow onto the slot you want | `{LL AAAB}` → arrow lands on the bottom slot → *90° (north)* |
| **Cardinal, symmetric build** | four equal arrows (all cancel), bind the element to just one — only its flow survives | `{AAA AAA AAA AAAB}` → *180° (west)* |
| **Diagonal** | two bound + two unbound arrows: kinetics cancel, the two flows sum | `{AAAB AAAB AAA AAA}` → *315° (southeast)* |
| **Fine angles** | unequal powers on opposing slots — the net force is the difference, so any ratio dials any angle | `{AAAAB AAB}` → 4v2 across top/bottom → *270° (south)*, net 2 |
| **Flip 180°** | a Null ring inverts the finished push | `N{AAAB}` → *90° (north). Its flow is inverted.* |
| **Curve in flight** | Sunwise/Widdershins bend the path after launch (~20°/rune) | `{AAAB) BBB}` → *bends sunwise, about 20°* |
| **Random** | an unstable border re-rolls the push every cast | `[^^^^^^]` → a fresh angle each casting |

### Projectiles that trigger on collide

The two-stage pattern: **an arrow is the flight, a `QA`-ringed inner circle is the warhead.**

```
{AAAAB QA[BBBBB RRRR]}
```
> *Fire shoots out at 272° (south) with strength 13… — the flight*
> *-# Payload: Held until it strikes something — Fire shoots out… fanned about 110° wide. Its border is uneven — the spell is unstable. — the warhead*

- The **arrow cluster** (`AAAAB`) gives the bolt its direction and speed — aim it with any technique from §4.
- The **`QA` ring** on the inner circle is the impact fuse: that circle stays sealed and inert while riding the shot (*Held until it strikes something*), and only unleashes on contact. The readout reports it as a **`Payload:`**, and its ring renders with outward-strike chevrons so an armed charge is visually unmistakable.
- **Warhead border choice matters.** `[ ]` = an explosion — direction, yield, and spread roll fresh at every impact (and its instability leak nudges the flight a little: real ballistic wobble). `{ }` = a precise payload, safe in the barrel — the singularity cannon (`UU{AAAAAAG CCCCG QA{*** @@@ UUU} [BBBB]}`) deliberately carries its black hole *stable* so it can't misbehave mid-flight, while its separate unstable fire circle detonates instantly as the propellant.
- **What merges vs. what waits**: the warhead's *elements* pool into the spell at cast (they color the readout and the flare), but its *trigger and flow are its own* — the `Payload:` line carries the true sequencing.
- **Variations**: `YY` ring instead of `QA` = a timed shell (explodes 2 beats after launch, hit or miss) · `QR` = proximity burst before contact · `Q.` = shatters when broken · motes in the warhead (`..`) = shrapnel · `)` on the launcher arrow = a curved delivery around cover · surge inside the warhead only (`QA[UU …]`) = bigger boom, unchanged flight.

## 5. Motion

| Rune | Name | Effect (as modifier, own cluster, or ring — identical) |
|------|------|--------------------------------------------------------|
| `(` | Widdershins | bends the cast counter-clockwise ~20° per rune (cap 160°) |
| `)` | Sunwise | bends it clockwise, same scale |
| `.` | Mote | the cast scatters into count+1 separate motes |
| `<` | Trace | **homing** — aims the cast back along whatever woke the circle (with `Q?`: the caster's own position); readout becomes *", back at its source,"* |
| `>` | Yonder | marks the landing point — one span ahead per mark (`>>>` lands 3 spans out); slot geometry picks the direction, `>` picks the distance |
| `&` | Coil | the cast coils, one turn per rune |

Motion merges upward from inner circles and pours out of injected phials. The flare in the render follows the solved path — curved, serpentine, or dotted.

## 5a. Shapeform — the `$` rune

`$` sculpts a **body**. Attach letters directly (`$VHII`) and each **letterform is literally the shape it takes** — the incantation is the blueprint:

`A` peaked arch · `B` double-bulge · `C` open crescent · `D` half-round · `E`/`F` combs of prongs · `G` hooked crescent · `H` bridged pair of pillars · `I` straight pillar · `J` hooked rod · `K` braced strut · `L` right-angle · `M` ridged wall · `N` sloped brace · `O` closed ring · `P` headed post · `Q` tailed ring · `R` legged loop · `S` winding curve · `T` crossbeam on a post · `U` open trough · `V` wedge · `W` doubled wedge · `X` cross · `Y` fork · `Z` zigzag

- Letters inside a `$`-cluster are **pure shape-spec, never runes** — `$J` is a hooked rod, not life. Repetition elongates (`$II` → *a straight pillar ×2*); more `$` marks scale the whole body (`$$$` = 3 spans).
- **Conjure vs. reshape**: with no marked target the form *takes shape* (built from whatever the spell provides — pair with Craft for the material). With a marked target (`_`, `O`, `V`…) it **reshapes the existing thing**: `{$$WO _ ~~G_}` → *It reshapes offering (2 spans) — a doubled wedge, then a closed ring.*
- **Monsters** are the intended craft: material + form + life + an animating loop — see the golem in §14. The circle renders the form-letters written large at its heart.

## 6. Resolution math

- **kinetic** = Σ arrow pushes · **flow** = Σ bound-arrow pushes · direction = kinetic + flow.
- **drift** = max(|kinetic|/total arrow power, |flow|/total bound power). **Balance = 1 − drift** (shown as a percentage).
- **Directional** when drift > 0.25 *and* the vectors don't fully cancel; otherwise the spell reads "even" and the Angle field shows *even*.
- **Angle**: 0° = east, 90° = north, 180° = west, 270° = south, rounded to whole degrees, with an 8-way compass word.
- **Strength** = element power + tint power + arrow power, rounded. Surges multiply before rounding; unstable rolls can leave one-decimal element powers.
- **Spread arc** ≈ 20° + 15° per spread point, capped 20–120°.
- **Determinism**: everything is deterministic except unstable borders. Ties (equal element powers) resolve alphabetically, so reruns match exactly.

## 7. Elements

Every element works four ways: a **cluster** (`BBB`) is a sigil source in the core; a **modifier** (`AAAB`) binds it to a glyph; on a plain **ring** (`B{...}`) it *infuses* the circle (adds element power); on a **Query ring** (`QB{ }`) it becomes a detection trigger (§9).

| Rune | Element | Rune name | | Rune | Element | Rune name |
|------|---------|-----------|-|------|---------|-----------|
| `B` | Fire | Ember | | `^` | Volt (electricity) | Spark |
| `W` | Water | Tide | | `:` | Time | Aeon |
| `Z` | Air | Zephyr | | `*` | Space | Astra |
| `G` | Ground | Stone | | `@` | Gravity | Vortex |
| `J` | Life | Jiva | | `%` | Decay (corruptor) | Rot |
| `!` | Light | Ray | | `/` | Ruin (corruptor) | Rend |

Circles with no element resolve as **Arcana**: raw force pushes and wards (*"The forces balance inward — the circle holds as a ward"*), or *"An empty circle — nothing resolves"* when there's nothing at all.

### Mixing

If the second-strongest element has **at least half** the power of the strongest, the two fuse. With three or more, only the top two bind — the third *"slips away"* (a note names it). Weaker seconds get a note explaining the half-power rule. Every base pair fuses:

| + | Water | Air | Ground | Life | Light | Volt | Time | Space | Gravity |
|---|-------|-----|--------|------|-------|------|------|-------|---------|
| **Fire** | Steam | Wildfire | Magma | Ash | Solar | Plasma | Smolder | Star | Meteor |
| **Water** | — | Mist | Mud | Bloom | Prism | Storm | Erosion | Nebula | Abyss |
| **Air** | | — | Sandstorm | Spirit | Mirage | Ion | Echo | Aether | Tempest |
| **Ground** | | | — | Verdure | Crystal | Magnet | Fossil | Moon | Bedrock |
| **Life** | | | | — | Dawn | Nerve | Elder | Dream | Wither |
| **Light** | | | | | — | Laser | Twilight | Beacon | Eclipse |
| **Volt** | | | | | | — | Flash | Aurora | Pulsar |
| **Time** | | | | | | | — | Eternity | Stasis |
| **Space** | | | | | | | | — | Singularity |

Special cases: **Decay + Ruin → Oblivion** (the only corruptor mix). **Glacier** forms by aspect transform, not pair-mix (§8). Mixing pools *everything* — sigils, bindings, ring infusions, and elements merged up from inner circles — so an inner water circle inside a fire circle makes Steam.

### Corruptors — Decay `%` and Ruin `/`

Corruptors sit outside normal mixing: they **corrupt whatever the spell resolves to** — plain elements, mixtures, layered casts — in tiers against the dominant element's power (both corruptors' powers pool):

| Corruptor power | Result | Readout |
|---|---|---|
| below half | nothing | *"The Decay (n) is too weak to touch the …"* |
| ≥ half, < equal | **tempered** | Decay: *"a slow ferment, not a rot"* · Ruin: *"weakening, not yet breaking"* |
| ≥ equal | **full** | Decay: *"it rots what it touches"* · Ruin: *"it breaks what it touches"* |

Tamed decay ferments wine; matched decay spoils it. Corruption darkens the render (strongly when full, faintly when mild) and adds a Corruption embed field (`Decay (4)` or `Decay (2, mild)`). Cast alone, corruptors are full elements (`{AAA AAA AAA AAA/ ///}` → *Ruin cleaves out at 180°*). Corruptors can also be **bound to workings** as any element can — `DDD%OE` is *Doom unmakes decay within essence, other*: a cleanse, aimed at the sickness rather than the patient (the stray decay-power prints a harmless too-weak note).

## 8. Aspects (workings)

Aspects take border slots (they don't push — which also makes them ideal aiming padding, §4) and add verb clauses to the readout.

| Rune | Name | Verb | Unaimed fallback | On a Query ring, triggers when… |
|------|------|------|------------------|--------------------------------|
| `C` | Craft | creates | matter | something is crafted nearby |
| `D` | Doom | unmakes | what it touches | something is unmade nearby |
| `L` | Lumen | sheds light upon | its surroundings | light falls upon it |
| `F` | Fathom | seeks | what is hidden | it is sought |
| `K` | Kindred | copies | its target | its likeness appears |
| `M` | Missive | carries word to | a distant ear | word is spoken nearby |
| `X` | Weave | links | what it binds | a bond is woven nearby |
| `~` | Flux | transmutes | what it touches | something changes nearby |
| `-` | Hoar | freezes | the air around it | cold sets in nearby |

**What a working acts on**, in priority order: ① its own target modifiers → ② the spell's marked targets (standalone target clusters, wherever they are) → ③ its bound element → ④ the fallback. With both an element and targets it reads *"{element} within {targets}"* — `~~~GO` → *Flux transmutes ground within other*. Targets marked with no working at all read *"Marked: … — no working binds them."*

**Aspect transforms** — some workings change the spell's element wholesale. Currently one: **Hoar over a Water spell → Glacier** (`{----O WW}` → *The glacier freezes over evenly… Hoar freezes other*). The table is extensible in `Resolver.luau`.

**Proven patterns**: seek-then-strike (`FFF^O DDD^OE` — Fathom aims Doom at the spark in someone); anchor (`XXTO`); broadcast (`MMMMM ZZZZ RRR OO` — a loud noise is Missive riding air); purge-and-restore (`CCCCJOE DDD%OE` — the healing pair); make-the-world (`CCC*# CCCW CCCG` — craft space, water, and ground into a place).

## 9. Targets, tethers, triggers & conditions

### Targets

| Rune | Target | Meaning | On a Query ring |
|------|--------|---------|-----------------|
| `V` | vessel | a container / an object's body | **trigger: it is touched** |
| `E` | essence | what's inside — contents, cells, the stuff of a thing | condition: while the essence holds |
| `T` | tether | the bond to the thing it's cast on | condition: while the tether holds |
| `S` | self | the caster / the circle itself | condition: while the self holds |
| `O` | other | anyone or anything else | condition: while the other holds |
| `#` | place | the ground it's drawn on | condition: while the place holds |
| `_` | offering | whatever is placed within the circle | condition: while the offering rests within |
| `?` | spell | **the spell cast upon you** (Omen) | **trigger: a spell is cast upon it** |

**Tethering to the thing it's cast on**: a bare `T` is the implicit bond to whatever the circle is drawn upon. The proper casting forges it explicitly with Weave — `XXTO` (to a being), `XXTV` (to an object), `XXT#` (to the place), `XXT_` (to the offering), `XXTS` (to yourself) — the bond then appears in the readout, follows the target when it moves, and gives counter-play a face: `DDT` (*Doom unmakes tether*) is the curse-breaker. `QT` rings read the same bond: the spell runs only while it holds.

### Triggers (`Q` on a ring)

A `Q` makes its circle conditional; the rune paired with it on the ring picks the sense. **One trigger binds per circle (first wins)**; a target can ride alongside for a condition (`QB` + `T` = triggers on fire, only while the tether holds). Nest circles to stack sensors.

| Pairing | Sense |
|---------|-------|
| `Q` + element (`QB` `QJ` `Q^`…) | triggers when that element is found |
| `Q` + aspect (`QM` `QL`…) | triggers on that phenomenon (table in §8) |
| `Q` + target | condition — runs *while* it holds (except `QV`, below) |
| `QA` | **impact** — triggers when it strikes something (outward-chevron ring) |
| `QV` | touched (contact-dot ring) |
| `QR` | something comes within reach (ripple ring) |
| `Q&` | it is shaken (zigzag ring) |
| `Q.` | it is broken (crack-mark ring) |
| `Q(` / `Q)` | it is moved — anti-tamper (motion-arrow ring) |
| `Q?` | **a spell is cast upon it** — counterspelling (incoming-circle ring; see below) |

Triggered circles lead their readout with **"Held until … —"**; a triggered *inner* circle is reported as a **`Payload:`**. Ordnance from the harness: `{AAAAB QA[BBBBB RRRR]}` (bolt with impact warhead), `QV[XXT# BBBBB GGG RRRR ..]` (landmine), `Q([XXTV BBBBB RRRR .. DDO]` (exploding chest), `QR[BBBB RRR]` (proximity mine), `QM{RRR GGG ~~~GO}` (speech-triggered petrifier).

### Counterspelling — the Omen rune `?`

`?` (Omen) is the target meaning **the spell being cast upon you**. `Q?` on a ring wakes the circle the moment magic targets you, and every aspect becomes a metamagic verb when aimed at `?` — a full counterspell toolkit from runes you already know (all verified):

| Working | Answer to the incoming spell | Readout |
|---------|------------------------------|---------|
| `DD?` | **cancel** — dispel it outright | *Doom unmakes spell* |
| `XX?O` | **redirect** — re-bind it to someone else | *Weave links other, spell* |
| `CC?` (bind an element: `CC^?`) | **strengthen / feed** it | *Craft creates volt within spell* |
| `~~?` (bind an element: `~~B?`) | **modify** — reshape what it is | *Flux transmutes fire within spell* |
| `--?` | **suspend** — hold it frozen mid-air | *Hoar freezes spell* |
| `KK?S` | **steal** — copy it for yourself | *Kindred copies self, spell* |
| `FF?` | **detect / read** it | *Fathom seeks spell* |

Ward patterns from the harness: `IQ?{DDDD?}` (the standing counterspell — *Held until a spell is cast upon it — Doom unmakes spell. It repeats endlessly*), `IQ?{XXX?O KK?S}` (mirror: steal a copy, send the original at someone else), `IQ?{----? FF?}` (suspend and study), `IQ?{CCC^? ~~~B?}` (the forge: everything cast at you comes out bigger and on fire).

**The absorb-amplify-return pattern** (element-specific counterwards): sense the element, unmake the incoming bolt, drink the remainder into an inverted phial, and return it by arrow — with Surges on both the phial and the redirector to send it back doubled. The anti-lightning talisman, drawn on paper and dead when ripped:

```
INQ.{XXTV IUQ?{FFF^O DDD^? AAAA1< 1NU{^^^^^^}}}
```
> *Lightning arcs out, back at its source, with strength 24. Fathom seeks volt within other. Doom unmakes volt within spell. Weave links tether, vessel. It runs tinged with volt (12). It repeats until it is broken.*

The `Q?` ring wakes it only when a spell is actually cast on you; `DDD^?` unmakes the volt *of that spell*; the `<` on the return arrow sends the answer to the caster's own position; and the two `U`s (phial ring and redirector ring) double the stored charge and the bolt that carries it.

### Break conditions (`NQ` — stoppers)

A **Null pressed directly against a Query** (`NQ`, adjacent runs) inverts the condition's sense: instead of *waiting for* the event, the circle **runs until it** — a break condition. On an endless (`I`) circle the readout fuses into *"It repeats until …"* — the sanctioned off-switch for infinite spells (the others: destroy the circle, cut its tether). Every sense family works as a breaker:

| Breaker | Runs until… | Breaker | Runs until… |
|---------|-------------|---------|-------------|
| `NQ` + element (`NQG`…) | that element is found | `NQT` | the tether is severed |
| `NQ:` | **its hour comes** (the timer) | `NQ_` | the offering is taken |
| `NQ` + aspect (`NQM`…) | that phenomenon (word spoken…) | `NQE` | the essence is spent (fuel) |
| `NQA` / `NQV` / `NQ&` / `NQ.` / `NQ(` / `NQR` | struck / touched / shaken / broken / moved / approached | `NQV`* | (see targets — V is the touch block) |
| `NQS` | the self departs | `NQO` | the other departs |
| `NQ#` | the place is unmade | | |

(`Q:` without the Null is the matching trigger: *"Held until its hour comes"* — a timer trap.)

**Measurement senses** — two composite checks on a Query ring:

- element + `S` = **outweigh check**: the spell compares *itself* against that element — `INQZS{ }` → *"It repeats until it outweighs the air"* (the ash-pollution stopper).
- element + digit = **threshold check**: the digit is tenths of the whole — `INQG4{ }` → *"It repeats until ground is 4 parts in ten of the whole"* (40%). A digit on a Q-bearing ring is a threshold, never a phial id.

The consumed `N` does not flip direction; an `N` elsewhere in the rings still does. One condition per circle — a trigger *or* a stopper (nest circles to combine; each inner circle keeps its own rings and breaker). Verified examples: `INQG{WWWW ----W RRRRR XXT#}` → *repeats until ground is found* · `INQT{BBB RRR}` → *until the tether is severed* · `INQ_{!!! RRR}` → *until the offering is taken* · `INQE{JJ CCJO}` → *until the essence is spent* · `INQ:{^^^ RRR}` → *until its hour comes.*

## 10. Flow rings & the unstable border

| Rune | Name | Effect | Exact behavior |
|------|------|--------|----------------|
| `P` | Pulse | repeats | fires ×(count+1) total |
| `I` | Iterate | endless | loops until the circle is destroyed (overrides Pulse in the readout; embed shows ∞) |
| `H` | Hold | sustains | *count* beats (the time unit; ~1s each — "30 seconds" is thirty H's) |
| `Y` | Yield | delays | waits *count* beats before firing — a fuse |
| `N` | Null | inverts | flips the push 180°; two cancel. `N{@@@@@}` = inverted gravity |
| `U` | Surge | amplifies | ×(1+count) on element power and arrow force |
| `Q` | Query | conditional | §9 |

Also legal on rings: **elements** (plain infusion; trigger with Q), **R** (spread), **motion** (applies), **digits** (phial ids, §11). Anything else idles with a note. Flow runes written *inside* a circle behave as rings too. Rings apply to *their own* circle before it merges — an inverted inner circle pushes backward into the pool; a surged phial injects hot. The render draws each ring with a unique pattern (dot-pairs, loops, double line, dots, dash-dot, inward chevrons, radial ticks) but only the first three rings per circle; resolution counts them all.

### Unstable `[ ]`

Freshly rolled every cast: direction jitters ±35°, a **leak** ejects 15–40% of the circle's power in a random direction, element power surges ×0.8–1.4, spread flares +0–2. Two regimes: with arrows, the leak *dilutes* against their force (a slight wild lean, like the singularity cannon's muzzle wobble); with **no arrows**, the leak is the only direction — fully directional at a pure random angle (`[^^^^^^]`, the random lightning). Readout appends *"Its border is uneven — the spell is unstable"*; the embed gains a Stability field; the border renders jagged. Instability carried by inner circles or injected phials marks the whole spell.

## 11. Phials & injections (digits)

- **Store**: a digit pressed against a border corks that circle — `1{CCCG !!}` holds crystal-craft as phial 1. Phials do **not** merge; they render with their number above them.
- **Inject**: the digit in a cluster (base or modifier) pours the phial in: the glyph takes the phial's **resolved element** (mixture included) as a **tint** — *"It runs tinged with crystal (3)"* — coloring the glyph and the glow; the phial's workings, targets, motion, and instability join the spell; strength rises by the phial's power. If the spell had no element of its own, the tint *becomes* its element.
- Digits `0–9` are ten separate phials. Two references = a double dose. **Phials are circle-local**: a cluster can only draw phials corked in its own circle.
- Unused: *"Phial n is corked — nothing draws on it."* Undefined: *"Nothing fills phial n — the injection fizzles."*

## 12. Circles & merging

Every spell is a circle; circles nest to depth 3 (one concentric, several orbiting — all circles). Inner circles **merge upward**:

| Merges into the parent | Stays local |
|---|---|
| kinetic & flow (direction) | flow rings (applied before merging) |
| element power (pools into the mix) | triggers → the sub becomes a **Payload** |
| spread, motion, instability | its own readout (reported as a note) |
| workings, targets, tints | phials (until injected) |

Sub-notes are labeled by role: `Inner circle:` (plain), `Payload:` (triggered), `Phial n:` (corked).

## 13. Reading the result

**Description** — solved sentences in order: trigger lead-in ("Held until…") → element line (from the element's own module: *Fire shoots out at…*, *Bedrock stands unmoved…*) → one line per working → marked-targets line → tints → corruption → motion (bend/motes/coil) → repeats/endless → hold → delay → condition → inversion → instability. **Notes** (small text): slipped third elements, too-weak corruptors/binds, sub-circle reports, phial status, idle rune warnings.

**Embed fields**: Strength · Angle (`137° (southeast)` or *even*) · Spread · Balance % · Circles (count) · Elements (`Fire + Water → Steam`, when mixed) · Repeats (`×3` or ∞) · Sustain · Delay · Trigger/Condition · Path (bends/motes/coils) · Stability · Corruption. Footer = your incantation; the image is the circle.

**The render**: border (jagged if unstable) + patterned rings outside; slot glyphs with their cluster text; the slot polygon; sigils stacked at the core with the core glow; target symbols orbiting; sub-circles inside (phials numbered); the flare showing the solved direction, curve, and spread — colored by element, shifted by tints, darkened by corruption. Visual caps (render only): 3 rings, 5 chevrons per arrow, glyph labels hidden on tiny circles.

## 14. Worked examples (readouts verbatim from the harness)

| Spell | Result |
|---|---|
| `{AAARB BBB AAARB}` | Fire burns evenly around the circle with strength 17. |
| `{AAARB BBB AAAR}` | Fire shoots out at 315° (southeast) with strength 16. |
| `{AAA AAA AAA AAAB}` | Fire shoots out at 180° (west) with strength 13. |
| `{LL AAAB}` | Fire shoots out at 90° (north)… Lumen sheds light upon its surroundings. |
| `{RRR BB {AAA}}` | Fire shoots out at 270° (south) with strength 5, fanned about 65° wide. |
| `{WWW BBB}` | Steam billows evenly around the circle with strength 6. |
| `PPHHQT{XXXVVE T {KKES E S} {KKEO E O}}` | twin bottles — Weave links essence, vessel ×2; Kindred mirrors both ways; while the tether holds. |
| `IHH…H[^^^^^^]` (30 H) | lightning at a fresh random angle each pulse, endlessly, for 30 beats. |
| `IQTYYYYY{XXTO GG ~~GOE %%}` | the petrification curse — slow, endless, tethered, mildly fermented. |
| `I{CCCCWV WW JJ %%}` | infinite wine — Bloom, a slow ferment, repeating endlessly. |
| `{^^^ JJJ FFF^O DDD^OE}` | turn off a brain — Nerve-fire; seek the spark; unmake it within their essence. |
| `PPPQT{XXTO JJJ CCCCJOE DDD%OE}` | the heal — pour life in, purge the rot out, in waves, while the tether holds. |
| `QV[XXT# BBBBB GGG RRRR ..]` | landmine — held until touched; magma + 3 motes of shrapnel, unstable. |
| `UU{AAAAAAG CCCCG QA{*** @@@ UUU} [BBBB]}` | singularity cannon — rock slug, powder charge, impact-triggered black hole. |
| `IUUU{XXT# ~~~~G# GGGG RRRRR N{@@@@@}}` | floating mountains — Bedrock aloft on an inverted-gravity engine, forever. |
| `I{CCCCCG GG $$VHII CCCJJ}` | the golem — Verdure; crafted ground given crafted life, shaped 2 spans: *a wedge, then a bridged pair of pillars, then a straight pillar ×2*, animated endlessly. |
| `INQ.{XXTV IUQ?{FFF^O DDD^? AAAA1< 1NU{^^^^^^}}}` | the lightning shield talisman — wakes when a spell targets you, unmakes its volt, returns it doubled *back at its source*; dies when the paper rips. |
| `IUUNYYHHQM[…]` (magnum opus) | voice-triggered endless inverted unstable plasma storm with a beacon tint, full rot, three motions, a phial, a two-stage payload, and a glacier circle. |

## 15. Extending the system

- **Runes**: `src/spell/Runes.luau` — letter → class + hint (the hint doubles as in-game lore).
- **Elements & mixtures**: one module each in `src/spell/elements/` (colors, emoji, drawn sigil, verb set) + `Registry`/`MixTable`/`Corruptors` in `elements/init.luau`.
- **Aspects**: `src/spell/Aspects.luau` (verb, fallback, drawn glyph); trigger phrases and `AspectTransforms` in `Resolver.luau`; trigger blocks in `TriggerBlocks`.
- **Test without Discord**: `lehua run test_spell.luau` renders every sample spell into `renders/` and prints the solved readouts.
