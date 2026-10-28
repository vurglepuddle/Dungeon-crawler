# Collaboration log

How Claude and Codex arrived at the game: proposals, challenges, decisions
and what was actually tested. Newest entries at the bottom.

## 28 October 2026: Round 1, two pitches

Claude opened with **the Undercroft of Lost Things**: a Finder sent under an
abbey where lost things end up, a Dungeon Master-style hand that touches the
world with items, ten chemistry tags, owners who want their things back, and
telegraphed combat ([R1_CLAUDE](proposals/R1_CLAUDE.md)).

Codex kept the premise and took most of the rest apart
([R1_CODEX](proposals/R1_CODEX.md)). A single tap that could mean eat, equip,
combine or throw is a guess, not a verb. Ten tags are a content engine before
one corridor is fun. Turning to look at a threat must not cost a turn. A thief
that runs off with a required key is recovery logic, not an encounter. And
"return the thing, get a better thing" is solved by the third run.

Codex's own idea became the heart of the game: **returning things repairs the
dungeon**. The Bell Porter has lost its clapper and its lift is dead. Keep the
clapper (a strong HEAVY club) or give it back and the lift runs again, a
shortcut that matters on the way home.

Codex also ran an art spike: one monster, one wall and one portrait painted by
its image generator and crushed to 31 shared colours at target size, next to a
code-drawn version of the same monster. The painted Bell Porter looks like it
came out of a 1993 VGA box; the code version reads better at 24 px. Decision:
hybrid art.

## 28 October 2026: Round 2, convergence

Claude accepted explicit verbs, one Finder, no light clock, free turning, five
capabilities, the restoration mechanic and the M1 stop
([R2_CLAUDE](proposals/R2_CLAUDE.md)). Claude kept the *feel* of the hand in a
smaller form (a selected item marks every valid target in the view with its
verb) and added: the Dawn Seal glows, so the way home reveals what you walked
past; no persistence machinery before a failure asks for it; pack pressure
measured by a bot rather than assumed; item cards with a line of lost-property
provenance; original music instead of Bach, at the owner's request.

## 28 October 2026: M1, the first corridor

Codex locked the agreed design into [DESIGN](DESIGN.md), [CONTRACT](CONTRACT.md)
and [ARCHITECTURE](ARCHITECTURE.md), then built M1: one generated floor in
first person, a round stone, a plate and a latching gate, a painted Bell Husk
that raises its arm a turn before it strikes, and an exit. Codex reported
13,469 headless checks with no failures, including 512 seeds walked to the
exit through ordinary actions, and its own pilot winning through real taps.

Claude reran both, exported a debug APK (it builds and signs; the phone test
is still to come) and then played off-script. That found what the scripted
run could not: **walking onto the plate does nothing**, and once you stand on
it there is no way to put the stone down, because PLACE only reaches the cell
ahead. Claude proposed that the Finder's own weight presses a plate (the gate
shuts again when you step off, which teaches why you need a heavy thing) plus
a DROP verb. The Husk also never moves and dies to two hits whatever you do;
it will approach in M2. Codex's own verdict on M1 agreed: "the corridor has
atmosphere ... repeat play still needs the restoration encounter and
multipurpose loot".

## 28 October 2026: M2, there and back again

Codex turned the corridor into a run: two floors, the Dawn Seal on the second,
and the walk home. Eight pockets with item cards that say who lost each thing
("Lost on a cold night."), a belt that protects the key and the Seal, an
automap, a title screen from an invented publisher (LOST MOTH, 1993), Husks
that close in on you, a red border and a hurt face when you're hit, seven
synthesized sound effects, and saves. Claude's plate fix landed as proposed:
your own weight opens the gate and it shuts when you step off.

Codex caught one balance bug on its own: a heavy club could kill a fresh Husk
mid-swing, which made guarding pointless. Its raised arm now limits a hit to
one damage; the big counter belongs to its recovery.

Claude reran everything (32,705 checks; full run, close and reopen pilots in
separate processes; the reopened game matched the saved state hash exactly)
and then looked hard at the screenshots. Corridors still look great, but the
new **open rooms break the first-person view**: a thin band of far wall over a
flat floor, an empty ceiling, tiny items, invisible stairs, and markers that
float away from their objects. Also, all 300 witness runs took 77 to 81 turns:
different shapes, same run. Both go first in M3, before the Bell Porter.

## 28 October 2026: The owner plays it on the phone

The owner installed M2 on the Pixel 9a: "Like the janky vibe. I'm serious!
This has some super retro vibes." They loved the wall, the walking animation
and the Finder's portrait, and found what no desktop test had: **saves failed
on the phone** (the same absolute-path trap as in Wind-up Warren; the app's
data folder held nothing but a shader cache), **the text was blurry** (VETKA
was imported with antialiasing, so glyph edges went grey before the 7x
upscale), the camera hole covered the floor number, item icons sat
off-centre, and the movement pad was too big for the view it served. Claude
fixed saves and text the same hour and put a playtest build on the phone. It
also made the app icon from the painted Bell Husk.

The owner then went back to the crawlers of their youth and sent three
screenshots: the dungeon centre stage, everything else "elegantly squished
into place", carved frames, a compact arrow block, inventory icons lying loose
with no boxes. That became the brief for M3b.

## 28 October 2026: M3a, rooms you can read and the Bell Porter

Codex rebuilt the room view: the Finder's lamp now fades the dungeon to black
three cells out, floors are flagstones in perspective, ceilings have ribs,
objects are bigger and cast shadows, and stairs look like stairs. The Bell
Porter arrived, painted the same way as the Husk: return its clapper and its
chest lights, a warm chord sounds, and the lift wakes between the landings.
Generation widened (65 to 95 turns down and back, 60 to 85 with the lift) and
loot became varied. Claude reran the 59,421 checks and the pilots.

Claude's review: the boxed labels now clutter the picture (one covers the
Porter's body); the log says "Looking is free." on every turn; and a kept
clapper is only one extra point of damage, so Claude proposed it should
*ring*, making every Husk in sight reel. Then keeping it is a different tool
rather than a bigger number.

## 28 October 2026: M3b, and three Codex workers

Codex A rebuilt the screen in the period style: a 148 x 150 view in a painted
bronze frame, a compact pad with a compass dial, a boxless inventory, gold
glints instead of labels over the picture, and a clapper you can keep and RING
once per floor to make every Husk in sight reel. Claude reran 120,615 checks
and seven pilots. The owner liked the buttons and compass and called the rest
"a bit of an old chocolate bar": a visible tile pattern, too uniform, needing
detail, diegetic elements and a second colour.

With Codex budget to spare, the owner asked for more workers. **Codex B** now
paints creatures, effects and fixtures and writes the music; **Codex C** does
the dungeon's dressing, icons, portraits, story plates, an ambience layer and
a manual. Both write only new files; Codex A remains the one who wires code.
B's first batch: three readable poses each for the Husk (its fist raised high
before it strikes), the Ash Hound and the Wick Ghost, the restored Porter,
crisp strike effects per weapon, a lever that flips and a plate that lies flat,
and three original pieces on a D-A-E-F bell motif. C's: wall dressing for both
floors, icons, the Finder in three states, title/win/death paintings, the LOST
MOTH emblem (the moth's body is a key), dust in the lamplight and a manual
written as if it came in the box. The owner: "Love the art."

Claude asked C to rebuild its walls on the painted stone the owner loves rather
than replacing it, and to offer A a set of non-tiling interface materials and
diegetic props with one contrasting accent colour.
