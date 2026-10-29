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

## 28 October 2026, evening: the owner plays it for real

M3d and then M3e went onto the owner's Pixel 9a, and the owner played long
sessions, reporting as they went. The headline: **save, fully close, reopen and
Continue works on the phone.** They loved the brazier, the elevator, both
optional branches ("pretty fun"), and the fact that branches are easy to walk
past ("this was core in old crawlers"). They missed the Ash Hound entirely and
called that fair: "it's sneaky like that". A run took about six minutes and
they never needed food: too easy, a little short.

They also found what no bot did: walking into stairs did nothing; equipped
items couldn't be dropped; target markers were nearly invisible; two keys
looked like one; a decorative arch beside a real gate read as part of the
door; the dead lift and the stairs down looked like plain doorways (the image
model had painted an impossible staircase, so the owner had another model
repaint it and that painting is now the stairs down); loot spawned under the
Porter; the lever had no head-on view; there were two health bars; the
brazier wouldn't light from a tap and the web wouldn't burn from an equipped
torch (they tossed the torch at it instead, "pretty 1990s jank"). Every one
of these is queued for Codex A, with the art from B and C already painted.

The owner also started painting: two reference images for the chrome (vines
on the borders, icons on the verb buttons) and then a hand-made 1:1 vine
overlay, drawn on templates Claude cut from the build. It fit first time.

Codex D's first QA sweep found no softlocks across 3,141 seeds and 768
adversarial trajectories, and two real bugs (a Husk sharing the stair landing,
malformed saves raising script errors). Codex A fixed both in M3e and added
SIDLE, so a creature waiting on a landing can never trap you.

## 29 October 2026, past midnight: M3f, and hunting the last placeholders

Codex A's M3f answered every phone note at once: stairs and lifts you walk
into, DROP and UNEQUIP for what you hold, bright target brackets, key counts
that name their gate, sealed fake arches, a shut lift that explains itself, a
head-on lever, one glass health vial, and Codex C's warm slate, leather and
brass above the dark controls. The owner played it twice: "this is actually
awesome ... crunchy pixel art vibes really give King's Field". They can see
it growing into "a dense 10-floor-deep difficult crawler where you barely
survive", which is now the long-term north star.

They asked for a sweep for leftover placeholder art and spotted the wall
dressings and the locked door. Codex C repainted every dressing into the
stone, including a locked door that finally swings open instead of borrowing
the portcullis. Codex D read every line that draws anything and wrote
[ART_AUDIT.md](ART_AUDIT.md), separating deliberate code visuals (map ink,
digits, glints) from the remaining stand-ins, which went to Codex B. Claude
removed Godot's stock boot image so the Lost Moth is the first thing you see.
The owner is painting their own vine overlay for the frame. Codex A is now
designing a third, harder floor ([STATUS](STATUS.md) has the details).

## 29 October 2026, 2 to 4 a.m.: the Lower Watch, and the owner's own frame

Codex A's M4a made the run three floors deep. The new Lower Watch recombines
what you already know, a Husk on the spine, a Hound by the key, a corded
chapel and a webbed storeroom, but its blows land harder. Codex D swept that
deeper game from a clean worktree, so A's half-written edits couldn't
disturb it. It found no softlock, crash or broken save, and measured that a
careless player dies on floor three more often than not, while a careful
one still walks out unhurt. M4b wired every painting the placeholder hunt
had produced, and added a guard so that a missing file now fails a test
instead of quietly reviving old code art on the phone. Codex C gave the
Lower Watch its own soot-and-rust look, and Codex B gave it its own music,
"The Watch Beneath the Bell", and painted the pack icons.

The owner finished their hand-painted vine overlay. It went in exactly as
drawn: skulls on the frame's corners, a bat-skull crest under the camera
hole, and a skull capping the compass needle. "The blue added a nice
contrast to the rest of the UI." They then asked for it to come alive, so
the skulls' eyes now flare a pale teal, rarely and at random ("ooo spooky").
Codex C cut the candle out into its own two-frame sprite, so the owner can
keep painting the overlay without redoing the flicker.

Then they played, on desktop and phone, and sent notes as they went:
- swings that "literally play for 1 frame" (slowed three times until they
  read like a 90s game);
- a door that hopped a tile away when unlocked;
- a hidden cache that gave its own secret away;
- a knife in hand that couldn't pry anything;
- two bright bevel lines along the screen's edges, which led to the bevel
  coming off every menu.

All were fixed the same night, and A's M4c turned the rest into one
focused pass. Along the way the owner set the tone for what comes next:
"JANK! (I freaking love jank) ... 90s games weren't perfect. I'm fine with
non-perfect." Imperfect painted detail is welcome; an animation you can't
see is a bug.

After about twelve hours, the session closed with every worker handed in,
everything pushed, the M4c build on the phone, and the owner's verdict:
"THANK YOU SO MUCH, this is SOOOOO gooood".

## 29 October 2026, afternoon and evening: the tutorial becomes a prologue

After a night's sleep and several more runs, the owner had a breakthrough:
the three floors weren't the game, they were "the perfect tutorial". Taking
the Dawn Seal should make the floor crumble ("mwahaha"), dropping the Finder
into a much older, larger dungeon with nothing but the Seal. The way out is
down, to a lift at the very bottom, and from there to the dawn ending that
already existed. Claude wrote the idea up as `docs/proposals/THE_DEEP.md`,
and the owner answered its questions in a few lines each:
- a confusing chain of needs matters more than sheer size;
- "Daggerfall dungeons as the size for now? AVERAGE";
- wake at 5 of 6 health;
- "Permadeath sucks!";
- magic "later!! 10000%".

The Codex usage promotion had just ended, so only two workers ran: A on code
and B on art, while C and D rested. A built the scaffold in one turn (M5a),
and a second turn worked through the owner's playtest notes (M5b):
- the Fall and the skippable tutorial;
- a 33x33 Deep of four blocks, built backwards from its stairs;
- death that wakes you at the floor's start;
- iron, bronze and gold keys;
- a map that charts what you see;
- the Seal's light.

B painted the Deep's cold slate, the crumble frames and three metals of key
and lock.

The owner painted more than ever:
- new side-lever frames;
- proper grips for the stone and torches, which had been held "between
  your pointer and middle finger";
- a first pass on every button icon, on a sheet Claude cut up for them;
- crumble frames redrawn to "feel more 3d".

They played a full run, Abbey to dawn, in 578 turns: "long enough, but not
exhausting". Then they steered the details from the phone, ending with a
pixel mockup of how the Seal's light should fall off. Claude rebuilt the
light that way: gentle bands, each dithering only into the next darker one.

One lesson worth keeping: never screenshot the owner's phone without
asking. They chat with clients on it.

The day closed with everything pushed, M5b on the phone, and the owner
"very satisfied", off to think about the game and paint.
