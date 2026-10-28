# Frozen r9 pack icons

These fifteen PNGs are exact copies of the committed r9 runtime set from
`d400b98`, saved before B's r10 revision. The original manifest stores their
hashes under the then-current runtime paths; r10 verification resolves each
filename to this archive and checks the bytes here.

`build_pack_icons_snapshot.py` and `verification.json` are historical records.
Use the normal `art_src/items/build_pack_icons.py` entry point for the current
set; the snapshot is not intended to be executed from this archive directory.
Original painted source images/prompts remain in their accepted locations.
