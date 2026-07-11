# Soup System — Complete Reference

A soup is a rune recipe ladled with `/soup recipe:`. The bot parses it with the same border grammar as spells, solves what the bowl holds (readouts are solved prose, never raw runes), and renders the bowl itself — glazed ceramic at a three-quarter angle on a dark table, liquid, ingredients, steam, and a spoon. Every rule below is implemented; every example was cooked and its readout copied verbatim.

Soup is **humble magic**: it feeds people, nothing more. The one dark corner of the kitchen is the pot left too long to itself — `%` spoilage draws flies.

---

## 1. Grammar

```
recipe := rim* border
border := '{' cluster* '}' | '[' cluster* ']'
rim    := runes pressed against the border — they go into the pot all the same
side   := a border inside the border — a small plate or cup served beside the bowl
```

- Same parser as `/spell`: 200 characters, case-insensitive, spaces separate clusters, smart punctuation is folded back into runes before cooking (an em-dash becomes `--` — two chill marks).
- `[ ]` is the **chaotic ladle** (§8). Mismatched borders, stray runes, and missing borders fail exactly as spells do.
- `{}` is a valid recipe: *Dishwater — plain water, ladled with conviction.*

## 2. Stocks

Every run of a stock rune adds its count to that stock's strength. The **strongest stock is the base** (ties go to whichever was written first).

| Rune | Stock | Reads as | Hue |
|------|-------|----------|-----|
| `B` | Ember | hearty tomato, fire-warm | hearth-red tomato |
| `W` | Clear | honest broth, nothing hidden | clear as rainwater |
| `G` | Forest Mushroom | earthy, root-deep | earthy root-brown |
| `J` | Green Garden | bright herbs torn small | garden herb-green |
| `!` | Golden Saffron | chicken stock threaded with saffron | lantern gold |
| `'` | Lavender Dream | dreamy, faintly strange — it hums | dreamy lavender-cream |
| `%` | Rancid | **spoilage** — the dark corner (§7) | gray-green murk |
| `:` | Deep Miso | fermented, aged until patient | miso-deep umber |
| `*` | Void-Ink | squid ink; light does not come back out | squid-ink black |

**The half rule**: a second stock joins the pot only if it holds **at least half** the base's strength — then it cuts the hue in the glass and earns a note (*"Cut with a forest mushroom stock — the two get along."*). A third stock always waits its turn. No stock at all is water — dishwater if nothing floats in it, a *Watery Soup* if something does.

## 3. Ingredients

Letter runes float in the bowl and are **drawn in the render**, one piece per rune. The readout counts them in words.

| Rune | Ingredient | In the bowl |
|------|-----------|-------------|
| `O` | noodle rings | wheat-colored rings, liquid showing through the hole |
| `I` | noodle strands | long pale strands lying across the surface |
| `D` | dumplings | plump pleated buns, pinched at the crown |
| `F` | fish | salmon slices, cream-striped |
| `C` | carrot coins | bright orange coins with a paler core |
| `L` | leek rings | green rings, pale-hearted |
| `M` | meat | irregular browned chunks |
| `E` | egg | soft-boiled halves, yolk up |
| `A` | star anise | eight-pointed dark pods |
| `T` | tofu | pale tilted cubes |

The render plates up to 10 of a kind and 22 pieces in all — the rest are in there somewhere. Each piece casts a waterline shadow and sits larger the nearer it floats.

## 4. Temperature

| Rune | Meaning |
|------|---------|
| `^` | heat — more `^`, more steam ribbons in the render |
| `-` | chill — condensation beads on the ceramic, running in little rivers |

Heat and chill fight: net `^` ≥ 3 is **piping hot**, 1–2 is **steaming**, net `-` 1–2 is **chilled**, ≥ 3 is **ice-cold**. A perfect tie is **lukewarm** (*"the kitchen argued about the fire and nobody won"*). Neither mark = **table-warm**, no ceremony about it. A chilled Green Garden or Ember bowl is named a **Gazpacho**.

## 5. Seasoning & structure

