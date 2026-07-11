# The Bindery — Complete Reference

A grimoire is a rune design bound with `/grimoire design:`. The bindery parses it with the same border grammar as spells, gathers every rune to the bench, and binds one book: cover material, cover sigil, clasps and lock, spine, page block, ribbons, chain — then passes a verdict on the whole (readouts are the binder's own words, like *"A masterwork grimoire bound in supple red-scaled dragonhide… The binder's verdict: a masterwork grimoire — shelve it under guard."*). The embed describes the book; the image is the book itself, closed on a dark shelf at a slight three-quarter angle — rounded spine to the left, page block at the fore-edge, furniture over all. Every example below was bound and its readout copied verbatim.

**Command**: `/grimoire design:` binds (200 runes). The same characters write other crafts — `/spell` (SPELLS.md), and the sibling commands listed there.

---

## 1. Grammar

```
design := ring* border
border := '{' rune-clusters '}' | '[' rune-clusters ']'
```

- Borders work exactly as in spells: `{ }` is a sound binding, `[ ]` is **cursed** (§8). Rings and clusters are all read at the bench, wherever they were written.
- A border **inside** a border is an **ex-libris** (§7): the nested circle becomes a small seal at the foot of the cover, and any sigil letters inside it mark the seal instead of the cover.
- `{}` is a blank commission — the bindery cuts honest tooled leather and sews a plain chapbook.
- Runes the bindery doesn't know are noted and left untooled: *"The Z rune means nothing to the bindery — it is left untooled."*

## 2. Cover materials

Repetition is **cure** — more of the body hide makes a finer skin (rough-cut → honest → well-cured → supple → flawless, capped at five). The strongest material takes the boards; ties go to the nobler hide. **The second-strongest becomes the trim** — the frame lines and tooling on the cover take its color.

| Rune | Cover | Nobility | Look |
|------|-------|----------|------|
| `*` | Void-Black | 10 | light-drinking black-violet, stars in the boards, a faint outer glow |
| `'` | Dream-Bound | 9 | opalescent pale skin washed with drifting pastel |
| `!` | Gilt Panels | 8 | gold-faced boards ruled into panels |
| `B` | Dragonhide | 7 | red scale rows, corner to corner |
| `^` | Storm-Touched | 6 | slate-blue hide, faint arcs crawling the boards |
| `W` | Moon-Pale Vellum | 5 | pale mottled parchment over board |
| `:` | Ancient Cracked Leather | 4 | old umber, cracks branching through the grain |
| `G` | Tooled Leather | 3 | honest brown calf, grained and poured |
| `/` | Ruinbound Ash | 2 | grey ash-hide scarred with dead script and scorch |
| `%` | Rotting Flesh | 1 | the dark corner: stitched, veined, weeping |

Tooling color is chosen to read: gilt tooling on dark hides, dark blind tooling on pale ones, trim-colored tooling when a trim is named.

## 3. Cover sigils

Ten letterforms stamp as the large front-cover emblem. **The first named takes the cover**; further sigils are set aside with a note. Repetition strikes the emboss **deeper** — *faintly tooled → cleanly tooled → struck deep → struck deep and bold → branded to the very boards* (five runes), and the stamp grows larger and heavier with it.

| Rune | Sigil | On the cover |
|------|-------|--------------|
| `C` | Circle-Seal | a graven circle-seal |
| `D` | Crossed Ward | a crossed ward |
| `X` | Woven Knot | an endless woven knot |
| `O` | Ring-Seal | a double ring-seal |
| `A` | Chevron-Blade | a chevron-blade, point to heaven |
| `S` | Serpent | a sinuous serpent |
| `Y` | World-Tree | a branching world-tree |
| `T` | Tower | a lone watchtower |
| `M` | Three Peaks | a range of three peaks |
| `E` | Unblinking Eye | an unblinking eye — it looks especially right on dream-bound skin |

## 4. Furniture

| Rune | Work |
|------|------|
| `H` | **clasp** — a metal strap with a buckle, wrapping the fore-edge (count; the bindery fits three at most) |
| `K` | a **hasp-lock** — a padlock hung at the fore-edge; the book is Locked |
| `R` | **corner caps** on all four corners |
| `U` | **spine ribs** — raised cords across the spine roll (count, up to six) |
| `I` | **page block thickness** — each Quire fattens the block (count, up to five; the fore-edge wedge grows to match) |
| `F` | **ribbon bookmarks** — trailing from the block onto the shelf: crimson, forest-green, midnight-blue, old-gold (count, up to four) |
| `.` | **bosses** — metal studs set about the frame (count, up to eight) |
| `~` | **gilt page edges** — the block gleams gold |
| `&` | **chained** — a shelf-chain stapled to the board, hanging and pooling on the shelf; the book is Chained |
| digits | the **edition figure**, tooled down the spine (up to four figures) |
| `$` | the **title** (§5) |

Clasp and lock metal follows the hide: **brass** on warm covers, **black iron** on void, storm, and ruinbound books. Pages count 60 leaves for a slim binding plus 62 per Quire (*a slim binding → a back-breaking block*).

## 5. The title — `$`

Inside a cluster, everything **after** a `$` is title text rather than runes: `{GGGG SSS $VENOM}` tools **VENOM** across the head of the cover. Each word takes its own mark — `$LEX $AUREA` reads **LEX AUREA** (spaces split clusters, so a bare second word would melt into runes). The cover holds sixteen letters; runes before the `$` in the same cluster still count as runes. A `$` with no letters behind it stays unnamed, with a note.

## 6. Quality

The bindery scores the whole commission — **material nobility × cure, sigil craft, and furniture completeness** (clasps, lock, corners, ribs, ribbons, bosses, gilt, chain, edition, title, ex-libris all count) — and passes one of five verdicts:

| Verdict | The binder's words |
|---------|--------------------|
| **shoddy chapbook** | *a shoddy chapbook, fit for kindling.* |
| **honest journal** | *an honest journal, plainly sewn and sound.* |
| **fine tome** | *a fine tome any shelf would be proud of.* |
| **masterwork grimoire** | *a masterwork grimoire — shelve it under guard.* |
| **legendary codex** | *a legendary codex — libraries have gone to war for less.* |

The verdict names the book: *Honest Leather-Bound Journal*, *Legendary Void Codex*. Chained, Locked, and Cursed take over the front of the name when they apply: *Chained Dragonhide Grimoire*, *Locked Gilt-Panelled Codex*. A bare hide binds a plain chapbook; a legendary codex wants a noble hide **and** a full bench of furniture.

## 7. The ex-libris — nested `{ }`

A border inside the border sets a small **ex-libris seal** at the foot of the cover — a double ring below the sigil. The first sigil letter written inside the nest marks the seal's field (`{!! B M {O} R H}` sets a ring-seal in it); an empty nest leaves the field blank. The readout notes it: *"An ex-libris seal is set at the foot, bearing a double ring-seal."*

## 8. The curse — `[ ]`

A design in an uneven border comes back **wrong**, and no two summonings find it the same: the cover is torn at the edges with threads hanging loose, stray leaves poke from the block, the clasps sit crooked and short, scratches cross the boards — and the curse gnaws the binder's score (the verdict rolls fresh with every summoning). The name gains **Cursed**, the embed gains a Cursed field, and the readout warns: *"The binding is torn and the threads hang loose — a curse gnaws this book, and no two summonings find it the same."*

## 9. Determinism

The same design binds the same book, down to every grain of leather and link of chain — reruns match pixel for pixel. The one exception is the curse: `[ ]` books are torn fresh with every summoning.

## 10. Reading the result

**Description** — the binder's report in order: the binding line (verdict, cure, hide, trim) → sigil and emboss depth → title → clasps and lock → corners and bosses → ribs and edition → leaves, thickness, gilt → ribbons → ex-libris → chain → curse warning → *"The binder's verdict: …"* **Notes** (small text): poured leather, set-aside sigils, overflow furniture, unknown runes.

**Embed fields**: Cover (hide, cure, trim) · Sigil (with emboss depth) · Pages (leaves, thickness, gilt) · Clasps (count and metal) · Quality — plus **Locked**, **Chained**, and **Cursed** when they apply. Title = the book's name. Footer = your design. If the binding tears mid-work (an internal error), the reply returns your design in a code block so you can copy it back.

## 11. Worked examples (readouts verbatim from the harness)

| Design | Book | Readout |
|---|---|---|
| `{GGG E H U}` | **Honest Leather-Bound Journal** | An honest journal bound in well-cured tooled leather. Its cover bears an unblinking eye, faintly tooled. A single brass clasp holds it shut. One raised cord ribs the spine. 60 leaves make a slim binding. The binder's verdict: an honest journal, plainly sewn and sound. |
| `{BBBB S HH R UUU ~ &}` | **Chained Dragonhide Grimoire** | A masterwork grimoire bound in supple red-scaled dragonhide. Its cover bears a sinuous serpent, faintly tooled. Two brass clasps hold it shut. Its corners are capped in brass. Three raised cords rib the spine. 60 leaves make a slim binding, gilt at the edges. A shelf-chain is stapled to the board — this book does not leave the library. The binder's verdict: a masterwork grimoire — shelve it under guard. |
| `{WWWW '' E ~ F}` | **Fine Pale Vellum Tome** | A fine tome bound in supple moon-pale vellum, trimmed in opaline dream-skin. Its cover bears an unblinking eye, faintly tooled. 60 leaves make a slim binding, gilt at the edges. A crimson ribbon marks the reader's place. The binder's verdict: a fine tome any shelf would be proud of. |
| `{!!!!! DD HHH K RR UUUU ~ .... 2 $LEX $AUREA}` | **Locked Gilt-Panelled Codex** | A legendary codex bound in flawless gilt panelling. Its cover bears a crossed ward, cleanly tooled. The title "LEX AUREA" is tooled across the head. Three brass clasps hold it shut, and a heavy hasp-lock besides. Its corners are capped in brass and its boards set with four bosses. Four raised cords rib the spine; the figure 2 stands at its head. 60 leaves make a slim binding, gilt at the edges. The binder's verdict: a legendary codex — libraries have gone to war for less. |
| `{***** EEEEE HH K R UUUUUU FF .... ~ & 7 III $NOX}` | **Chained Void Codex** | A legendary codex bound in flawless void-black hide that drinks the light. Its cover bears an unblinking eye, branded to the very boards. The title "NOX" is tooled across the head. Two black iron clasps hold it shut, and a heavy hasp-lock besides. Its corners are capped in black iron and its boards set with four bosses. Six raised cords rib the spine; the figure 7 stands at its head. 246 leaves make a heavy block, gilt at the edges. Two ribbons — crimson, forest-green — trail from the block. A shelf-chain is stapled to the board — this book does not leave the library. The binder's verdict: a legendary codex — libraries have gone to war for less. |
| `{:::: C U U I 3}` | **Honest Ancient Journal** | An honest journal bound in supple ancient cracked leather. Its cover bears a graven circle-seal, faintly tooled. Two raised cords rib the spine; the figure 3 stands at its head. 122 leaves make a modest block. The binder's verdict: an honest journal, plainly sewn and sound. |
| `{%%% S K &}` | **Chained Rotting Flesh-Bound Chapbook** | A shoddy chapbook bound in well-cured rotting flesh, stitched and weeping. Its cover bears a sinuous serpent, faintly tooled. A heavy hasp-lock holds it shut — the key is another matter. 60 leaves make a slim binding. A shelf-chain is stapled to the board — this book does not leave the library. The binder's verdict: a shoddy chapbook, fit for kindling. |
| `{GG K IIIII HH}` | **Locked Leather-Bound Journal** | An honest journal bound in honest tooled leather. Two brass clasps hold it shut, and a heavy hasp-lock besides. 370 leaves make a back-breaking block. The binder's verdict: an honest journal, plainly sewn and sound. |
| `{GGGG SSS $VENOM U U F}` | **Honest Leather-Bound Journal** | An honest journal bound in supple tooled leather. Its cover bears a sinuous serpent, struck deep. The title "VENOM" is tooled across the head. Two raised cords rib the spine. 60 leaves make a slim binding. A crimson ribbon marks the reader's place. The binder's verdict: an honest journal, plainly sewn and sound. |
| `{!! B M {O} R H}` | **Fine Gilt-Panelled Tome** | A fine tome bound in honest gilt panelling, trimmed in dragonhide. Its cover bears a range of three peaks, faintly tooled. A single brass clasp holds it shut. Its corners are capped in brass. 60 leaves make a slim binding. An ex-libris seal is set at the foot, bearing a double ring-seal. The binder's verdict: a fine tome any shelf would be proud of. |
| `[GG E HH F]` | **Cursed Leather-Bound Chapbook** | A shoddy chapbook bound in honest tooled leather. Its cover bears an unblinking eye, faintly tooled. Two brass clasps hold it shut. 60 leaves make a slim binding. A crimson ribbon marks the reader's place. The binding is torn and the threads hang loose — a curse gnaws this book, and no two summonings find it the same. The binder's verdict: a shoddy chapbook, fit for kindling. |
| `{}` | **Shoddy Leather-Bound Chapbook** | A shoddy chapbook bound in rough-cut tooled leather. 60 leaves make a slim binding. The binder's verdict: a shoddy chapbook, fit for kindling. |

*(The cursed example's verdict rolls fresh per summoning — yours may come back an honest journal, or worse.)*

## 12. Extending the bindery

- **Covers**: `src/grimoire/Resolver.luau` — `Materials` (colors, nobility, name words) and the rune maps.
- **Sigils**: `Sigils` in the Resolver names them; `SigilArt` in `src/grimoire/Renderer.luau` draws them.
- **Test without Discord**: `lehua run test_grimoire.luau` binds every sample into `renders/grimoire-*.png` and prints the binder's reports.
