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