| Rune | Meaning | Exact behavior |
|------|---------|----------------|
| `~` | Sweeten | honey; thin gold threads drizzled on the surface |
| `.` | Pepper | visible flecks — over everything, the way pepper actually lands; more than 2 and it *bites back* |
| `&` | Cream | a white spiral drawn through the surface; with fish it names a **Bisque**, alone a **Velouté** |
| `(` `)` | Stir | a lazy spiral left in the surface |
| digit | Simmer | hours in the pot, summed (`44` = 8 hours); deepens the color, enriches the readout, and cooks off taint (§7) |
| `H` | Thicken | one step up the viscosity dial per rune (§5a) |
| `R` | Thin | one step down the viscosity dial per rune (§5a) |
| `$` | Chef | the rest of the cluster is the chef's name, chalked on a little board by the bowl (10 letters fit; the first `$` wins) |
| anything else | Scraps | inert — *"the kitchen cannot place K — it sinks quietly to the bottom"* |

Three or more noodles (`O`/`I`) in a plain soup make it a **Noodle Soup**. **Serves** = 1 + one per 6 pieces + 1 for a stew, capped at a table of five.

### 5a. The viscosity dial

`H` and `R` fight; the net count sets the body, and every step changes both the render and the readout. The embed carries a **Body** field with the level's name.

| Net | Body | Readout | In the render |
|-----|------|---------|---------------|
| `RRR`+ | **watery** | *Thinned to the edge of being water — the spoon comes up with little more than a memory of flavor.* | palest, most translucent surface; the bowl's bottom glows through; ingredients sit small and clearly visible under the broth; brightest gleam. Names a **Thin … Broth**, −1 quality, and tends to **dishwater** if nothing else is going on |
| `RR` | **thin** | *Drawn down to a thin consommé, clear enough to read the maker's mark through.* | translucent; maker's mark showing; strong gleam. A **Consommé** |
| `R` | **light** | *Light-bodied — it slips off the spoon without a second thought.* | faintly translucent, brighter shine. A **Consommé** |
| — | **honest** | (no line) | the default surface |
| `H` | **thick** | *Thickened to a proper stew — the ladle drags through it.* | opaque and matte, dappled; ingredients sink to their waterlines. A **Stew**, +1 serving |
| `HH` | **spoon-standing** | *Thick enough to stand a spoon in.* | more dapple, surface lumps appear, ingredients half-sunk |
| `HHH`+ | **stew-solid** | *Stew-solid — less a soup than a landscape with gravy.* | fully matte and lumpy; ingredients ride deep, more mound than float |

Every step deeper into `H` sinks the pieces further and roughens the surface; every step into `R` pales the hue, thins the opacity, and shrinks what floats until the broth closes over it.

## 6. Quality

Quality is solved from the whole composition — stock strength, ingredient variety, a balanced count of pieces, seasoning, simmer time, deliberate temperature, deliberate body. Watery nothing is **dishwater**; a spoiled bowl is a **health hazard** no matter what else went in.

| Tier | Verdict |
|------|---------|
| dishwater | Dishwater — the spoon sinks without hope. |
| poor | A poor bowl — it fills a stomach and apologizes the whole way down. |
| honest | An honest bowl — plain, warm, and welcome after a long day. |
| hearty | A hearty bowl — the kind that ends arguments and starts naps. |
| exquisite | An exquisite bowl — the table goes quiet at the first spoonful. |
| legendary | A bowl to remember — they will tell of this soup in winters to come. |
| health hazard | A health hazard — the flies found it first. Send it back and burn the pot. |

**Legendary** takes the full craft — a strong stock, five kinds of ingredients, seasoning, a long simmer, deliberate heat and body. A legendary bowl wears the word in its name: *Legendary Ember Stew*.

## 7. Spoilage

`%` is the taint. Measured against the base stock's strength:

| Taint | Result |
|---|---|
| less than the base | a **sour whiff** note and a hard quality penalty — eat it today or not at all |
| ≥ the base (or no base) | the whole bowl turns: **Rancid Soup**, gray-green murk, scum on the surface, stink lines instead of steam, and **flies** circling the rim |

