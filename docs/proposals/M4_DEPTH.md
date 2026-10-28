# M4 depth: the lower watch

Written before implementation. The owner's six-minute phone run is the
baseline; the following timings are targets until another human plays.

## The change I recommend

Make new ordinary games three floors. Preserve old two-floor Continues
exactly, and keep floor count available as a parameter. Do not stretch the
first two floors or close off their easily missed branches. The brazier,
kennel and cold wick remain discoveries rather than mandatory tutorials.

Floor three, **The Lower Watch**, recombines familiar pieces. Its keyed
gate always appears, with the seed still choosing the weight-gate module,
loop reach/side and loot. An Ash Hound waits in the side loop near the key;
it can be fed, fought or manoeuvred around. The ordinary Husk occupies the
spine. A corded side chapel holds a Wick Ghost and a tonic. A webbed opposite
storeroom offers fresh padding and supplies. These extra branches stay
optional and easy to walk past. Light and food are offered before commitment.

Use the existing 17x17 construction and art. No new creature, item kind,
clock, resource meter, chase respawn or party member. The Porter still
reconnects entrance and deepest landing: returning the clapper becomes an
especially welcome reward after the third descent. Stairs remain viable.

## Difficulty that is fair on the phone

Floors one and two retain their current damage and timing. On new deeper
floors, Husk/Ghost mistakes cost **2 HP**, and a Hound lunge costs **3 HP**.
Announce those stakes in short intent/inspection text. Keep exactly one
committed beat between wind-up and impact, the stored two-cell Hound lane,
free turning, universal GUARD and full recovery counters. Do not inflate HP.

An intact coat still absorbs one whole hit. Saving it for a deep lunge is
now worth three health; its torn floor sprite makes the spent state legible.
FOOD can end the Hound encounter quickly or heal a wound. A tonic restores
two, making a missed deep tell a consequential but recoverable mistake.
Guarantee accessible food, a fresh coat and healing on three, while leaving
inventory capacity unchanged. Do not make the required key depend on FIRE,
GLOW or an unconsumed ration. Ordinary fighting must always remain possible.

I disagree with forcing food use through unavoidable chip damage. Our good
contract is that a careful player can learn to avoid damage. More damage
alone also does not create tactical depth. The Hound/key crossing, optional
wards, supplies and restoration choice have to carry that part. If a human
still finds the run trivial, tune encounter geometry before adding health.

## Length and what we measure

Target **10-15 minutes for an exploring, careful first run**. The accepted
two-floor capability route takes about 120 bot turns and six human minutes;
a third floor with both optional detours should approach 190-250 turns.
This is a pacing hypothesis, not a stopwatch conversion. A knowledgeable
Seal runner who misses branches should be faster; that is desirable.

Report separate core and capability-tour turn ranges over hundreds of seeds,
plus a real-tap three-floor pilot. Do not pad a corridor just to meet a number.
If the safe recombination falls short, leave additional layout expansion for
review instead of declaring a ten-minute run from bot timings alone.

## Proof and compatibility

Use a new rules/content/generator profile only for newly constructed deep
runs. Old m3.3 snapshots store their explicit floors and one-damage actors;
Continue never regenerates or upgrades them. Keep existing two-floor proof
and pilot cohorts available explicitly, and retain exact legacy hashes.

The witness must replay ordinary actions down and home, for keeping and
returning the clapper, with an additional capability tour through the new
branches. A no-damage witness proves that encounters are avoidable; it does
not prove challenge, pacing or that a person will need healing. Separately
test deliberate missed deep tells, whole-hit coat absorption, healing and
feeding the deep Hound. Validate new damage fields before reading them.

Keep three actors maximum on a deep floor. If a landing is occupied, that
actor already uses one of the three: its three clear neighbours therefore
cannot all be occupied by the remaining two. SIDLE remains a safe escape.
Reserve creature/fixture/loot cells as before. Never consume a required tag,
steal a key, close a solved return gate or strand a dropped weapon.

## What I would cut

First cut extra storeroom loot if pack pressure becomes busywork. Cut one
optional deep ward if the third floor repeats the first two too literally.
Reduce the Hound's hit to two if the three-point lesson feels punitive on
touch. Keep the third floor and Porter shortcut if those earn their minutes.
Leave mandatory attrition, additional enemies, longer floors, multi-enemy
timing puzzles and any guarantee of 10-15 minutes for review. They need
human evidence beyond a solvable seed and a green pilot.
