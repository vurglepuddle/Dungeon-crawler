# The Deep: the whole game around the tutorial we already have

A proposal for the owner's review, 29 October 2026. Nothing here is built yet.
It turns the owner's idea into a shape, a feature list, a first scaffold, and
the questions only the owner can answer. **The owner answered the questions
the same afternoon; their answers come first and override anything below.**

## The owner's answers (29 October)

1. **Size: confusing beats huge.** "Some of the old puzzles in crawlers
   weren't just that large, but were confusing, for example if you need fire
   to progress a spiderweb, but the fire only torch is locked behind 2 doors,
   and you need to go through whatever else and unlock a hidden passage,
   that's almost the same amount of rooms as the first three layers, but will
   take way longer to progress. But sprawling is still a good idea (with some
   more unique rooms inside... Traps?)"
   - So a Deep floor has **about as many rooms as all three Abbey floors
     together**, and its length comes from a **nested chain of needs**: the
     way on is behind a web, the fire is behind two doors, and one of those
     doors is behind a hidden passage.
   - Unique rooms and traps come after the scaffold.
   - The owner's follow-up: "Maybe daggerfall dungeons as the size for now?
     AVERAGE, and we can obviously scale up/down. I remember daggerfall to be
     a bit confusing (in a good way)". This is a feel reference only, with no
     copied layouts:
     - the floor is built from interlocking blocks, each about one Abbey
       floor;
     - blocks have several connections each, so routes loop and cross;
     - average means about four blocks (2x2, roughly 33x33);
     - block count is a setting, so the size can go up or down.
2. **Health on waking: 5 of 6**, after the Fall or a skipped start. "Maybe we
   can increase HP later on with found objects."
3. **No permadeath.** "Wake up with the dawn seal and your items dropped
   besides your weapon on the starting point of the level you currently at?
   Permadeath sucks!"
   - Claude's reading: you wake at the current floor's arrival point with the
     Seal and your wielded weapon. Everything else you carried lies where you
     fell. The floor keeps its progress.
   - Claude's assumption, for the owner to confirm: this applies to new runs
     in the Abbey too.
4. **Magic: later.** "10000%".
5. **Your lost things: yes, scattered, "not next to you".**
6. The names (the Deep, the Winding) are fine.
7. **Keep the Porter's lift** in the Abbey; where exactly is decided later.

### Later the same afternoon

- **Mix and match the art families by room.** The owner: "have a unique room
  in the generator be in wall/floor/ceiling design 1, then another one in 2,
  that way we don't have to make a billion textures (and some of them can be
  super unique, too)".
  - The Deep should choose a wall/floor/ceiling family **per block or room**,
    not per floor, from f1-f4.
  - A few rare unique rooms can get their own one-off sets.
- **The Deep's dark slate (B's f4)** is one mood among several: "Deep is very
  dark, but we can have some rooms in that style - just not all. It's a bit
  of a vibe tbh."
- **Combat needs a revamp.** "The current one is fine for now, but we truly
  need more depth there and a more interesting loop." This needs its own
  proposal before the Deep grows past the scaffold, because two-creature
  encounters and "full of enemies" depend on it.

## The idea, in the owner's words

> The entire first three levels can be used as a tutorial (first time
> mandatory, second+ you can skip), and as you reach and grab for the dawn
> emblem, the artefact you went to get, the floor obviously crumbles under you
> and you drop down to level 4 out of 3, mwahaha, and now it's giant,
> confusing, no exit, full of enemies and obviously you lost all of your damn
> items when dropping down besides the emblem.

> If you skipped the tutorial you wake up in the middle of the room with
> nothing but the emblem still, and it's the same quest, get up to the top
> floor again. Obviously there are no stairs up, you need to go down down down
> to reach the elevator or whatever.

The ending already exists: the Finder holding the Seal in the dawn light
outside the ruins, with the animated sun glow. So the game needs the middle.

## Why this fits what we have

- **The three floors already teach every verb.** Weight and latch, keys, fire
  and webs, food and the Hound, EDGE and cords, GLOW and the Ghost, throwing,
  guarding and countering, and the Seal itself. The tutorial is finished.
- **Losing everything turns lessons into skills.** In the Abbey you were
  handed the right tool next to each problem. In the Deep you have to
  remember that bread calms a Hound, and then find some bread.
