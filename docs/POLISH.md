# Small things waiting in the Undercroft

The kit is nearly complete. Prefer finishing its integration and looking at
it on the phone before commissioning more art. Costs below mean hands-on
implementation and one focused check; phone review is additional.

## Already covered

Checked against A's current `main.gd` and `dungeon_view.gd`, and B's
`docs/ART.md`, on 28 October 2026. These are source-level integration findings,
not a claim that this latest combination has passed phone review.

| Earlier delight | What now covers it |
| --- | --- |
| ~~More convincing strikes~~ | B's three-frame EDGE/HEAVY/hands effects, damage burst and numbers; A draws them from accepted combat events, with recoil/portrait feedback. Avoid another screen shake layer. |
| ~~The Finder catches a breath~~ | C's fine/hurt/near-death portraits, including the stronger v2 injuries. A selects near-death at 1 HP, hurt at 2–3 HP or during the short hit reaction. Fine remains the original face. |
| ~~A little glint on something useful~~ | B's three-frame gold/selected glints, wired by A with stable object phases and a long quiet interval. Decorative candles and puddles should not receive these cues. |
| ~~Architecture that tells you where you are~~ | B's stairs, gates, lift and exit faces/overlays, wired by A to actual fixtures and their state. C supplies matching painted walls, surface variants and room props; prop/surface placement is still a separate integration choice. |
| ~~A sconce that remembers its wall~~ | A selects C's painted wall dressing by a stable face hash; sconces alternate the two flame frames at 250 ms. |
| ~~A mote caught in the lamp~~ | A adds C's restrained ambience over the dungeon view and disables it on menus. Floor selection also enables the existing decorative floor-two drips. |
| ~~Owners' little histories~~ | A loads C's provenance into cards/pickup text with catalog fallback. The clapper's existing purpose and tutorial remain game-owned text. |
| ~~A dignified epitaph~~ | A selects C's death couplets using presentation-only seed/turn indexing. Retry and seed remain on the result screen. |
| ~~A quiet stair blackout~~ | A saves the committed action before C's fade-out, synchronizes at black, then fades in using the existing transition gate. |
| ~~A warm homecoming~~ | C's dawn/Seal plate and B's win music are selected by A from a committed win. The new three-state dawn sequence below still needs its presentation clock. |
| A moth on the publisher screen | **Art covered in this batch:** two registered wing states, fixed key body and lettering. A still needs to choose the frame by elapsed menu time. |
| A small life in the still pictures | **Art covered in this batch:** title lamp, dawn/Seal and flame→ember→dark sequences. Timings and end holds are in `ENV_ART.md`; playback remains A's work. |
| The restored Porter's bow | B's restored pose and A's state swap already give RETURN a visible response. A separate animated bow would be extra; defer it. |

## Earlier picks still worth considering

| Delight | Remaining cost | Hook and acceptance |
| --- | --- | --- |
| The lift answers the bell | 20–40 min | One muted chain tick after the existing restoration chord, once per restoration event. B's working-lift art already supplies the visual change. |
| The coat's last stitch | 20–40 min | A soft tear on the existing armour-absorbed event instead of its generic bump. No new durability or longer input lock. |
| A drain answers a footfall | 45–75 min | A quiet metallic step on an accepted move onto a tagged floor drain. Wait until decorative surface placement is settled. |
| A bell-shaped tapestry stain | 15–30 min | Place an existing tapestry near the Porter. Recognition is the reward; no mandatory clue or hidden interaction. |
| Put the stone down gently | 20–35 min | DROP/PLACE currently reuse pickup audio. Add a subdued local set-down sound without physics, moving loot or an extra turn. |
| Water only where it belongs | 20–40 min | The floor-two drip effect is wired. Refine it to damp rooms once decoration tags exist; do not add another overlay or imply a water hazard. |
| A scratch on the automap | 60–90 min, defer | A's new survey records seen space; it is not a player annotation tool. Manual marks would still need a clear touch control and saved-state work. |

## Small additions now that the kit is full

| Delight | Cost | Hook and acceptance |
| --- | --- | --- |
| Let the last picture settle | 10–20 min | During a result animation, an art tap may jump straight to its final held frame. RETRY/NEW RUN keep working immediately. No new mandatory wait. |
| One distant drip | 20–40 min | A sparse, quiet floor-two water sound after a long idle pause. Respect SFX OFF and app backgrounding; no turn/RNG consumption or false enemy cue. |
| The map unfolds | 15–30 min | A brief dry paper sound on MAP, softer on CLOSE. One sound per accepted open/close, using existing controls. |
| A remembered publisher | 10–20 min | Show the existing skippable splash once per launch, rather than again on each trip back to the title. Keep its two wing states slow. |
| The last item comes home | 20–35 min | Once on a committed win, pair the Seal's pulse with one soft chime already available in the audio kit. Keep the win music underneath and respect both audio switches. |

Keep decorations quiet enough that B's interaction glints and raised-arm tells
stay obvious. Any new motion should use at most two or three distinct frames.
The room kit supplies atmosphere; placement must preserve item visibility and
the distinction between a usable opening and a painted recess.