**The simmer fights the taint**: every 2 hours of simmer cook away 1 point of `%`. `{!!!! %% 44}` boils the rot into confession and serves clean — *"Whatever had turned (2), the long simmer cooked it clean away."*

## 8. The chaotic ladle

An uneven border `[ ]` serves **Mystery Soup**: the stock hue and the ingredients roll fresh with every serving — the readout tells you what the ladle dredged up today. Seasoning, temperature, simmer, and body are still yours; the quality is judged on whatever surfaced. A `[ ]` **inside** a `{ }` rolls just the side plate. Everything else about a recipe is deterministic: the same runes always plate the same bowl, pixel for pixel.

## 9. Sides and the chef

- A border **inside** the border is a **side dish**: its best ingredient goes on a small plate beside the bowl (`{!!! OOO {DD}}` → *On the side: a small plate of two plump dumplings.*), rendered and all. A nested border holding only stock becomes **a little cup of broth** in the bowl's hue. An empty `{}` inside is *an empty plate — the kitchen's little joke*. The table fits one side; the rest wait in the kitchen.
- `$NAME` chalks the chef's name on a slate board in front of the bowl — hand-written, underlined, ten letters at most.

## 10. Verified bowls

Readouts copied verbatim from the kitchen harness (`lehua run test_soup.luau`).

**`{!!! R}`** — the title bowl.
> **Golden Saffron Consommé** — A golden chicken stock threaded with saffron — rich as a harvest evening. Nothing floats in it — the broth stands alone. Served table-warm, no ceremony about it. Unseasoned — the salt sits on the table if you must. Light-bodied — it slips off the spoon without a second thought. An honest bowl — plain, warm, and welcome after a long day.

**The viscosity ladder** — the same pot at five settings (`{GGG MM CC …}`), body line and name verbatim:

| Recipe | Name | Body line |
|--------|------|-----------|
| `{GGG MM CC RRR}` | **Thin Forest Mushroom Broth** | Thinned to the edge of being water — the spoon comes up with little more than a memory of flavor. |
| `{GGG MM CC RR}` | **Forest Mushroom Consommé** | Drawn down to a thin consommé, clear enough to read the maker's mark through. |
| `{GGG MM CC R}` | **Forest Mushroom Consommé** | Light-bodied — it slips off the spoon without a second thought. |
| `{GGG MM CC H}` | **Forest Mushroom Stew** | Thickened to a proper stew — the ladle drags through it. |
| `{GGG MM CC HH}` | **Forest Mushroom Stew** | Thick enough to stand a spoon in. |
| `{GGG MM CC HHHH}` | **Forest Mushroom Stew** | Stew-solid — less a soup than a landscape with gravy. |

**`{!! RRR}`** — watery nothing, by choice.
> **Dishwater** — A golden chicken stock threaded with saffron — rich as a harvest evening. Nothing floats in it — the broth stands alone. Served table-warm, no ceremony about it. Unseasoned — the salt sits on the table if you must. Thinned to the edge of being water — the spoon comes up with little more than a memory of flavor. Dishwater — the spoon sinks without hope.

**`{BBBB MMM CC L H ^^ . 3}`** — a real supper.
> **Ember Stew** — A hearty tomato stock, fire-warm and hearth-red — it tastes like the last hour of a long winter. Adrift in it: three chunks of stewed meat, two carrot coins, and a leek ring. Served steaming hot, the first spoonful a small act of courage. Dusted with cracked pepper. Simmered three hours, until the flavors stopped arguing. Thickened to a proper stew — the ladle drags through it. An exquisite bowl — the table goes quiet at the first spoonful.

**`{BBBBBB MMM CC LL OO E ^^ .. & 44 H}`** — the full craft in one pot.
> **Legendary Ember Stew** — A hearty tomato stock, fire-warm and hearth-red — it tastes like the last hour of a long winter. Adrift in it: three chunks of stewed meat, two carrot coins, two leek rings, two noodle rings, and a soft-boiled egg half. Served steaming hot, the first spoonful a small act of courage. Dusted with cracked pepper; a swirl of cream drawn through the surface. Slow-simmered eight hours — the pot did the thinking. Thickened to a proper stew — the ladle drags through it. A bowl to remember — they will tell of this soup in winters to come.

