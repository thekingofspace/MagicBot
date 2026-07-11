# The Wandwright — Complete Reference

A wand is a rune design turned with `/wand design:`. The wandwright parses it with the same border grammar as spells, reads every rune off the bench, and turns one wand: wood, shaft form, tip, core, grip, ornament, and a solved **quality verdict** (readouts are the maker's own voice — *"A wand of true goldenwood… The maker's verdict: an heirloom. Bury it with someone worthy."*). The embed describes the wand; the image is the wand itself, laid large and diagonal on dark velvet — grain, silhouette, glowing tip, gilt, wrap, and all. Every example below was turned and its readout copied verbatim.

The same bench raises **staves** with `/staff design:` — a craft of its own, with headpieces, ferrules, and hangings (§13).

**Commands**: `/wand design:` turns, `/staff design:` raises (200 runes each). The same characters write other crafts — `/spell` (SPELLS.md), and the sibling commands listed there.

---

## 1. Grammar

```
design := ring* border
border := '{' rune-clusters '}' | '[' rune-clusters ']'
```

- Borders work exactly as in spells: `{ }` is a true turning, `[ ]` is a **wild wand** (§9). Rings, clusters, and nested circles are all legal — the wandwright reads every rune wherever it was written, with two exceptions: a nested `{ }` becomes a **charm** (§7), and everything after a `$` in its cluster becomes an **inscription** (§7).
- `{}` is a bare order — *"No wood was named — the maker cuts honest pine"* — and pine plus nothing solves to a Twig.
- Runes the wandwright doesn't know are noted and planed away: *"The - rune means nothing to the wandmaker — it is planed away."*

## 2. Woods

The strongest wood takes the body; the **second-strongest becomes the handle** — two-tone work, rendered and read out. Ties go to the nobler wood, then to the first written.

| Rune | Wood | Nobility | Look |
|------|------|----------|------|
| `*` | Ebon void-wood | 9 | near-black violet, star flecks in the grain |
| `!` | Goldenwood | 8 | gilded, a bright sheen streak |
| `:` | Petrified wood | 7 | grey stone, cross-banded strata |
| `''` | Dreamwood | 7 | pale opal, pastel shimmer dashes |
| `^` | Lightning-struck ash | 6 | ash grey, dark scorch streaks |
| `J` | Living greenwood | 5 | green, tiny leaf sprouts still growing |
| `B` | Cherrywood | 4 | warm orchard red |
| `G` | Oak | 3 | honest brown |
| `W` | Willow | 3 | pale cream |
| `%` | Blighted wood | 1 | sickly, cracked, weeping in the dark |
| — | Plain pine | 2 | the default when no wood is named |

**The apostrophe is dual-natured**: one `'` in the whole design is a single drop of dream — it hardens into a **gem tip** (§4). Two or more `''` are timber, and vie as dreamwood.

## 3. Shaft form

| Rune | Form |
|------|------|
| `I` | length — count = spans, from a one-span thumb-stub to a ten-span **staff** (no `I` = the maker's standard three; more than ten fall away with a note) |
| `S` | serpentine wave |
| `Z` | zigzag — a lightning-bolt shaft |
| `(` `)` | one long curve, widdershins / sunwise (they cancel each other) |
| `=` | lathe-turned dead straight |
| `&` | helical spiral carving down the shaft |
| `.` | gnarled knots (count = knots, capped at seven) |
| `R` | refined taper — thin duelist's point |

Serpent, zigzag, curve, and straight contest the **silhouette**: the strongest count wins, ties to the first written; none of them leaves the branch's natural gentle bow. Spiral, knots, and taper are carvings and stack on any silhouette.

## 4. Tips

The tip is the showpiece, rendered with a soft glow bloom in the body wood's light (§2 hues: gilded, violet, storm-blue, opaline…). **Repetition drives the glow**: lit faintly → lit steady → burning bright → blazing → blazing fit to read by (five runes).

| Rune | Tip |
|------|-----|
| `O` | glass orb, lit from within |
| `A` | faceted crystal point |
| `Y` | forked twin-tip |
| `C` | glowing crescent, horns outward |
| `'` (single) | dream-gem |
| `V` | plain tapered point, polished |
| `T` | flat seal — only when no showpiece tip is named (T does double duty, §5) |
| — | bare wood, the way the first wands were |

Orb, crystal, fork, crescent, and gem contest the tip by count (ties to first written). **A beaten orb becomes the pommel**: extra `O` runs — or an `O` that lost the tip contest — slide down the shaft and seat as a heel knob, with a note.

## 5. Handle & grip

| Rune | Grip-work |
|------|-----------|
| `T` | handle section — count = grip spans (capped at four) |
| `X` | leather cross-wrap |
| `H` | gilt guard collar at the joint (a second `H` adds a second ring) |
| `O` | pommel knob (see §4) |
| `K` | carved knuckle grips |
| `F` | charm-cord tassel swinging from the butt |
| `N` | a skull carved at the heel — a memento |
| digits | the **maker's mark**, burned beside the grip (four figures; the rest are set aside) |

Grip-work with no `T` is granted one span with a note: *"Grip-work wants a grip — the maker allows one span."*

## 6. The core

Every wand is read out with a core at its heart. It is solved, not chosen:

- A **rival wood written strong** (three-plus runes that didn't win the body) lends its signature core — `^^^` inside an oak wand seats *"a core of storm-glass"*; `***` seats *"a sliver of the starless void"*; each wood has one.
- Otherwise the body wood offers one of its own three cores, picked deterministically from the design — *"an acorn that refused to fall"*, *"moonlight, folded eight times"*, *"the patience of stone"*…
- **Wild wands** (§9) roll a fresh core from the wild list every cast: *"a hair of something that should not have been caught"*, *"a feather that fell upward"*…

## 7. Ornament

| Rune | Ornament |
|------|----------|
| `~` | gilt banding rings — count = bands, capped at seven with a note |
| `$` | **inscription** — everything after the `$` in that cluster is burned down the grain (`$LUMOS` burns LUMOS; twelve letters, the rest scatter as smoke). Rendered small along the shaft, in burn-dark on pale woods and glow-light on dark ones |
| `{ }` nested | an **attuned charm** — a glowing mote orbiting the tip (up to three; the charm takes its hue from the strongest wood written inside it) |
| `U` | runic fuller-groove channeled down the shaft, faintly alight |

## 8. Quality

Quality is solved from **wood nobility + tip + proportion + ornament balance**: a showpiece tip scores 2, a grip ratio between 2:1 and 5:1 scores best, one-to-three ornaments read as taste while six-plus draw a mutter about gaudy work, and blighted wood drags everything down. The verdict tiers:

**Twig** (<4) · **Apprentice** (<7) · **Journeyman** (<10) · **Master** (<13) · **Heirloom** (13+)

Master and Heirloom wands carry the rank in their name (*Master's Petrified Staff*, *Heirloom Ebonwood Orb-Wand*); a Twig is named a Twig whatever it hoped to be.

## 9. Wild wands — `[ ]`

A design in an uneven border is a **wild wand**: the shaft comes out crooked (a fresh wobble every cast), sparks crackle around the wood and off the tip, the core rolls fresh from the wild list, and the name gains **Wild**. The readout owns it: *"It is a wild wand — crooked, sparking, deaf to instruction."* The embed gains a **Wild** field: *no two casts alike.*

## 10. Determinism

The same design turns the same wand, down to every grain line and star fleck — reruns match pixel for pixel. The one exception is the wild border above.

## 11. Reading the result

**Description** — the maker's readout in order: wood and length → handle wood → silhouette → carvings → tip → core → grip → collar/pommel/skull/tassel/mark → bands → inscription → charms → groove → wild → *"The maker's verdict: …"* **Notes** (small text): poured pine, beaten orbs, granted grips, caps, unknown runes, gaudy work.

**Embed fields**: Wood (with any handle wood) · Length (spans and word) · Tip (with glow) · Core · Quality (· Wild). Title = the wand's name. Footer = your design; the image is the wand on velvet.

## 12. Worked examples (readouts verbatim from the harness)

| Design | Wand | Readout |
|---|---|---|
| `{!!! OO ~~~ T}` | **Heirloom Goldenwood Orb-Wand** | A wand of true goldenwood, three spans heel to tip — the maker's standard. The shaft keeps the gentle bow the branch was born with. A glass orb rides the tip, lit steady with gilded light. At its heart: a promise, notarized. The grip runs one span. Three gilt bands ring the shaft. The maker's verdict: an heirloom. Bury it with someone worthy. |
| `{**** O ~~ TT X H}` | **Heirloom Ebonwood Orb-Wand** | A wand of ebon void-wood, three spans heel to tip — the maker's standard. The shaft keeps the gentle bow the branch was born with. A glass orb rides the tip, lit faintly with violet light. At its heart: a sliver of the starless void. The grip runs two spans, cross-wrapped in leather. A gilt collar guards the joint. Two gilt bands ring the shaft. The maker's verdict: an heirloom. Bury it with someone worthy. |
| `[^^^ ZZ IIII]` | **Wild Lightning-Ash Zigzag Wand** | A wand of lightning-struck ash, four spans heel to tip — long. The shaft breaks and breaks again — a zigzag of caught lightning. The tip is left bare wood, the way the first wands were. At its heart: a hair of something that should not have been caught. It is a wild wand — crooked, sparking, deaf to instruction. The maker's verdict: sound work. It will serve a lifetime. *(wild — the core and crook roll fresh every cast)* |
| `{%%%}` | **Blighted Twig** | A wand of blighted wood, three spans heel to tip — the maker's standard. The shaft keeps the gentle bow the branch was born with. The tip is left bare wood, the way the first wands were. At its heart: something that weeps in the dark. The maker's verdict: kindling. It may yet surprise. |
| `{:::: = A U}` | **Master's Petrified Crystal-Wand** | A wand of petrified elderwood, three spans heel to tip — the maker's standard. The shaft is lathe-turned dead straight — you could sight a star along it. A faceted crystal crowns it, lit faintly with jade light. At its heart: dust of the first forest. A runic groove channels the shaft, faintly alight. The maker's verdict: master's work — wands like this choose their owners. |
| `{!!! WW O TT X}` | **Heirloom Goldenwood Orb-Wand** (willow handle) | A wand of true goldenwood, three spans heel to tip — the maker's standard. The handle is cut of pale willow — two-tone work. The shaft keeps the gentle bow the branch was born with. A glass orb rides the tip, lit faintly with gilded light. At its heart: the interest on a dragon's hoard. The grip runs two spans, cross-wrapped in leather. The maker's verdict: an heirloom. Bury it with someone worthy. |
| `{**** $NOX O T}` | **Heirloom Ebonwood Orb-Wand** (inscribed) | A wand of ebon void-wood, three spans heel to tip — the maker's standard. The shaft keeps the gentle bow the branch was born with. A glass orb rides the tip, lit faintly with violet light. At its heart: one bee from the swarm between worlds. The grip runs one span. An inscription is burned down the grain: "NOX". The maker's verdict: an heirloom. Bury it with someone worthy. |
| `{JJJ .. C F}` | **Master's Greenwood Crescent-Wand** | A wand of living greenwood, three spans heel to tip — the maker's standard. The shaft keeps the gentle bow the branch was born with. Two gnarled knots ride the grain. A leaf-green-lit crescent horns the tip. At its heart: sap that refuses to slow. The grip runs one span. A charm-cord tassel swings from the butt. The maker's verdict: master's work — wands like this choose their owners. |
| `{:::: IIIIIIIIII = U TT K}` | **Master's Petrified Staff** | A wand of petrified elderwood, ten spans heel to tip — a full staff. The shaft is lathe-turned dead straight — you could sight a star along it. The tip is sealed flat — all restraint. At its heart: the patience of stone. The grip runs two spans, carved for the knuckles. A runic groove channels the shaft, faintly alight. The maker's verdict: master's work — wands like this choose their owners. |
| `{GGGG '}` | **Oaken Gem-Wand** | A wand of honest oak, three spans heel to tip — the maker's standard. The shaft keeps the gentle bow the branch was born with. A single drop of dream hardened at the tip into a small gem. At its heart: a knot of century oak-heart. The maker's verdict: an honest first effort — it will cast. |
| `{GGG Y O}` | **Oaken Forked Wand** | A wand of honest oak, three spans heel to tip — the maker's standard. The shaft keeps the gentle bow the branch was born with. The tip forks twin — two points that never quite agree. At its heart: a nail drawn from an honest door. The grip runs one span. A knob of the same wood pommels the heel. The maker's verdict: sound work. It will serve a lifetime. |
| `{BBB SSS R}` | **Cherrywood Serpentine Wand** | A wand of orchard cherrywood, three spans heel to tip — the maker's standard. The shaft runs serpentine, wave upon wave. It tapers to a point a duelist would envy. The tip is left bare wood, the way the first wands were. At its heart: a curl of blossom-smoke. The maker's verdict: an honest first effort — it will cast. |

## 13. Staves — `/staff`

A staff is its own solver, not a long wand (a ten-span wand may still call itself a *Staff* in its name — the staffwright is not fooled). `/staff design:` reads the same grammar, woods (§2), cores (§6), charms, inscriptions, gilt bands, groove, maker's mark, and wild border — but raises a **caster-height vertical** piece: 8–12 spans, thick-shafted, rendered upright on the velvet with its crown at the top and its foot on the ground.

### 13.1 Height & shaft

- `I` — count sets the height: 8 spans (*shoulder-high*) through 12 (*gate-tall, a door's argument*); no `I` = 9, *caster-height*. More than four `I` fall away with a note.
- Silhouettes reuse the form runes (§3): `=` planed dead straight (*a pilgrim's mile-eater*), `Z` *crooked as a march uphill*, `S` serpentine, `( )` one long bow, `&` spiral carving, `.` gnarled knots, `R` draws thin toward the crown.
- `H` — **metal collar rings** segmenting the shaft (count = collars, capped at four).
- `J` — when greenwood is not the body wood, a **living vine** winds the shaft, sprouting leaves.
- `$` — the inscription **spirals** down the shaft instead of running the grain.
- `X` (grip wrapped where the hand falls), `K` (finger-rests), digits (maker's mark at the grip) all carry over.
- **Two-tone**: the second-strongest wood works the **crown** — the claw, prongs, or cradle at the head are cut from it.

### 13.2 Headpieces — the crown jewel

The head contest works like wand tips: strongest count wins, ties to first written, repetition drives the glow. Every head is rendered distinctly with its own glow bloom in the body wood's light.

| Rune | Head | On the crown |
|------|------|--------------|
| `A` | **Crystal cradle** | a raw crystal held in a claw of twisted wood |
| `O` | **Floating orb** | a glass orb caged between prongs, never quite touching |
| `L` | **Lantern cage** | an iron cage with a little fire inside, ring finial on top |
| `Y` | **Forked crown** | twin prongs; three runes or more fork it **three ways** |
| `C` | **Crescent holder** | a crescent moon held above claw mounts, horns outward |
| `'` (single) | **Gnarled knot, gem-set** | a knot ball with a gem grown into it (two-plus `''` are dreamwood timber, §2) |
| `D` | **Antler crown** | spreading tined antlers, glow snagged in the tines |
| — | bare crown, a wanderer's plain top |

### 13.3 Foot & hangings

| Rune | Work |
|------|------|
| `T` | **iron ferrule** shoeing the heel |
| `V` | **ground iron spike** |
| — | worn heel, bare wood rounded by miles |
| `F` | **hanging cords** beneath the crown — feathers and beads (count = cords, capped at three) |
| `N` | a small skull bound beneath the crown |
| nested `{ }` | charm motes orbiting the head |

### 13.4 Decorations

The staffwright's bench keeps a whole drawer of finery beyond the hangings above — every piece rendered visibly and read out in the maker's voice. Decorations count toward ornament balance (§13.5): one-to-three is taste, six-plus draws the gaudy mutter.

| Rune | Decoration | On the staff |
|------|------------|--------------|
| `+` | **Hanging bells** | gold bells on cords beneath the crown (count = bells, capped at four) — *"they chime when the road turns"* |
| `;` | **Teeth string** | a cord of old teeth and knuckle-bones clicking against the wood |
| `/` | **Prayer ribbons** | colored cloth strips tied below the crown (count = ribbons, capped at four), *"still mid-sentence"* |
| `#` | **Dreamcatcher** | a thread web — strung **between the prongs** of a forked crown, or hung as a hoop with feathers beneath any other |
| `<` | **Gem clusters** | glow-lit crystals sprouting from the shaft grain (count = clusters, capped at four) |
| `M` | **Moss & mushrooms** | soft moss quilting the wood, tiny red-capped mushrooms keeping it company |
| `E` | **Spirit wisps** | faint glowing motes drifting about the shaft with little trails (count = wisps, capped at four) — dimmer and freer than charm motes, and they pay no rent |
| `Q` | **Serpent carving** | a carved serpent climbing the shaft, scale-ticked, glow-eyed, *"patient as winter"* — in relief, pale on dark woods, dark on pale |
| `-` | **Key-ring** | a ring of old iron keys at the grip — none of them fit anything anymore |
| `@` | **Knotted rope grip** | a rope-wrapped second grip section with end knots and a frayed tail |
| `LL`+ | **Wax drippings** | a lantern crown burned two runes strong weeps cream wax rivulets down the shaft |

### 13.5 Staff quality

**Nobility + head (2) + balance (head *and* shod foot 2, either 1) + ornament balance** (§13.4 decorations included), same tiers as §8. A twig-grade staff is named a **Pole**. Staff verdicts speak in miles: *"sound timber. Mountains respect it"*, *"an heirloom. Towers are built around such staves."* Wild `[ ]` staves come out crooked, sparking, *loyal to no road*, and roll their core fresh.

**Embed fields**: Wood (with any crown wood) · Height · Head (with glow) · Core · Foot · Quality (· Wild). Title = the staff's name (*Heirloom Ebonwood Orb-Staff*, *Master's Greenwood Lantern-Staff*, *Willow Pole*).

### 13.6 Worked staff examples (readouts verbatim from the harness)

| Design | Staff | Readout |
|---|---|---|
| `{**** OO ~ F}` | **Heirloom Ebonwood Orb-Staff** | A staff of ebon void-wood, nine spans crown to heel — caster-height. The shaft keeps the honest lean of the tree it was. An orb floats caged between prongs, never quite touching, lit steady. At its heart: a sliver of the starless void. One cord swings beneath the crown — feathers and beads that remember weather. One gilt band rings the shaft. The heel is bare wood, worn round by miles. The maker's verdict: an heirloom. Towers are built around such staves. |
| `{JJJ L X T}` | **Master's Greenwood Lantern-Staff** | A staff of living greenwood, nine spans crown to heel — caster-height. The shaft keeps the honest lean of the tree it was. A lantern cage crowns it, its little fire lit faintly. At its heart: the first birdsong of an unwritten year. A leather grip is wrapped where the hand falls. The heel is shod in an iron ferrule. The maker's verdict: master's work — it will outwalk its bearer. |
| `{BBB D T 7}` | **Master's Cherrywood Antlered Staff** | A staff of orchard cherrywood, nine spans crown to heel — caster-height. The shaft keeps the honest lean of the tree it was. An antler crown spreads from the head — rose light snagged in the tines. At its heart: a drop of orchard amber. The maker's mark — 7 — is burned at the grip. The heel is shod in an iron ferrule. The maker's verdict: master's work — it will outwalk its bearer. |
| `{^^ YYY V}` | **Master's Lightning-Ash Forked Staff** | A staff of lightning-struck ash, nine spans crown to heel — caster-height. The shaft keeps the honest lean of the tree it was. The crown forks three ways — bare prongs that catch the weather. At its heart: the echo of the strike that split it. The heel ends in a ground iron spike. The maker's verdict: master's work — it will outwalk its bearer. |
| `{:::: J $WAYFARER X T}` | **Master's Petrified Staff** (vine-wrapped, inscribed) | A staff of petrified elderwood, nine spans crown to heel — caster-height. The crown is worked in living greenwood — two-tone work. The shaft keeps the honest lean of the tree it was. A living vine winds the shaft, still sprouting leaves. The crown is left bare — a wanderer's plain top. At its heart: the patience of stone. A leather grip is wrapped where the hand falls. An inscription spirals down the grain: "WAYFARER". The heel is shod in an iron ferrule. The maker's verdict: master's work — it will outwalk its bearer. |
| `{!!! IIII O ~~~ HH V F F}` | **Heirloom Goldenwood Orb-Staff** (gate-tall) | A staff of true goldenwood, twelve spans crown to heel — gate-tall, a door's argument. The shaft keeps the honest lean of the tree it was. Two metal collars segment the shaft. An orb floats caged between prongs, never quite touching, lit faintly. At its heart: a promise, notarized. Two cords swing beneath the crown — feathers and beads that remember weather. Three gilt bands ring the shaft. The heel ends in a ground iron spike. The maker's verdict: an heirloom. Towers are built around such staves. |
| `{WWW =}` | **Willow Pole** | A staff of pale willow, nine spans crown to heel — caster-height. The shaft is planed dead straight — a pilgrim's mile-eater. The crown is left bare — a wanderer's plain top. At its heart: a willow-wisp caught at dusk. The heel is bare wood, worn round by miles. The maker's verdict: a walking stick with ambitions. |
| `[%% ^^ Z L]` | **Wild Lightning-Ash Lantern-Staff** | A staff of lightning-struck ash, nine spans crown to heel — caster-height. The crown is worked in blighted wood — two-tone work. The shaft is crooked as a march uphill, and proud of it. A lantern cage crowns it, its little fire lit faintly. At its heart: a whisker plucked from a sleeping omen. The heel is bare wood, worn round by miles. It is a wild staff — crooked, sparking, and loyal to no road. The maker's verdict: sound timber. Mountains respect it. *(wild — the core and crook roll fresh every cast)* |
| `{WWW C T ++}` | **Willow Crescent-Staff** (belled) | A staff of pale willow, nine spans crown to heel — caster-height. The shaft keeps the honest lean of the tree it was. A crescent moon is held at the crown, lit faintly. At its heart: the sigh of a very patient tree. Two bells hang beneath the crown — they chime when the road turns. The heel is shod in an iron ferrule. The maker's verdict: sound timber. Mountains respect it. |
| `{** - @ L}` | **Heirloom Ebonwood Lantern-Staff** (keys, rope) | A staff of ebon void-wood, nine spans crown to heel — caster-height. The shaft keeps the honest lean of the tree it was. A lantern cage crowns it, its little fire lit faintly. At its heart: one bee from the swarm between worlds. A knotted rope binds a second grip, salt-stiff and sure. A ring of old keys hangs at the grip — none of them fit anything anymore. The heel is bare wood, worn round by miles. The maker's verdict: an heirloom. Towers are built around such staves. |
| `{!! LL T}` | **Master's Goldenwood Lantern-Staff** (waxed) | A staff of true goldenwood, nine spans crown to heel — caster-height. The shaft keeps the honest lean of the tree it was. A lantern cage crowns it, its little fire lit steady. At its heart: the interest on a dragon's hoard. Old wax has wept down from the lantern and been left. The heel is shod in an iron ferrule. The maker's verdict: master's work — it will outwalk its bearer. |
| `{'''' EE ; C}` | **Master's Dreamwood Crescent-Staff** (wisps, teeth) | A staff of dreamwood, nine spans crown to heel — caster-height. The shaft keeps the honest lean of the tree it was. A crescent moon is held at the crown, lit faintly. At its heart: the name you almost remember on waking. A string of old teeth and knuckle-bones clicks against the wood. Two spirit wisps drift about it, paying no rent. The heel is bare wood, worn round by miles. The maker's verdict: master's work — it will outwalk its bearer. |
| `{**** III OO ~~ H + / # << M E Q - @ ; 7 $VIA X T F N ..}` | **Heirloom Ebonwood Orb-Staff** (everything at once) | A staff of ebon void-wood, eleven spans crown to heel — gate-tall. The shaft keeps the honest lean of the tree it was. Two gnarled knots ride the grain. One metal collar segments the shaft. An orb floats caged between prongs, never quite touching, lit steady. At its heart: a breath held since the first dark. A leather grip is wrapped where the hand falls. A small skull is bound beneath the crown — a memento. One cord swings beneath the crown — feathers and beads that remember weather. The maker's mark — 7 — is burned at the grip. Two gilt bands ring the shaft. An inscription spirals down the grain: "VIA". A knotted rope binds a second grip, salt-stiff and sure. A carved serpent climbs the shaft, patient as winter. Two gem clusters sprout from the grain like frost. Moss quilts the old wood, and tiny mushrooms keep it company. A bell hangs beneath the crown — it chimes when the road turns. A string of old teeth and knuckle-bones clicks against the wood. A prayer ribbon is tied below the crown, still mid-sentence. A dreamcatcher hoop hangs beneath the crown, patient for nightmares. A spirit wisp drifts about it, paying no rent. A ring of old keys hangs at the grip — none of them fit anything anymore. The heel is shod in an iron ferrule. The maker's verdict: an heirloom. Towers are built around such staves. *(note: So much finery — the maker mutters about gaudy work.)* |

## 14. Extending the bench

- **Woods & cores**: `src/wand/Resolver.luau` — `Woods` (colors, nobility, glow hues, signature and seed cores), the rune maps, and `ResolveStaff` for the staff path.
- **Tips, heads & wood detail**: `TipDrawers`, `StaffHeads`, `StaffFeet`, and `WoodDetail` in `src/wand/Renderer.luau` draw them.
- **Test without Discord**: `lehua run test_wand.luau` turns every wand sample into `renders/wand-*.png` and raises every staff sample into `renders/staff-*.png`, prints the solved readouts, and proves determinism by double-rendering stable designs.
