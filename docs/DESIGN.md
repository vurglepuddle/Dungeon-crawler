# UNDERCROFT

A Finder enters the abbey's Undercroft of Lost Things. Missing possessions
collect below; some are useful, some are still wanted. Find another use for
something ordinary. Bring the Dawn Seal home. Eventually, put something back
where it belongs and watch the dungeon come alive again.

Current milestone: **M3d, the painted undercroft**. Doors, stairs and lift
landings belong to the masonry. The floors have painted dressing, cast stone
surfaces, restrained ambience and reactive Finder portraits. The parchment map
distinguishes walked ground from forward glimpses. The owner's phone feedback
takes precedence over the old bands. Capability encounters remain M3e.

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

The current slice has twelve item definitions: rust knife, round stone, iron club,
padded coat, red tonic, dry bread, ham bone, glass shard, hooded lamp, abbey
key, Dawn Seal and Bell clapper. Thirteen remains the slice ceiling; the
reed torch is reserved for the FIRE module. HEAVY, EDGE, FOOD and
GLOW appear on cards, but current rules implement weight, weapon, food/healing and Seal
objective rules. Cutting, burning and ghost interactions belong to the later content round.

The knife does 1 damage; ordinary HEAVY weapons do 2 during recovery.
The clapper does 3; the same braced-arm limit still applies. It can also
RING once per floor, described below. A raised/braced
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
wind-up bells, gates, pickup, a kept-clapper ring and a warm restoration chord.
An original sparse bell/reed score now accompanies the title and floors, with
a short win cue. MUSIC and SFX have independent persistent switches. No samples,
downloads, reused Warren music or external services are involved.

The Husk's idle, raised-fist wind-up and staggered recovery are separate painted
poses at 64/40/24 px. A real hit briefly uses recoil and flashes the target for
one drawn frame. EDGE cuts a thin streak, HEAVY makes a broad impact and bare
hands make a small knock; a native 16px number shows actual damage. Three
80ms effect frames never extend the normal input gate or resolve combat.
The Finder's portrait shudders by two pixels when hurt, alongside the border.

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

The map is a cartographer's parchment with sepia rules and hatched masonry.
Walked ground has solid ink; glimpsed ground has dashed edges. A small ? marks
an unsurveyed edge without consulting the hidden terrain beyond it. Known
stairs, gates, lift, Porter and Seal room use ink glyphs. An architectural
glyph is discovered by seeing its face, not merely standing on its logical
cell while looking away. A dark pin shows the Finder's heading. The map fits
known bounds, using eight-pixel cells or larger when space permits. Looking
and opening/closing the map remain free.

Surveying uses the view's 148 camera rays and lamp range, blocked by masonry
and closed gates/doors. It ignores the old coarse cardinal visited mask.
Walked/seen bits and discovered landmarks persist in checked UI metadata,
independent of rule hashes. Older saves without a survey keep their run intact
and begin a fresh survey at the loaded viewpoint.

The view uses the Finder's lamp: surfaces fade to black by about 3.5 cells.
Flagstones and ceiling ribs share world-aligned perspective seams. Small
objects have shadows and a minimum sprite size. Primary painted plain walls
dominate, with sparse stable cracks, damp, chains, tapestries, drains and
four-fps sconces. Cast floor/ceiling materials share world-cell seams. Deeper
stone is already painted darker; no extra blue floor tint is applied.

Exit, stairs and lift are fixed wall faces, with arches and thresholds sampled
through the wall camera. Dead lift chains hang slack with cobwebs; restoration
lights the lamp and tightens them. Gates have transparent apertures with the
real passage behind their iron. No corresponding mid-cell floor sprite remains.
The fixture's original logical cell and reach stay unchanged. A return stair
may be behind you on arrival: turn to see it, or use its existing UP verb.
Loose own-cell possessions still appear at the bottom edge for reachability.

The dungeon picture is 148 x 150 inside a three-pixel bronze frame. The top
strip is separate: seed left, floor/MAP right, logical x54-96 empty for the
phone camera. NEW remains a named pilot alias to the seed control. The normal
342px height is divided into top strip 18, framed view 156, messages 34,
portrait/equipment/belt 38, pack 22, verbs 24, controls/compass 48 and footer 2.

