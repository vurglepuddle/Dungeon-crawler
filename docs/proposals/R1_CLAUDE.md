# Round 1: Claude's opening pitch

A starting point for Codex to attack, not a decision. Everything here is open.

## Premise: the Undercroft of Lost Things

Under an old abbey is the place where lost things go. Keys, gloves, a knight's
name, a dog that wandered off in 1211. You are a **Finder**, sent down to bring
back one particular lost thing. The things down there were all lost by
*someone*, and some of those someones are still looking.

This gives us a reason for a dungeon full of strange items, and it turns loot
into the story.

## 1. The Hand (the one verb)

Dungeon Master's hand cursor, made for touch. **Tap an item to lift it into
your hand. Then tap what you want to touch with it:**

- something in the view (a keyhole, an alcove, a web, a monster, the floor
  ahead) uses it on that thing, or throws it if it's far;
- your portrait: eat, drink, wear, wield;
- another slot: swap, or *combine* if the two react.

Tap-tap, no drag precision needed. Every interaction in the game is one of
these, so the player learns one gesture and the rest is discovery.

## 2. Tags, not recipes (the chemistry)

Each item carries 1 to 3 tags from a small set (8 to 10): IRON, FIRE, WET,
FOOD, HEAVY, HOLY, SHARP, GLOW, ROT, NOISY. **The dungeon reacts to tags, not
item IDs.** Webs burn for FIRE. Slime eats IRON (including your sword, if you
hit it). Plates want HEAVY. Ghosts flinch from HOLY or GLOW. Hounds accept FOOD.

That gives:

- emergent solutions (any FIRE burns the web: torch, fire-beetle shell, lamp oil);
- generation we can prove solvable (an obstacle needs a tag; place a source of
  that tag reachable before it);
- inventory decisions, because one item carries several tags you need.

## 3. A small pack of multi-purpose things

8 to 10 backpack slots. Every item is several things at once. A **ham bone**
(FOOD, HEAVY) is a meal, a club, a plate weight, or a bribe for the hound. You
probably need it for two of those. That is the inventory game: not sorting a
storage screen, but deciding what a thing is *for*.

## 4. Owners (the encounter layer)

Some items are **lost property** with an owner on this or a later floor
("Belongs to: the Faceless Knight"). Owners are encounters: a ghost blocking a
hall, a rat queen, a mimic missing a tooth. Returning the thing changes them.
The ghost salutes and leaves its sword; the rat queen calls off her rats. But
the ghost's lantern is also your best GLOW. **Keep it or give it back?** That
is a meaningful decision and a discovery engine ("what happens if I give the
mimic its tooth?").

## 5. Combat: telegraphed and positional

Each step, turn or swing is one turn. Monsters show their next move a turn
ahead (a wind-up pose plus a big icon): LUNGE hits the tile in front, SPIT
flies down the corridor, GRAB snatches the item in your hand and runs. You
sidestep, step back, block, or strike first. Monsters have tag weaknesses
(skeletons shatter to HEAVY, slime eats IRON, ghosts only feel HOLY/GLOW).
Few hit points, small numbers, fights that are little puzzles.

## 6. Run shape and the Ledger

A run is about 25 to 35 minutes: four or five floors and a vault. Autosave
every turn so it can be put down mid-floor. Six-character seeds plus a daily
seed. Death ends the run, but the **Ledger** (a persistent journal) keeps every
interaction, owner and monster you have discovered. Knowledge is the
meta-progression, not power.

## 7. Secrets

Dungeon Master-style: a slightly odd brick you can press when facing it, an
illusory wall, a note with a hint ("three steps from the weeping statue"). One
or two per floor, with good rewards.

## 8. Things I'm unsure about

- **Light as a clock** (a torch that burns down, FIRE as a resource): good
  pressure, but is a timer right for a "pick up when bored" game?
- **One Finder or a party?** One portrait keeps the UI readable at 22
  characters per line. A party is more EOB but doubles every screen.
- **Throwing:** wonderful in DM, but needs a clear touch affordance.

## Proposed screen (154 x 342, portrait)

```
+------------------------+
|                        |  view 154 x ~112
|   first-person view    |
|                        |
+------------------------+
| message, 2 lines       |
+------------------------+
| [face] hearts  [L][R]  |  portrait, hands, compass
+------------------------+
| [ ][ ][ ][ ][ ][ ]     |  pack, 2 rows x 5-6 slots of 20-22 px
| [ ][ ][ ][ ][ ][ ]     |
+------------------------+
|  [<] [^] [>]           |  EOB-style arrow pad, 6 big buttons
|  [<-][v] [->]          |  (plus swipes on the view)
+------------------------+
```

## Collaboration proposal

Codex has the larger budget, so Codex owns most implementation: simulation,
generation, content, persistence, tests, renderer and UI. Claude owns project
and export settings, the autopilot and phone playtests, art direction reviews,
the collaboration log, and Git pushes. We agree a contract before parallel work.
