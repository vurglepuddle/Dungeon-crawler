# UNDERCROFT

A Finder enters the abbey's Undercroft of Lost Things. Missing possessions
collect below; some are useful, some are still wanted. Find another use for
something ordinary. Bring the Dawn Seal home. Eventually, put something back
where it belongs and watch the dungeon come alive again.

Current milestone: **M2, a complete small run**, following the M1 review.
The Bell Porter and restored lift remain the intended signature of M3.

## The playable run

Two generated, persistent floors. Find a key on each floor, pass its locked
gate, descend, take the Dawn Seal and return to the entrance. Both sets of
stairs work in both directions. Gates, monsters, dropped loot, equipment and
visited cells retain their state while the Finder is elsewhere.

A floor has an entry room, a weight gate, a middle area with a useful loop
and side room, a keyed gate and an upper room. Seeded offsets, mirrors, loop
lengths and alcoves vary the geometry. This is bounded constructive generation,
not random tile noise. Floor count is a parameter (currently supported 1–4).

The direct BELL42 witness takes 77 committed turns. The fifteen-minute goal
remains a human pacing target, not a claim already demonstrated by this
milestone. Do not lengthen corridors just to reach it.

## Hands, pockets and small decisions

Eight pack slots, a hand slot, a coat slot, and a separate protected belt.
Selecting a pack item opens a readable card: name, capabilities/effect, a
lost-property provenance line and explicit actions. WIELD/WEAR, EAT and DROP
cost a beat. CLOSE clears the selection. Marked world targets can be touched
while the card is open: a selected HEAVY item makes the plate say PLACE.

DROP puts the selected pack item on the Finder's own cell. PLACE reaches the
plate directly ahead. Dropped objects persist; multiple nearby objects offer
a named chooser. A full pack rejects ordinary pickup without losing anything:
drop, equip or use something to make room. Keys and the Seal go to the belt,
even with a full pack, and cannot be dropped or consumed.

Eleven definitions are active in M2: rust knife, round stone, iron club,
padded coat, red tonic, dry bread, ham bone, glass shard, hooded lamp, abbey
key and Dawn Seal. Thirteen remains the slice ceiling; torch and clapper are
reserved for the later capability/restoration modules. HEAVY, EDGE, FOOD and
GLOW appear on cards, but M2 implements weight, weapon, food/healing and Seal
objective rules. Cutting, burning and ghost interactions belong to M3.

The knife does 1 damage; HEAVY weapons do 2 during recovery. A raised/braced
arm limits an impatient hit to 1, so gear does not erase the guard/dodge tell.
A coat absorbs one blow, with its
spent state stored on the item so swapping cannot refresh it. Healing items
are consumed only when healing is needed. Equipment exchange transfers the
old item into the vacated pack slot. There is no durability or weight tally.

Pressure is measured, not assumed. Each floor offers ten ordinary items plus
its essential key (and the final Seal). Across 64 greedy exploration probes,
floor one starts with eight free slots and ends full, leaving one ordinary
offering; floor two starts full and leaves nine. The minimal witness carries
little. These are different policies, not a claim that every human will make
the same choices or that all loot is balanced.

## Weight and a way back

The Finder's own weight presses a plate. Step off and the gate shuts again.
There is a gap between plate and gate, so body weight alone cannot bridge it.
DROP a HEAVY thing while standing there, or PLACE one from the cell ahead.

A latch on the far side opens the gate permanently. It remains reachable if
the Finder has crossed. Recovering the weight after latching cannot trap
anyone. A body or HEAVY object in the doorway also holds it open; gates do not
crush or destroy items. A matching belt key opens a keyed gate permanently.

## Read the creature, choose a beat

The Bell Husk now approaches down a visible straight lane. Adjacent to the
Finder, it raises an arm and announces the cell it will strike next beat.
Turning to look, inspecting, selecting and opening the map are free.
Movement, striking, guarding and physical item/fixture actions advance time.
Invalid actions spend nothing.

Backstep and the strike hits the old cell. After recovery, the Husk steps in
again. GUARD blocks the announced physical blow. Strike during recovery; a
HEAVY weapon can finish it with that single counter. The starter knife still
has a damage-free answer. Killing a source cancels its pending strike.
Inactive floors do not take enemy turns, and stairs add no arrival attack.

A real hit adds a red view border, a small view knock and a hurt portrait
overlay/tint, alongside health and short text. A handful of locally synthesised
effects covers footsteps, bumps, hits, guard clangs, wind-up bells, gates and
pickup. There are no samples, music, downloads or external services. Music is
M4: original, not the reused Warren/VETKA Bach pieces.

## Finish, pause, return

A title screen offers NEW RUN and CONTINUE under a fictional 1993 publisher.
New run explicitly replaces the old one. The end screens offer retry/new run.
Death ends the run; there is no power carried into the next attempt.
Win requires bringing the Seal back to floor one's entrance.

Every accepted command is saved before animation, including free rotation.
Pause and close save again. Versioned JSON uses user://run.json with validated
staging and a last-good backup. A corrupt slot never replaces a valid live
simulation. No session receipts or Ledger framework is added in M2.

The map shows seen floor cells and known fixtures with a large facing marker.
It opens/closes freely, never issues movement, and does not reveal hidden
unseen rooms. The 154 x 342 bands, VETKA 16 px minimum, nearest filtering and
at least 18 x 18 logical touch targets remain fixed. Curved gold arrows turn;
straight green arrows step. Touch is sufficient; no swipe or joystick is needed.

## What gives the finished slice its identity

M3 adds one owner/restoration encounter. Return the Bell Porter's clapper to
restore a useful lift, or retain its HEAVY utility longer. The ordinary stairs
remain viable. Returning late is permitted; if it dominates, tune the route
value instead of inventing quest expiry.

The Seal's GLOW reveals optional marks on the way home and keeps optional
ghosts at a distance. A renewable FIRE source precedes a required web; EDGE
opens a clearly hinted optional panel; FOOD can spare a hound encounter.
No thieves, item-eating enemies, item-swallowing pits, compulsory hidden walls
or return-trip spawns. One good restoration is enough.

M4 polishes poses, quieter walls, portraits, original bell-motif music, concise
knowledge-only Ledger cards, a period-style manual and phone acceptance.
M2 proves the full loop and persistence. It does not yet establish third-run
variety or the signature restoration payoff.
