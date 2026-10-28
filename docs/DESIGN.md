# UNDERCROFT

A Finder enters the Undercroft of Lost Things: an abbey's buried store of
missing possessions and the people still looking for them. Find another use
for an ordinary object. Bring something home. Occasionally, put something
back where it belongs and watch the dungeon come alive again.

Agreed direction after [R1](proposals/R1_CODEX.md) and
[R2](proposals/R2_CLAUDE.md), 28 October 2026. M1 is the first playable below;
the rest describes the intended slice, not features already implemented.

## The short run

One Finder, two persistent generated floors, about fifteen minutes. Retrieve
the Dawn Seal below and leave through the entrance. Two floors is a content
parameter; a third is considered only after playtesting establishes a need.
No party, light timer, hunger, durability or random accuracy rolls.

Five capabilities explain the objects: HEAVY, EDGE, FIRE, FOOD and GLOW.
Keys match named locks; lost property matches named owners. No recipe graph.
Thirteen item definitions is the ceiling: knife, lamp, stone, bone, bread,
torch, clapper, shard, tonic, club, coat, key and Seal. Belt essentials cannot
be consumed, dropped or thrown. Ordinary loot occupies one pack slot each.

The pack starts at eight slots in the full slice, subject to measurement:
report pickups offered against free slots, especially on floor two. Six may
produce better decisions. Slot count is a parameter, not an article of faith.
Ordinary item details include one short provenance line in the lost-property
voice. The four-slot M1 pack is a deliberately small interaction prototype.

## Put the place back together

The Bell Porter is missing its clapper. Keep it as a strong HEAVY tool, or
return it and restore a lift linking the lower landing with the entrance.
The ordinary route remains open. Returning changes space and the owner's
behaviour; it does not dispense a better club that cancels the trade.
Returning late is allowed. If that dominates, tune the lift's placement/value
instead of inventing an expiry. One good restoration encounter is enough.

The Dawn Seal is GLOW. On the way home it reveals marks and optional panels
that were invisible on descent, and keeps optional ghosts at a distance.
There are no return-trip spawns. Revealed content is a second look, with no
mandatory scavenger hunt or key behind a secret.

## Touch and combat

Tap an item to select it. Valid adjacent view targets show a marker with a
verb: PLACE, BURN or RETURN. Tap that marker to commit exactly that action.
Unmarked things do nothing with a selected item. Portrait uses are explicit
EAT/WEAR markers when implemented. Throwing eventually has its own TOSS verb
and short lane preview; no automatic throws or combinations.

Turning, inspecting, selecting and rearranging the pack are free. Movement,
pickup, placement, use, equipping, strikes, guard and wait advance one beat.
Invalid commands change nothing. A wind-up advertises fixed threatened cells;
the next committed beat resolves that attack without expanding or retargeting
it. Guard blocks one adjacent physical strike; recovery is the safe opening.
M1's Husk holds its post. Later, approach and hound lanes add movement.

The slice adds a Husk, a FOOD-bribable hound and an optional GLOW-sensitive
ghost, introduced separately. Required fights have repeatable starter counters.
No theft, item-eating enemies, item-swallowing pits or unannounced off-screen
damage. Weight gates latch open so tools can be recovered without trapping
the player. Required FIRE has a reachable renewable source before its web.

Death ends the run. Retry seed starts over. Leaving with the Seal wins.
Knowledge-only Ledger cards remember observed interactions, with no permanent
power. M2 adds staged `user://run.json` plus backup; M1 has no disk persistence.
Receipts/reconciliation wait for an evidenced need. No daily seed yet.

## The phone is the design surface

154 x 342 logical pixels, nearest filtering, VETKA 16 px minimum. Text fits
roughly 21–22 characters per line; actual font widths are checked too. Touch
targets are at least 18 x 18 logical pixels. No required swipes or joystick.

| Band | Purpose |
| --- | --- |
| y 0–117 | Illustrated first-person view; seed/new-run access within it |
| y 118–153 | Two feedback lines |
| y 154–189 | Finder portrait, health, facing, equipment presentation |
| y 190–237 | Pack and selected-item detail |
| y 238–261 | Up to three explicit verbs |
| y 262–341 | Six movement buttons; bent turn arrows, straight strafe arrows |

Painted/reduced 64/40 px monsters, simplified 24 px variants, illustrated
masonry and portrait, code-drawn UI and item symbols. Quieter masonry and
reactive portraits are later polish. Original sparse modal bell music is M4;
do not reuse Warren/VETKA Bach pieces. An invented publisher splash and an
old-style manual are later personality work, not blockers for first play.

## Build order and stopping points

**M1:** generated tiny floor, first-person movement, stone pickup, selected
PLACE marker, plate/latching gate, one Husk, exit/retry/new seed. Real existing
spike art. No saves, title flow, equipment rules or restoration yet. A witness
and a real-touch pilot traverse it end to end. Ask whether the minute is fun.

**M2:** complete two-floor Seal run, pack/equipment choices, keys, title/end,
saves and Android interruption acceptance. Tune movement/combat before adding
more content. **M3:** the five capabilities, hound/ghost, explicit throwing,
Porter restoration, return reveals and hinted secret. **M4:** accepted art,
original audio, concise Ledger, variation, manual and phone finish.

## Open disagreements

No R2 disagreement blocks M1. I accept deferring fallback runs and persistence
machinery; bounded construction plus an explicit error is sufficient now.
For the full slice, six versus eight pack slots remains empirical: start at
eight and reduce only when offered-loot measurements and play justify it.
Runtime-cached wall patches are my choice for M1, so texture changes need no
Python rebuild. The tiny layout has limited variation; do not mistake its
seed sweep for evidence that repeated full runs will be interesting.