The original painted bronze remains on buttons and the compass. Large panels
use continuous, nonrepeating dark slate or teal enamel with thin bevels and
corner studs. The map uses worn parchment; cards use a dark verdigris
inset. A leather fold holds eight boxless icons at 19px pitch. Belt loops sit
behind the protected possessions, and a slim glass oil gauge repeats health
beside the portrait's bar. Icons retain their native centred 16 x 16 canvas.
The compass needle kicks and settles when turning; its letter remains precise.
The top strip has carved rail ends, a painted MAP button and a clear camera
gap. C's centred sixteen-pixel icons replace possession placeholders. Finder
paintings show fine at 4-6 HP, hurt at 2-3 and near death at 1; the last takes
priority over transient hurt. These presentation motions consume no time.

Pressure plates are shallow inset floor trapezoids, with a pressed rim/state.
Possessions paint after the supporting plate. The latch is a lever hinged to
a fixed wall beside its cell; its handle flips down and stays visible after
use. The restored Porter raises its palms and lights its chest in a new pose.

There are no labels or boxes on the dungeon picture. A small gold glint marks
a usable object; its painted body is the tap target. B's three-frame sparkle
has a long quiet interval and a stable per-object phase. Selected-item targets
have small corner cues in the item's colour. The strip spells out PLACE,
RETURN, RING or UNLOCK. A pile chooser names only the objects on that cell.
The world cue and hit area share the actual sprite projection and occlusion.

Item cards occupy the lower screen. While inspecting, the verb strip moves
into the message band immediately below the picture, so the selected verb
remains visible while its object glints. Closing the card restores the event
lines unchanged. Looking and ordinary footsteps no longer replace those lines.
Save failure uses a small persistent ! in the floor/status control; tapping it
offers status and retry. Saving never substitutes an error for an event.

The six movement tiles are 24 x 22 in a tight block beside a half-dial compass.
Bent arrows turn freely; straight arrows step. VETKA remains native 16 px,
nearest filtering remains, and every touch target is at least 18 x 18.
The owner's Android storage and font-import fixes remain intact. The title/end
menu offers separate MUSIC and SFX switches; the old sound pilot name still
addresses SFX. Preferences live outside the run snapshot. The app icon and
launcher framing remain the owner's assets.

A skippable LOST MOTH illustration precedes the title painting. CONTINUE and
NEW RUN are already reachable beneath it. Win/death plates leave seed, turn
count, epitaph and controls outside the art. Provenance and floor names come
from C's validated short text; urgent combat events retain priority. Dust,
subtle lamp flicker and deeper-floor drips stay inside the picture. Stair and
lift actions commit/save first, then fade the old picture out and the new one
in. The fade briefly holds input and never resolves an enemy action.

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

Keeping the clapper grants RING once per floor from pack or hand. It reaches
Husks in the facing 90-degree cone, up to three cells away, with clear sight
past walls and closed gates. Every listener's wind-up is cancelled and it
reels into recovery for this beat. There is one action to counter or get past;
other creatures and hidden/rear Husks remain dangerous. An empty call costs
nothing. Leaving/re-entering, dropping/equipping and saving cannot recharge a
floor. Returning the used clapper later still restores the lift.

The clapper card explains the charge and shows whether it is spent here.
RING targets glint; the successful ring has its own synthesized tone, event
text and a lowered, muted recovery sprite. The guaranteed guard/counter route
continues to work without using the bell.

Balance remains provisional: RING has reach and can interrupt several Husks,
but the current floors contain one Husk each. The extra damage point alone
still adds no value over a HEAVY counter against two health. Future encounters
must make the choice richer; this turn does not add enemies to manufacture it.

The next content round still needs these modules, one reviewed interaction
at a time. The Seal's GLOW reveals optional marks on the way home and keeps optional
ghosts at a distance. A renewable FIRE source precedes a required web; EDGE
opens a clearly hinted optional panel; FOOD can spare a hound encounter.
No thieves, item-eating enemies, item-swallowing pits, compulsory hidden walls
or return-trip spawns. One good restoration is enough.

M4 continues quieter walls, portraits, concise
knowledge-only Ledger cards, a period-style manual and phone acceptance.
M3d keeps the full loop and restoration, integrates the painted kit and makes
the map a durable survey. No extra enemy or capability fixture rule ships here.
Third-run appeal, the capability encounters and the return-trip reveal still
need implementation and human review.
