# M1 game art

These five PNGs are exact copies of the approved pipeline spike's reduced
outputs, not references to files outside the exported game. Their original
painted sources, code variant, shared palette and prompts remain editable in
`art_src/spike/`. The near/middle Husk and portrait/wall came from original
built-in image generation; the distant Husk was drawn by code. No external
asset pack or runtime service is involved.

| Game asset | Spike output |
| --- | --- |
| stone_wall.png | results/stone_wall_64.png |
| bell_husk_64.png | results/bell_porter_painted_h64.png |
| bell_husk_40.png | results/bell_porter_painted_h40.png |
| bell_husk_24.png | results/bell_porter_code_h24.png |
| finder.png | results/finder_portrait_32.png |

The controller draws the small inventory stone and arrows in code. The view
creates simple local stone/plate/exit sprites and caches wall-column images
once at load. M1 reuses one Husk pose with a dimmed/lowered recovery display;
distinct poses and quieter masonry remain later art work.
