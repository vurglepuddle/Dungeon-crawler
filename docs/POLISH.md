# Small things waiting in the Undercroft

Codex C's next-pick list. Estimates are hands-on implementation plus a focused
check, assuming existing assets and controls. Phone review is additional.
No feature below is implemented by this document. Prices are time, not money.

| Delight | Approximate cost | Hook and acceptance |
| --- | --- | --- |
| A sconce that remembers its wall | 30–60 min | Stable face hash selects the new two-frame texture. Turn away/back: the fixture stays put; no global RNG. |
| The lift answers the bell | 20–40 min | One muted chain tick after the restoration chord. Limit to the visible landing, once per restoration event. |
| A moth on the publisher screen | 30–60 min | Two hand-pixel wing states around the existing Lost Moth mark. Skippable; no delay before CONTINUE. |
| A mote caught in the lamp | 15–30 min | Wire `ambience.gd`; keep dust off menus and below interaction cues. Check the glints still stand out. |
| Water only where it belongs | 30–60 min | Enable floor-two drips in wet rooms; later use a visible damp-wall marker. Never imply a new water hazard. |
| A warm homecoming | 30–60 min | Show the dawn/Seal vignette after a committed win; one warm chord, then existing retry/new-run actions. |
| The Finder catches a breath | 20–40 min | Select the new fine/hurt/near-death portrait at health thresholds. A short hurt reaction may override the fine face. |
| The coat's last stitch | 30–45 min | One soft tear on the existing armour-absorbed event; its card already records spent padding. No new durability. |
| A drain answers a footfall | 45–90 min | Quiet metallic step on a tagged grate-adjacent tile, only on accepted movement. Decoration never steals the action. |
| A bell-shaped tapestry stain | 20–40 min | Place one existing tapestry near the Porter. Let players recognise it; no mandatory hidden clue or new text. |
| Owners' little histories | 30–60 min | Load the provenance JSON into item cards. Respect two lines of at most 21 characters; preserve the clapper tutorial. |
| A dignified epitaph | 20–40 min | Pick a death couplet by seed/turn without consuming simulation RNG. Keep seed and retry available. |
| A quiet stair blackout | 30–60 min | Wire the fade completion handshake to existing input gating; save before animation. Cancel safely on menu/resume. |
| Put the stone down gently | 30–45 min | Distinguish DROP from pickup with a small local thunk. No physics, extra turn, or moving loot. |
| A scratch on the automap | 45–90 min | Optional player mark on seen cells, behind a clear tool. Needs save-schema work and touch review; defer until map UI has room. |
| The restored Porter's bow | 1–2 h | A tiny nod after RETURN, using B's accepted art. Do not delay input beyond the current action animation. |

Good first bundle: deterministic wall dressing, restrained ambience, reactive
portrait, and the two ending pictures. They add place and character using
events the game already owns.

Keep decorative arches distinct from a usable route. A locked-looking painting
must never impersonate UNLOCK, and a bright flame must never hide a target glint.