**`{WWW}`** — watery nothing, honestly served.
> **Dishwater** — A clear broth, honest all the way to the bottom of the bowl. Nothing floats in it — the broth stands alone. Served table-warm, no ceremony about it. Unseasoned — the salt sits on the table if you must. Dishwater — the spoon sinks without hope.

**`{JJJJ CC TT -- .}`** — cold on purpose.
> **Green Garden Gazpacho** — A green garden stock, bright with herbs torn small over the pot. Adrift in it: two carrot coins and two tofu cubes. Served chilled — the bowl sweats cold beads onto the table. Dusted with cracked pepper. A hearty bowl — the kind that ends arguments and starts naps.

**`{:::: IIII OO ^ 44}`** — ramen from the dark shelf.
> **Deep Miso Noodle Soup** — A fermented stock, miso-deep — aged in the dark until it learned patience. Adrift in it: four long noodle strands and two noodle rings. Served steaming hot, the first spoonful a small act of courage. Unseasoned — the salt sits on the table if you must. Slow-simmered eight hours — the pot did the thinking. An exquisite bowl — the table goes quiet at the first spoonful.

**`{''' EE &}`** — the strange one.
> **Lavender Dream Velouté** — A lavender-cream stock, dreamy and faintly strange — it hums when nobody is looking. Adrift in it: two soft-boiled egg halves. Served table-warm, no ceremony about it. A swirl of cream drawn through the surface. An honest bowl — plain, warm, and welcome after a long day.

**`{!!! FF &&}`** — cream meets fish.
> **Golden Saffron Bisque** — A golden chicken stock threaded with saffron — rich as a harvest evening. Adrift in it: two slices of fish. Served table-warm, no ceremony about it. A swirl of cream drawn through the surface. An honest bowl — plain, warm, and welcome after a long day.

**`{%%%% MM}`** — send it back.
> **Rancid Soup** — Something in this pot turned days ago and has been served anyway. Adrift in it, unfortunately: two chunks of stewed meat. Served table-warm, no ceremony about it. Unseasoned — the salt sits on the table if you must. A health hazard — the flies found it first. Send it back and burn the pot.

**`{!!!! %% 44}`** — the simmer saves it.
> **Golden Saffron Soup** — A golden chicken stock threaded with saffron — rich as a harvest evening. Nothing floats in it — the broth stands alone. Served table-warm, no ceremony about it. Unseasoned — the salt sits on the table if you must. Slow-simmered eight hours — the pot did the thinking. A hearty bowl — the kind that ends arguments and starts naps. *Whatever had turned (2), the long simmer cooked it clean away.*

**`{!!! OOO {DD}}`** — with a side.
> **Golden Saffron Noodle Soup** — A golden chicken stock threaded with saffron — rich as a harvest evening. Adrift in it: three noodle rings. Served table-warm, no ceremony about it. Unseasoned — the salt sits on the table if you must. On the side: a small plate of two plump dumplings. An honest bowl — plain, warm, and welcome after a long day.

**`[OO CC]`** — the chaotic ladle (this serving; yours will differ).
> **Mystery Soup** — The chaotic ladle serves what it will — today it dredges up deep miso stock, miso-deep umber. The ladle brought up a star anise pod and a plump dumpling. Served table-warm, no ceremony about it. Unseasoned — the salt sits on the table if you must. A hearty bowl — the kind that ends arguments and starts naps. *A chaotic ladle — every serving comes up different.*

**`{JJJ CC $MARA}`** — signed work.
> **Green Garden Soup** — A green garden stock, bright with herbs torn small over the pot. Adrift in it: two carrot coins. Served table-warm, no ceremony about it. Unseasoned — the salt sits on the table if you must. An honest bowl — plain, warm, and welcome after a long day. *Chalked on the board: soup by MARA.*
