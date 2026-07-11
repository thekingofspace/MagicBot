# The Forge — Weapons Written in Runes

A weapon is a pattern struck with `/forge pattern:`. The same rune characters that cast spells, read by a different craft entirely — this is a blade language. The smith parses the pattern, solves the finished weapon from the numbers (readouts are solved verdicts like *"The blade runs 3 spans, quenched twice, folded into true steel."*), and renders the weapon large on the dark of the forge. Every rule below is implemented — every example was forged and its readout copied verbatim.

**Grammar is the spell grammar** (see SPELLS.md §1): runes wrapped in a `{ }` border, clusters separated by spaces, 200 characters, runes pressed against the border soak into the whole billet. The parser forgives smart punctuation — `{—-IIIAG T O}` forges exactly as `{---IIIAG T O}` (a phone's long dash unfolds into two honest stock bars, so the billet forges thick instead of breaking). What the runes *mean* at the anvil is another matter.

---

## 1. The runes of the smithy

| Rune | Name | Meaning at the anvil |
|------|------|----------------------|
| `A` | Edge | head-rune of all **blade weapons**; each `A` is a pass of the honing stone (sharpness) |
| `D` | Bit | head-rune of the **axe**; count is the spread of the crescent |
| `M` | Mass | head-rune of the **hammer**; count is the weight of the block |
| `Y` | Fork | head-rune of the **spear**; count is the length of the point — 4 or more splits it into a trident |
| `V` | Point | head-rune of the **arrow**; count is the breadth of the head — 4 or more grinds a broadhead |
| `K` | Knuckle | head-rune of the **knuckles**; count is the weight of the bar stock |
| `S` | Sickle | head-rune of the **sickle**; count is the depth of the reaping crescent — 5 or more is a war sickle |
| `E` | Ward | head-rune of the **shield**; count is its size — 1 buckler, 2 round shield, 3 kite shield, 4+ tower shield |
| `J` | Flange | head-rune of the **mace**; count is the flange count — 6 or more is a great mace |
| `I` | Span | one span of blade (or of haft, on hafted weapons; of shaft, on arrows; a ply of the face, on shields) |
| `T` | Grip | one span of hilt for the hand (riveted straps, on shields) |
| `H` | Guard | a crossguard; count is its width in hands (rim banding, on shields — 2 is double-banded) |
| `O` | Pommel | a pommel (or butt-cap on hafted weapons; the center boss, on shields); count is its heft |
| `U` | Fuller | a groove down the flat — lighter, no weaker; two makes twin fullers |
| `R` | Reach | stretches the taper — longer, thinner, half a span of reach each |
| `F` | Fletch | one feather at the nock — arrows fly true fletched, and tumble bare (means nothing off the quiver) |
| `G` | Iron | the honest metal; **three or more irons fold into steel, five or more fold past steel into watered damascus** (the layer count shows in the grain) |
| `B` | Fire-forge | bronze — but laid over iron it **blues the steel** instead |
| `W` | Silver | moon-pale silver |
| `!` | Gold | soft gold chasing |
| `*` | Voidsteel | dark, light-drinking, wickedly keen |
| `:` | Ancient | metal older than the forge, green with patina |
| `^` | Storm | storm-forged, hammered under lightning |
| `%` `/` | Curse | corrupted metal — pitted, weeping, brittle |
| `(` `)` | Curve | bends the blade widdershins / sunwise — scimitars, kukris |
| `&` | Wave | ripples the edge flame-wise — the flamberge |
| `.` | Serrate | saw-teeth along the back edge (spikes, on knuckles; barbs, on arrows; spikes between the flanges, on maces; a spiked boss or studded face, on shields) |
| `<` | Moon | the point flares into a crescent — a moon-shaped tip on blades, a crescent head on arrows; elsewhere it is counted but finds no point to clip |
| `>` | Clip | clips the spine straight to the point — the Bowie profile on a knife |
| `=` | Twin-edge | both edges ground true — it cuts on the draw and the backswing |
| `_` | Hollow | hollow grind — scooped to a whisper behind the edge: lighter, keener, a touch fragile |
| `+` | Spine | a reinforced back, forged thick — tougher and heavier on the bind |
| `-` | Stock | a bar of raw stock left on the billet — each one a finger of thickness: the flat broadens toward a slab, weight and durability climb, the fine edge suffers, and a crossguard `H` is forged thick to match (a stouter haft, on hafted weapons; extra board behind the face, on shields) |
| `;` | Channel | a blood channel cut hard against the edge — narrower than any fuller, and darker work |
| `@` | Basket | guard-work over the fingers: 1 knuckle-bow, 2 ringed bow, 3+ a full basket of steel ribs |
| `'` | Jewel | a gem set in the pommel (the boss, on shields); count is its size — smart quotes land here too |
| `,` | Tassel | a battle charm on a crimson cord (a champion's tassel, on shields) |
| `#` | Counterweight | socketed behind the pommel — steadies a long blade toward the hand |
| `?` | Hook | a hook-back on axes (a **Halberd** on a 5-span haft), a dismounting lug on spears, hooked barbs on arrows, a back-spike on maces, a blade-catcher on the spine of swords |
| `N` | Memento | carves the pommel into a grinning skull (wants a pommel to carve, and says so without one) |
| `~` | Quench | one deliberate quench mark — tempers the metal, raises the craft |
| `X` | Wrap | crossed wire wound on the grip or haft (crossed cord lacing, on shields) |
| `$` | Etch | the letters after it are carved verbatim onto the flat (painted large across the face as a device, on shields) |
| digit | Proof | a proof-mark stamped at the ricasso (only the first takes) |
| `{ }` inside | Inscription | a smith's inscription rings the tang — and steadies the work |
| `[ ]` border | **Warp** | the quench goes wrong: bent silhouette, jagged edge, fresh rolls every forge (a shield warps ragged, with a crack walking the boards) |

Any other rune finds no purchase in the metal — *slag on the shop floor* — and each distinct kind of slag lowers the quality.

## 2. What the metal becomes

- The **dominant head-rune** decides the category: `A` edge (blades), `D` axe, `M` hammer, `Y` spear, `V` arrow, `K` knuckles, `S` sickle, `E` shield, `J` mace. Ties fall to whichever was struck first; no head-rune at all falls to a plain edge (with a note).
- **Length sorts the blades.** Blade spans = the `I` count. One span or less is a **knife**; two to four a **sword**; five or more a **greatsword**. An unspanned blade falls to two spans, by habit of the hand. On hafted weapons `I` is the haft instead (axes and hammers default to 3, spears to 5, sickles to a hand's haft of 1). On arrows `I` is the shaft (default 4; six or more is a *Cloth-Yard Shaft*).
- **Shape refines the name**: a curved sword is a *Scimitar*, a curved knife a *Kukri*, a waved blade a *Flamberge* (a waved knife, a *Kris*), a 4-span straight sword a *Longsword*; a 6-bit axe is a *Double Axe*, a 5-mass hammer a *Maul*, a 4-fork spear a *Trident*, a 7-span spear a *Pike*. A curved sword wearing **both** a guard `H` and a wire wrap `X` is a *Cutlass* — thin, stretched, and drawn without the working highlight down the flat. A 4-span sickle haft makes a *Scythe*; spiked knuckles are *Spiked Knuckles*; a barbed arrow a *Barbed Arrow*, a `<`-headed one a *Crescent Arrow*. A clip-pointed knife is a *Bowie Knife*; a straight sword in a double basket a *Broadsword*; a hooked axe a *Hooked Axe* (a *Halberd* on a 5-span haft); a spiked mace a *Morning Star*, six flanges a *Great Mace*, a 5-span haft a *Polemace*. Shields are named by their size (*Buckler / Round Shield / Kite Shield / Tower Shield*), and spikes prefix it (*Spiked Buckler*).
- **The strongest metal wins the billet**; every other metal present becomes accent and inlay (*"Chased with gold."*) — on shields the accents are **paint**, laid across the field in halves or quarters. No metal at all forges plain iron. The craft rules of §1 apply first: `GGG` is steel, `GGGGG` is watered damascus, `B`+`G` is blued steel.

## 3. Stats

Every forging is solved into six fields: **Weight** (spans, furniture, and the metal's density), **Sharpness** (passes of the stone + serration + the metal's temper, out of 10), **Durability** (the metal's nature + quenches + fullers, out of 10), **Balance** (see the craft rules), **Reach** (spans + stretch), and **Quality**. On a shield the Reach field reads as **Coverage** — how much of the line it walls off — the embed relabels it and the readout says so. The grinds pull their honest weight: twin edges and a reinforced spine add heft, thick stock `-` piles it on, a hollow grind and a blood channel take it away; a counterweight steadies the balance of a long blade.

Deterministic: the same pattern forges the same weapon every time — **except a warped `[ ]` forging, which rolls its lean, its jag, and its penalties fresh at every cast.**

## 4. Quality — the craft rules

The forge judges the work **poor / common / fine / masterwork / mythic**. The full weights are the smith's secret, but the shape of the judgment is honest:

- **Proportion.** A blade wants about **three spans of blade to one of grip** — inside that band the balance sings; past six-to-one it is a pole with delusions. A haft wants at least as many spans as its head has weight.
- **Completeness.** A guard, a grip, and a pommel each please the eye; a bare tang or naked fingers cost you (and earn a note).
- **Deliberate steps raise the work**: quench marks `~` (up to three count), a wire wrap `X`, a fuller `U`, a blood channel `;`, basket-work `@`, a set jewel `'`, a battle charm `,`, an etching `$`, and above all **inscriptions** — a `{ }` circle worked into the pattern.
- **A shield is judged as a wall**: boss, rim, and straps each please the eye (strapless shields ride the arm by hope alone, and the notes say so); the face wants at least as many plies as its ward has size — a thin-faced tower is one good maul from kindling.
- **Waste lowers it**: every distinct rune that lands as slag, and the warp of an uneven border.

Mythic is real and reachable — see the verified examples — but it demands proportion *and* ornament *and* a clean pattern.

## 5. Warp, curve, and edgework

- `[ ]` **warps the forging**: the silhouette bends visibly off true, the edge runs jagged, the readout names the lean in degrees, and sharpness/durability/balance take rolled penalties. Every `/forge` of a warped pattern is a different weapon.
- `(` and `)` **curve the blade** (about a hand of sweep per rune, drawn into the render); `&` waves it; `.` saws it. All three change the type name where tradition demands it.
- `<` **flares the point into a crescent** — the moon-shaped tip. On swords and knives the spine is scooped concave just behind a flared horn; on arrows the whole head is forged as a crescent, made to cut rigging and wing, not to pierce. The readout names it plainly.
- `>` **clips the point** the other way — the spine is cut straight (faintly concave) to the tip with a false-edge glint, and a clipped knife is named a *Bowie Knife*.
- **The grinds are drawn, not just counted**: `=` puts the edge sheen on both sides, `_` scoops shadowed hollows either side of a bright median ridge, `+` lays a heavy stripe down the back, `;` cuts a thin dark channel hard against the true edge — none of them are the fuller, and the readout keeps them straight.
- **Damascus shows its grain**: five or more `G` fold the billet past steel, and the render draws the watered layers — wavy light-and-dark lanes rippling the length of the flat — while the readout counts the folds and the layers (`2^folds`, capped at 256).
- **Etchings** (`$WOLF`) are carved letter-by-letter down the flat, engraved dark with a light under-cut. **Proof digits** are stamped in a ring at the ricasso. **Inscriptions** (nested `{ }`) are reported on the tang, their words joined with `·`.

## 6. Verified forgings (readouts verbatim from the harness)

| Pattern | Verdict |
|---|---|
| `{IIIAG TTO}` | ⚔️ **Iron Sword** — The blade runs 3 spans, iron through and through. The edge took 1 pass of the stone — a working edge, no more. The grip takes 2 spans; a round pommel seats the tang. Common work — it will serve. |
| `{IIIAAAG H T O U}` | ⚔️ **Masterwork Iron Sword** — The blade runs 3 spans, iron through and through. The edge was honed keen — 3 passes of the stone. A fuller runs the flat — lighter, no weaker. A crossguard of 1 hand shields the fist; the grip takes 1 span; a round pommel seats the tang. Masterwork — the balance sings in the hand. |
| `{IAAAW T O}` | 🗡️ **Silver Dagger** — The blade runs 1 span, of moon-pale silver. The edge was honed keen — 3 passes of the stone. |
| `{IIIIAAAGGG H T O ~~}` | ⚔️ **Fine Steel Longsword** — The blade runs 4 spans, quenched twice, folded into true steel. |
| `{DDDW III X O}` | 🪓 **Fine Silver Axe** — The bit spreads 3 hands of silver on a haft of 3 spans. The haft is wound in crossed wire; a silver butt-cap weights the heel. Fine work — a keeper. |
| `{MMMMMG IIIII X}` | 🔨 **Iron Maul** — The head is a 5-weight block, iron through and through, on a haft of 5 spans. |
| `{YYYYW IIIIII O}` | 🔱 **Silver Trident** — The point runs 4 hands long, of moon-pale silver, atop a shaft of 6 spans. A silver butt-cap weights the heel. |
| `{IIIAAG))) H T O}` | ⚔️ **Fine Iron Scimitar** — It sweeps sunwise — a drawing cut, 3 hands of bend. |
| `{IAAA(( T O}` | 🗡️ **Iron Kukri** — The blade runs 1 span… It sweeps widdershins — a drawing cut, 2 hands of bend. |
| `{IIIIIAAA^^ HH TT OO U ~~}` | ⚔️ **Masterwork Storm-Forged Greatsword** — The blade runs 5 spans, quenched twice, hammered under a living storm. The edge was honed keen — 3 passes of the stone. |
| `[IIIIIAA&&* HH TT OO]` | ⚔️ **Warped Fine Voidsteel Great Flamberge** — The edge ripples flame-wise down its length… The quench warped it — it leans 7° off true and the edge runs jagged. *(rolls fresh every forge)* |
| `{IIIAAAG H T O U ~~ X $WOLF {ANVIL}}` | ⚔️ **Mythic Iron Sword** — …wound in crossed wire; a round pommel seats the tang. Etched on the flat: "WOLF". A smith's inscription rings the tang: "ANVIL". Mythic work — the forge will not see its like again. |
| `{IIIA% T}` | ⚔️ **Corrupted Sword** — The blade runs 3 spans, of pitted, cursed metal that weeps at the edges. |
| `{}` | ⚒️ **Iron Ingot** — An unworked ingot — no shaping rune ever struck it. The anvil waits. |

### The quiver — arrows (`V`)

Ammunition, not armament: featherweight (the scales bottom out at a tenth of a pound, not a third), fragile in the shaft, and its reach belongs to the bow — the readout says so honestly and the Reach field stays at half a span. `I` is the shaft, `F` the fletching (bare shafts tumble, and the notes say so), `O` cuts the nock, `X` whips the head on with cord, `.` files in barbs, `<` forges a crescent head. A shaft wants at least twice the spans its head has fingers.

| Pattern | Verdict |
|---|---|
| `{VVG IIII FF O}` | 🏹 **Fine Iron Arrow** — The shaft runs 4 spans; the head is ground 2 fingers broad, iron through and through. Fletched with 2 feathers, set true at the nock. A cut nock seats the string. Reach is the bow's affair — in the hand it is half a span of trouble. Fine work — a keeper. *(weight 0.3 lb, reach 0.5)* |
| `{VVW IIIIII FFF O ~}` | 🏹 **Fine Silver Cloth-Yard Shaft** — The shaft runs 6 spans, quenched once; the head is ground 2 fingers broad, of moon-pale silver. Fletched with 3 feathers, set true at the nock. … |
| `{VVVVB IIIIIIII FF O ~}` | 🏹 **Fine Bronze Broadhead Arrow** — The shaft runs 8 spans, quenched once; the head is ground 4 fingers broad, cast of fire-forged bronze. … |
| `{VVG IIII FF O <}` | 🏹 **Fine Iron Crescent Arrow** — …The head is forged as a crescent moon — made to cut, not to pierce. … |

### The fist — knuckles (`K`)

Four finger-rings and a palm bar, no blade at all: sharpness sits at nil unless `.` raises spikes over the rings. `T` pads the bar for the palm (a bare bar earns a note), `X` winds it in wire, and the proportion rule wants 2–4 weights of stock — a fist is not a sledge. Weight, durability, and balance carry the verdict; struck in `B` bronze it wears the classic brass look.

| Pattern | Verdict |
|---|---|
| `{KKKB T X}` | 👊 **Fine Bronze Knuckles** — Four finger-rings and a palm bar of 3-weight stock, cast of fire-forged bronze. The palm bar is padded for the fist, wound in crossed wire. Its reach ends where the fist does. Fine work — a keeper. *(sharp 0/10, balance 92%)* |
| `{KKKG.. T ~}` | 👊 **Fine Iron Spiked Knuckles** — …Spikes stand proud of the rings (2 to the row). The palm bar is padded for the fist. … |
| `{KKB T X ~~ $OOF {IRONJAW}}` | 👊 **Masterwork Bronze Knuckles** — …Etched on the flat: “OOF”. A smith's inscription rings the tang: “IRONJAW”. Masterwork — the balance sings in the hand. |

### The harvest — sickles (`S`)

A short haft and a deeply hooked crescent meeting at a sharp point — the inward reaping curve, nothing like the outward bulge of an axe bit or the gentle sweep of a `)` scimitar. (`C` was weighed for the crescent and left as slag on purpose — the smith reads `S`.) The haft defaults to a single hand-span; a haft of 4 or more raises the blade onto a pole as a **Scythe**. Sickles take the hafted furniture — butt-cap `O`, wire `X`, hand-stop `H` — plus `.` saw-teeth on the inner edge and `$` etchings down the haft. Proportion wants a haft short (≤2) or fully pole (≥4); the in-between is neither fish nor fowl.

| Pattern | Verdict |
|---|---|
| `{SSSG II O ~}` | 🌙 **Iron Sickle** — The crescent hooks inward 3 hands deep, iron through and through, on a haft of 2 spans, quenched once. An iron butt-cap weights the heel. Common work — it will serve. |
| `{SSSSW IIIII O X}` | 🌙 **Fine Silver Scythe** — The crescent hooks inward 4 hands deep, of moon-pale silver, on a haft of 5 spans. The haft is wound in crossed wire; a silver butt-cap weights the heel. Fine work — a keeper. |
| `{SSS^ II O X $REAP}` | 🌙 **Fine Storm-Forged Sickle** — …Etched on the flat: “REAP”. Fine work — a keeper. |
| `[SSS: II O]` | 🌙 **Warped Ancient Sickle** — …The quench warped it — it leans 5° off true and the edge runs jagged. *(rolls fresh every forge)* |

### The moon tip and the cutlass (`<`, `H`+`X` on a curve)

| Pattern | Verdict |
|---|---|
| `{IIIAAG H T O <}` | ⚔️ **Fine Iron Sword** — …The point flares into a crescent — a moon-shaped tip. … |
| `{IIIAAAW))) RR H T O X ~ <}` | ⚔️ **Masterwork Silver Cutlass** — The blade runs 3 spans, quenched once, of moon-pale silver. The edge was honed keen — 3 passes of the stone. It sweeps sunwise — a drawing cut, 3 hands of bend. The point flares into a crescent — a moon-shaped tip. Reach-drawn — the taper was stretched 2 hands past its weight. A crossguard of 1 hand shields the fist; the grip takes 1 span, wound in crossed wire; a round pommel seats the tang. Masterwork — the balance sings in the hand. |

### The wall — shields (`E`)

Not a weapon but a promise: face-on in the render — boss, banded rim, plank grain (a buckler is all steel), strap plates behind the boss, and the field painted in the accent metals, halved for one, quartered for two. Sharpness sits at nil unless `.` grinds the boss to a spike (or studs a bossless face); `I` lays up the plies, and the proportion rule wants at least as many plies as the ward has size. Reach reads as **Coverage**. A warped shield goes ragged at the rim and a crack walks the boards.

| Pattern | Verdict |
|---|---|
| `{EG T O}` | 🛡️ **Fine Iron Buckler** — A buckler scarcely wider than the fist behind it, iron through and through. An iron boss stands proud at the center; riveted straps take the forearm. Raised well, it walls off 1.5 spans of the line. Fine work — a keeper. *(sharp 0/10, coverage 1.5)* |
| `{EEG III H T O}` | 🛡️ **Fine Iron Round Shield** — A round shield a full arm's-length across, iron through and through. The face is laid up 3 plies thick. An iron boss stands proud at the center; the rim is banded in iron, riveted fast; riveted straps take the forearm. Raised well, it walls off 2.5 spans of the line. Fine work — a keeper. |
| `{EEEW III H T O $ROSE}` | 🛡️ **Masterwork Silver Kite Shield** — A kite shield running shoulder to knee, of moon-pale silver. …The device “ROSE” is painted large across the face. Masterwork — the balance sings in the hand. |
| `{EEEEG IIIII HH T O ~~ X}` | 🛡️ **Masterwork Iron Tower Shield** — A tower shield that walls the bearer boot to chin, quenched twice, iron through and through. The face is laid up 5 plies thick. An iron boss stands proud at the center; the rim is double-banded in iron, riveted fast; riveted straps take the forearm, laced with crossed cord. Raised well, it walls off 4.5 spans of the line. Masterwork — the balance sings in the hand. *(weight 7.3 lb, dur 9.7/10)* |
| `{EEG III H T O ! ^}` | 🛡️ **Fine Iron Round Shield** — …The field is laid with gold leaf. The field is painted storm-grey, streaked with lightning. … |
| `{E* .. T O}` | 🛡️ **Fine Voidsteel Spiked Buckler** — …The boss is drawn out into a wicked spike. … |
| `[EEEEG IIII H T O]` | 🛡️ **Warped Fine Iron Tower Shield** — …The forging warped it — the face leans 11° off true and a crack walks the boards. *(rolls fresh every forge)* |

### The flanged head — maces (`J`)

A hafted weapon like the axe and hammer, so the haft wants as many spans as the head has flanges, and the butt-cap, wire, and hand-stop all apply. The head renders as a radiating crown of flanges around a riveted core with a top spike; `.` stands spikes between the flanges and names it a *Morning Star*; `?` adds a back-spike for the seams in plate.

| Pattern | Verdict |
|---|---|
| `{JJJG III T O}` | ⚙️ **Iron Mace** — The head bristles with 3 flanges, iron through and through, on a haft of 3 spans. An iron butt-cap weights the heel. Common work — it will serve. *(weight 3.8 lb, sharp 1.9/10)* |
| `{JJJJ* III ... O}` | ⚙️ **Voidsteel Morning Star** — The head bristles with 4 flanges, of light-drinking voidsteel, on a haft of 3 spans. Spikes stand out between the flanges (3 to the round). A voidsteel butt-cap weights the heel. Common work — it will serve. |
| `{JJJJJJB IIIIII X O}` | ⚙️ **Fine Bronze Great Mace** — The head bristles with 6 flanges, cast of fire-forged bronze, on a haft of 6 spans. The haft is wound in crossed wire; a bronze butt-cap weights the heel. Fine work — a keeper. *(weight 8.1 lb)* |

### The grind and the furniture — the modifier wave

| Pattern | Verdict |
|---|---|
| `{IAAG> T O +}` | 🗡️ **Iron Bowie Knife** — …The spine is clipped straight to the point — a fighting point, quick to turn. The spine is forged thick — a reinforced back that will not snap on the bind. … |
| `{IIIAAAGGGGG H T O U ~~}` | ⚔️ **Masterwork Damascus Sword** — The blade runs 3 spans, quenched twice, folded past steel into watered damascus. The billet was folded 5 times — 32 layers of watered grain ripple down the flat. The edge was honed keen — 3 passes of the stone. A fuller runs the flat — lighter, no weaker. A crossguard of 1 hand shields the fist; the grip takes 1 span; a round pommel seats the tang. Masterwork — the balance sings in the hand. *(sharp 7.6/10, dur 10/10)* |
| `{IIIAAAGGGGG))) H T O X @@ ~ '}` | ⚔️ **Masterwork Damascus Cutlass** — …It sweeps sunwise — a drawing cut, 3 hands of bend. A crossguard of 1 hand shields the fist; a ringed knuckle-bow cages the fingers; the grip takes 1 span, wound in crossed wire; a round pommel seats the tang; a cut jewel is set in the pommel. Masterwork — the balance sings in the hand. |
| `{IIIAAG @@ T O =}` | ⚔️ **Fine Iron Broadsword** — …Both edges are ground true — it cuts on the draw and the backswing. A ringed knuckle-bow cages the fingers; … |
| `{IIAAAW _ T O ;}` | ⚔️ **Silver Sword** — …Hollow-ground — the flat is scooped to a whisper behind the edge. A blood channel is cut hard against the edge — narrower than any fuller, and darker work. … |
| `{IIIIIIAAG++ HH TT OO #}` | ⚔️ **Fine Iron Greatsword** — …The spine is forged thick — a reinforced back that will not snap on the bind. …a counterweight is socketed behind the pommel. *(balance 99%)* |
| `{IIIAAG))) H T O N ,}` | ⚔️ **Masterwork Iron Scimitar** — …a pommel carved as a grinning skull seats the tang; a battle charm swings from the hilt on a crimson cord. … |
| `{DDDG IIIII ? O}` | 🪓 **Iron Halberd** — The bit spreads 3 hands of iron on a haft of 5 spans. A hook curls from the back of the bit — made to pull shields down and riders from the saddle. … |
| `{VV* IIII FF O .. ?}` | 🏹 **Fine Voidsteel Barbed Arrow** — …Barbs are filed into the head (2 to the side) — it will not draw back out. The barbs are hooked back on themselves — cutting them out is butcher's work. … |

### The thick stock (`-`)

Each `-` is a bar of raw stock the smith declines to grind away: the count is the spine thickness in fingers. The render broadens the whole flat (four bars or more and the silhouette is a slab cleaver, blunt-snouted and wall-shadowing), weight climbs substantially, durability climbs, sharpness slips — you cannot hone a wall — and the balance drifts down the blade. **The guard follows the billet**: a thick-stocked sword wearing an `H` gets a visibly chunkier crossguard bar, and the readout says so. On hafted weapons the stock goes into the haft; on shields, into the boards. (Slag no more: `-` was once swept off the shop floor, and old patterns that carried it now simply forge thicker.)

| Pattern | Verdict |
|---|---|
| `{III--AG T O}` | ⚔️ **Fine Iron Sword** — The blade runs 3 spans, iron through and through. The billet was left thick-stocked — 2 fingers of spine behind the edge. The edge took 1 pass of the stone — a working edge, no more. The grip takes 1 span; a round pommel seats the tang. Fine work — a keeper. *(weight 3.3 lb, sharp 2.5/10, dur 7/10)* |
| `{III-----AAG T O}` | ⚔️ **Fine Iron Sword** — The blade runs 3 spans, iron through and through. The billet was left thick-stocked — 5 fingers of spine behind the edge, a slab that owes more to the cleaver than the fencer. The edge took 2 passes of the stone — a working edge, no more. The grip takes 1 span; a round pommel seats the tang. Fine work — a keeper. *(weight 4.9 lb, dur 8.5/10)* |
| `{III---AAG HH T O}` | ⚔️ **Fine Iron Sword** — The blade runs 3 spans, iron through and through. The billet was left thick-stocked — 3 fingers of spine behind the edge; the guard is forged to match, a bar as thick as the blade it wards. The edge took 2 passes of the stone — a working edge, no more. A crossguard of 2 hands shields the fist; the grip takes 1 span; a round pommel seats the tang. Fine work — a keeper. |
| `{DDDG III--- X O}` | 🪓 **Fine Iron Axe** — The bit spreads 3 hands of iron on a haft of 3 spans. The billet was left thick-stocked — the haft is turned 3 fingers stout. The haft is wound in crossed wire; an iron butt-cap weights the heel. Fine work — a keeper. |
| `{EEEEG IIIII-- HH T O}` | 🛡️ **Fine Iron Tower Shield** — …The face is laid up 5 plies thick. The billet was left thick-stocked — 2 fingers of board behind the face. …the rim is double-banded in iron, riveted fast… *(weight 8.2 lb, dur 9.3/10)* |

## 7. Reading the result

**Title** — the weapon named from its own properties: warp first, then quality (Crude / Fine / Masterwork / Mythic), then the metal, then the type (*Warped Fine Voidsteel Great Flamberge*). **Description** — the smithy's solved verdict, in forging order: the body line (spans, quenches, metal) → edge → sweep/wave/teeth → stretch → fullers → furniture → accents → etchings → inscriptions → proof-mark → warp → the quality verdict. **Notes** (small text): missing guards, bare tangs, filed-off numerals, and every rune that fell as slag. **Fields**: Weight · Sharpness /10 · Durability /10 · Balance % · Reach (spans) · Quality. Footer = your pattern; the image is the weapon itself — tapered, curved, warped, etched, and colored by its metal.

## 8. Extending the forge

- **Rune meanings, materials, stats, quality**: `src/forge/Resolver.luau` (materials are a table — add a metal in one entry).
- **The drawing**: `src/forge/Renderer.luau` — each category has its own builder on a shared bent-axis frame.
- **Test without Discord**: `lehua run test_forge.luau` forges every sample into `renders/forge-*.png` and prints the solved verdicts.