- **It is the owner's long-term dream.** "A dense 10-floor-deep difficult
  crawler where you barely survive" is exactly what the Deep should become.
- **It fits the story.** This is the Undercroft of Lost Things, and now the
  Finder's own things are lost property. An optional touch: a few of them
  turn up in the Deep, with provenance lines like "Yours. It fell with you."
- **The game's title, UNDERCROFT, still fits.** The Abbey Below sits over a
  much older, larger undercroft.

## The shape of the game

| Part | Floors | What happens |
| --- | --- | --- |
| **The Abbey Below** (tutorial) | 1-3 | Today's run, almost unchanged. It ends when you take the Seal. |
| **The Fall** | between 3 and 4 | The floor crumbles. You fall, and keep only the Seal. |
| **The Deep** | 4 onward | Big, confusing and hostile. Stairs only go down, and some floors drop you. |
| **The Winding** (the way out) | the bottom | An ancient lift shaft. Wake it and ride it all the way up. |
| **Dawn** | | The existing ending. |

"Go down to go up" gives the Deep a clear goal: always reach the bottom.

## First time, and every time after

- A small **profile file**, separate from any run, remembers that you have
  fallen once (`user://profile.json`, `fallen: true`).
- **First NEW GAME** goes straight into the Abbey, as today.
- **Later NEW GAMEs** offer two starts: **THE ABBEY** (the full descent) or
  **THE DEEP** (wake below).
- **Waking in the Deep** puts you in the middle of a room with only the Seal
  on your belt. One short card says something like: "You remember the Seal's
  warmth, and the floor giving way. Then nothing."
- Both starts produce the **same Deep for the same seed**, so a tutorial run
  and a skipped run can be compared.

## The Fall

- **Trigger:** taking the Seal on floor 3. Today that starts the trip home;
  in the new structure the trip home is gone.
- **Presentation:**
  - two or three crumble frames, a short shake, a dark beat with one line of
    text, a thump, then the waking card;
  - readable speed, as the owner wants for every animation.
- **Rules:**
  - pack, hand, coat, belt keys and anything dropped stay behind (or are
    scattered below, if the owner likes that touch);
  - the Seal stays;
  - **I recommend full health on waking.** Skipped runs start at full health,
    so tutorial runs should too.

### Two tutorial beats that only happen on the way home

Removing the trip home also removes two lessons. Both need a new place:

1. **The Seal reveals hidden things.** The scored-dawn cache is revealed by
   coming back with the Seal. Move this lesson to the first Deep room: a
   faint mark on the wall beside where you wake, which the Seal reveals.
   That is the first thing you learn down there, and it's a useful one.
2. **The Bell Porter and his lift.** Returning the clapper repairs the lift
   to the entrance, a shortcut you would no longer need. Keep it as the act
   of kindness it is: restoring him teaches that **a woken lift carries you
   home**. That foreshadows the Winding at the bottom of the Deep. The
   restored lift could also carry you to the Seal room, which shortens a
   second Abbey run.

## The Deep: big, confusing and hostile

Each item says whether it belongs in the first scaffold or later.

1. **Bigger floors** (scaffold).
   - Today every floor is 17x17. That number is hard-coded in about twenty
     places in the code.
   - Make grid size a floor setting. Deep floors start at **33x33**, four
     times the area.
   - Build them by stitching together sectors about the size of today's
     floors, so most of the generator is reused.
   - The map needs panning, and probably zoom.
2. **Down only** (scaffold).
   - The Deep has no stairs up: there are stairs down and, later, one-way
     drops (pits and crumbling floor, repeating the Fall).
   - **Contract:** every Deep floor can be finished with nothing but the Seal
     and what that floor contains. Witness bots prove it from empty hands,
     every seed. Because you never go back up, nothing left behind can strand
     you.
3. **More creatures** (scaffold count, later behaviour).
   - Today a floor has three at most. Deep floors get **six to ten**, spread
     across sectors so most fights are still one at a time.
   - Sometimes two creatures meet you at once. That is the real step up in
     difficulty, and needs its own fairness pass.
   - Later: patrols and wanderers, and new creatures from B.
4. **Confusing, but fair** (later).
   - Loops, dead ends and corridors that look alike.
   - Dark sectors where light matters.
   - Hidden doors the Seal reveals (the scored panel, grown up).
   - Levers that open a gate in another sector, and one-way doors.
   - The map is your friend; the Deep is never random noise.
