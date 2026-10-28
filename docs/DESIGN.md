# UNDERCROFT

A Finder enters the abbey's Undercroft of Lost Things. Missing possessions
collect below; some are useful, some are still wanted. Find another use for
something ordinary. Bring the Dawn Seal home. Eventually, put something back
where it belongs and watch the dungeon come alive again.

Current milestone: **M3a, the lamp and the Bell Porter**. A complete short
run now includes one restoration. Capability encounters follow in M3b; this
checkpoint deliberately stops before adding more enemies.

## The playable run

Two generated, persistent floors. Cross a weight gate, find the side-room key,
pass the keyed gate and meet the Bell Porter. Descend, take the Dawn Seal and
return home. Later floors can have a weight gate, a keyed gate, or both.
Stairs work both ways. Gates, monsters, dropped loot, equipment, restored
landings and visited cells retain their state while the Finder is elsewhere.

Entry and upper rooms are three cells wide; narrow corridors join a useful
loop and a small side room. Seeds vary loop reach, loop height, which side
holds the key, landing position, later gate modules and ordinary loot.
Floor count remains a parameter (1-4). No corridor length is added merely to
make a witness longer. Across 300 two-floor seeds, stairs-only witnesses take
65-95 turns and restoration witnesses 60-85. This is more structural variety
than M2's 77-81, but it is still one encounter vocabulary.

BELL42 takes 73 turns if the clapper is left alone, 74 if carried as a club,
or 66 if returned and the lift used. These are reproducible bot routes, not
optimal-path or fifteen-minute human pacing claims.

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

Twelve definitions are active in M3a: rust knife, round stone, iron club,
padded coat, red tonic, dry bread, ham bone, glass shard, hooded lamp, abbey
key, Dawn Seal and Bell clapper. Thirteen remains the slice ceiling; the
reed torch is reserved for the FIRE module. HEAVY, EDGE, FOOD and
GLOW appear on cards, but current rules implement weight, weapon, food/healing and Seal
objective rules. Cutting, burning and ghost interactions belong to M3b.

The knife does 1 damage; ordinary HEAVY weapons do 2 during recovery.
The clapper does 3; the same braced-arm limit still applies. A raised/braced
arm limits an impatient hit to 1, so gear does not erase the guard/dodge tell.
A coat absorbs one blow, with its
spent state stored on the item so swapping cannot refresh it. Healing items
are consumed only when healing is needed. Equipment exchange transfers the
old item into the vacated pack slot. There is no durability or weight tally.

Pressure is measured, not assumed. Across 64 greedy probes, the first floor
offers 8-12 ordinary items and the second 4-7. Floor-one exit capacity ranges
from zero to one free pocket; floor two ends full. BELL42 offers nine then
four ordinary items. Its greedy bot enters floor two full and leaves three
of that floor's four offerings. Keys and the Seal are excluded from these
counts. Clapper recovery is optional; returning it frees its pocket/hand.
The bot retains duplicates and does not model human taste.

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
overlay/tint, alongside health and short text. Locally synthesised effects cover footsteps, bumps, hits, guard clangs,
wind-up bells, gates, pickup and a warm restoration chord. There are no samples, music, downloads or external services. Music is
M4: original, not the reused Warren/VETKA Bach pieces.

## Finish, pause, return

A title screen offers NEW RUN and CONTINUE under a fictional 1993 publisher.
New run explicitly replaces the old one. The end screens offer retry/new run.
Death ends the run; there is no power carried into the next attempt.
Win requires bringing the Seal back to floor one's entrance.

Every accepted command is saved before animation, including free rotation.
Pause and close save again. Versioned JSON uses user://run.json with validated
staging and a last-good backup. A corrupt slot never replaces a valid live
simulation. M2 saves continue as their exact stored run, without regeneration; they
retain M2 geometry and contain no retroactively inserted Porter. No session
receipts or Ledger framework is added here.

The map fits the seen bounds, with cells of at least eight pixels when space
permits and a large facing marker. Seen stairs, gates, lift landings and the
Seal site have distinct marks. The Seal site remains marked after pickup.
No unseen rooms are revealed. Looking and opening/closing the map are free.

The view uses the Finder's lamp: surfaces fade to black by about 3.5 cells.
Flagstones and ceiling ribs share world-aligned perspective seams. Small
objects have shadows and a minimum sprite size. Down stairs are a black well
with descending treads; up stairs rise inside a stone frame. Own-cell items
and stairs remain visible at the bottom edge. These are readable sprite
conventions at 154 pixels, not an attempt at physically exact perspective.

A TAKE marker identifies one object or one pile on a single cell. The pile
chooser lists only that pile. Its label and object both accept taps. Labels
use the same projection/occlusion as their objects and stack in stable ID
order when they collide. A selected clapper marks its owner RETURN, just as
a selected HEAVY item marks a plate PLACE.

The 154 x 342 bands, VETKA 16 px minimum, nearest filtering and at least
18 x 18 touch targets remain fixed. Curved gold arrows turn; straight green
arrows step. Touch is sufficient; no swipe or joystick is needed.

## What gives the finished slice its identity

The Bell Porter waits beside the upper landing on floor one. Its lost clapper
is a HEAVY club in the side room. Its provenance names the owner; its card
says that returning it wakes the lift. The Porter's own free card explains
the choice. RETURN permanently puts the item back, lights the Porter's heart
and wakes both landings with a short chord. It works from a pocket or hand.
The returned clapper cannot be picked up, dropped, equipped or returned twice.

The lift connects the entrance to the deepest floor's entry landing; with one
floor, it connects entry and upper landing. RIDE costs one beat and freezes
the departed floor, like stairs, with no arrival attack. A blocked destination
rejects the trip. The ordinary stairs always remain viable. Returning late
is allowed. No quest expires or optional weapon becomes secretly essential.

Honest balance limit: against a two-health Husk, the three-damage clapper's
extra point adds no benefit over another HEAVY counter. Restoration already
has a travel payoff; the keep choice needs the later encounters to justify
its extra damage. Do not pretend that this checkpoint has solved that trade.

M3b still needs the following modules, one reviewed interaction at a time.
The Seal's GLOW reveals optional marks on the way home and keeps optional
ghosts at a distance. A renewable FIRE source precedes a required web; EDGE
opens a clearly hinted optional panel; FOOD can spare a hound encounter.
No thieves, item-eating enemies, item-swallowing pits, compulsory hidden walls
or return-trip spawns. One good restoration is enough.

M4 polishes poses, quieter walls, portraits, original bell-motif music, concise
knowledge-only Ledger cards, a period-style manual and phone acceptance.
M3a proves the full loop, persistent restoration and a useful way home.
Third-run appeal, the capability encounters and the return-trip reveal still
need implementation and human review.
