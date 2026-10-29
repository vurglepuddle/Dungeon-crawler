# Verb icons on one sheet

All 36 button icons on one indexed canvas, so they can be painted and
compared side by side.

- **`verb_sheet.png`** is the sheet to paint. It is 96x96 and indexed, using
  the icons' shared palette, with index 0 transparent.
  - Each icon keeps its canvas: 12x12, or 6x12 and 8x12 for the narrow
    versions of long words.
  - Slots sit on a 16 px grid. Pixels outside a slot are ignored.
- **`verb_sheet_guide.png`** outlines each slot. Put it on a layer under the
  icons, and hide or delete that layer before saving.
- **`verb_sheet_labels_6x.png`** is an enlarged reference with each slot's
  name ("c6" and "c8" are the narrow versions).
- **`layout.json`** says which slot is which file.

After painting, save the sheet as an indexed PNG, then run this from the
repository root:

```
python art_src/ui_offer/verb_sheet/verb_sheet.py split
```

That rewrites only the icons that changed in `assets/art/ui_offer/verb_*.png`.
If someone edits single icon files instead, `verb_sheet.py make` rebuilds
the sheet from them.