5. **Scavenging** (scaffold uses existing loot).
   - Generous with junk, stingy with healing, so the eight pockets matter
     again.
   - The thirteen existing item kinds are enough to start.
6. **The Seal, your only constant** (puzzles first, magic later).
   - It already reveals marks and glows.
   - Add **dawn locks**: sun-carved doors that open only to the Seal.
   - Magic is the owner's "maybe". If it comes, I'd suggest rites learned
     from murals: a short ward, a spark of FIRE, a flash that turns a Ghost.
     Each spends the Seal's warmth, which refills in **shafts of daylight**:
     thin cracks to the surface that are also landmarks pointing home.
7. **The Winding** (scaffold as the existing lift, art later).
   - The last floor holds a great lift shaft.
   - The scaffold uses today's lift: step on, ride, dawn.
   - Later, waking it is the final puzzle (a chain, a bell, a counterweight),
     echoing the Porter.

## Death in a longer game

Today a death ends the run with an epitaph. That's fine for a fifteen-minute
run, but harsh after an hour in the Deep. There are three options:

- **Permadeath** as today: pure, but brutal on a phone.
- **Wake where you landed** (my recommendation). Each Deep floor saves its
  arrival state, and death offers to wake again at that floor's landing, with
  the floor reset. It is still dangerous, but it doesn't wipe the evening.
- Both, as a choice at the start.

## What we would build first: M5a, the scaffold

Updated with the owner's answers: **one sprawling Deep floor built around a
chain of needs, then the Winding**; waking at 5 of 6; death wakes you at the
floor's arrival point; your lost things are scattered. The original draft
follows for reference.

The goal is a playable skeleton, ugly where it has to be:

- **Two acts in one run.** The run records whether you are in the Abbey or
  the Deep. New games use a new rules profile; old M3f and M4c saves keep
  their own rules and still end with the trip home.
- **The Fall:**
  - taking the Seal on floor 3 empties your hands and pockets and drops you
    to Deep floor 1;
  - a placeholder shake and fade, plus the waking card.
- **Deep floor size as a setting** (33x33): generator, simulation, saves,
  view and map all respect it. The map pans.
- **Two Deep floors and the Winding:**
  - each Deep floor is stitched from existing modules, with six to eight
    existing creatures, stairs down only, and existing loot;
  - the last floor has the lift, which ends the run at dawn.
- **The Seal lesson** moved to a mark beside where you wake.
- **The profile flag** and the two-start title menu.
- **Witness bots:** empty-handed and solvable on every Deep floor, across
  hundreds of seeds.
- **Placeholder art:** the Lower Watch look stretches over the Deep for now.

Not in M5a: magic, new creatures, one-way drops, dark sectors, patrols, new
music, the final lift puzzle, and anything we haven't seen on the phone yet.

## Later, roughly in order

- **M5b, the Deep's vocabulary:** one-way drops, dawn locks, hidden doors,
  levers across sectors, two-creature encounters, lost things that turn up.
- **M5c, the Seal's rites** (if wanted), daylight shafts, one new creature.
- **M5d, length and difficulty**, tuned from the owner's phone runs, toward
  the ten-floor "barely survive" crawler.
- **In parallel (B):**
  - crumble frames, the waking room, the Winding;
  - a Deep wall family, so the Deep doesn't look like the Abbey;
  - Deep music, and later new creatures.

## Codex budget

The promotion has ended, so at most two workers run at once:

- **A** builds code;
- **B** makes art and music;
- **D** (QA) joins only for a sweep, at **medium** effort;
- Claude verifies, commits and ships, and makes small fixes directly (as
  with the lever).

## Questions for the owner

My recommendation comes first in each.

1. **How big is the first Deep?** Two floors plus the Winding for the
   scaffold, then grow toward ten.
2. **Health on waking:** full, so tutorial and skipped runs match.
3. **Death in the Deep:** wake at the current floor's landing, with that floor
   reset. Or permadeath?
4. **Magic:** later. Build the Seal's puzzle uses first, and see whether the
   Deep wants rites.
5. **Your lost things turning up below:** yes, a few, as a wink, never the
   ones you'd need.
6. **Names:** "The Deep" and "the Winding" are working titles. The owner may
   want others.
7. **The Porter's lift in the Abbey:** keep it as a kindness that also
   shortens a second Abbey run.
